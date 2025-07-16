package charlie_utils

fVec :: proc(i_vector: [$N]int) -> (f_vector: [N]f32) {
	for val, i in i_vector {
		f_vector[i] = f32(i_vector[i])
	}
	return f_vector
}

iVec :: proc(f_vector: [$N]int) -> (i_vector: [N]f32) {
	for val, i in f_vector {
		i_vector[i] = int(f_vector[i])
	}
	return i_vector
}
