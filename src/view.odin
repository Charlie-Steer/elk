package main

import sdl "vendor:sdl3"
import osdl "sdl3_wrapper"
import u "charlie-utils"

View :: struct {
	// TODO: Refactor into iRect
	// text_location: iVec2,
	// dimensions_in_chars: iVec2,
	cell_rect: iRect,

	// TODO: Position + size vs rect is completely redundant wtf.
	position: fVec2,
	size: fVec2,
	rect: sdl.FRect,

	number_of_lines_that_fit_on_screen: int,
}

view: View

move_view :: proc(view: ^View, direction: Direction) {
	switch direction {
		case .LEFT:
			view.cell_rect.position.x -= 1;
		case .DOWN:
			view.cell_rect.position.y += 1;
		case .UP:
			view.cell_rect.position.y -= 1;
		case .RIGHT:
			view.cell_rect.position.x += 1;
	}

	// Correction.
	u.clamp(&view.cell_rect.position.y, -max_view_lines_above_text, number_of_lines - view.number_of_lines_that_fit_on_screen + max_view_lines_under_text)
	// TODO: Sophisticated right view clamp.
	u.clamp_min(&view.cell_rect.position.x, -max_view_lines_left_of_text)

	update_view_position(view)

	make_cursor_follow_view(&cursor, view^)
	// update_cursor(&cursor, view^)
	// update_view(view, cursor)
}

make_view_follow_cursor :: proc(view: ^View, cursor: Cursor) {
	// Follow cursor.
	// NOTE: Note the symmetry between odd and even statements.
	if cursor.view_location.x < 0 {
		view.cell_rect.position.x = cursor.column
	} else if cursor.view_location.x >= view.cell_rect.dimensions.x {
		view.cell_rect.position.x = cursor.column - view.cell_rect.dimensions.x + 1
	} else if cursor.view_location.y < 0 {
		view.cell_rect.position.y = cursor.line
	} else if cursor.view_location.y >= view.cell_rect.dimensions.y {
		view.cell_rect.position.y = cursor.line - view.cell_rect.dimensions.y + 1
	}

	update_view_position(view)
}

update_view_position :: proc(view: ^View) {
	// view.position = { f32(view.cell_rect.position.x) * f32(font.dimensions.x), f32(view.cell_rect.position.y) * f32(font.dimensions.y) }
	view.position = u.fVec(view.cell_rect.position) * u.fVec(font.dimensions)
}

upkeep_view :: proc(view: ^View, cursor: Cursor) {
	view.number_of_lines_that_fit_on_screen = window.dimensions.y / font.dimensions.y // NOTE: Constant calculation.
	// view.cell_rect.dimensions = {window.dimensions.x / font.dimensions.x, window.dimensions.y / font.dimensions.y} // NOTE: Constant calculation.
	view.cell_rect.dimensions = window.dimensions / font.dimensions // NOTE: Constant calculation.
}
