package mml

import "core:math/linalg"
import "core:math/rand"
import "core:slice"

handle_token_physics :: proc(state: ^State) {
	physics := state.config.physics
	render := state.config.render
	camera := &state.camera
	mouse := &state.mouse

	state.just_sorted = false
	mouse.hovered_token = nil
	token_count := cast(i32)len(state.tokens)

	for &parent_token in state.tokens {
		for &child_token, child_token_index in parent_token.childs {
			physics_parent_child(child_token, &parent_token, physics)

			for &sibling, sibling_index in parent_token.childs {
				if sibling_index == child_token_index {
					continue
				}
				physics_child_sibling(sibling, child_token, physics)
			}

		}

		physics_parent_neighbour(token_count, &parent_token, physics, state)

		parent_token.color = render.color_default

		// whonky stuff due to rendering 
		// the particles are in screen space by default cuz of how my code works rn 
		// (probably)
		if linalg.distance(get_screen_to_world(parent_token.pos, camera^), (state.mouse.pos)) < parent_token.size * camera.zoom {
			mouse.hovered_token = &parent_token
		}
		apply_verlet(&parent_token, physics.scale_factor, physics.damping_factor)
	}

	for &sort_crit in state.sort_crit {
		sort_crit.hash = get_hash_key(get_cell_coords(state.tokens[sort_crit.index].pos, physics.cell_size), token_count)
	}

	if !(slice.is_sorted_by(state.sort_crit[:], token_sort_proc)) {
		slice.sort_by(state.sort_crit[:], token_sort_proc)
		state.just_sorted = true
	}
}

physics_parent_child :: proc(child, parent: ^Token, physics: Physics) {
	dist := linalg.distance(child.pos, parent.pos)

	if dist == 0 {
		dist = rand.float32()
	}

	diff := child.pos - parent.pos
	dir := linalg.normalize0(diff)

	if dir == {} {
		dir = {rand.float32(), rand.float32()}
	}

	dist_min := physics.min_distance + parent.size
	dist_max := physics.max_distance + parent.size

	force: [2]f32

	if dist < dist_min {
		force = dir * (dist_min - dist + cast(f32)child.child_count) * physics.repulsive_force
	} else if dist > dist_max {
		force = -dir * (dist - dist_max + cast(f32)child.child_count) * physics.attraction_force
	}

	child.force += force
	parent.force -= force
}

physics_child_sibling :: proc(sibling, child: ^Token, physics: Physics) {
	sibling_dist := linalg.distance(sibling.pos, child.pos)
	sibling_diff := child.pos - sibling.pos
	sibling_dir := linalg.normalize0(sibling_diff)

	if sibling_dist < physics.sibling_min_distance + child.size {
		sibling_force: [2]f32
		dist_scaler := physics.min_distance - sibling_dist
		sibling_force = sibling_dir * dist_scaler * physics.sibling_repulsive_force
		child.force += sibling_force
		sibling.force -= sibling_force
	}
}

physics_parent_neighbour :: proc(token_count: i32, parent: ^Token, physics: Physics, state: ^State) {
	hash := get_hash_key(get_cell_coords(parent.pos, physics.cell_size), token_count)

	sort_crit_lookup_index := state.look_up[hash]

	for i: i32 = sort_crit_lookup_index; i < token_count; i += 1 {
		if state.sort_crit[sort_crit_lookup_index].hash != state.sort_crit[i].hash {
			break
		}

		neighbor_token := &state.tokens[state.sort_crit[i].index]

		neighbor_token_dist := linalg.distance(neighbor_token.pos, parent.pos)
		neighbor_token_diff := parent.pos - neighbor_token.pos
		neighbor_token_dir := linalg.normalize0(neighbor_token_diff)
		neighbor_token_force: [2]f32
		if neighbor_token_dist < physics.neighbour_min_distance {
			neighbor_token_force =
				neighbor_token_dir * (physics.neighbour_min_distance - neighbor_token_dist) * physics.neighbour_repulsive_force
		}
		parent.force += neighbor_token_force
		neighbor_token.force -= neighbor_token_force
	}
}
