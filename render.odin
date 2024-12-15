package main

import "core:fmt"
import "core:strings"
import im "imgui"
import im_glfw "imgui/imgui_impl_glfw"
import im_gl "imgui/imgui_impl_opengl3"
import gl "vendor:OpenGL"
import "vendor:glfw"

render_tokens :: proc(state: ^State) {
	camera := state.camera
	mouse := state.mouse
	render := state.config.render
	drawlist := im.GetWindowDrawList()

	if mouse.hovered_token != nil {
		mouse.hovered_token.color = render.color_hovered
	}

	if mouse.dragged_token != nil {
		mouse.dragged_token.pos = (mouse.pos - camera.target) / camera.zoom
		mouse.dragged_token.color = render.color_dragged
	}

	if mouse.clicked_token != nil {
		mouse.clicked_token.color = render.color_selected
	}

	// draws the lines between each token 
	for t in state.tokens {
		for c in t.childs {

			to := get_screen_to_world(t.pos, camera)
			from := get_screen_to_world(c.pos, camera)
			color := get_color(t.color)
			thickness := camera.zoom * render.line_thickness
			im.DrawList_AddLine(drawlist, to, from, color, thickness)
		}
	}

	// draws the tokens 
	for token in state.tokens {
		pos := get_screen_to_world(token.pos, camera)
		color := get_color(token.color)
		size := token.size * camera.zoom
		im.DrawList_AddCircleFilled(drawlist, pos, size, color, 32)

		color = get_color(render.color_font)
		im.DrawList_AddText(drawlist, pos, color, fmt.ctprint(token.name))
	}

	// draws and handles the settings
	render_config_settings(&state.config)
}

render_associated_data :: proc(state: State) {

	im.BeginChild("Select Data to View", {}, {.FrameStyle, .ResizeY})
	if state.mouse.clicked_token != nil {
		im.SeparatorText("Associated Files")
		for asso_files in state.mouse.clicked_token.associated_files {
			if im.Button(fmt.ctprint(asso_files.path)) {
				state.mouse.clicked_token.to_render = asso_files
			}
		}
		im.SeparatorText("Inline Content")
		for cont_block in state.mouse.clicked_token.content_blocks {
			total_len := len(cont_block)
			text: string
			if total_len > 0 {
				if total_len < 30 {
					text = cont_block[:total_len - 1]
				} else {
					text = cont_block[:30]
				}
			}
			if im.Button(fmt.ctprintf("%s%s", text, "...")) {
				state.mouse.clicked_token.to_render = cont_block
			}
		}
	}
	im.EndChild()
	im.BeginChild("Data View", {}, {.FrameStyle})
	if state.mouse.clicked_token != nil {
		switch to_render in state.mouse.clicked_token.to_render {
		case Associated_File:
			im.SeparatorText(fmt.ctprint(to_render.path))
			im.TextWrapped(fmt.ctprintf("%s", to_render.content))
		case string:
			im.TextWrapped(fmt.ctprint(to_render))
		}
	}
	im.EndChild()
}

render_config_settings :: proc(config: ^Config) {

	im.PushStyleColorImVec4(im.Col.FrameBg, im.GetStyle().Colors[im.Col.WindowBg])

	if im.CollapsingHeader("Settings") {
		// Render settings
		im.SeparatorText("Render Settings")
		im.SliderFloat4("Font Color", &config.render.color_font, 0.0, 1.0)
		im.SliderFloat4("Default Color", &config.render.color_default, 0.0, 1.0)
		im.SliderFloat4("Hover Color", &config.render.color_hovered, 0.0, 1.0)
		im.SliderFloat4("Drag Color", &config.render.color_dragged, 0.0, 1.0)
		im.SliderFloat4("Selected Color", &config.render.color_selected, 0.0, 1.0)
		im.SliderFloat("Line Thickness", &config.render.line_thickness, 0.1, 10.0)

		// Physics settings
		im.SeparatorText("Physics Settings")
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
	im.PopStyleColor()
}
