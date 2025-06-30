package main

import "core:strings"

// NOTE: Add error handling?
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
