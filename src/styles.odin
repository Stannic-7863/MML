package mml

import im "imgui"

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
