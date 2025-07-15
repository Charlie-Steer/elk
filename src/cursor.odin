package main

import sdl "vendor:sdl3"
import osdl "sdl3_wrapper"
import u "charlie-utils"
import "core:fmt"

Cursor :: struct {
	text_location: iVec2,
	view_location: iVec2,
	// current_line: ^Line,
	rect: fRect,

	max_column_in_memory: int,
}

Direction :: enum {
	LEFT,
	DOWN,
	UP,
	RIGHT,
}


clamp_x :: proc() {
	u.clamp(&cursor.text_location.x, 0, len(lines[cursor.text_location.y].text) - 1)
}

// NOTE: Clamp cursor on movement instead of (just) posterior correction?
move_cursor :: proc(cursor: ^Cursor, direction: Direction, lines: [dynamic]Line) {
	switch direction {
		case .LEFT:
			cursor.text_location.x -= 1
		case .DOWN:
			cursor.text_location.y += 1
		case .UP:
			cursor.text_location.y -= 1
		case .RIGHT:
			cursor.text_location.x += 1
	}

	if (direction == .LEFT || direction == .RIGHT) {
		clamp_x()
		cursor.max_column_in_memory = cursor.text_location.x
	} else if (direction == .DOWN || direction == .UP) {
		cursor.text_location.x = cursor.max_column_in_memory
		u.clamp(&cursor.text_location.y, 0, number_of_lines)
		clamp_x()
	}

	// NOTE: update_cursor_in_view() unnecessary if make_view_follow_cursor() based on absolute text location
	update_cursor_in_view(cursor)
	make_view_follow_cursor(&view, cursor^)
	update_cursor_in_view(cursor)
	fmt.println("MOVED CURSOR", view.text_location, cursor.text_location)
}

update_cursor_in_view :: proc(cursor: ^Cursor) {
	cursor.view_location = cursor.text_location - view.text_location

	cursor_view_location := [2]f32{f32(cursor.view_location.x), f32(cursor.view_location.y)}
	font_dimensions := [2]f32{f32(font.width), f32(font.height)}
	cursor.rect = fRect {
		position = cursor_view_location * font_dimensions,
		dimensions = font_dimensions,
	}
}

make_cursor_follow_view :: proc(cursor: ^Cursor, view: View) {
	fmt.println("Cursor:", cursor.text_location)
	if cursor.text_location.x < view.text_location.x {
		cursor.text_location.x = view.text_location.x
	} else if cursor.text_location.x >= view.text_location.x + view.dimensions_in_chars.x {
		cursor.text_location.x = view.text_location.x + view.dimensions_in_chars.x - 1
	}

	if cursor.text_location.y < view.text_location.y {
		fmt.println("cursor was above view.", view.text_location, cursor.text_location)
		cursor.text_location.y = view.text_location.y
		cursor.text_location.x = cursor.max_column_in_memory
		clamp_x()
	} else if cursor.text_location.y >= view.text_location.y + view.dimensions_in_chars.y {
		fmt.println("cursor was under view.", view.text_location, cursor.text_location)
		cursor.text_location.y = view.text_location.y + view.dimensions_in_chars.y - 1
		cursor.text_location.x = cursor.max_column_in_memory
		clamp_x()
	}

	update_cursor_in_view(cursor)
}

// upkeep_cursor :: proc(cursor: ^Cursor, view: View) {
// 	cursor_view_location := [2]f32{f32(cursor.view_location.x), f32(cursor.view_location.y)}
// 	font_dimensions := [2]f32{f32(font.width), f32(font.height)}
// 	cursor.rect = fRect {
// 		position = cursor_view_location * font_dimensions,
// 		dimensions = font_dimensions,
// 	}
// }

// NOTE: Make cursor.text_location the boss.
// WARNING: Is number_of_lines updated correctly?
render_cursor :: proc(cursor: ^Cursor, index_first_line_on_screen: int) {
	// cursor.current_line = &lines[index_first_line_on_screen + cursor.view_location.y]

	// u.clamp_array(&cursor.view_location, iVec2{0, 0}, iVec2{len(cursor.current_line.text) - 1, number_of_lines})

	osdl.SetRenderDrawColorFloat(renderer, {1, 1, 1, 0.65})
	sdl.SetRenderDrawBlendMode(renderer, sdl.BlendMode{.BLEND})
	osdl.RenderFillRect(renderer, cursor.rect)
}
