package charlie_utils

import sdl "vendor:sdl3"
import wsdl "../sdl3_wrapper/"

iVec2 :: [2]int
iVec3 :: [3]int
iVec4 :: [4]int
iColor :: iVec4

fVec2 :: [2]f32
fVec3 :: [3]f32
fVec4 :: [4]f32
fColor :: fVec4
Color :: fColor

fRect :: wsdl.fRect
iRect :: wsdl.iRect

custom_context :: struct {
	renderer: ^sdl.Renderer,
}

draw_rectangle :: proc(position, dimensions: fVec2, color: Color) {
	renderer := (^custom_context)(context.user_ptr).renderer
	sdl.SetRenderDrawColorFloat(renderer, color.x, color.y, color.z, color.w)
	rect := sdl.FRect{ position.x, position.y, dimensions.x, dimensions.y }
	sdl.RenderFillRect(renderer, &rect)
}
