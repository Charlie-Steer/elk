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

	cell_width: int,
	rect: fRect,

	column_in_memory: int,
}

cursor := Cursor {
	cell_width = 1, // HACK: If not set to a value, cursor won't render until cursor_move().
}

Direction :: enum {
	LEFT,
	DOWN,
	UP,
	RIGHT,
}

Move_Unit :: enum {
	CELLS,
	BYTES,
}


clamp_column :: proc(line_width_in_cells: int) {
	u.clamp(&cursor.column, 0, line_width_in_cells - 1)
}

// TODO: Needs refactor into something more sensible. Shared interface with switch for .MOVE and .REMOVE?
// NOTE: Could be called only when going into insert mode and on insert writes.
loop_through_graphemes  :: proc(line_text: string, column: int, graphemes: [dynamic]utf8.Grapheme, direction: Direction) {
	if (column == 0) {
		if len(graphemes) == 0 {
			cursor.cell_width = graphemes[0].width
		} else {
			cursor.cell_width = 1
		}
		return
	}
	columns_traversed: int
	grapheme_index: int // NOTE: for debugging.
	grapheme_width_in_columns: int
	for i := 0; i < len(graphemes); i += 1 {
		grapheme_index = i
		grapheme_width_in_columns = graphemes[i].width
		// fmt.println("GRAPHEME WIDTH: ", grapheme_width_in_columns)
		columns_traversed += grapheme_width_in_columns
		// fmt.println(column)
		// fmt.println(columns_traversed, "\n")
		if (columns_traversed >= column) {
			if columns_traversed > column {
				fmt.println("columns_traversed > column")
				if direction == .LEFT {
					cursor.column -= (grapheme_width_in_columns - 1)
					cursor.byte_location = graphemes[i].byte_index
					cursor.cell_width = graphemes[i].width
				} else if direction == .RIGHT {
					cursor.column += (grapheme_width_in_columns - 1)
					cursor.byte_location = graphemes[i + 1].byte_index
					cursor.cell_width = graphemes[i + 1].width
				}
			} else {
				fmt.println("columns_traversed == column")
				cursor.byte_location = graphemes[i + 1].byte_index
				cursor.cell_width = graphemes[i + 1].width
			}
			return
		}
	}

	fmt.println("grapheme_count < column_index")
}

delete_grapheme :: proc(line_text: string, column: int, graphemes: [dynamic]utf8.Grapheme, direction: Direction) {
	if (column == 0) {
		if len(graphemes) == 0 {
			cursor.cell_width = graphemes[0].width
		} else {
			cursor.cell_width = 1
		}
		return
	}
	columns_traversed := -1
	for i := 0; i < len(graphemes); i += 1 {
		columns_traversed += graphemes[i].width
		fmt.println(i, columns_traversed, column)
		if (columns_traversed >= column) {
			if direction == .LEFT {
				remove_range(&lines[cursor.line].text, graphemes[i - 1].byte_index, graphemes[i].byte_index)
				cursor.byte_location = graphemes[i - 1].byte_index
				cursor.column -= graphemes[i - 1].width
				cursor.cell_width = graphemes[i].width
			} else if direction == .RIGHT && (i + 1) < len(graphemes) {
				remove_range(&lines[cursor.line].text, graphemes[i].byte_index, graphemes[i + 1].byte_index)
				cursor.cell_width = graphemes[i + 1].width
			}
			update_cursor_in_view(&cursor)
			return
		}
	}

	fmt.println("grapheme_count < column_index")
}

// NOTE: Clamp cursor on movement instead of (just) posterior correction?
move_cursor :: proc(cursor: ^Cursor, direction: Direction, lines: [dynamic]Line, grapheme_amount: int) {
	#partial switch direction {
		case .DOWN:
			cursor.line += 1
		case .UP:
			cursor.line -= 1
		case .LEFT:
			cursor.column -= 1
		case .RIGHT:
			cursor.column += 1
	}
	u.clamp(&cursor.line, 0, number_of_lines)

	line := lines[cursor.line]
	line_text := string(line.text[:])
	graphemes, grapheme_count, rune_count, line_width_in_cells := utf8.decode_grapheme_clusters(line_text, true)

	if (direction == .LEFT || direction == .RIGHT) {
		clamp_column(line_width_in_cells)
		cursor.column_in_memory = cursor.column
	} else if (direction == .DOWN || direction == .UP) {
		cursor.column = cursor.column_in_memory
		clamp_column(line_width_in_cells)
	}

	grapheme_width_in_columns: int
	// cursor.byte_location, grapheme_width_in_columns = loop_through_graphemes(line_text, cursor.column, graphemes, direction)
	loop_through_graphemes(line_text, cursor.column, graphemes, direction)


	// TODO: MAKE SO IF CURSOR DOESN'T LAND ON FIRST COL OF GRAPHEME, IT CORRECTS TO THE FIRST.

	// NOTE: update_cursor_in_view() unnecessary if make_view_follow_cursor() based on absolute text location
	update_cursor_in_view(cursor)
	make_view_follow_cursor(&view, cursor^)
	update_cursor_in_view(cursor)
	// fmt.println("MOVED CURSOR", view.cell_rect.position, cursor.grid_location)
}


