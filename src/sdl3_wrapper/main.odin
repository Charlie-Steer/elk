package sdl3_wrapper

import sdl "vendor:sdl3"
import "core:c"

fVec2 :: [2]f32
fVec3 :: [3]f32
fVec4 :: [4]f32
Color :: fVec4
iVec2 :: [2]int
iVec3 :: [3]int
iVec4 :: [4]int

fRect :: struct {
	position: fVec2,
	dimensions: fVec2,
}

CreateWindowAndRenderer :: #force_inline proc(title: cstring, width, height: int, window_flags: sdl.WindowFlags, window: ^^sdl.Window, renderer: ^^sdl.Renderer) -> bool {
	ok := sdl.CreateWindowAndRenderer(title, i32(width), i32(height), window_flags, window, renderer)
	return ok
}

GetRenderOutputSize :: #force_inline proc(renderer: ^sdl.Renderer, w, h: ^int) -> bool {
	ok := sdl.GetRenderOutputSize(renderer, transmute(^i32)w, transmute(^i32)h)
	return ok
}

SetWindowSize :: #force_inline proc(window: ^sdl.Window, w, h: int) -> bool {
	ok := sdl.SetWindowSize(window, i32(w), i32(h))
	return ok
}

RenderTexture :: proc(renderer: ^sdl.Renderer, texture: ^sdl.Texture, src_rect, dst_rect: Maybe(^fRect)) -> bool {
	src_sdl_rect, dst_sdl_rect: Maybe(^sdl.FRect)
	if rect, ok := src_rect.?; ok {
		src_sdl_rect = &sdl.FRect {
			x = rect.position.x,
			y = rect.position.y,
			w = rect.dimensions.x,
			h = rect.dimensions.y,
		}
	}
	if rect, ok := dst_rect.?; ok {
		dst_sdl_rect = &sdl.FRect {
			x = rect.position.x,
			y = rect.position.y,
			w = rect.dimensions.x,
			h = rect.dimensions.y,
		}
	}
	ok := sdl.RenderTexture(renderer, texture, src_sdl_rect, dst_sdl_rect)
	return ok
}

GetTextureSize :: proc(texture: ^sdl.Texture) -> (dimensions: fVec2, ok: bool) {
	ok = sdl.GetTextureSize(texture, &dimensions.x, &dimensions.y)
	return dimensions, ok
}
