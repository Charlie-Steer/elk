package main

import sdl "vendor:sdl3"
import osdl "sdl3_wrapper"
import u "charlie-utils"
import "core:fmt"
import "core:unicode/utf8"

// I need to count byte position
// and grapheme and/or cell position.
Cursor :: struct {
	byte_location: int,
	grapheme_location: int,
	// grid_location: iVec2, // column and line location.
	column: int,
	line: int,

	view_location: iVec2, // cell location within camera-space.

	rect: fRect,

	column_in_memory: int,
}

cursor: Cursor

Direction :: enum {
	LEFT,
	DOWN,
	UP,
	RIGHT,
}


clamp_column :: proc() {
	u.clamp(&cursor.column, 0, len(lines[cursor.line].text) - 1)
}

// NOTE: Clamp cursor on movement instead of (just) posterior correction?
move_cursor :: proc(cursor: ^Cursor, direction: Direction, lines: [dynamic]Line) {
	switch direction {
		case .LEFT:
			// utf8.grapheme_count(lines[cursor.line].text[:cursor.grapheme_location])
			cursor.column -= 1
		case .DOWN:
			cursor.line += 1
		case .UP:
			cursor.line -= 1
		case .RIGHT:
			cursor.column += 1
	}

	if (direction == .LEFT || direction == .RIGHT) {
		clamp_column()
		cursor.column_in_memory = cursor.column
	} else if (direction == .DOWN || direction == .UP) {
		cursor.column = cursor.column_in_memory
		u.clamp(&cursor.line, 0, number_of_lines)
		clamp_column()
	}

	// NOTE: update_cursor_in_view() unnecessary if make_view_follow_cursor() based on absolute text location
	update_cursor_in_view(cursor)
	make_view_follow_cursor(&view, cursor^)
	update_cursor_in_view(cursor)
	// fmt.println("MOVED CURSOR", view.cell_rect.position, cursor.grid_location)
}

update_cursor_in_view :: proc(cursor: ^Cursor) {
	// cursor.view_location = cursor.grid_location - view.cell_rect.position
	cursor.view_location = {cursor.column, cursor.line} - view.cell_rect.position

	cursor.rect = fRect {
		position = u.fVec(cursor.view_location) * u.fVec(font.dimensions),
		dimensions = u.fVec(font.dimensions),
	}
	// cursor.rect.position = cursor_view_location * [2]f32{f32(font.dimensions.x), f32(font.height)}
}

make_cursor_follow_view :: proc(cursor: ^Cursor, view: View) {
	fmt.println("Cursor:", iVec2{cursor.line, cursor.column})
	if cursor.column < view.cell_rect.position.x {
		cursor.column = view.cell_rect.position.x
		cursor.column_in_memory = cursor.column
	} else if cursor.column >= view.cell_rect.position.x + view.cell_rect.dimensions.x {
		cursor.column = view.cell_rect.position.x + view.cell_rect.dimensions.x - 1
		cursor.column_in_memory = cursor.column
	}

	if cursor.line < view.cell_rect.position.y {
		fmt.println("cursor was above view.", view.cell_rect.position, iVec2{cursor.line, cursor.column})
		cursor.line = view.cell_rect.position.y
		cursor.column = cursor.column_in_memory
		clamp_column()
	} else if cursor.line >= view.cell_rect.position.y + view.cell_rect.dimensions.y {
		fmt.println("cursor was under view.", view.cell_rect.position, iVec2{cursor.line, cursor.column})
		cursor.line = view.cell_rect.position.y + view.cell_rect.dimensions.y - 1
		cursor.column = cursor.column_in_memory
		clamp_column()
	}

	update_cursor_in_view(cursor)
}

// upkeep_cursor :: proc(cursor: ^Cursor, view: View) {
// 	cursor_view_location := [2]f32{f32(cursor.view_location.x), f32(cursor.view_location.y)}
// 	font_dimensions := [2]f32{f32(font.dimensions.x), f32(font.height)}
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
	if (mode == .NORMAL) {
		osdl.RenderFillRect(renderer, cursor.rect)
	} else if (mode == .INSERT) {
		insert_rect := cursor.rect
		insert_rect.dimensions.x = 2;
		osdl.RenderFillRect(renderer, insert_rect)
	} else {
		panic("Inexistent mode.");
	}
}
