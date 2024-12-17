package main

import "core:log"
import "core:mem"

INFO :: log.info
ERROR :: log.error
INFO_F :: log.infof
ERROR_F :: log.errorf

main :: proc() {

	// logger setup 
	context.logger = log.create_console_logger(
		log.Level.Debug,
		log.Options{.Level, .Procedure, .Line, .Terminal_Color},
	)
	defer log.destroy_console_logger(context.logger)

	// to keep track of mem leaks 
	when ODIN_DEBUG {
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		context.allocator = mem.tracking_allocator(&track)

		defer {
			if len(track.allocation_map) > 0 {
				ERROR_F("=== %v allocations not freed: ===\n", len(track.allocation_map))
				for _, entry in track.allocation_map {
					ERROR_F("- %v bytes @ %v\n", entry.size, entry.location)
				}
			}
			if len(track.bad_free_array) > 0 {
				ERROR_F("=== %v incorrect frees: ===\n", len(track.bad_free_array))
				for entry in track.bad_free_array {
					ERROR_F("- %p @ %v\n", entry.memory, entry.location)
				}
			}
			mem.tracking_allocator_destroy(&track)
		}
	}

	// main program
	run()
}
