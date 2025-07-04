all:
	odin run . -- \
	  -I/usr/local/include/SDL3_ttf \
	  -L/usr/local/lib \
	  -lSDL3_ttf -lfreetype -lharfbuzz

.PHONY: all
