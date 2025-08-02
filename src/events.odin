package main

import sdl "vendor:sdl3"
import "core:fmt"
import "core:unicode/utf8"

debug_event :: proc(e: sdl.Event) {
	fmt.println(e.type)
	fmt.println(e.key.scancode)
	fmt.println(e.key.mod)
}

run_events :: proc() {
	e: sdl.Event
	for sdl.PollEvent(&e) {
		#partial switch e.type {
		case .QUIT:
			window.should_close = true
		case .KEY_DOWN:
			debug_event(e)
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
				} else if (e.key.scancode == .S && e.key.mod == sdl.KMOD_LCTRL) {
					fmt.println("Saving...")
					combine_lines_into_single_buffer_and_save_file(lines)
				} else if (e.key.scancode == .I || e.key.scancode == .A) {
					sdl.StartTextInput(window.handle);
					mode = .INSERT
				}
			} else if mode == .INSERT {
				if e.key.scancode == .CAPSLOCK || e.key.scancode == .ESCAPE {
					sdl.StopTextInput(window.handle);
					mode = .NORMAL
				} else if e.key.scancode == .BACKSPACE {
					fmt.println("PRESSED BACKSPACE!")
					fmt.println("col: ", cursor.column)
					if (cursor.column == 0) {
						if (cursor.line > 0) {
							move_cursor(&cursor, .UP, lines, 1)
							move_cursor(&cursor, .RIGHT, lines, max(int) / 2)
							line_is_empty := bool(len(lines[cursor.line].text) == 0)
							merge_lines(&lines, cursor.line, cursor.line + 1)
							if (!line_is_empty) {
								move_cursor(&cursor, .RIGHT, lines, 1)
							}
						}
					} else {
						// WARNING: Duplicated code with move_cursor()
						line := lines[cursor.line]
						line_text := string(line.text[:])
						delete_grapheme(line_text, cursor.column, line.graphemes, .LEFT)
					}
				} else if e.key.scancode == .DELETE {
					// if cursor.column + cursor.cell_width == lines[cursor.line].len_columns {
					if cursor.column + (cursor.cell_width - 1) == lines[cursor.line].len_columns {
						merge_lines(&lines, cursor.line, cursor.line + 1)
					} else { 
						line := lines[cursor.line]
						line_text := string(line.text[:])
						delete_grapheme(line_text, cursor.column, line.graphemes, .RIGHT)
					}
				}
			}
		case .TEXT_INPUT:
			if e.type == sdl.EventType.TEXT_INPUT {
				fmt.println("TEXT_INPUT event!")
				for r in string(e.text.text) {
					insert_rune_in_line(&lines[cursor.line], r)
				}
			}
		}
	}
}
