package main

import "core:time"
import "core:os"
import sdl "vendor:sdl3"
import wsdl "sdl3_wrapper"

calculate_app_time :: proc() -> App_Time {
	app_time := App_Time {
		ns = time.Duration(sdl.GetTicksNS()),
		ms = f64(app_time.ns) / 1_000_000,
		s = app_time.ms / 1_000,
	}
	return app_time
}

draw_fps_counter :: proc(renderer: ^sdl.Renderer, fps_texture: ^sdl.Texture) {
	src, dst: wsdl.fRect

	src.dimensions, _ = wsdl.GetTextureSize(fps_texture)

	dst.dimensions = src.dimensions
	dst.position.x = f32(window.dimensions.x) - src.dimensions.x

	wsdl.RenderTexture(renderer, fps_texture, &src, &dst)
}

error_and_exit :: proc(category := sdl.LogCategory.APPLICATION) {
	sdl.LogError(i32(category), sdl.GetError())
	os.exit(1);
}
