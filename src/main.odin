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
	width, height: f32,
	should_close: bool,
}

Line :: struct {
	texture: ^sdl.Texture,
	text: [dynamic]u8,
	height_in_lines: int,
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
	size: int,
	height: int,
}

window := Window {
	width = 640,
	height = 480,
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

renderer: ^sdl.Renderer

App_Time :: struct { msec, sec: f32 }
app_time: App_Time;

open_file :: proc(filename: string) -> os.Handle {
	file, err := os.open(filename, os.O_RDONLY)
	if (err != os.ERROR_NONE) {
		fmt.fprintln(os.stderr, "ERROR: file not found.")
		os.exit(1)
	}
	return file
}

// NOTE: Two step get size and then read might be a security risk.
get_file_content :: proc(file: os.Handle) -> string {
	file_stat, err := os.fstat(file)
	if (err != os.ERROR_NONE) {
		fmt.fprintln(os.stderr, "ERROR: couldn't stat file.")
		os.exit(1)
	}
	fmt.println(file_stat.size)
	content := make([]u8, file_stat.size)
	content, err = os.read_entire_file_from_handle_or_err(file) // NOTE: allocates memory.
	if (err != os.ERROR_NONE) do os.exit(1)

	return string(content)
}

main :: proc() {
	///////////////
	// APP INIT //
	//////////////

	ok := sdl.SetAppMetadata("Elk", "0.1", "com.elk.charlie"); assert(ok)
	ok = sdl.Init({.VIDEO}); assert(ok)
	window_flags := sdl.WindowFlags{.BORDERLESS}
	ok = sdl.CreateWindowAndRenderer("Elk", i32(window.width), i32(window.height), window_flags, &window.handle, &renderer); assert(ok)

	// Init ttf.
	if !ttf.Init() {
        panic("Failed to init SDL3_ttf\n")
    } else {
		fmt.println("Successfully initiated SDL3_ttf!")
	}

	font.handle = ttf.OpenFont("/usr/share/fonts/TTF/JetBrainsMono-Regular.ttf", f32(font.size))
	if (font.handle == nil) do error_and_exit()
	defer ttf.CloseFont(font.handle)
	font.height = int(ttf.GetFontLineSkip(font.handle))
	// fmt.println(font.height)

	// NOTE: Do I want to have the file open for the duration of the program or just on open and on save?
	filename := "main.odin"
	file := open_file(filename)
	defer os.close(file)

	file_content := get_file_content(file)

	text_string := expand_tabs(file_content, 4)
	// lines := split_string_in_lines(text_string)
	lines := split_string_in_line_structs(text_string)

	// textures := make([dynamic]^sdl.Texture)

	for &line, i in lines {
		// text_surface := ttf.RenderText_Blended_Wrapped(font.handle, strings.unsafe_string_to_cstring(string(line.text[:])), 0, colors.WHITE, i32(window.width - margins.left - margins.right))
		text_surface := ttf.RenderText_Blended(font.handle, strings.unsafe_string_to_cstring(string(line.text[:])), 0, colors.WHITE)
		// if (text_surface == nil) do error_and_exit()
		if (text_surface == nil) {
			continue
		} else {
			// fmt.printfln("line %d: %s", i, line.text) 
			fmt.printfln("line %d: %v", i, line.text) 
			// fmt.println("surface: ", text_surface.h) 
			line.texture = sdl.CreateTextureFromSurface(renderer, text_surface)
			// fmt.println("texture: ", line.texture.h) 
			line.height_in_lines = int(line.texture.h) / font.height
			// fmt.println("height_in_lines: ", line.height_in_lines)
			// fmt.println()
			sdl.DestroySurface(text_surface)
		}
	}

	first_iteration := true // NOTE: For testing purposes.


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
					view.line += (window.height / f32(font.height)) / 2
				}
				else if keycode == 'K' {
					view.line -= (window.height / f32(font.height)) / 2
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
		sdl.RenderClear(renderer)
		calculate_app_time(&app_time);

		// frame_rendering
		background_color := Color{ 0, color_offset, 0.3, 1 }
		fill_screen(background_color)
		// draw_rectangle({f32(window_dimensions.x / 2) - 300 / 2, f32(window_dimensions.y / 2) - 100 / 2},
		// 	{300, 100}, {1, 0, 1, 1})

		w, h: c.int
		sdl.GetRenderOutputSize(renderer, &w, &h)
		if (first_iteration) do fmt.printfln("w: %d, h: %d\n", w, h)

		// NOTE: text.size is a bad estimation. The text has a diffrent width and heigth.
		view.position = { view.column, view.line } * f32(font.height)
		view.position.y = view.line * f32(font.height)
		// fmt.printfln("col: %v, line: %v, position: %v", view.column, view.line, view.position)

		// render_text(text.texture)
		render_only_visible_lines(lines)

		sdl.RenderPresent(renderer)
		first_iteration = false
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

// This line is just here for security in case file read cuts data.
// This line is just here for security in case file read cuts data.
// This line is just here for security in case file read cuts data.
// This line is just here for security in case file read cuts data.
// This line is just here for security in case file read cuts data.
// This line is just here for security in case file read cuts data.
// This line is just here for security in case file read cuts data.
// This line is just here for security in case file read cuts data.
// This line is just here for security in case file read cuts data.
// This line is just here for security in case file read cuts data.
// This line is just here for security in case file read cuts data.
// This line is just here for security in case file read cuts data.
// This line is just here for security in case file read cuts data.
// This line is just here for security in case file read cuts data.
// This line is just here for security in case file read cuts data.
// This line is just here for security in case file read cuts data.
// This line is just here for security in case file read cuts data.
