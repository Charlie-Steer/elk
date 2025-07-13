package main

import "colors"
import cs "charlie"

import sdl "vendor:sdl3"
import ttf "vendor:sdl3/ttf"
import osdl "sdl3_wrapper"
import ottf "sdl3_ttf_wrapper"

import "core:c"
import "core:os"
import "core:fmt"
import "core:strings"
import "core:math"
import "core:time"
import "core:strconv"

iVec2 :: [2]int
iVec3 :: [3]int
iVec4 :: [4]int
iColor :: iVec4

fVec2 :: [2]f32
fVec3 :: [3]f32
fVec4 :: [4]f32
fColor :: fVec4
Color :: fColor

fRect :: osdl.fRect
iRect :: osdl.iRect

SECOND :: 1_000_000_000

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

Cursor :: struct {
	location: iVec2,
	rect: fRect,
}

cursor: Cursor

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

main :: proc() {
	///////////
	// START //
	///////////

	ok := sdl.SetAppMetadata("Elk", "0.1", "dev.charlie.elk"); assert(ok)
	ok = sdl.Init(sdl.InitFlags{.VIDEO}); assert(ok)
	window_flags := sdl.WindowFlags{
		.BORDERLESS,
		// .RESIZABLE,
		.FULLSCREEN,
		// .MAXIMIZED,
	}
	// NOTE: window width and height could be stored in persistent data across restarts.
	ok = osdl.CreateWindowAndRenderer("Elk", window.width, window.height, window_flags, &window.handle, &renderer); assert(ok)

	ok = ttf.Init(); if !ok do panic("Failed to init SDL3_ttf\n")

	// FONT
	font.handle = ttf.OpenFont("/usr/share/fonts/TTF/JetBrainsMono-Regular.ttf", f32(font.size))
	if (font.handle == nil) do error_and_exit()
	defer ttf.CloseFont(font.handle)
	font.height = int(ttf.GetFontLineSkip(font.handle))
	ok = ottf.GetGlyphMetrics(font.handle, ' ', nil, nil, nil, nil, &font.width)
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

	first_iteration := true // NOTE: For testing purposes.

	///////////
	// FRAME //
	///////////

	frames_this_second: int
	frames_last_second: int
	last_second_time: u64
	fps_texture: ^sdl.Texture
	for !window.should_close {
		sdl.RenderClear(renderer)
		run_events()

		frame_start_time := sdl.GetTicksNS()

		// Update state.
		number_of_lines_that_fit_on_screen := window.height / font.height
		view.line = clamp(view.line, -max_view_lines_above_text, len(lines) - number_of_lines_that_fit_on_screen + max_view_lines_under_text)
		view.column = cs.clamp_min(view.column, -max_view_lines_left_of_text)
		view.position = { f32(view.column) * f32(font.width), f32(view.line) * f32(font.height) }

		set_line_indeces_and_number_of_lines(&lines) // NOTE: Could be done upon edits instead.

		// Update window.
		osdl.GetRenderOutputSize(renderer, &window.width, &window.height)
		// osdl.SetWindowSize(window.handle, window.width, window.height) // WARNING: This is INCREDIBLY expensive.

		// Rendering.
		sdl.SetRenderDrawBlendMode(renderer, sdl.BlendMode{})
		background_color := Color{ 0, 0, 0.3, 1 }
		fill_screen(background_color)
		index_first, index_last := get_indeces_for_lines_in_view(lines)
		render_lines(lines, index_first, index_last)

		// Cursor.
		update_and_render_cursor :: proc(cursor: ^Cursor) {
			cursor_location := [2]f32{f32(cursor.location.x), f32(cursor.location.y)}
			font_dimensions := [2]f32{f32(font.width), f32(font.height)}
			cursor.rect = fRect {
				position = cursor_location * font_dimensions,
				dimensions = {f32(font.width), f32(font.height)}
			}
			// sdl.SetRenderDrawColor(renderer, 255, 255, 255, 160)
			osdl.SetRenderDrawColorFloat(renderer, {1, 1, 1, 0.65})
			sdl.SetRenderDrawBlendMode(renderer, sdl.BlendMode{.BLEND})
			osdl.RenderFillRect(renderer, cursor.rect)
		}
		update_and_render_cursor(&cursor)

		if (show_fps_counter) do draw_fps_counter(renderer, fps_texture)

		sdl.RenderPresent(renderer)
		first_iteration = false


		// Time end.

		frame_end_time := sdl.GetTicksNS()
		if (lock_framerate) {
			alloted_frame_time := u64(1_000_000_000 / target_fps)
			excedent_frame_time := (frame_start_time + alloted_frame_time) - frame_end_time
			if (excedent_frame_time > 0) {
				time.sleep(time.Duration(excedent_frame_time))
			}
		}
		frames_this_second += 1

		frame_end_time = sdl.GetTicksNS()
		if (frame_end_time - last_second_time > SECOND) {
			if show_fps_counter {
				fps_char_buf: [16]u8
				fps_surface := ttf.RenderText_Blended(font.handle, strings.unsafe_string_to_cstring(strconv.itoa(fps_char_buf[:], frames_this_second)), 0, colors.YELLOW)
				fps_texture = sdl.CreateTextureFromSurface(renderer, fps_surface)
			}
			last_second_time = frame_end_time
			fmt.println("fps: ", frames_this_second)
			frames_this_second = 0
		}
	}

	/////////
	// END //
	/////////

	sdl.Quit()
}

