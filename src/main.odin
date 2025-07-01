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
	w, h: f32,
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
	height: i32,
}

window := Window {
	w = 640,
	h = 480,
}

text := Text {
	string = text_string,
}
view: View
font := Font{
	size = 14,
}

Margins :: struct {
	up, down, left, right: f32
}
margins := Margins{ 10, 0, 20, 0 }
// margins := Margins{ 0, 0, 0, 0 }

renderer: ^sdl.Renderer

App_Time :: struct { msec, sec: f32 }
app_time: App_Time;

main :: proc() {
	///////////////
	// APP INIT //
	//////////////

	ok := sdl.SetAppMetadata("Elk", "0.1", "com.elk.charlie"); assert(ok)
	ok = sdl.Init({.VIDEO}); assert(ok)
	window_flags := sdl.WindowFlags{.BORDERLESS}
	ok = sdl.CreateWindowAndRenderer("Elk", i32(window.w), i32(window.h), window_flags, &window.handle, &renderer); assert(ok)

	// Init ttf.
	if !ttf.Init() {
        panic("Failed to init SDL3_ttf\n")
    } else {
		fmt.println("Successfully initiated SDL3_ttf!")
	}

	font.handle = ttf.OpenFont("/usr/share/fonts/TTF/JetBrainsMono-Regular.ttf", f32(font.size))
	if (font.handle == nil) do error_and_exit()
	defer ttf.CloseFont(font.handle)
	font.height = ttf.GetFontLineSkip(font.handle)
	fmt.println(font.height)

	filename := "main.odin"
	file, err := os.open(filename, os.O_RDONLY)
	if (err != os.ERROR_NONE) {
		fmt.fprintln(os.stderr, "ERROR: file not found.")
		os.exit(1)
	}
	defer os.close(file)
	file_stat: os.File_Info
	file_stat, err = os.fstat(file)
	if (err != os.ERROR_NONE) {
		fmt.fprintln(os.stderr, "ERROR: couldn't stat file.")
		os.exit(1)
	}
	fmt.println(file_stat.size)
	text_byte_array := make([]u8, file_stat.size)
	text_byte_array, err = os.read_entire_file_from_handle_or_err(file) // NOTE: allocates memory.
	if (err != os.ERROR_NONE) do os.exit(1)

	text_string := expand_tabs(string(text_byte_array), 4)
	// for c in transmute([]byte)text_string {
	// 	fmt.println(c)
	// }
	// assert(false)
	// TODO: separate string in lines.
	// TODO: Rework with core lib functions and pay attention to conventions.
	// lines := strings.split_lines(text_string)
	lines := split_string_in_lines(text_string)
	c_lines: []cstring
	// for line, i in lines {
	// 	c_lines[i] = strings.unsafe_string_to_cstring(string())
	// }
	
	// fmt.print(string(lines[0][:]))
	// for line, i in lines {
	// 	fmt.print(string(line[:]))
	// }

	append_elem(&lines[0], 0x00)
	fmt.printfln("%s", lines[0])
	c_string := strings.unsafe_string_to_cstring(string(lines[0][:]))
	fmt.println(c_string)

	text_surface := ttf.RenderText_Blended_Wrapped(font.handle, strings.unsafe_string_to_cstring(string(lines[0][:])), 0, colors.WHITE, i32(window.w - margins.left - margins.right))
	fmt.println("C")
	// text_surface := ttf.RenderText_Blended(font.handle, text_string, 0, colors.WHITE)
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
				keycode := sdl.GetKeyFromScancode(e.key.scancode, e.key.mod, false)
				if keycode == 'J' {
					view.line += (window.h / f32(font.height)) / 2
				}
				else if keycode == 'K' {
					view.line -= (window.h / f32(font.height)) / 2
				}
				else if e.key.scancode == .ESCAPE || e.key.scancode == .Q {
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

		// NOTE: text.size is a bad stimation. The text has a diffrent width and heigth.
		view.position = { view.column, view.line } * f32(font.height)
		view.position.y = view.line * f32(font.height)
		// fmt.printfln("col: %v, line: %v, position: %v", view.column, view.line, view.position)

		render_text(text.texture)

		sdl.RenderPresent(renderer)
		first_iteration = false
	}

	///////////////
	// APP QUIT //
	//////////////

	sdl.Quit()
}

Text_Texture :: struct {
	handle: ^sdl.Texture,
	w, h: f32,
}

render_text :: proc(texture: ^sdl.Texture) {
	text_texture := Text_Texture{ handle = texture }
	sdl.GetTextureSize(text_texture.handle, &text_texture.w, &text_texture.h)

	src_rect_y_position := clamp(view.position.y, 0, text_texture.h)
	src_rect := sdl.FRect{
		x = 0,
		y = src_rect_y_position,
		w = window.w,
		h = min(window.h, text_texture.h - src_rect_y_position)
	}

	dst_rect := sdl.FRect{
		x = 0 + (margins.left),
		y = view.position.y > 0 ? 0 : -view.position.y + (margins.up),
		w = window.w - (margins.left + margins.right),
		h = src_rect.h - (margins.up + margins.down),
	}

	background_rect := sdl.FRect{
		x = 0,
		y = (view.position.y > 0 ? 0 : -view.position.y + (margins.up)) - (f32(font.height) * 0.4),
		w = window.w,
		h = src_rect.h - (margins.up + margins.down) + (f32(font.height) * 0.8),
	}

	// Background
	sdl.SetRenderDrawColor(renderer, 0x24, 0x28, 0x3b, 0xff)
	sdl.RenderFillRect(renderer, &background_rect)

	sdl.RenderTexture(renderer, text_texture.handle, &src_rect, &dst_rect)
}

render_only_visible_lines :: proc() {
}

calculate_app_time :: proc(app_time: ^App_Time) {
	app_time.msec = f32(sdl.GetTicks())
	app_time.sec = f32(sdl.GetTicks()) / 1000
}

fill_screen :: proc(color: Color) {
	sdl.SetRenderDrawColor(renderer, 0x1f, 0x23, 0x35, 0xff)
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
