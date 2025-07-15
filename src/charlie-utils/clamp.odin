package charlie_utils

clamp :: proc(value: ^$T, min, max: T) {
	if value^ < min do value^ = min
	if value^ > max do value^ = max
}

clamp_min :: proc(value: ^$T, min: T) {
	if value^ < min do value^ = min
}

clamp_max :: proc(value: ^$T, max: T) {
	if value^ > max do value^ = max
}


clamp_array :: proc(arr: ^[$N]$T, min, max: [N]T) {
	for &val, i in arr {
		val = (val < min[i] ? min[i] : val)
		val = (val > max[i] ? max[i] : val)
	}
}

clamp_array_min :: proc(arr: ^[$N]$T, min: [N]T) {
	for &val, i in arr {
		val = (val < min[i] ? min[i] : val)
	}
}

clamp_array_max :: proc(arr: ^[$N]$T, max: [N]T) {
	for &val, i in arr {
		val = (val < max[i] ? max[i] : val)
	}
}


get_clamped :: proc(value: $T, min, max: T) -> (clamped_value: T) {
	if value < min do clamped_value = min
	else if value > max do clamped_value = max
	else do clamped_value = value
	return clamped_value
}

get_clamped_min :: proc(value: $T, min: T) -> (clamped_value: T) {
	if value < min do clamped_value = min
	else do clamped_value = value
	return clamped_value
}

get_clamped_max :: proc(value: $T, max: T) -> (clamped_value: T) {
	if value > max do clamped_value = max
	else do clamped_value = value
	return clamped_value
}


get_clamped_array :: proc(array: [$N]$T, min, max: [N]T) -> (clamped_array: [N]T) {
	clamped_array = array
	for &val, i in clamped_array {
		val = (val < min[i] ? min[i] : val)
		val = (val > max[i] ? max[i] : val)
	}
	return clamped_array
}

get_clamped_array_min :: proc(arr: [$N]$T, min: [N]T) -> (clamped_array: [N]T) {
	clamped_array = array
	for &val, i in clamped_array {
		val = (val < min[i] ? min[i] : val)
	}
	return clamped_array
}

get_clamped_array_max :: proc(arr: [$N]$T, max: [N]T) -> (clamped_array: [N]T) {
	clamped_array = array
	for &val, i in clamped_array {
		val = (val < max[i] ? max[i] : val)
	}
	return clamped_array
}