draw_fps_counter :: proc(renderer: ^sdl.Renderer, fps_texture: ^sdl.Texture) {
	src, dst: osdl.fRect

	src.dimensions, _ = osdl.GetTextureSize(fps_texture)

	dst.dimensions = src.dimensions
	dst.position.x = f32(window.width) - src.dimensions.x

	osdl.RenderTexture(renderer, fps_texture, &src, &dst)
}

set_line_indeces_and_number_of_lines :: proc(lines: ^[dynamic]Line) {
	i: int
	for ; i < len(lines); i += 1 {
		lines[i].index = i
	}
	number_of_lines = i
	// fmt.println("number_of_lines: ", number_of_lines)
}

calculate_app_time :: proc() -> App_Time {
	app_time := App_Time {
		ns = time.Duration(sdl.GetTicksNS()),
		ms = f64(app_time.ns) / 1_000_000,
		s = app_time.ms / 1_000,
	}
	return app_time
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
			if keycode == 'H' {
				view.column -= (window.width / font.width) / 2
			} else if keycode == 'J' {
				view.line += (window.height / font.height) / 2
				// fmt.println(window.height, font.height, (window.height / font.height) / 2)
			} else if keycode == 'K' {
				view.line -= (window.height / font.height) / 2
				// fmt.println(window.height, font.height, (window.height / font.height) / 2)
			} else if keycode == 'L' {
				view.column += (window.width / font.width) / 2
			} else if e.key.scancode == .ESCAPE || e.key.scancode == .Q {
				window.should_close = true
			} else if e.key.scancode == .H && e.key.mod == sdl.KMOD_NONE {
				cursor.location.x -= 1
			} else if e.key.scancode == .J && e.key.mod == sdl.KMOD_NONE {
				cursor.location.y += 1
			} else if e.key.scancode == .K && e.key.mod == sdl.KMOD_NONE {
				cursor.location.y -= 1
			} else if e.key.scancode == .L && e.key.mod == sdl.KMOD_NONE {
				cursor.location.x += 1
			} else if e.key.scancode == .H && e.key.mod & sdl.KMOD_ALT != sdl.KMOD_NONE {
				view.column -= 1;
			} else if e.key.scancode == .J && e.key.mod & sdl.KMOD_ALT != sdl.KMOD_NONE {
				view.line += 1;
			} else if e.key.scancode == .K && e.key.mod & sdl.KMOD_ALT != sdl.KMOD_NONE {
				view.line -= 1;
			} else if e.key.scancode == .L && e.key.mod & sdl.KMOD_ALT != sdl.KMOD_NONE {
				view.column += 1;
			} else if e.key.scancode == .D {
				debug_rendering = !debug_rendering
			} else if (e.key.scancode == .F) && (e.key.mod & sdl.KMOD_SHIFT != sdl.KMOD_NONE) {
				lock_framerate = !lock_framerate
			} else if (e.key.scancode == .F && e.key.mod == sdl.KMOD_NONE) {
				show_fps_counter = !show_fps_counter
			}
		}
	}
}

// LAST LINE
