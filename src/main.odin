package main

import "colors"

import sdl "vendor:sdl3"
import ttf "vendor:sdl3/ttf"

import "core:c"
import "core:os"
import "core:fmt"
import "core:strings"
import "core:math"

fVec2 :: [2]f32
fVec3 :: [3]f32
fVec4 :: [4]f32
Color :: fVec4
iVec2 :: [2]i32
iVec3 :: [3]i32
iVec4 :: [4]i32

Window :: struct {
	handle: ^sdl.Window,
	size: iVec2,
	should_close: bool,
}

Text :: struct {
	string: cstring,
	texture: ^sdl.Texture,
	size: fVec2,
}

View :: struct {
	line: f32,
	column: f32,
	position: fVec2,
	size: fVec2,
	window: sdl.FRect,
}

Font :: struct {
	handle: ^ttf.Font,
	size: i32,
}

window := Window {
	size = {680, 480}
}
text := Text {
	string = text_string,
}
view: View
font := Font{
	size = 12
}

Margins :: struct {
	up, down, left, right: f32
}
margins := Margins{ 10, 0, 20, 0 }

renderer: ^sdl.Renderer

App_Time :: struct { msec, sec: f32 }
app_time: App_Time;

main :: proc() {
	///////////////
	// APP INIT //
	//////////////

	ok := sdl.SetAppMetadata("Elk", "0.1", "com.elk.charlie"); assert(ok)
	ok = sdl.Init({.VIDEO}); assert(ok)
	ok = sdl.CreateWindowAndRenderer("Elk", window.size.x, window.size.y, {}, &window.handle, &renderer); assert(ok)

	// Init ttf.
	if !ttf.Init() {
        panic("Failed to init SDL3_ttf\n")
    } else {
		fmt.println("Successfully initiated SDL3_ttf!")
	}

	font.handle = ttf.OpenFont("/usr/share/fonts/TTF/JetBrainsMono-Regular.ttf", f32(font.size))
	if (font.handle == nil) do error_and_exit()
	defer ttf.CloseFont(font.handle)

	text_surface := ttf.RenderText_Blended_Wrapped(font.handle, text_string, 0, colors.WHITE, window.size.x - i32(margins.left) - i32(margins.right))
	if (text_surface == nil) do error_and_exit()
	else {
		text.texture = sdl.CreateTextureFromSurface(renderer, text_surface)
		sdl.DestroySurface(text_surface)
	}

	first_iteration := true


	//////////////////
	// APP ITERATE //
	/////////////////

	color_offset: f32
	for !window.should_close {
		// EVENTS
		e: sdl.Event
		for sdl.PollEvent(&e) {
			#partial switch e.type {
			case .QUIT:
				window.should_close = true
			case .KEY_DOWN:
				if e.key.scancode == .ESCAPE || e.key.scancode == .Q {
					window.should_close = true
				}
				else if e.key.scancode == .J {
					view.line += 1;
				}
				else if e.key.scancode == .K {
					view.line -= 1;
				}
			}
		}
		calculate_app_time(&app_time);

		// frame_rendering
		background_color := Color{ 0, color_offset, 0.3, 1 }
		fill_screen(background_color)
		// draw_rectangle({f32(window_dimensions.x / 2) - 300 / 2, f32(window_dimensions.y / 2) - 100 / 2},
		// 	{300, 100}, {1, 0, 1, 1})

		w, h: c.int
		sdl.GetRenderOutputSize(renderer, &w, &h)
		if (first_iteration) do fmt.printfln("w: %d, h: %d\n", w, h)

		sdl.GetTextureSize(text.texture, &text.size.x, &text.size.y)
		view.size.y = text.size.y < f32(window.size.y) ? text.size.y : f32(window.size.y)
		view.size.x = text.size.x
		view.position.y = view.line * f32(font.size)
		view.window = sdl.FRect{ view.position.x, view.position.y, view.size.x, view.size.y }
		text_dst_rect := sdl.FRect{ margins.left, margins.up, max(text.size.x, f32(window.size.x)), view.size.y }
		sdl.RenderTexture(renderer, text.texture, &view.window, &text_dst_rect)

		// TODO: width of text buffer should take margins into account.

		sdl.RenderPresent(renderer)
		first_iteration = false;
	}

	///////////////
	// APP QUIT //
	//////////////

	sdl.Quit()
}

calculate_app_time :: proc(app_time: ^App_Time) {
	app_time.msec = f32(sdl.GetTicks())
	app_time.sec = f32(sdl.GetTicks()) / 1000
}

fill_screen :: proc(color: Color) {
	sdl.SetRenderDrawColorFloat(renderer, color.x, color.y, color.z, color.w)
	sdl.RenderClear(renderer)
}

draw_rectangle :: proc(position, dimensions: fVec2, color: Color) {
	sdl.SetRenderDrawColorFloat(renderer, color.x, color.y, color.z, color.w)
	rect := sdl.FRect{ position.x, position.y, dimensions.x, dimensions.y }
	sdl.RenderFillRect(renderer, &rect)
}

error_and_exit :: proc(category := sdl.LogCategory.APPLICATION) {
	sdl.LogError(category, sdl.GetError())
	os.exit(1);
}
