package mml

import "core:fmt"
import "core:math/linalg"
import im "imgui"

render_tokens :: proc(state: ^State) {
	camera := state.camera
	mouse := state.mouse
	render := state.config.render
	drawlist := im.GetWindowDrawList()

	// handle colors 
	if mouse.hovered_token != nil {
		mouse.hovered_token.color = render.color_hovered
	}

	if mouse.clicked_token != nil {
		mouse.clicked_token.color = render.color_selected
	}

	if mouse.dragged_token != nil {
		mouse.dragged_token.pos = (mouse.pos - camera.target) / camera.zoom
		mouse.dragged_token.color = render.color_dragged
	}

	// draws the lines between each token 

	for &t in state.tokens {
		for c in t.childs {
			parent_pos := get_screen_to_world(t.pos, camera)
			child_pos := get_screen_to_world(c.pos, camera)

			thickness := camera.zoom * render.line_thickness
			color := get_color(t.color)
			im.DrawList_AddLine(drawlist, parent_pos, child_pos, color, thickness)

			direction := child_pos - parent_pos
			direction_length := linalg.length(direction)

			if direction_length == 0.0 {
				continue
			}

			normalized_dir := direction / direction_length

			arrowhead_length := 6.0 * camera.zoom
			arrowhead_width := 4.0 * camera.zoom

			tip := child_pos - normalized_dir * c.size * camera.zoom

			base := tip - normalized_dir * arrowhead_length

			perp := [2]f32{normalized_dir.y, -normalized_dir.x}

			left_wing := base + perp * arrowhead_width
			right_wing := base - perp * arrowhead_width

			im.DrawList_AddLine(drawlist, tip, left_wing, color, thickness)
			im.DrawList_AddLine(drawlist, tip, right_wing, color, thickness)
		}
	}

	for token in state.tokens {
		pos := get_screen_to_world(token.pos, camera)
		size := token.size * camera.zoom

		color := get_color(token.color)
		im.DrawList_AddCircleFilled(drawlist, pos, size, color, 32)

		color = get_color(render.color_font)
		im.DrawList_AddText(drawlist, pos, color, fmt.ctprint(token.name))
	}

	render_config_settings(&state.config)
	render_mml_editor(state)
}

render_associated_data :: proc(state: ^State) {
	render_data_selection(state)
	render_data_edit(state)
}

render_data_selection :: proc(state: ^State) {
	im.BeginChild("Data Selection for Viewing", {}, {.FrameStyle, .ResizeY})
	defer im.EndChild()

	if state.mouse.clicked_token == nil {
		return
	}

	im.SeparatorText("Associated Files")

	for &asso_files in state.mouse.clicked_token.associated_files {
		if im.Button(fmt.ctprint(asso_files.path)) {
			append(&state.mouse.clicked_token.tabs, &asso_files)
		}
	}

	im.SeparatorText("Inline Content")

	for inline_content in state.mouse.clicked_token.inline_contents {
		total_len := len(inline_content)
		text: string
		if total_len > 0 {
			if total_len < 30 {
				text = inline_content[:total_len - 1]
			} else {
				text = inline_content[:30]
			}
		}
		if im.Button(fmt.ctprintf("%s%s", text, "...")) {
			append(&state.mouse.clicked_token.tabs, inline_content)
		}
	}
}

render_data_edit :: proc(state: ^State) {
	im.BeginChild("Data View", {}, {.FrameStyle})
	defer im.EndChild()

	if state.mouse.clicked_token == nil {
		return
	}

	im.BeginTabBar("associated data editor tab bar")
	defer im.EndTabBar()

	to_close: int = -1

	for tab, index in state.mouse.clicked_token.tabs {
		is_open: bool = true
		switch v in tab {
		case ^Associated_File:
			if im.BeginTabItem(fmt.ctprintf("%s ##hidden %i", v.path, index), &is_open) {
				defer im.EndTabItem()

				im.SeparatorText(fmt.ctprint(v.path))

				avail_space := im.GetContentRegionAvail()
				button_size := im.CalcTextSize("Discard Commit").x + 2 * im.GetStyle().ItemSpacing.x + 2 * im.GetStyle().FramePadding.x * 2

				im.SameLine(avail_space.x - button_size)

				if im.IsWindowFocused() && im.IsKeyDown(.LeftCtrl) && im.IsKeyPressed(.S) {
					write_to_associated_file(v.path, v.backing_buffer[:])
				}

				if im.Button("Commit") {
					write_to_associated_file(v.path, v.backing_buffer[:])
				}

				if im.IsItemHovered() {
					im.SetTooltip("Ctrl + s to save")
				}

				buf_cstr := cstring(raw_data(v.backing_buffer[:]))
				im.InputTextMultiline(
					"##hidden Associated File Edit",
					buf_cstr,
					len(v.backing_buffer) + 1, // for null termination
					avail_space,
					{.AllowTabInput, .CallbackResize},
					multiline_edit_resize_callback,
					&v.backing_buffer,
				)
			}
		case string:
			if im.BeginTabItem(fmt.ctprintf("[ReadOnly] Inline Block %i", index), &is_open) {
				im.InputTextMultiline("##hidden inline content view", fmt.ctprint(v), len(v), {}, {.ReadOnly})
				im.EndTabItem()
			}
		}

		if !is_open {
			to_close = index
		}

	}

	if to_close >= 0 {
		unordered_remove(&state.mouse.clicked_token.tabs, to_close)
	}
}