// // NOTE: Clamp cursor on movement instead of (just) posterior correction?
// move_cursor :: proc(cursor: ^Cursor, direction: Direction, lines: [dynamic]Line, grapheme_amount: int) {
// 	switch direction {
// 		case .LEFT:
// 			cursor.column -= 1
// 		case .DOWN:
// 			cursor.line += 1
// 		case .UP:
// 			cursor.line -= 1
// 		case .RIGHT:
// 			cursor.column += 1
// 	}
// 	line := lines[cursor.line]
// 	line_text := string(line.text[:])
// 	graphemes, grapheme_count, rune_count, line_width_in_cells := utf8.decode_grapheme_clusters(line_text, true)
//
// 	if (direction == .LEFT || direction == .RIGHT) {
// 		clamp_column(line_width_in_cells)
// 		cursor.column_in_memory = cursor.column
// 	} else if (direction == .DOWN || direction == .UP) {
// 		u.clamp(&cursor.line, 0, number_of_lines)
//
// 		cursor.column = cursor.column_in_memory
// 		clamp_column(line_width_in_cells)
// 	}
//
// 	line = lines[cursor.line]
// 	line_text = string(line.text[:])
// 	// graphemes, grapheme_count, rune_count, string_width_in_cells := utf8.decode_grapheme_clusters(line_text, true)
// 	grapheme_width_in_columns: int
// 	cursor.byte_location, grapheme_width_in_columns = get_byte_index_and_column_width_of_grapheme_in_column(line_text, cursor.column, graphemes)
//
// 	// if (grapheme_width_in_columns > 1) {
// 	// 	switch direction {
// 	// 		case .LEFT:
// 	// 			cursor.column -= grapheme_width_in_columns - 1
// 	// 		case .DOWN:
// 	// 			cursor.line += grapheme_width_in_columns - 1
// 	// 		case .UP:
// 	// 			cursor.line -= grapheme_width_in_columns - 1
// 	// 		case .RIGHT:
// 	// 			cursor.column += grapheme_width_in_columns - 1
// 	// 	}
// 	// }
// 	if (grapheme_width_in_columns > 1) {
// 		switch direction {
// 			case .LEFT:
// 				cursor.column -= grapheme_width_in_columns - 1
// 			case .DOWN:
// 				cursor.line += grapheme_width_in_columns - 1
// 			case .UP:
// 				cursor.line -= grapheme_width_in_columns - 1
// 			case .RIGHT:
// 				cursor.column += grapheme_width_in_columns - 1
// 		}
// 	}
//
// 	// NOTE: update_cursor_in_view() unnecessary if make_view_follow_cursor() based on absolute text location
// 	update_cursor_in_view(cursor)
// 	make_view_follow_cursor(&view, cursor^)
// 	update_cursor_in_view(cursor)
// 	// fmt.println("MOVED CURSOR", view.cell_rect.position, cursor.grid_location)
// }

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

	line := lines[cursor.line]
	line_text := string(line.text[:])
	_, _, _, line_width_in_cells := utf8.decode_grapheme_clusters(line_text, true)

	if cursor.line < view.cell_rect.position.y {
		fmt.println("cursor was above view.", view.cell_rect.position, iVec2{cursor.line, cursor.column})
		cursor.line = view.cell_rect.position.y
		cursor.column = cursor.column_in_memory
		clamp_column(line_width_in_cells)
	} else if cursor.line >= view.cell_rect.position.y + view.cell_rect.dimensions.y {
		fmt.println("cursor was under view.", view.cell_rect.position, iVec2{cursor.line, cursor.column})
		cursor.line = view.cell_rect.position.y + view.cell_rect.dimensions.y - 1
		cursor.column = cursor.column_in_memory
		clamp_column(line_width_in_cells)
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
		normal_rect := cursor.rect
		normal_rect.dimensions.x *= f32(cursor.cell_width)
		osdl.RenderFillRect(renderer, normal_rect)
	} else if (mode == .INSERT) {
		insert_rect := cursor.rect
		insert_rect.dimensions.x = 2;
		osdl.RenderFillRect(renderer, insert_rect)
	} else {
		panic("Inexistent mode.");
	}
}
