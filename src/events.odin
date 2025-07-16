package main

import sdl "vendor:sdl3"

run_events :: proc() {
	e: sdl.Event
	for sdl.PollEvent(&e) {
		#partial switch e.type {
		case .QUIT:
			window.should_close = true
		case .KEY_DOWN:
			keycode := sdl.GetKeyFromScancode(e.key.scancode, e.key.mod, false)
			if keycode == 'H' {
				view.cell_rect.position.x -= (window.dimensions.x / font.dimensions.x) / 2
			} else if keycode == 'J' {
				view.cell_rect.position.y += (window.dimensions.y / font.dimensions.y) / 2
				// fmt.println(window.height, font.dimensions.y, (window.height / font.dimensions.y) / 2)
			} else if keycode == 'K' {
				view.cell_rect.position.y -= (window.dimensions.y / font.dimensions.y) / 2
				// fmt.println(window.height, font.dimensions.y, (window.height / font.dimensions.y) / 2)
			} else if keycode == 'L' {
				view.cell_rect.position.x += (window.dimensions.x / font.dimensions.x) / 2
			} else if e.key.scancode == .ESCAPE || e.key.scancode == .Q {
				window.should_close = true
			} else if e.key.scancode == .H && e.key.mod == sdl.KMOD_NONE {
				move_cursor(&cursor, .LEFT, lines)
			} else if e.key.scancode == .J && e.key.mod == sdl.KMOD_NONE {
				move_cursor(&cursor, .DOWN, lines)
			} else if e.key.scancode == .K && e.key.mod == sdl.KMOD_NONE {
				move_cursor(&cursor, .UP, lines)
			} else if e.key.scancode == .L && e.key.mod == sdl.KMOD_NONE {
				move_cursor(&cursor, .RIGHT, lines)
			} else if e.key.scancode == .H && e.key.mod & sdl.KMOD_ALT != sdl.KMOD_NONE {
				move_view(&view, .LEFT)
			} else if e.key.scancode == .J && e.key.mod & sdl.KMOD_ALT != sdl.KMOD_NONE {
				move_view(&view, .DOWN)
			} else if e.key.scancode == .K && e.key.mod & sdl.KMOD_ALT != sdl.KMOD_NONE {
				move_view(&view, .UP)
			} else if e.key.scancode == .L && e.key.mod & sdl.KMOD_ALT != sdl.KMOD_NONE {
				move_view(&view, .RIGHT)
			} else if e.key.scancode == .D {
				debug_rendering = !debug_rendering
			} else if (e.key.scancode == .F) && (e.key.mod & sdl.KMOD_SHIFT != sdl.KMOD_NONE) {
				lock_framerate = !lock_framerate
			} else if (e.key.scancode == .F && e.key.mod == sdl.KMOD_NONE) {
				show_fps_counter = !show_fps_counter
			}
		}
	}
}
