package main

import sdl "vendor:sdl3"
import osdl "sdl3_wrapper"

update_and_render_cursor :: proc(cursor: ^Cursor) {
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
