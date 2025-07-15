package main

import sdl "vendor:sdl3"
import osdl "sdl3_wrapper"
import u "charlie-utils"

View :: struct {
	// line: int,
	// column: int,
	text_location: iVec2,
	dimensions_in_chars: iVec2,

	position: fVec2,
	size: fVec2,
	rect: sdl.FRect,

	number_of_lines_that_fit_on_screen: int,
}

move_view :: proc(view: ^View, direction: Direction) {
	switch direction {
		case .LEFT:
			view.text_location.x -= 1;
		case .DOWN:
			view.text_location.y += 1;
		case .UP:
			view.text_location.y -= 1;
		case .RIGHT:
			view.text_location.x += 1;
	}

	// Correction.
	u.clamp(&view.text_location.y, -max_view_lines_above_text, number_of_lines - view.number_of_lines_that_fit_on_screen + max_view_lines_under_text)
	// TODO: Sophisticated right view clamp.
	u.clamp_min(&view.text_location.x, -max_view_lines_left_of_text)

	update_view_position(view)

	make_cursor_follow_view(&cursor, view^)
	// update_cursor(&cursor, view^)
	// update_view(view, cursor)
}

make_view_follow_cursor :: proc(view: ^View, cursor: Cursor) {
	// Follow cursor.
	// NOTE: Note the symmetry between odd and even statements.
	if cursor.view_location.x < 0 {
		view.text_location.x = cursor.text_location.x
	} else if cursor.view_location.x >= view.dimensions_in_chars.x {
		view.text_location.x = cursor.text_location.x - view.dimensions_in_chars.x + 1
	} else if cursor.view_location.y < 0 {
		view.text_location.y = cursor.text_location.y
	} else if cursor.view_location.y >= view.dimensions_in_chars.y {
		view.text_location.y = cursor.text_location.y - view.dimensions_in_chars.y + 1
	}

	update_view_position(view)
}

update_view_position :: proc(view: ^View) {
	// view.position = { f32(view.text_location.x) * f32(font.width), f32(view.text_location.y) * f32(font.height) }
	f_view_text_location := fVec2{ f32(view.text_location.x), f32(view.text_location.y) }
	view.position = f_view_text_location * {f32(font.width), f32(font.height)}
}

upkeep_view :: proc(view: ^View, cursor: Cursor) {
	view.number_of_lines_that_fit_on_screen = window.height / font.height // NOTE: Constant calculation.
	view.dimensions_in_chars = {window.width / font.width, window.height / font.height} // NOTE: Constant calculation.
}
