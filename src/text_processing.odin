package main

import "core:strings"
import "core:unicode/utf8"
import "core:fmt"
import "core:os"
import u "charlie-utils"

// NOTE: Add error handling?
// NOTE: Apparently theres an expand_tabs proc on core:strings
@(require_results)
expand_tabs :: proc(str: string, tab_width: int) -> string {
	builder := strings.builder_make()
	for c in str {
		if c == '\t' {
			for i in 0..<tab_width {
				strings.write_rune(&builder, ' ')
			}
		} else {
			strings.write_rune(&builder, c)
		}
	}
	// strings.write_rune(&builder, 0x00)
	return (strings.to_string(builder))
}

@(require_results)
copy_substring :: proc(slice: string) -> [dynamic]u8 {
	substring := make_dynamic_array_len_cap([dynamic]u8, 0, len(slice))
	for c, i in transmute([]u8)slice {
		append(&substring, slice[i])
	}
	// append(&substring, ' ')
	// append(&substring, 0x00)
	return substring
}

split_string_in_lines :: proc(text: string) -> [dynamic]([dynamic]u8) {
	lines: = make([dynamic]([dynamic]u8))
	// line_number: i32 = 0
	line_start_index: int 
	for c, i in transmute([]u8)text {
		if c == '\n' {
			// current_rune_size := utf8.rune_size(r)
			// lines[line_number] = copy_substring(text[line_start_index:i + current_rune_size])
			// line_start_index = i + current_rune_size
			// lines[line_number] = copy_substring(text[line_start_index:i])
			substr := copy_substring(text[line_start_index:i])
			// fmt.println(substr)
			append_elem(&lines, substr)
			line_start_index = i
			// line_number += 1
		}
	}
	return lines
}

split_string_in_line_structs :: proc(text: string) -> [dynamic]Line {
	lines: = make([dynamic]Line)
	line_start_index: int 
	for c, i in transmute([]u8)text {
		if c == '\n' {
			// substr := copy_substring(text[line_start_index:(i + 1)])
			substr := copy_substring(text[line_start_index:i])
			append_elem(&lines, Line{ text = substr })
			line_start_index = i + 1
		}
	}
	return lines
}

// REASSEMBLY PROCESS

combine_lines_into_single_buffer_and_save_file :: proc(lines: [dynamic]Line) {
	buffer := make_dynamic_array_len_cap([dynamic]u8, 0, 4096) // NOTE: Allocation.
	for line in lines {
		append_string(&buffer, string(line.text[:]))
		append_elem(&buffer, '\n')
	}
	fmt.println(string(buffer[:]))
	file, err_open := os.open("/home/charlie/projects/elk/edit_playground/edited.odin", os.O_CREATE | os.O_TRUNC | os.O_WRONLY, 0o644)
	if err_open != .NONE {
		fmt.eprintln("ERROR: COULDN'T OPEN FILE")
	}
	defer os.close(file)

	bytes_written, err_write := os.write(file, buffer[:])
	if err_write != .NONE {
		fmt.eprintln("ERROR: COULDN'T WRITE CONTENTS TO FILE")
	} else {
		fmt.printfln("Wrote %v bytes.", bytes_written)
	}
}

// Creating and destroying lines.

merge_lines :: proc(lines: ^[dynamic]Line, index_a, index_b: int) {
	if (index_a < 0 || index_b >= len(lines)) {
		return
	}

	append_elem_string(&lines[index_a].text, string(lines[index_b].text[:]))

	ordered_remove(lines, index_b)

	update_line_data(&lines[cursor.line])
	set_line_indeces_and_number_of_lines(lines)
}


// TODO: Return cursor_width also.
@(require_results)
traverse_line_to_column :: proc(line: ^Line, target_column: int, gravity_enabled := true, allow_col_after_end := false) -> (grapheme_idx, col_idx, byte_idx, grapheme_width: int) {
	if len(line.text) == 0 {
		return 0, 0, 0, 1
	}
	last_column := (line.len_columns - 1)
	if allow_col_after_end {
		last_column += 1
	}

	target_col := u.get_clamped(target_column, 0, last_column) // NOTE: One over real columns, to be able to insert characters at the end of the line.

	fmt.printfln("col: %d\nlast_col: %d\ntarget_col: %d\n", cursor.column, last_column, target_column)
	grapheme := line.graphemes[grapheme_idx]
	for col_idx < target_col { //😊😊😊a
		assert(grapheme.width >= 1)
		col_idx += grapheme.width >= 1 ? grapheme.width : 1 // NOTE: Probably unnecessary ternary operation but just in case.

		if (col_idx > target_col) {
			if gravity_enabled || col_idx > last_column {
				col_idx -= grapheme.width
				fmt.println("Went past last column and had to be corrected.")
				break
			}
		}

		graphemes_len := len(line.graphemes)
		if (grapheme_idx + 1 < graphemes_len) {
			grapheme_idx += 1
			grapheme = line.graphemes[grapheme_idx]
		} else if (allow_col_after_end && (col_idx == line.len_columns)) {
			// NOTE: Unsure if returning -1 for non-valid values is the right thing. For byte_idx it could be len(line.text) although not a valid index.
			fmt.println("On call after end.")
			// return -1, line.len_columns, -1, 1
			// NOTE: I think it's grapheme_idx + 1
			return grapheme_idx + 1, line.len_columns, len(line.text), 1
		} else {
			fmt.println("Return A.")
			return grapheme_idx, col_idx, grapheme.byte_index, grapheme.width
		}
	}
	fmt.println("Return B.")
	return grapheme_idx, col_idx, grapheme.byte_index, grapheme.width
}

split_line_at_cursor :: proc(lines: ^[dynamic]Line, cursor: Cursor) {
	line := &lines[cursor.line]
	// grapheme_idx, col_idx, byte_idx, grapheme_width := traverse_line_to_column(&line, cursor.column, gravity_enabled=true)
	grapheme_idx, col_idx, byte_idx, grapheme_width := traverse_line_to_column(line, cursor.column, gravity_enabled=true)

	new_text := make([dynamic]u8)
	append_string(&new_text, string(line.text[byte_idx:]))
	fmt.println(cursor.byte_location, len(line.text))
	remove_range(&line.text, cursor.byte_location, len(line.text))

	inject_at_elem(lines, cursor.line + 1, Line{text = new_text})
	update_lines_data(lines[cursor.line : cursor.line + 2])
	set_line_indeces_and_number_of_lines(lines)
	fmt.println("new_string: ", string(lines[cursor.line + 1].text[:]))
	fmt.println("old_string: ", string(lines[cursor.line].text[:]))
}
