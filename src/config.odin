package main

window_width := 640
window_height := 480

font_size : f32 = 15

margins := Margins{ 0, 0, 9, 0 }
// margins := Margins{ 0, 0, 0, 0 }

max_view_lines_above_text, max_view_lines_under_text := 1, 2
max_view_lines_left_of_text, max_view_lines_right_of_text := 0, 1

debug_rendering := false

show_fps_counter := true
lock_framerate := false
target_fps := 60

maximized := true
