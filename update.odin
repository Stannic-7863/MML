package main

import "core:time"
import im "imgui"

handle_tokens :: proc(state: ^State) {
	handle_token_physics(state)
	handle_token_events(state)
	handle_token_grid(state)
	render_tokens(state)
}

handle_token_grid :: proc(state: ^State) {
	if state.just_sorted {
		for sort_crit, sort_crit_index in state.sort_crit {
			if sort_crit_index == 0 {
				continue
			}
			index := sort_crit.index
			prev_hash := state.sort_crit[sort_crit_index - 1].hash
			hash := sort_crit.hash

			if hash != prev_hash {
				token_old_hash := get_hash_key(
					get_cell_coords(state.tokens[index].old_pos, state.config.physics.cell_size),
					cast(i32)len(state.tokens),
				)

				if val, ok := state.look_up[token_old_hash];
				   ok && val == cast(i32)sort_crit_index {
					delete_key(&state.look_up, token_old_hash)
				}

				state.look_up[hash] = cast(i32)sort_crit_index
			}
		}
	}
}

handle_token_events :: proc(state: ^State) {
	if !(im.IsWindowHovered()) {
		return
	}

	wheel := im.GetIO().MouseWheel / 5
	state.camera.zoom += wheel
	state.camera.zoom = state.camera.zoom <= 0.1 ? 0.1 : state.camera.zoom

	handle_camera_drag(state)

	if im.IsMouseClicked(.Left) {
		state.mouse.clicked_time = time.now()
	}

	if (im.IsMouseDown(.Left)) {
		if time.since(state.mouse.clicked_time) > time.Millisecond * 300 &&
		   state.mouse.hovered_token != nil {
			state.mouse.dragged_token = state.mouse.hovered_token
		}
	}

	if !im.IsMouseReleased(.Left) {
		return
	}

	if time.since(state.mouse.clicked_time) < time.Millisecond * 300 {
		state.mouse.clicked_token = state.mouse.hovered_token
	}
	state.mouse.dragged_token = nil
}

handle_camera_drag :: proc(state: ^State) {
	if !im.IsMouseDown(.Right) {
		state.camera.is_dragging = false
		return
	}

	if (state.camera.is_dragging) {
		state.camera.target += (state.mouse.pos - state.camera.drag_offset)
		state.camera.drag_offset = state.mouse.pos
		return
	}

	state.camera.is_dragging = true
	state.camera.drag_offset = state.mouse.pos
}
