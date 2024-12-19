package mml

import "core:fmt"
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

parse_mml_from_file :: proc(path: string) -> (mml_file: [dynamic]byte, tokens: [dynamic]Token, ok: bool) {
	file, err := os2.read_entire_file_from_path(path, context.temp_allocator)

	if err != nil {
		delete(file)
		ERROR_F("Error opening mml file.\nProvided Path : %s\nError : %v", path, err)
		return {}, nil, false
	}

	INFO_F("Loaded mml file from path \"%s\"", path)
	backing_buff := make([dynamic]byte)

	for b in file {
		append(&backing_buff, b)
	}

	tokens = parse_mml(cast(string)backing_buff[:], path)

	return backing_buff, tokens, true
}

parse_mml :: proc(mml_str: string, path: string) -> [dynamic]Token {
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

	parser_loop: for parser_loop_index < len(mml_str) {
		switch mml_str[parser_loop_index] {
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
			t.value = mml_str[parser_token_start_index:parser_loop_index]
			append(&parser_tokens, t)
			is_parsing_identifier = false

		case '{':
			if !is_parsing_inline_content {
				parser_token_start_index = parser_loop_index + 1
				is_parsing_inline_content = true
			}
		case '}':
			if mml_str[parser_loop_index - 1] != '/' {
				break
			}
			t: Parser_Token
			t.type = .Inline_Content
			t.value = mml_str[parser_token_start_index:parser_loop_index - 1]
			append(&parser_tokens, t)
			is_parsing_inline_content = false
		case '>':
			if !is_parsing_inline_content && mml_str[parser_loop_index - 1] == '<' {
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
					t.value = mml_str[parser_token_start_index:parser_loop_index]
					append(&parser_tokens, t)
				}
			}
		}
		parser_loop_index += 1
	}

	add_child_mode: bool
	current_connection_token: ^Parser_Connection_Token

	for parser_loop_index < len(mml_str) {
		switch mml_str[parser_loop_index] {
		case '[':
			parser_token_start_index = parser_loop_index + 1
		case ']':
			if add_child_mode {
				append(&current_connection_token.child, mml_str[parser_token_start_index:parser_loop_index])
				break
			}
			t: Parser_Connection_Token
			t.parent = mml_str[parser_token_start_index:parser_loop_index]
			append(&parser_connection_tokens, t)
			current_connection_token = &parser_connection_tokens[len(parser_connection_tokens) - 1]
		case '(':
			add_child_mode = true
		case ')':
			add_child_mode = false
		}
		parser_loop_index += 1
	}

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
					t.inline_contents = make([dynamic]string)
					t.tabs = make([dynamic]Tab)

					append(&tokens, t)
					current_token = &tokens[len(tokens) - 1]

				case .Inline_Content:
					append(&current_token.inline_contents, p_t.value)

				case .File_Path:
					last_slash: int
					for i := len(path) - 1; i >= 0; i -= 1 {
						if path[i] == '/' || path[i] == '\\' {
							last_slash = i
							break
						}
					}

					mml_dir := path[:last_slash]

					if mml_dir == "" {
						break
					}

					data, err := os2.read_entire_file_from_path(fmt.tprintf("%s/%s", mml_dir, p_t.value), context.temp_allocator)
					if err != nil {
						ERROR_F("Error : %v", err)
						break
					}

					backing_buffer := make([dynamic]byte, len(data) + 1)
					copy(backing_buffer[:], data)
					append(
						&current_token.associated_files,
						Associated_File{path = fmt.aprintf("%s/%s", mml_dir, p_t.value), backing_buffer = backing_buffer},
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
