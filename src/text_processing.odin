package main

import "core:strings"
import "core:unicode/utf8"
import "core:fmt"
import "core:os"

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
}
