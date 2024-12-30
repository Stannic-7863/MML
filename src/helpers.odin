package mml

import "base:runtime"
import "core:math/linalg"
import im "imgui"
import gl "vendor:OpenGL"
import glfw "vendor:glfw"

get_window_size :: proc(window: glfw.WindowHandle) -> [2]f32 {
	width, height := glfw.GetWindowSize(window)
	return {cast(f32)width, cast(f32)height}
}

get_color :: proc(color: [4]f32) -> u32 {
	return im.ColorConvertFloat4ToU32(color)
}

get_token_size :: proc(token: Token) -> f32 {
	return (linalg.log10(cast(f32)token.child_count + 1) + 1) * 5
}

get_cell_coords :: proc(pos: [2]f32, cell_size: f32) -> [2]i32 {
	return {cast(i32)(pos.x / cell_size), cast(i32)(pos.y / cell_size)}
}

get_screen_to_world :: proc(v: [2]f32, camera: Camera) -> [2]f32 {
	return (v * camera.zoom) + camera.target
	//return (v * camera.zoom) + camera.target
}

get_hash_key :: proc(pos: [2]i32, number_of_particles: i32) -> i32 {
	x_hash := pos.x * 15823
	y_hash := pos.y * 9737333
	return (x_hash + y_hash) % number_of_particles
}

// recursive, includes all branching childs
get_total_childs :: proc(t: Token) -> int {
	child: int = len(t.childs)
	for c in t.childs {
		child += get_total_childs(c^)
	}
	return child
}
import "core:fmt"
// call back to resize the input buffer
multiline_edit_resize_callback :: proc "c" (data: ^im.InputTextCallbackData) -> i32 {
	context = runtime.default_context()
	for event in data.EventFlag {
		if event == im.InputTextFlag.CallbackResize {
			backing_buffer := cast(^[dynamic]byte)data.UserData
			resize(backing_buffer, data.BufTextLen)
			data.Buf = cstring(raw_data(backing_buffer^[:]))
		}
	}
	return 0
}

init_window :: proc(
	width: i32 = 800,
	height: i32 = 640,
	name: cstring = "",
	GL_MAJOR: i32 = 4,
	GL_MINOR: i32 = 6,
) -> (
	window: glfw.WindowHandle,
	ok: bool,
) {

	if glfw.Init() != true {
		ERROR_F("Error creating window. \nDescription : %s\nError Code : %i", glfw.GetError())
		return nil, false
	}
	glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, GL_MAJOR)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, GL_MINOR)
	glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)

	window = glfw.CreateWindow(width, height, name, nil, nil)
	INFO_F("Created Window of size %ix%i", glfw.GetWindowSize(window))

	glfw.MakeContextCurrent(window)
	glfw.SetFramebufferSizeCallback(window, proc "c" (window: glfw.WindowHandle, width, height: i32) {
		gl.Viewport(0, 0, width, height)
	})

	gl.load_up_to(cast(int)GL_MAJOR, cast(int)GL_MINOR, glfw.gl_set_proc_address)
	gl.Viewport(0, 0, width, height)

	return window, true
}

close_window :: proc(window: glfw.WindowHandle) {
	glfw.DestroyWindow(window)
	glfw.Terminate()
}
