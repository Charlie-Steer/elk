package main

import sdl "vendor:sdl3"
import "core:fmt"
import cs "charlie"
import "colors"

// For now only intended to draw non-wrapping monospaced lines.
// Probably write separate logic if you want to implement wrapping text.
render_only_visible_lines :: proc(lines: [dynamic]Line) {
	frame := sdl.FRect{
		x = f32(margins.left),
		y = f32(margins.up),
		w = f32(window.width - (margins.left + margins.right)),
		h = f32(window.height - (margins.up + margins.down)),
	}
	
	line_vertical_offset: f32
	// fmt.println("before: ", view.position.x)
	// fmt.println("after: ", cs.clamp_min(view.position.x, 0))
	for line, i in lines {
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
		line_vertical_offset = f32(font.height) * f32(i) - view.position.y
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
		sdl.SetRenderDrawColor(renderer, 255, 0, 0, 255)
		bounds := dst
		sdl.RenderRect(renderer, &bounds)

		if (i == 4) {
			fmt.println("src: ", src)
			fmt.println("dst: ", dst, '\n')
		}

		// NOTE: Probably needs rework.
		// background_rect := sdl.FRect{
		// 	x = 0,
		// 	y = (view.position.y > 0 ? 0 : -view.position.y + (margins.up)) - (f32(font.height) * 0.4),
		// 	w = window.width,
		// 	h = src.h - (margins.up + margins.down) + (f32(font.height) * 0.8),
		// }
		background_rect := dst
		background_rect.x = 0
		background_rect.w = f32(window.width)
		background_rect.h = f32(font.height)
		// background_rect.y += f32(font.height)
		// fmt.println(background_rect.h)

		// Background
		// sdl.SetRenderDrawColor(renderer, 0x24, 0x28, 0x3b, 0xff)
		//
		// // sdl.RenderFillRect(renderer, &background_rect)
		// if i % 3 == 0 {
		// 	sdl.RenderFillRect(renderer, &background_rect)
		// } else {
		// 	sdl.RenderRect(renderer, &background_rect)
		// }

		sdl.RenderTexture(renderer, texture, &src, &dst)
	}
}
