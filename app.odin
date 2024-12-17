package main

import "core:strings"
import "vendor:glfw"

import im "imgui"
import im_glfw "imgui/imgui_impl_glfw"
import im_gl "imgui/imgui_impl_opengl3"
import gl "vendor:OpenGL"

import nfd "nfd"

run :: proc() {
	nfd.Init()
	defer nfd.Quit()

	window, ok := init_window(800, 800, "MML VIEWER")
	if !ok {
		return
	}
	defer close_window(window)

	im.CreateContext()
	defer im.DestroyContext()

	im_glfw.InitForOpenGL(window, true)
	im_gl.Init("#version 330")
	defer im_glfw.Shutdown()
	defer im_gl.Shutdown()

	set_style_everforest()

	im.FontAtlas_AddFontFromFileTTF(im.GetIO().Fonts, "./Assets/JetBrainsMono-Regular.ttf", 16)

	state: State = new_state()

	for (!glfw.WindowShouldClose(window)) {
		free_all(context.temp_allocator)

		state.mouse.pos = im.GetMousePos()

		glfw.PollEvents()
		begin()
		main_menu(&state)
		main_window(&state)
		end(window)
	}

	delete_state(state)
}

main_window :: proc(state: ^State) {
	im.Begin(
		"Main window",
		nil,
		{.NoTitleBar, .NoCollapse, .NoResize, .NoMove, .MenuBar, .NoBringToFrontOnFocus},
	)
	im.SetWindowPos(0)
	im.SetWindowSize(im.GetIO().DisplaySize)
	graph_view(state)
	im.SameLine()
	stuff: type_of(state) = {}
	data_view(state)
	im.End()
}

main_menu :: proc(state: ^State) {
	if (im.BeginMainMenuBar()) {
		if (im.BeginMenu("File")) {
			if (im.MenuItem("Open", "ctrl + o")) {
				path: cstring
				filters := [1]nfd.Filter_Item{{"Mind Map Lang", "mml"}}
				args := nfd.Open_Dialog_Args {
					filter_list  = raw_data(filters[:]),
					filter_count = len(filters),
				}
				result := nfd.OpenDialogU8_With(&path, &args)
				switch result {
				case .Okay:
					{
						delete(state.mml.file.path)
						state.mml.file.path = strings.clone_from_cstring(path)
						state.mml.is_loaded = true
						reload_state(state)
						nfd.FreePathU8(path)
					}
				case .Cancel:
					INFO_F("User canceled opening/using file dialouge")
				case .Error:
					ERROR_F("Error while opening/using file dialouge")
				}
			}
			im.EndMenu()
		}
		im.EndMainMenuBar()
	}
}

graph_view :: proc(state: ^State) {
	im.BeginChild("Graph View", {}, {.FrameStyle, .ResizeX}, {.NoScrollWithMouse, .NoScrollbar})
	handle_tokens(state)
	im.EndChild()
}

data_view :: proc(state: ^State) {
	win_bg := im.GetStyle().Colors[im.Col.WindowBg]
	frame_bg := im.GetStyle().Colors[im.Col.FrameBg]
	frame_padding := im.GetStyle().FramePadding

	im.GetStyle().FramePadding = 0
	im.PushStyleColorImVec4(im.Col.FrameBg, win_bg)
	im.BeginChild("Data View", {}, {.FrameStyle})

	im.PopStyleColor()
	im.PushStyleColorImVec4(im.Col.Button, win_bg)
	im.GetStyle().FramePadding = frame_padding
	render_associated_data(state)
	im.PopStyleColor()
	im.EndChild()

}

begin :: proc() {
	im_gl.NewFrame()
	im_glfw.NewFrame()
	im.NewFrame()
}

end :: proc(window: glfw.WindowHandle) {
	im.EndFrame()
	im.Render()

	display_w, display_h := glfw.GetFramebufferSize(window)
	gl.Viewport(0, 0, display_w, display_h)

	gl.ClearColor(0, 0, 0, 1)
	gl.Clear(gl.COLOR_BUFFER_BIT)

	im_gl.RenderDrawData(im.GetDrawData())
	glfw.SwapBuffers(window)
}
