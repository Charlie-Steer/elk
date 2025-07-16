package main

import sdl "vendor:sdl3"
import "core:fmt"
import u "charlie-utils"
import "colors"

// For now only intended to draw non-wrapping monospaced lines.
// Probably write separate logic if you want to implement wrapping text.
render_lines :: proc(frame: sdl.FRect, lines: [dynamic]Line, index_first, index_last: int) {
	line_vertical_offset: f32
	for line, i in lines[index_first:index_last + 1] {
		texture := line.texture
		if texture == nil {
			continue
		}

		src := sdl.FRect{
			x = u.get_clamped_min(view.position.x, 0),
			y = 0,
			w = min(f32(texture.w) - u.get_clamped_min(view.position.x, 0), frame.w),
			h = min(f32(texture.h), frame.h),
		}

		line_vertical_offset = f32(font.dimensions.y) * f32(line.index) - view.position.y
		dst := sdl.FRect{
			x = view.position.x < 0 ? frame.x + (-view.position.x) : frame.x,
			y = frame.y + line_vertical_offset,
			w = src.w,
			h = src.h,
		}

		if debug_rendering == true {
			if (line.index == index_first || line.index == index_last) do sdl.SetRenderDrawColor(renderer, 0, 255, 0, 255)
			else do sdl.SetRenderDrawColor(renderer, 255, 0, 0, 255)
			sdl.RenderRect(renderer, &dst)
		}

		sdl.RenderTexture(renderer, texture, &src, &dst)
	}
}

render_background :: proc(frame: sdl.FRect, index_first, index_last: int) {
	// Background
	background_vertical_margin := f32(font.dimensions.y) * 0.2
	background_horizontal_margin := f32(font.dimensions.y) * 0.15
	// background_vertical_margin := f32(0)
	background_rect: sdl.FRect
	if view.position.y < 0 {
		background_rect.y = f32(margins.up) + (-view.position.y) - background_vertical_margin
		background_rect.h = (f32(font.dimensions.y * (index_last + 2 - index_first)) + background_vertical_margin)
	}
	else {
		background_rect.y = f32(margins.up)
		background_rect.h = f32(window.dimensions.y - font.dimensions.y * (index_last + 1 - index_first)) + background_vertical_margin
		background_rect.h = f32(font.dimensions.y * (index_last + 1 - index_first)) + background_vertical_margin
	}

	if view.position.x <= 0 {
		background_rect.x = -background_horizontal_margin
		background_rect.w = f32(frame.w) + background_horizontal_margin
	} else {
		background_rect.x = 0
		background_rect.w = f32(frame.w)
	}

	sdl.SetRenderDrawColor(renderer, 0x24, 0x28, 0x3b, 0xff)
	sdl.RenderFillRect(renderer, &background_rect)
}

fill_screen :: proc(color: Color) {
	sdl.SetRenderDrawColor(renderer, 0x1f, 0x23, 0x35, 0xff)
	sdl.RenderClear(renderer)
}
