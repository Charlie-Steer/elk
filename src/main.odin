package main

import "colors"
import u "charlie-utils"

import sdl "vendor:sdl3"
import ttf "vendor:sdl3/ttf"
import wsdl "sdl3_wrapper"
import wttf "sdl3_ttf_wrapper"

import "core:c"
import "core:os"
import "core:fmt"
import "core:strings"
import "core:math"
import "core:time"
import "core:strconv"

window := Window {
	dimensions = {window_width, window_height},
}
renderer: ^sdl.Renderer

font := Font{
	size = font_size,
}
lines: [dynamic]Line
number_of_lines: int

app_time: App_Time;

main :: proc() {
	///////////
	// START //
	///////////

	ok := sdl.SetAppMetadata("Elk", "0.1", "dev.charlie.elk"); assert(ok)
	ok = sdl.Init(sdl.InitFlags{.VIDEO}); assert(ok)
	window_flags := sdl.WindowFlags{
		.BORDERLESS,
		// .RESIZABLE,
		// .FULLSCREEN,
		// .MAXIMIZED,
	}
	// NOTE: window width and height could be stored in persistent data across restarts.
	ok = wsdl.CreateWindowAndRenderer("Elk", window.dimensions.x, window.dimensions.y, window_flags, &window.handle, &renderer); assert(ok)

	ok = ttf.Init(); if !ok do panic("Failed to init SDL3_ttf\n")

	// FONT
	font.handle = ttf.OpenFont("/usr/share/fonts/TTF/JetBrainsMono-Regular.ttf", f32(font.size))
	if (font.handle == nil) do error_and_exit()
	defer ttf.CloseFont(font.handle)
	font.dimensions.y = int(ttf.GetFontLineSkip(font.handle))
	ok = wttf.GetGlyphMetrics(font.handle, ' ', nil, nil, nil, nil, &font.dimensions.x)
	if !ok {
		error_and_exit()
	}

	// NOTE: Do I want to have the file open for the duration of the program or just on open and on save?
	filename := "main.odin"
	file := open_file(filename)
	defer os.close(file)

	file_content := get_file_content(file)
	text_string := expand_tabs(file_content, 4)
	lines = split_string_in_line_structs(text_string)

	// WARNING: This is done for every line whether it fits on screen or not.
	for &line, i in lines {
		text_surface := ttf.RenderText_Blended(font.handle, strings.unsafe_string_to_cstring(string(line.text[:])), 0, colors.WHITE)
		if (text_surface == nil) {
			continue
		} else {
			line.texture = sdl.CreateTextureFromSurface(renderer, text_surface)
			line.height_in_lines = int(line.texture.h) / font.dimensions.y
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
	upkeep_view(&view, cursor)
	cursor.rect.dimensions = {f32(font.dimensions.x), f32(font.dimensions.y)}
	for !window.should_close {
		sdl.RenderClear(renderer)
		run_events()

		frame_start_time := sdl.GetTicksNS()

		// Update state.
		number_of_lines = len(lines)

		upkeep_view(&view, cursor)
		if first_iteration do fmt.println("view.dimensions_in_chars: ", view.cell_rect.dimensions)
		// upkeep_cursor(&cursor, view)

		set_line_indeces_and_number_of_lines(&lines) // NOTE: Could be done upon edits instead.

		// Update window.
		wsdl.GetRenderOutputSize(renderer, &window.dimensions.x, &window.dimensions.y)
		// wsdl.SetWindowSize(window.handle, window.width, window.height) // WARNING: This is INCREDIBLY expensive.

		// Rendering.
		sdl.SetRenderDrawBlendMode(renderer, sdl.BlendMode{})
		background_color := Color{ 0, 0, 0.3, 1 }
		fill_screen(background_color)

		// NOTE: index_first and index_last should probably be a part of the view struct.
		index_first, index_last := get_indeces_for_lines_in_view(lines)

		frame := sdl.FRect{
			w = f32(window.dimensions.x),
			h = f32(window.dimensions.y),
		}
		render_background(frame, index_first, index_last)
		render_lines(frame, lines, index_first, index_last)

		// Cursor.
		render_cursor(&cursor, index_first)

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
			// fmt.println("fps: ", frames_this_second)
			frames_this_second = 0
		}
	}

	/////////
	// END //
	/////////

	sdl.Quit()
}

get_indeces_for_lines_in_view :: proc(lines: [dynamic]Line) -> (start_index, end_index: int) {
	start_index = u.get_clamped_min(view.cell_rect.position.y, 0)
	end_index = u.get_clamped(view.cell_rect.position.y + (window.dimensions.y / font.dimensions.y) - 1, 0, number_of_lines - 1)
	return start_index, end_index
}

set_line_indeces_and_number_of_lines :: proc(lines: ^[dynamic]Line) {
	i: int
	for ; i < len(lines); i += 1 {
		lines[i].index = i
	}
	number_of_lines = i
	// fmt.println("number_of_lines: ", number_of_lines)
}

// LAST LINE
