package main

import "core:os"
import "core:fmt"
import "core:strings"
import "vendor:sdl3"
import "core:math"
import sdl "vendor:sdl3"

// ok: bool = true

window: ^sdl.Window
renderer: ^sdl.Renderer

main :: proc() {
	// init_program()
	ok := sdl.SetAppMetadata("Elk", "0.1", "com.elk.charlie"); assert(ok)
	ok = sdl.Init({.VIDEO}); assert(ok)
	ok = sdl.CreateWindowAndRenderer("Elk", 640, 480, {}, &window, &renderer); assert(ok)

	color_offset: u8
	main_loop: for {
		event: sdl.Event
		for sdl.PollEvent(&event) {
			#partial switch event.type {
			case .QUIT:
				break main_loop
			case .KEY_DOWN:
				if event.key.scancode == .ESCAPE do break main_loop
				else if event.key.scancode == .W do color_offset += 100
			}
		}

		time := f32(sdl.GetTicks()) / 1000
		fmt.println(time)
		value_a := u8(math.remap(math.sin(time), -1, 1, 0, 255))
		value_b := u8(math.remap(math.cos(time), -1, 1, 0, 255))

		sdl.SetRenderDrawColor(renderer, value_a, color_offset, value_b, 0)
		sdl.RenderClear(renderer)
		sdl.RenderPresent(renderer)
	}

	sdl.Quit()
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
