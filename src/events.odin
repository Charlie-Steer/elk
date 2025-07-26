package main

import sdl "vendor:sdl3"
import "core:fmt"
import "core:unicode/utf8"

run_events :: proc() {
	e: sdl.Event
	for sdl.PollEvent(&e) {
		#partial switch e.type {
		case .QUIT:
			window.should_close = true
		case .KEY_DOWN:
			keycode := sdl.GetKeyFromScancode(e.key.scancode, e.key.mod, false)
			if mode == .NORMAL {
				if e.key.scancode == .Q {
					window.should_close = true
				} else if keycode == 'H' {
					view.cell_rect.position.x -= (window.dimensions.x / font.dimensions.x) / 2
				} else if keycode == 'J' {
					view.cell_rect.position.y += (window.dimensions.y / font.dimensions.y) / 2
					// fmt.println(window.height, font.dimensions.y, (window.height / font.dimensions.y) / 2)
				} else if keycode == 'K' {
					view.cell_rect.position.y -= (window.dimensions.y / font.dimensions.y) / 2
					// fmt.println(window.height, font.dimensions.y, (window.height / font.dimensions.y) / 2)
				} else if keycode == 'L' {
					view.cell_rect.position.x += (window.dimensions.x / font.dimensions.x) / 2
				} else if e.key.scancode == .H && e.key.mod == sdl.KMOD_NONE {
					move_cursor(&cursor, .LEFT, lines, 1)
				} else if e.key.scancode == .J && e.key.mod == sdl.KMOD_NONE {
					move_cursor(&cursor, .DOWN, lines, 1)
				} else if e.key.scancode == .K && e.key.mod == sdl.KMOD_NONE {
					move_cursor(&cursor, .UP, lines, 1)
				} else if e.key.scancode == .L && e.key.mod == sdl.KMOD_NONE {
					move_cursor(&cursor, .RIGHT, lines, 1)
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
				} else if (e.key.scancode == .I || e.key.scancode == .A) {
					sdl.StartTextInput(window.handle);
					mode = .INSERT
				}
			} else if mode == .INSERT {
				if e.key.scancode == .CAPSLOCK || e.key.scancode == .ESCAPE {
					sdl.StopTextInput(window.handle);
					mode = .NORMAL
				}
			}
		case .TEXT_INPUT:
			if e.type == sdl.EventType.TEXT_INPUT {
				fmt.println("TEXT_INPUT event!")
				for r in string(e.text.text) {
					rune_bytes, n_bytes := utf8.encode_rune(r)
					fmt.println(rune_bytes)
					assert(n_bytes > 0 && n_bytes <= 4)
					if n_bytes == 1 {
						inject_at_elem(&lines[cursor.line].text, cursor.byte_location, rune_bytes[0])
					} else if n_bytes == 2 {
						inject_at_elems(&lines[cursor.line].text, cursor.byte_location, rune_bytes[0], rune_bytes[1])
					} else if n_bytes == 3 {
						inject_at_elems(&lines[cursor.line].text, cursor.byte_location, rune_bytes[0], rune_bytes[1], rune_bytes[2])
					} else {
						inject_at_elems(&lines[cursor.line].text, cursor.byte_location, rune_bytes[0], rune_bytes[1], rune_bytes[2], rune_bytes[3])
					}
					move_cursor(&cursor, .RIGHT, lines, 1)
					fmt.printfln("%v", lines[cursor.line].text)
					fmt.printfln("%s", lines[cursor.line].text)
					// fmt.printfln("correct: %v", transmute([]u8)string("día"))
				}
			}
		}
	}
}
