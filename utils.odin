package main

import "core:math/linalg"
import "imgui"
import gl "vendor:OpenGL"
import glfw "vendor:glfw"

new_state :: proc() -> State {
	return {
		config = get_default_config(),
		tokens = make([dynamic]Token),
		tokens_sort_crit = make([dynamic]Sort_Criteria),
		token_index_map = make(map[i32]i32),
		camera = {zoom = 1},
	}
}

delete_state :: proc(state: State) {
	for t in state.tokens do delete_token(t)
	delete(state.tokens)
	delete(state.tokens_sort_crit)
	delete(state.token_index_map)
}

delete_token :: proc(t: Token) {
	delete(t.childs)
	delete(t.associated_files)
	delete(t.content_blocks)
}

get_default_config :: proc() -> Config {
	return Config {
		physics = {
			cell_size = 150,
			damping_factor = 0.93,
			scale_factor = 60.0,
			min_distance = 150,
			max_distance = 190,
			sibling_min_distance = 40,
			sibling_repulsive_force = 2,
			neighbour_min_distance = 40,
			neighbour_repulsive_force = 2,
			global_gravity = 1,
			repulsive_force = 2,
			attraction_force = 1,
			global_center = {0, 0},
		},
		render = {
			line_thickness = 1,
			color_dragged = [4]f32{40, 50, 60, 255} / 255,
			color_default = [4]f32{0.563, 0.379, 0.327, 1.0},
			color_hovered = [4]f32{158, 160, 211, 255} / 255,
			color_selected = [4]f32{0.522, 0.212, 0.228, 1.0},
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

token_sort_proc :: proc(i, j: Sort_Criteria) -> bool {return i.hash < j.hash}

get_window_size :: proc(window: glfw.WindowHandle) -> [2]f32 {
	width, height := glfw.GetWindowSize(window)
	return {cast(f32)width, cast(f32)height}
}

get_color :: proc(color: [4]f32) -> u32 {
	return imgui.ColorConvertFloat4ToU32(color)
}

get_token_size :: proc(token: Token) -> f32 {
	return (linalg.sqrt(cast(f32)token.child_count + 1)) * 5
}

get_cell_coords :: proc(pos: [2]f32, cell_size: f32) -> [2]i32 {
	return {cast(i32)(pos.x / cell_size), cast(i32)(pos.y / cell_size)}
}

get_screen_to_world :: proc(v: [2]f32, camera: Camera) -> [2]f32 {
	return (v * camera.zoom) + camera.target
}

get_hash_key :: proc(pos: [2]i32, number_of_particles: i32) -> i32 {
	x_hash := pos.x * 15823
	y_hash := pos.y * 9737333
	return (x_hash + y_hash) % number_of_particles
}

get_total_childs :: proc(t: Token) -> int {
	child: int = len(t.childs)
	for c in t.childs {
		child += get_total_childs(c^)
	}
	return child
}

init_window :: proc(
	width: i32 = 800,
	height: i32 = 640,
	name: cstring = "",
	GL_MAJOR: i32 = 4,
	GL_MINOR: i32 = 6,
) -> glfw.WindowHandle {

	glfw.Init()
	glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, GL_MAJOR)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, GL_MINOR)
	glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)

	window := glfw.CreateWindow(width, height, name, nil, nil)

	glfw.MakeContextCurrent(window)
	glfw.SetFramebufferSizeCallback(
		window,
		proc "c" (window: glfw.WindowHandle, width, height: i32) {
			gl.Viewport(0, 0, width, height)
		},
	)

	gl.load_up_to(cast(int)GL_MAJOR, cast(int)GL_MINOR, glfw.gl_set_proc_address)
	gl.Viewport(0, 0, width, height)

	return window
}

close_window :: proc(window: glfw.WindowHandle) {
	glfw.DestroyWindow(window)
	glfw.Terminate()
}
