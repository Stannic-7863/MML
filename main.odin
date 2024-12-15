package main

import "core:fmt"
import "core:mem"
import im "imgui"
import im_glfw "imgui/imgui_impl_glfw"
import im_gl "imgui/imgui_impl_opengl3"
import nfd "nfd"
import gl "vendor:OpenGL"
import "vendor:glfw"

PRINT :: fmt.println

PRINT_VERBOSE :: proc(arg: ..any) {
	for a in arg {
		fmt.printf("%#v", a)
	}
	fmt.printf("\n")
}

main :: proc() {
	when ODIN_DEBUG {

		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		context.allocator = mem.tracking_allocator(&track)

		defer {
			if len(track.allocation_map) > 0 {
				fmt.eprintf("=== %v allocations not freed: ===\n", len(track.allocation_map))
				for _, entry in track.allocation_map {
					fmt.eprintf("- %v bytes @ %v\n", entry.size, entry.location)
				}
			}
			if len(track.bad_free_array) > 0 {
				fmt.eprintf("=== %v incorrect frees: ===\n", len(track.bad_free_array))
				for entry in track.bad_free_array {
					fmt.eprintf("- %p @ %v\n", entry.memory, entry.location)
				}
			}
			mem.tracking_allocator_destroy(&track)
		}
	}
	run()
}

