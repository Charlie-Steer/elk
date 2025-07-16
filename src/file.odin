package main

import "core:os"
import "core:fmt"

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
