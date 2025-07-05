package charlie

clamp_min :: proc(value: $T, min: T) -> T {
	if value < min do return min
	else do return value
}

clamp_max :: proc(value: $T, max: T) -> T {
	if value > max do return max
	else do return value
}
