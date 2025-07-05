package main

import sdl "vendor:sdl3"
import "core:fmt"
import cs "charlie"
import "colors"

// For now only intended to draw non-wrapping monospaced lines.
// Probably write separate logic if you want to implement wrapping text.
render_lines :: proc(lines: [dynamic]Line, index_first, index_last: int) {
	frame := sdl.FRect{
		w = f32(window.width),
		h = f32(window.height),
	}
	// frame := sdl.FRect{
	// 	x = f32(margins.left),
	// 	y = f32(margins.up),
	// 	w = f32(window.width - (margins.left + margins.right)),
	// 	h = f32(window.height - (margins.up + margins.down)),
	// }

	// NOTE: Refactor Background rendering outside and make frame rectangle a parameter for both procs?

	// Background
	background_vertical_margin := f32(font.height) * 0.2
	background_horizontal_margin := f32(font.height) * 0.15
	// background_vertical_margin := f32(0)
	background_rect: sdl.FRect
	if view.position.y < 0 {
		background_rect.y = f32(margins.up) + (-view.position.y) - background_vertical_margin
		background_rect.h = (f32(font.height * (index_last + 2 - index_first)) + background_vertical_margin)
	}
	else {
		background_rect.y = f32(margins.up)
		background_rect.h = f32(window.height - font.height * (index_last + 1 - index_first)) + background_vertical_margin
		background_rect.h = f32(font.height * (index_last + 1 - index_first)) + background_vertical_margin
	}

	if view.position.x <= 0 {
		background_rect.x = -background_horizontal_margin
		background_rect.w = f32(frame.w) + background_horizontal_margin
	} else {
		background_rect.x = 0
		background_rect.w = f32(frame.w)
	}
	// fmt.println(background_rect.h)

	sdl.SetRenderDrawColor(renderer, 0x24, 0x28, 0x3b, 0xff)
	sdl.RenderFillRect(renderer, &background_rect)
	
	fmt.println("first: ", index_first)
	fmt.println("last: ", index_last)
	line_vertical_offset: f32
	// fmt.println("before: ", view.position.x)
	// fmt.println("after: ", cs.clamp_min(view.position.x, 0))
	for line, i in lines[index_first:index_last + 1] {
		// fmt.printfln("line %d: %s") 
		texture := line.texture
		if texture == nil {
			continue
		}

		// src_rect_y_position := clamp(view.position.y, 0, f32(texture.h))
		src := sdl.FRect{
			// x = view.position.x,
			x = cs.clamp_min(view.position.x, 0),
			y = 0,
			// w = min(f32(texture.w) - clamp(view.position.x, 0, view.position.x), frame.w),
			// w = min(f32(texture.w) - view.position.x, frame.w),
			w = min(f32(texture.w) - cs.clamp_min(view.position.x, 0), frame.w),
			// w = min(f32(texture.w), frame.w),
			h = min(f32(texture.h), frame.h),
		}
		// src = sdl.FRect{
		// 	x = view.position.x,
		// 	y = 0,
		// 	// w = min(f32(texture.w) - clamp(view.position.x, 0, view.position.x), frame.w),
		// 	w = min(f32(texture.w) - cs.clamp_min(view.position.x, 0), frame.w),
		// 	// w = min(f32(texture.w), frame.w),
		// 	h = min(f32(texture.h), frame.h),
		// }

		// fmt.println(texture)
		// fmt.println("height_in_lines: ", line.height_in_lines)
		// fmt.println("texture_height: ", line.texture.h)
		// TODO: Only draw lines that fit on screen.
		line_vertical_offset = f32(font.height) * f32(line.index) - view.position.y
		dst := sdl.FRect{
			// x = frame.x,
			x = view.position.x < 0 ? frame.x + (-view.position.x) : frame.x,
			// x = frame.x - view.position.x,
			y = frame.y + line_vertical_offset,
			// w = window.w - (margins.left + margins.right),
			// w = src.w < frame.w ? src.w : frame.w,
			w = src.w,
			// h = src.h < frame.h ? src.h : frame.h,
			h = src.h,
		}

		fmt.println("id: ", line.index)
		if debug_rendering == true {
			if (line.index == index_first || line.index == index_last) do sdl.SetRenderDrawColor(renderer, 0, 255, 0, 255)
			else do sdl.SetRenderDrawColor(renderer, 255, 0, 0, 255)
			sdl.RenderRect(renderer, &dst)

			// if (i == 4) {
			// 	fmt.println("src: ", src)
			// 	fmt.println("dst: ", dst, '\n')
			// }
		}

		sdl.RenderTexture(renderer, texture, &src, &dst)
	}
}
