package main

import sdl "vendor:sdl3"
import ttf "vendor:sdl3/ttf"
import wsdl "sdl3_wrapper"
import wttf "sdl3_ttf_wrapper"
import "core:time"
import "core:unicode/utf8"

// NOTE: Not all types and constants are featured here.
// Only those that didn't seem specially relevant to any particular file.

iVec2 :: [2]int
iVec3 :: [3]int
iVec4 :: [4]int
iColor :: iVec4

fVec2 :: [2]f32
fVec3 :: [3]f32
fVec4 :: [4]f32
fColor :: fVec4
Color :: fColor

fRect :: wsdl.fRect
iRect :: wsdl.iRect

SECOND :: 1_000_000_000

Window :: struct {
	handle: ^sdl.Window,
	
	position: iVec2,
	dimensions: iVec2,

	should_close: bool,
}

Font :: struct {
	handle: ^ttf.Font,
	size: f32,

	dimensions: iVec2,
}

Line :: struct {
	texture: ^sdl.Texture,
	text: [dynamic]u8,
	height_in_lines: int,
	index: int,
	
	graphemes: [dynamic]utf8.Grapheme,
	len_columns: int,
	len_graphemes: int,

	is_dirty: bool,
}

Margins :: struct {
	up, down, left, right: int
}

App_Time :: struct {
	ns: time.Duration,
	ms: f64,
	s: f64,
}