run :: proc() {
	nfd.Init()
	defer nfd.Quit()

	window := init_window(1000, 1000, "MML VIEWER")
	defer close_window(window)

	im.CreateContext()
	defer im.DestroyContext()


	im_glfw.InitForOpenGL(window, true)
	im_gl.Init("#version 330")
	defer im_glfw.Shutdown()
	defer im_gl.Shutdown()

	set_style_everforest()

	state: State = new_state()

	for (!glfw.WindowShouldClose(window)) {

		state.mouse.pos = im.GetMousePos()
		state.window.size = get_window_size(window)

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
						mml_str, tokens, ok := parse_mml_from_file(cast(string)path)
						if ok {
							clear_state_token_data(state)
							state.tokens = make([dynamic]Token)
							state.tokens_sort_crit = make([dynamic]Sort_Criteria)
							state.token_index_map = make(map[i32]i32)
							state.mml_string = mml_str
							state.tokens = tokens
							for i in 0 ..< len(state.tokens) {
								append(&state.tokens_sort_crit, Sort_Criteria{index = cast(i32)i})
							}
						}
						nfd.FreePathU8(path)
					}
				case .Cancel:
				case .Error:
				}
			}
			if (im.MenuItem("Open Recent")) {
			}
			if (im.MenuItem("Save", "ctrl + s")) {
			}
			if im.MenuItem("Save As") {
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

	im.PushStyleColorImVec4(im.Col.FrameBg, frame_bg)
	render_associated_data(state^)
	im.PopStyleColor()

	im.EndChild()

	im.PopStyleColor()
	im.GetStyle().FramePadding = frame_padding
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

set_style_everforest :: proc() {
	style := im.GetStyle()

	style.FrameRounding = 5
	style.TabRounding = 5
	style.ChildRounding = 5
	style.PopupRounding = 5
	style.GrabRounding = 3
	style.ScrollbarRounding = 3


	colors := &style.Colors
	colors[im.Col.Text] = im.Vec4{0.83, 0.78, 0.67, 1.0}
	colors[im.Col.TextDisabled] = im.Vec4{0.60, 0.60, 0.60, 1.0}
	colors[im.Col.WindowBg] = im.Vec4{0.12, 0.14, 0.15, 1.0}
	colors[im.Col.ChildBg] = im.Vec4{0.12, 0.14, 0.15, 1.0}
	colors[im.Col.PopupBg] = im.Vec4{0.15, 0.18, 0.20, 1.0}
	colors[im.Col.Border] = im.Vec4{0.31, 0.36, 0.35, 1.0}
	colors[im.Col.BorderShadow] = im.Vec4{0.12, 0.14, 0.15, 1.0}
	colors[im.Col.FrameBg] = im.Vec4{0.18, 0.22, 0.24, 1.0}
	colors[im.Col.FrameBgHovered] = im.Vec4{0.25, 0.29, 0.31, 1.0}
	colors[im.Col.FrameBgActive] = im.Vec4{0.31, 0.36, 0.35, 1.0}
	colors[im.Col.TitleBg] = im.Vec4{0.31, 0.36, 0.35, 1.0}
	colors[im.Col.TitleBgActive] = im.Vec4{0.29, 0.32, 0.34, 1.0}
	colors[im.Col.TitleBgCollapsed] = im.Vec4{0.31, 0.36, 0.35, 1.0}
	colors[im.Col.MenuBarBg] = im.Vec4{0.31, 0.36, 0.35, 1.0}
	colors[im.Col.ScrollbarBg] = im.Vec4{0.15, 0.18, 0.20, 1.0}
	colors[im.Col.ScrollbarGrab] = im.Vec4{0.31, 0.36, 0.35, 1.0}
	colors[im.Col.ScrollbarGrabHovered] = im.Vec4{0.25, 0.29, 0.31, 1.0}
	colors[im.Col.ScrollbarGrabActive] = im.Vec4{0.83, 0.78, 0.67, 1.0}
	colors[im.Col.CheckMark] = im.Vec4{0.83, 0.78, 0.67, 1.0}
	colors[im.Col.SliderGrab] = im.Vec4{0.83, 0.78, 0.67, 1.0}
	colors[im.Col.SliderGrabActive] = im.Vec4{0.83, 0.78, 0.67, 1.0}
	colors[im.Col.Button] = im.Vec4{0.18, 0.22, 0.24, 1.0}
	colors[im.Col.ButtonHovered] = im.Vec4{0.25, 0.29, 0.31, 1.0}
	colors[im.Col.ButtonActive] = im.Vec4{0.31, 0.36, 0.35, 1.0}
	colors[im.Col.Header] = im.Vec4{0.25, 0.29, 0.31, 1.0}
	colors[im.Col.HeaderHovered] = im.Vec4{0.31, 0.36, 0.35, 1.0}
	colors[im.Col.HeaderActive] = im.Vec4{0.34, 0.39, 0.37, 1.0}
	colors[im.Col.Separator] = im.Vec4{0.31, 0.36, 0.35, 1.0}
	colors[im.Col.SeparatorHovered] = im.Vec4{0.31, 0.36, 0.35, 1.0}
	colors[im.Col.SeparatorActive] = im.Vec4{0.31, 0.36, 0.35, 1.0}
	colors[im.Col.ResizeGrip] = im.Vec4{0.25, 0.29, 0.31, 1.0}
	colors[im.Col.ResizeGripHovered] = im.Vec4{0.31, 0.36, 0.35, 1.0}
	colors[im.Col.ResizeGripActive] = im.Vec4{0.83, 0.78, 0.67, 1.0}
	colors[im.Col.TabHovered] = im.Vec4{0.25, 0.29, 0.31, 1.0}
	colors[im.Col.Tab] = im.Vec4{0.18, 0.22, 0.24, 1.0}
	colors[im.Col.TabSelected] = im.Vec4{0.31, 0.36, 0.35, 1.0}
	colors[im.Col.TabSelectedOverline] = im.Vec4{0.25, 0.29, 0.31, 1.0}
	colors[im.Col.TabDimmed] = im.Vec4{0.48, 0.52, 0.47, 1.0}
	colors[im.Col.TabDimmedSelected] = im.Vec4{0.48, 0.52, 0.47, 1.0}
	colors[im.Col.TabDimmedSelectedOverline] = im.Vec4{0.48, 0.52, 0.47, 1.0}
	colors[im.Col.DockingPreview] = im.Vec4{0.65, 0.75, 0.50, 1.0}
	colors[im.Col.DockingEmptyBg] = im.Vec4{0.15, 0.18, 0.20, 1.0}
	colors[im.Col.PlotLines] = im.Vec4{0.83, 0.78, 0.67, 1.0}
	colors[im.Col.PlotLinesHovered] = im.Vec4{0.90, 0.60, 0.46, 1.0}
	colors[im.Col.PlotHistogram] = im.Vec4{0.90, 0.60, 0.46, 1.0}
	colors[im.Col.PlotHistogramHovered] = im.Vec4{0.90, 0.49, 0.50, 1.0}
	colors[im.Col.TableHeaderBg] = im.Vec4{0.18, 0.22, 0.24, 1.0}
	colors[im.Col.TableBorderStrong] = im.Vec4{0.31, 0.36, 0.35, 1.0}
	colors[im.Col.TableBorderLight] = im.Vec4{0.25, 0.29, 0.31, 1.0}
	colors[im.Col.TableRowBg] = im.Vec4{0.18, 0.22, 0.24, 1.0}
	colors[im.Col.TableRowBgAlt] = im.Vec4{0.83, 0.78, 0.67, 1.0}
	colors[im.Col.TextLink] = im.Vec4{0.50, 0.73, 0.70, 1.0}
	colors[im.Col.TextSelectedBg] = im.Vec4{0.51, 0.75, 0.57, 1.0}
	colors[im.Col.DragDropTarget] = im.Vec4{0.86, 0.74, 0.50, 1.0}
	colors[im.Col.NavHighlight] = im.Vec4{0.31, 0.36, 0.35, 1.0}
	colors[im.Col.NavWindowingHighlight] = im.Vec4{0.83, 0.78, 0.67, 1.0}
	colors[im.Col.NavWindowingDimBg] = im.Vec4{0.83, 0.78, 0.67, 1.0}
	colors[im.Col.ModalWindowDimBg] = im.Vec4{0.48, 0.52, 0.47, 1.0}
}
