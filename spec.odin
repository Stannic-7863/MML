package main

import "core:time"

Associated_File :: struct {
	path:    string,
	content: []u8,
}

Token :: struct {
	name:             string,
	rank:             int,
	child_count:      int,
	childs:           [dynamic]^Token,
	content_blocks:   [dynamic]string,
	associated_files: [dynamic]Associated_File,
	to_render:        union {
		string,
		Associated_File,
	},
	using physics:    struct {
		size:    f32,
		pos:     [2]f32,
		force:   [2]f32,
		old_pos: [2]f32,
	},
	using render:     struct {
		color: [4]f32,
	},
}

Config :: struct {
	physics: struct {
		cell_size:                 f32,
		damping_factor:            f32,
		scale_factor:              f32,
		min_distance:              f32,
		max_distance:              f32,
		sibling_min_distance:      f32,
		sibling_repulsive_force:   f32,
		neighbour_min_distance:    f32,
		neighbour_repulsive_force: f32,
		global_gravity:            f32,
		repulsive_force:           f32,
		attraction_force:          f32,
		global_center:             [2]f32,
	},
	render:  struct {
		line_thickness: f32,
		color_font:     [4]f32,
		color_hovered:  [4]f32,
		color_dragged:  [4]f32,
		color_default:  [4]f32,
		color_selected: [4]f32,
	},
}

Camera :: struct {
	zoom:        f32,
	is_dragging: bool,
	target:      [2]f32,
	drag_offset: [2]f32,
}

Mouse :: struct {
	pos:           [2]f32,
	hovered_token: ^Token,
	dragged_token: ^Token,
	clicked_token: ^Token,
	clicked_time:  time.Time,
}


Sort_Criteria :: struct {
	index: i32,
	hash:  i32,
}


State :: struct {
	mml_string:       string,
	config:           Config,
	camera:           Camera,
	mouse:            Mouse,
	just_sorted:      bool,
	token_index_map:  map[i32]i32,
	tokens:           [dynamic]Token,
	tokens_sort_crit: [dynamic]Sort_Criteria,
	window:           struct {
		size:          [2]f32,
		window_handle: rawptr,
	},
}
