SRC = src/
BIN = elk.bin

all: run

run:
	@odin run $(SRC) -debug

debug:
	@odin build $(SRC) -debug -out:$(BIN) && gdb ./$(BIN)
	@$(MAKE) clean

clean:
	@rm -f $(BIN)

.PHONY: all run debug

# all:
# 	odin run . -- \
# 	  -I/usr/local/include/SDL3_ttf \
# 	  -L/usr/local/lib \
# 	  -lSDL3_ttf -lfreetype -lharfbuzz

