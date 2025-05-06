package main

import "core:os"
import "core:fmt"
import "core:strings"
import "vendor:sdl3"
import "core:math"
import sdl "vendor:sdl3"
import tt "vendor:stb/truetype"

// ok: bool = true
Vector2 :: [2]f32
Vector3 :: [3]f32
Vector4 :: [4]f32
Color :: Vector4

window: ^sdl.Window
renderer: ^sdl.Renderer

window_dimensions := [2]i32{ 640, 480 }

main :: proc() {
	// init_program
	ok := sdl.SetAppMetadata("Elk", "0.1", "com.elk.charlie"); assert(ok)
	ok = sdl.Init({.VIDEO}); assert(ok)
	ok = sdl.CreateWindowAndRenderer("Elk", window_dimensions.x, window_dimensions.y, {}, &window, &renderer); assert(ok)

	color_offset: f32
	window_should_close := false
	for !window_should_close {
		// handle_events
		e: sdl.Event
		for sdl.PollEvent(&e) {
			#partial switch e.type {
			case .QUIT:
				window_should_close = true
			case .KEY_DOWN:
				if e.key.scancode == .ESCAPE || e.key.scancode == .Q {
					window_should_close = true
				}
				else if e.key.scancode == .W {
					color_offset += 0.1
					if color_offset > 1 {
						color_offset = 0
					}
				}
			}
		}

		// frame_processing
		app_time_ms := f32(sdl.GetTicks())
		app_time_s := f32(sdl.GetTicks()) / 1000
		fmt.println(app_time_ms)
		value_a := math.remap(math.sin(app_time_s), -1, 1, 0, 1)
		value_b := math.remap(math.cos(app_time_s), -1, 1, 0, 1)

		// frame_rendering
		background_color := Color{ 0, color_offset, 0.3, 1 }
		fill_screen(background_color)
		draw_rectangle({f32(window_dimensions.x / 2) - 300 / 2, f32(window_dimensions.y / 2) - 100 / 2},
			{300, 100}, {1, 0, 1, 1})

		// TODO: Render text with stb/truetype.

		sdl.RenderPresent(renderer)
	}

	sdl.Quit()
}

fill_screen :: proc(color: Color) {
	sdl.SetRenderDrawColorFloat(renderer, color.x, color.y, color.z, color.w)
	sdl.RenderClear(renderer)
}

draw_rectangle :: proc(position, dimensions: Vector2, color: Vector4) {
	sdl.SetRenderDrawColorFloat(renderer, color.x, color.y, color.z, color.w)
	rect := sdl.FRect{ position.x, position.y, dimensions.x, dimensions.y }
	sdl.RenderFillRect(renderer, &rect)
}

error_and_exit :: proc(message: string, kind := "ERROR", code: int = 1) {

	strs := [?]string{kind, ": ", message}
	final_str, err := strings.concatenate(strs[:])
	if (err != nil) {
		os.exit(1)
	}

	sdl.Log(strings.unsafe_string_to_cstring(final_str))
	os.exit(code)
}
