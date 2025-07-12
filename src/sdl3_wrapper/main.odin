package sdl3_wrapper

import sdl "vendor:sdl3"
import "core:c"

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