render_config_settings :: proc(config: ^Config) {

	im.PushStyleColorImVec4(im.Col.FrameBg, im.GetStyle().Colors[im.Col.WindowBg])
	if im.CollapsingHeader("Settings") {
		// Render settings
		im.Indent()
		defer im.Unindent()
		if im.CollapsingHeader("Render Settings") {
			im.SliderFloat4("Font Color", &config.render.color_font, 0.0, 1.0)
			im.SliderFloat4("Default Color", &config.render.color_default, 0.0, 1.0)
			im.SliderFloat4("Hover Color", &config.render.color_hovered, 0.0, 1.0)
			im.SliderFloat4("Drag Color", &config.render.color_dragged, 0.0, 1.0)
			im.SliderFloat4("Selected Color", &config.render.color_selected, 0.0, 1.0)
			im.SliderFloat("Line Thickness", &config.render.line_thickness, 0.1, 10.0)
		}
		// Physics settings
		if im.CollapsingHeader("Physics Settings") {
			physics := &config.physics
			im.SliderFloat("Cell Size", &physics.cell_size, 1.0, 500.0)
			im.SliderFloat("Damping Factor", &physics.damping_factor, 0.0, 1.0)
			im.SliderFloat("Scale Factor", &physics.scale_factor, 0.1, 10.0)
			im.SliderFloat("Min Distance", &physics.min_distance, 0.0, 1000.0)
			im.SliderFloat("Max Distance", &physics.max_distance, 0.0, 1000.0)
			im.SliderFloat("Sibling Min Distance", &physics.sibling_min_distance, 0.0, 1000.0)
			im.SliderFloat("Sibling Repulsion Force", &physics.sibling_repulsive_force, 0.0, 1000.0)
			im.SliderFloat("Neigbour Min Distance", &physics.neighbour_min_distance, 0.0, 1000.0)
			im.SliderFloat("Neigbour Repulsion Force", &physics.neighbour_repulsive_force, 0.0, 10.0)
			im.SliderFloat("Repulsion Force", &physics.repulsive_force, 0.0, 1000.0)
			im.SliderFloat("Attraction Force", &physics.attraction_force, 0.0, 1000.0)
			im.SliderFloat("Global Gravity", &physics.global_gravity, -10.0, 10.0)
			im.SliderFloat2("Global Center", &physics.global_center, -1000.0, 1000.0)
		}
	}
	im.PopStyleColor()
}

render_mml_editor :: proc(state: ^State) {
	if im.CollapsingHeader("mml editor") {

		im.PushStyleColorImVec4(im.Col.FrameBg, im.GetStyle().Colors[im.Col.WindowBg])
		defer im.PopStyleColor()

		if !state.mml.is_loaded {
			return
		}

		avail_space := im.GetContentRegionAvail()

		if im.IsWindowFocused() && im.IsKeyDown(.LeftCtrl) && im.IsKeyPressed(.S) {
			write_to_associated_file(state.mml.file.path, state.mml.file.backing_buffer[:])
			reload_tokens(state)
		}

		buf_cstr := cstring(raw_data(state.mml.file.backing_buffer[:]))
		text_space := im.CalcTextSize(buf_cstr, nil, false, avail_space.x)
		text_space.x = avail_space.x
		text_space.y += 60
		im.InputTextMultiline(
			"##hidden Associated File Edit",
			buf_cstr,
			len(state.mml.file.backing_buffer) + 1, // for null termination
			text_space,
			{.AllowTabInput, .CallbackResize},
			multiline_edit_resize_callback,
			&state.mml.file.backing_buffer,
		)
	}
}
