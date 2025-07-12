package main

import "colors"
import cs "charlie"

import sdl "vendor:sdl3"
import ttf "vendor:sdl3/ttf"

import "core:c"
import "core:os"
import "core:fmt"
import "core:strings"
import "core:math"
import "core:time"
import "core:strconv"

fVec2 :: [2]f32
fVec3 :: [3]f32
fVec4 :: [4]f32
Color :: fVec4
iVec2 :: [2]i32
iVec3 :: [3]i32
iVec4 :: [4]i32

Window :: struct {
	handle: ^sdl.Window,
	x, y: int,
	width, height: int,
	should_close: bool,
}

Line :: struct {
	texture: ^sdl.Texture,
	text: [dynamic]u8,
	height_in_lines: int,
	index: int,
}

Text :: struct {
	string: cstring,
	texture: ^sdl.Texture,
	size: fVec2,
}

View :: struct {
	line: int,
	column: int,
	position: fVec2,
	size: fVec2,
	window: sdl.FRect,
}

Font :: struct {
	handle: ^ttf.Font,
	size: int,
	height: int,
	width: int,
}

window := Window {
	width = window_width,
	height = window_height,
}

view: View
font := Font{
	size = font_size,
}

Margins :: struct {
	up, down, left, right: int
}

renderer: ^sdl.Renderer

App_Time :: struct {
	ns: time.Duration,
	ms: f64,
	s: f64,
}
app_time: App_Time;

number_of_lines: int

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
	content := make([]u8, file_stat.size)
	content, err = os.read_entire_file_from_handle_or_err(file) // NOTE: allocates memory.
	if (err != os.ERROR_NONE) do os.exit(1)

	return string(content)
}

get_indeces_for_lines_in_view :: proc(lines: [dynamic]Line) -> (start_index, end_index: int) {
	start_index = cs.clamp_min(view.line, 0)
	end_index = clamp(view.line + (window.height / font.height) - 1, 0, number_of_lines - 1)
	return start_index, end_index
}

