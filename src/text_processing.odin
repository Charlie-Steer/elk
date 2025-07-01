package main

import "core:strings"
import "core:unicode/utf8"
import "core:fmt"

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
	strings.write_rune(&builder, 0x00)
	return (strings.to_string(builder))
}

@(require_results)
copy_substring :: proc(slice: string) -> [dynamic]u8 {
	substring := make_dynamic_array_len_cap([dynamic]u8, 0, len(slice) + 1)
	for c, i in transmute([]u8)slice {
		append(&substring, slice[i])
	}
	append(&substring, 0x00)
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
