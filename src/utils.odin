package mml

import "core:math/linalg"
import "core:os/os2"
import im "imgui"

new_state :: proc() -> State {
	INFO("New State")
	return {
		config = get_default_config(),
		tokens = make([dynamic]Token),
		sort_crit = make([dynamic]Sort_Criteria),
		look_up = make(map[i32]i32),
		camera = {zoom = 1},
	}
}

reload_state :: proc(state: ^State) {
	delete(state.mml.file.backing_buffer)
	mml_str, tokens, ok := parse_mml_from_file(state.mml.file.path)
	if ok {
		state.mml.file.backing_buffer = mml_str
		delete_state_token_data(state^)
		state.look_up = make(map[i32]i32)
		state.tokens = make([dynamic]Token)
		state.sort_crit = make([dynamic]Sort_Criteria)
		state.tokens = tokens
		state.mouse.hovered_token = nil
		state.mouse.dragged_token = nil
		state.mouse.clicked_token = nil
		for i in 0 ..< len(state.tokens) {
			append(&state.sort_crit, Sort_Criteria{index = cast(i32)i})
		}
		INFO("Reloaded State")
		radial_spread(&state.tokens[0], state.config)
	}
}

reload_tokens :: proc(state: ^State) {
	tokens := parse_mml(string(state.mml.file.backing_buffer[:]), state.mml.file.path)
	delete_state_token_data(state^)
	state.look_up = make(map[i32]i32)
	state.tokens = make([dynamic]Token)
	state.sort_crit = make([dynamic]Sort_Criteria)
	state.tokens = tokens
	state.mouse.hovered_token = nil
	state.mouse.dragged_token = nil
	state.mouse.clicked_token = nil
	for i in 0 ..< len(state.tokens) {
		append(&state.sort_crit, Sort_Criteria{index = cast(i32)i})
	}
	INFO("Reloaded Tokens")
}

delete_state :: proc(state: State) {
	if state.mml.is_loaded {
		delete(state.mml.file.path)
	}
	delete(state.mml.file.backing_buffer)
	delete_state_token_data(state)
	INFO("Delete State")
}

delete_state_token_data :: proc(state: State) {
	INFO("Delete token data")
	for t in state.tokens do delete_token(t)
	delete(state.tokens)
	delete(state.sort_crit)
	delete(state.look_up)
}

delete_token :: proc(t: Token) {
	for f in t.associated_files {
		delete(f.backing_buffer)
	}
	delete(t.tabs)
	delete(t.childs)
	delete(t.associated_files)
	delete(t.inline_contents)
}

get_default_config :: proc() -> Config {
	return Config {
		physics = {
			cell_size = 120,
			damping_factor = 0.90,
			scale_factor = 50.0,
			min_distance = 100,
			max_distance = 300,
			sibling_min_distance = 60,
			sibling_repulsive_force = 0.5,
			neighbour_min_distance = 80,
			neighbour_repulsive_force = 0.5,
			global_gravity = 0.5,
			repulsive_force = 1.5,
			attraction_force = 1.2,
			global_center = {0, 0},
		},
		render = {
			line_thickness = 1.5,
			color_dragged = [4]f32{0.457, 0.296, 0.235, 1.0},
			color_default = [4]f32{0.6, 0.4, 0.3, 1.0},
			color_hovered = [4]f32{0.62, 0.63, 0.83, 1.0},
			color_selected = [4]f32{0.7, 0.2, 0.25, 1.0},
			color_font = [4]f32{1.0, 1.0, 1.0, 1.0},
		},
	}
}

apply_verlet :: proc(t: ^Token, scale_factor: f32, damp_factor: f32 = 0.9) {
	temp := t.pos
	t.pos = (2 * t.pos - t.old_pos + t.force / scale_factor)
	t.force = 0
	t.old_pos = temp

	velocity := t.pos - t.old_pos
	t.pos = t.old_pos + velocity * damp_factor
}

token_sort_proc :: proc(i, j: Sort_Criteria) -> bool {
	return i.hash < j.hash
}

write_to_associated_file :: proc(path: string, content: []byte) {
	err := os2.write_entire_file(path, content)
	if err != nil {
		INFO_F("Error saving file.\nFile path : %s\nError : %v", path, err)
		return
	}
	INFO_F("File Saved at path \"%s\"", path)
}

radial_spread :: proc(token: ^Token, config: Config, total_spread: f32 = linalg.PI * 2, initial: f32 = 0) {

	dist := config.physics.max_distance - config.physics.min_distance
	dist /= 2

	spread := total_spread / cast(f32)len(token.childs)

	initial: f32 = 0

	for &c, index in token.childs {

		x := linalg.cos(initial) * dist
		y := linalg.sin(initial) * dist

		c.pos = {x, y} + token.pos
		c.old_pos = c.pos

		initial += spread

		radial_spread(c, config, linalg.PI / 3, initial - linalg.PI / 3)
	}
}
