package sdl3_ttf_wrapper

// import sdl "vendor:sdl3"
import ttf "vendor:sdl3/ttf"
import "core:c"

GetGlyphMetrics :: #force_inline proc(font: ^ttf.Font, ch: rune, minx, maxx, miny, maxy, advance: ^int) -> bool {
	ok := ttf.GetGlyphMetrics( font, u32(ch), transmute(^i32)minx, transmute(^i32)maxx, transmute(^i32)miny, transmute(^i32)maxy, transmute(^i32)advance)
	return ok
}
