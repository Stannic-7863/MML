package main

import "core:fmt"
import "core:math/rand"
import "core:os/os2"


@(private = "file")
Parser_Token_Type :: enum {
	File_Path,
	Identifier,
	Inline_Content,
}

@(private = "file")
Parser_Token :: struct {
	type:  Parser_Token_Type,
	value: string,
}

@(private = "file")
Parser_Connection_Token :: struct {
	parent: string,
	child:  [dynamic]string,
}


parse_mml :: proc(text: string) -> [dynamic]Token {
	parser_tokens: [dynamic]Parser_Token
	defer delete(parser_tokens)
	parser_connection_tokens: [dynamic]Parser_Connection_Token
	defer delete(parser_connection_tokens)
	defer for e in parser_connection_tokens {
		delete(e.child)
	}

	is_parsing_identifier: bool
	is_parsing_inline_content: bool
	is_parsing_filepath: bool

	parser_token_start_index: int = 0
	parser_loop_index: int

	parser_loop: for parser_loop_index < len(text) {
		switch text[parser_loop_index] {
		case '[':
			if is_parsing_inline_content {
				break
			}
			parser_token_start_index = parser_loop_index + 1
			is_parsing_identifier = true
		case ']':
			if is_parsing_inline_content {
				break
			}
			t: Parser_Token
			t.type = .Identifier
			t.value = text[parser_token_start_index:parser_loop_index]
			append(&parser_tokens, t)
			is_parsing_identifier = false

		case '{':
			if !is_parsing_inline_content {
				parser_token_start_index = parser_loop_index + 1
				is_parsing_inline_content = true
			}
		case '}':
			if text[parser_loop_index - 1] != '/' {
				break
			}
			t: Parser_Token
			t.type = .Inline_Content
			t.value = text[parser_token_start_index:parser_loop_index - 1]
			append(&parser_tokens, t)
			is_parsing_inline_content = false
		case '>':
			if !is_parsing_inline_content && text[parser_loop_index - 1] == '<' {
				break parser_loop
			}
		case '"':
			if !is_parsing_inline_content & !is_parsing_identifier {
				if !is_parsing_filepath {
					parser_token_start_index = parser_loop_index + 1
					is_parsing_filepath = true
					break
				}
				if is_parsing_filepath {
					is_parsing_filepath = false
					t: Parser_Token
					t.type = .File_Path
					t.value = text[parser_token_start_index:parser_loop_index]
					append(&parser_tokens, t)
				}
			}
		}
		parser_loop_index += 1
	}

	add_child_mode: bool
	current_connection_token: ^Parser_Connection_Token

	for parser_loop_index < len(text) {
		switch text[parser_loop_index] {
		case '[':
			parser_token_start_index = parser_loop_index + 1
		case ']':
			if add_child_mode {
				append(
					&current_connection_token.child,
					text[parser_token_start_index:parser_loop_index],
				)
				break
			}
			t: Parser_Connection_Token
			t.parent = text[parser_token_start_index:parser_loop_index]
			append(&parser_connection_tokens, t)
			current_connection_token = &parser_connection_tokens[len(parser_connection_tokens) - 1]
		case '(':
			add_child_mode = true
		case ')':
			add_child_mode = false
		}
		parser_loop_index += 1
	}

	// PRINT_VERBOSE(parser_connection_tokens)

	append(&parser_tokens, Parser_Token{type = .Identifier})

	tokens: [dynamic]Token
	current_token: ^Token
	first_token: bool = true
	last_identifier_index: int

	for parser_token, index in parser_tokens {
		if parser_token.type == .Identifier {
			if first_token {
				first_token = false
				continue
			}
			for p_t in parser_tokens[last_identifier_index:index] {
				switch p_t.type {
				case .Identifier:
					t: Token
					t.name = p_t.value
					t.childs = make([dynamic]^Token)
					t.associated_files = make([dynamic]Associated_File)
					t.content_blocks = make([dynamic]string)
					i := append(&tokens, t)
					current_token = &tokens[len(tokens) - 1]
				case .Inline_Content:
					append(&current_token.content_blocks, p_t.value)
				case .File_Path:
					content, err := os2.read_entire_file_from_path(p_t.value, os2.heap_allocator())
					if err != nil {
						fmt.println(err)
						break
					}
					append(
						&current_token.associated_files,
						Associated_File{path = p_t.value, content = content},
					)
				}
			}
			last_identifier_index = index
		}
	}

	for connection_token in parser_connection_tokens {
		for &parent_token in tokens {
			if parent_token.name != connection_token.parent {
				continue
			}
			for &token_child in tokens {
				for connection_token_name in connection_token.child {
					if token_child.name != connection_token_name {
						continue
					}
					append(&parent_token.childs, &token_child)
				}
			}
		}
	}

	for &t in tokens {
		t.child_count = get_total_childs(t)
		t.size = get_token_size(t)
	}
	return tokens
}
