package csl

import sdl "vendor:sdl3"
import ttf "vendor:sdl3/ttf"

import "core:strings"
import u "../charlie-utils"

Renderer :: sdl.Renderer
Texture :: sdl.Texture
Surface :: sdl.Surface
Font :: ttf.Font

iVec2 :: [2]int
iVec3 :: [3]int
iVec4 :: [4]int
iColor :: iVec4

u8Vec4 :: [4]u8
u8Color :: u8Vec4

fVec2 :: [2]f32
fVec3 :: [3]f32
fVec4 :: [4]f32
fColor :: fVec4
Color :: fColor

csl_context :: struct {
	renderer: ^Renderer
}

create_text_texture :: proc(text: string, font: ^Font, size: f32, color := u8Color{255, 255, 255, 255}, renderer: ^Renderer = (^csl_context)(context.user_ptr).renderer) -> ^Texture {
	// c_text: cstring
	// has_null_byte: bool
	//
	// if text[len(text) - 1] == 0x00 {
	// 	has_null_byte = true
	// }
	// if has_null_byte {
	// 	c_text = strings.unsafe_string_to_cstring(text)
	// } else {
	// 	c_text = strings.clone_to_cstring(text)
	// }

	ttf.SetFontSize(font, size)
	surface := ttf.RenderText_Blended(font, strings.clone_to_cstring(text), len(text), sdl.Color(color))
	if surface == nil {
		return nil
	} else {
		texture := sdl.CreateTextureFromSurface(renderer, surface)
		sdl.DestroySurface(surface)
		// if !has_null_byte {
		// 	delete(c_text)
		// }
		return texture
	}
}

create_glyph_texture :: proc(glyph: rune, font: ^Font, size: f32, color := u8Color{255, 255, 255, 255}, renderer: ^Renderer = (^csl_context)(context.user_ptr).renderer) -> ^Texture {
	ttf.SetFontSize(font, size)
	surface := ttf.RenderGlyph_Blended(font, u32(glyph), sdl.Color(color))
	if surface == nil {
		return nil
	} else {
		texture := sdl.CreateTextureFromSurface(renderer, surface)
		sdl.DestroySurface(surface)
		return texture
	}
}

@(require_results)
get_monospaced_font_dimensions :: proc(font: ^Font) -> (dimensions: iVec2) {
	ttf.GetGlyphMetrics(font, ' ', nil, nil, nil, nil, (^i32)(&dimensions.x))
	dimensions.y = int(ttf.GetFontLineSkip(font))
	return dimensions
}
