package main

import "core:time"

// hold data to any associated file, loaded when parsing mml
Associated_File :: struct {
	path:           string,
	backing_buffer: [dynamic]byte,
}

Tab :: union {
	string,
	^Associated_File,
}

Token :: struct {
	size:             f32,
	pos:              [2]f32,
	force:            [2]f32,
	old_pos:          [2]f32,
	color:            [4]f32,
	child_count:      int,
	name:             string,
	tabs:             [dynamic]Tab,
	childs:           [dynamic]^Token,
	inline_contents:  [dynamic]string,
	associated_files: [dynamic]Associated_File,
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

Mml :: struct {
	file:      Associated_File,
	is_loaded: bool,
}

State :: struct {
	mml:         Mml,
	just_sorted: bool,
	mouse:       Mouse,
	config:      Config,
	camera:      Camera,
	look_up:     map[i32]i32,
	tokens:      [dynamic]Token,
	sort_crit:   [dynamic]Sort_Criteria,
}
