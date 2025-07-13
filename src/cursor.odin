package main

import sdl "vendor:sdl3"
import osdl "sdl3_wrapper"
import cs "charlie"

Direction :: enum {
	LEFT,
	DOWN,
	UP,
	RIGHT,
}

// NOTE: Clamp cursor on movement instead of (just) posterior correction?
move_cursor :: proc(cursor: ^Cursor, direction: Direction) {
	switch direction {
		case .LEFT:
			cursor.location.x -= 1
			cs.clamp(&cursor.location.x, 0, len(cursor.current_line.text) - 1)
			cursor.max_column_in_memory = cursor.location.x
		case .DOWN:
			cursor.location.y += 1
			cursor.location.x = cursor.max_column_in_memory
		case .UP:
			cursor.location.y -= 1
			cursor.location.x = cursor.max_column_in_memory
		case .RIGHT:
			cursor.location.x += 1
			cs.clamp(&cursor.location.x, 0, len(cursor.current_line.text) - 1)
			cursor.max_column_in_memory = cursor.location.x
	}
	// if (direction == .LEFT || direction == .RIGHT) {
	// 	cursor.max_column_in_memory = cursor.location.x
	// }
}

update_and_render_cursor :: proc(cursor: ^Cursor, index_first_line_on_screen: int) {
	// WARNING: Is number_of_lines updated correctly?
	cursor.current_line = &lines[index_first_line_on_screen + cursor.location.y]
	cs.clamp_array(&cursor.location, iVec2{0, 0}, iVec2{len(cursor.current_line.text) - 1, number_of_lines})
	cursor_location := [2]f32{f32(cursor.location.x), f32(cursor.location.y)}
	font_dimensions := [2]f32{f32(font.width), f32(font.height)}
	cursor.rect = fRect {
		position = cursor_location * font_dimensions,
		dimensions = {f32(font.width), f32(font.height)}
	}
	// sdl.SetRenderDrawColor(renderer, 255, 255, 255, 160)
	osdl.SetRenderDrawColorFloat(renderer, {1, 1, 1, 0.65})
	sdl.SetRenderDrawBlendMode(renderer, sdl.BlendMode{.BLEND})
	osdl.RenderFillRect(renderer, cursor.rect)
}