next_second: f64 = 1
fps_texture: ^sdl.Texture
frames_this_second: int
main :: proc() {
	///////////
	// START //
	///////////

	// sdl.SetHint(sdl.
	ok := sdl.SetAppMetadata("Elk", "0.1", "dev.charlie.elk"); assert(ok)
	ok = sdl.Init(sdl.InitFlags{.VIDEO}); assert(ok)
	window_flags := sdl.WindowFlags{
		.BORDERLESS,
		// .RESIZABLE,
		// .FULLSCREEN,
		// .MAXIMIZED,
	}
	// NOTE: window width and height could be stored in persistent data across restarts.
	ok = sdl.CreateWindowAndRenderer("Elk", i32(window.width), i32(window.height), window_flags, &window.handle, &renderer); assert(ok)

	ok = ttf.Init(); if !ok do panic("Failed to init SDL3_ttf\n")

	// FONT
	font.handle = ttf.OpenFont("/usr/share/fonts/TTF/JetBrainsMono-Regular.ttf", f32(font.size))
	if (font.handle == nil) do error_and_exit()
	defer ttf.CloseFont(font.handle)
	font.height = int(ttf.GetFontLineSkip(font.handle))
	ok = ttf.GetGlyphMetrics(font.handle, ' ', nil, nil, nil, nil, transmute(^i32)&font.width)
	if !ok {
		error_and_exit()
	}

	// NOTE: Do I want to have the file open for the duration of the program or just on open and on save?
	filename := "main.odin"
	file := open_file(filename)
	defer os.close(file)

	file_content := get_file_content(file)
	text_string := expand_tabs(file_content, 4)
	lines := split_string_in_line_structs(text_string)

	// WARNING: This is done for every line whether it fits on screen or not.
	for &line, i in lines {
		// text_surface := ttf.RenderText_Blended_Wrapped(font.handle, strings.unsafe_string_to_cstring(string(line.text[:])), 0, colors.WHITE, i32(window.width - margins.left - margins.right))
		text_surface := ttf.RenderText_Blended(font.handle, strings.unsafe_string_to_cstring(string(line.text[:])), 0, colors.WHITE)
		if (text_surface == nil) {
			continue
		} else {
			line.texture = sdl.CreateTextureFromSurface(renderer, text_surface)
			line.height_in_lines = int(line.texture.h) / font.height
			sdl.DestroySurface(text_surface)
		}
	}

	global_frame_counter: u64 // NOTE: DELETE?
	first_iteration := true // NOTE: For testing purposes.

	///////////
	// FRAME //
	///////////

	for !window.should_close {
		run_events()

		// Update baseline data.
		number_of_lines_that_fit_on_screen := window.height / font.height
		view.line = clamp(view.line, -max_view_lines_above_text, len(lines) - number_of_lines_that_fit_on_screen + max_view_lines_under_text)
		view.column = cs.clamp_min(view.column, -max_view_lines_left_of_text)

		set_line_indeces_and_number_of_lines(&lines) // NOTE: Could be done upon edits instead.

		sdl.GetRenderOutputSize(renderer, transmute(^i32)(&window.width), transmute(^i32)(&window.height))
		sdl.SetWindowSize(window.handle, i32(window.width), i32(window.height)) // WARNING: According to research this seems to perform a system call on every call.

		view.position = { f32(view.column) * f32(font.width), f32(view.line) * f32(font.height) }

		background_color := Color{ 0, 0, 0.3, 1 }
		fill_screen(background_color)
		index_first, index_last := get_indeces_for_lines_in_view(lines)
		render_lines(lines, index_first, index_last)

		if (show_fps_counter) {
			fps_texture_width, fps_texture_height: f32
			sdl.GetTextureSize(fps_texture, &fps_texture_width, &fps_texture_height)
			fps_dst := sdl.FRect {
				x = (f32(window_width) - fps_texture_width),
				y = 0,
				w = fps_texture_width,
				h = fps_texture_height,
			}
			sdl.RenderTexture(renderer, fps_texture, nil, &fps_dst)
		}

		sdl.RenderPresent(renderer)
		first_iteration = false

		// NOTE: WIP
		if (show_fps_counter) {
			render_fps_to_texture :: proc() -> ^sdl.Texture{
				frames_this_second_text : [16]u8
				strconv.itoa(frames_this_second_text[:], frames_this_second)
				fps_surface := ttf.RenderText_Blended(font.handle, strings.unsafe_string_to_cstring(string(frames_this_second_text[:])), 0, colors.YELLOW)
				fps_texture = sdl.CreateTextureFromSurface(renderer, fps_surface)
				return fps_texture
			}

			frames_this_second += 1
			global_frame_counter += 1

			calculate_app_time(&app_time);

			if (lock_framerate) {
				// frame_stabilization
				ensure(frames_this_second > 0)
				one_frame_duration := time.Duration((1 / f64(fps_limit)) * 1_000_000_000) // NOTE: Constant calculation.
				next_frame_target_time := one_frame_duration * time.Duration(global_frame_counter)
				if app_time.ns < next_frame_target_time {
					time.sleep(next_frame_target_time - app_time.ns)
				} else if (app_time.ns >= next_frame_target_time) {
					next_frame_target_time += one_frame_duration
				}
			}

			if (app_time.s >= next_second) {
				if (lock_framerate) {
					missed_seconds := cs.clamp_min(math.floor(app_time.s - next_second), 0)
					fmt.println(app_time.s)
					fmt.printfln("Second %v frames: %v", next_second, frames_this_second)
					next_second += missed_seconds + 1
				}

				render_fps_to_texture()

				frames_this_second = 0
			}
		}
	}

	/////////
	// END //
	/////////

	sdl.Quit()
}

set_line_indeces_and_number_of_lines :: proc(lines: ^[dynamic]Line) {
	i: int
	for ; i < len(lines); i += 1 {
		lines[i].index = i
	}
	number_of_lines = i
	// fmt.println("number_of_lines: ", number_of_lines)
}

calculate_app_time :: proc(app_time: ^App_Time) {
	app_time.ns = time.Duration(sdl.GetTicksNS())
	app_time.ms = f64(app_time.ns) / 1_000_000
	app_time.s = app_time.ms / 1_000
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

run_events :: proc() {
	e: sdl.Event
	for sdl.PollEvent(&e) {
		#partial switch e.type {
		case .QUIT:
			window.should_close = true
		case .KEY_DOWN:
			keycode := sdl.GetKeyFromScancode(e.key.scancode, e.key.mod, false)
			if keycode == 'J' {
				view.line += (window.height / font.height) / 2
				// fmt.println(window.height, font.height, (window.height / font.height) / 2)
			} else if keycode == 'K' {
				view.line -= (window.height / font.height) / 2
				// fmt.println(window.height, font.height, (window.height / font.height) / 2)
			} else if keycode == 'H' {
				view.column -= (window.width / font.width) / 2
			} else if keycode == 'L' {
				view.column += (window.width / font.width) / 2
			} else if e.key.scancode == .ESCAPE || e.key.scancode == .Q {
				window.should_close = true
			} else if e.key.scancode == .J {
				view.line += 1;
			} else if e.key.scancode == .K {
				view.line -= 1;
			} else if e.key.scancode == .H {
				view.column -= 1;
			} else if e.key.scancode == .L {
				view.column += 1;
			} else if e.key.scancode == .D {
				debug_rendering = !debug_rendering
				show_fps_counter = debug_rendering
			} else if e.key.scancode == .F {
				lock_framerate = !lock_framerate
			}
		}
	}
}

// LAST LINE
