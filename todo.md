# Scratchpad
Saving edits:
- Replacing spaces with tabs depending on configuration.
- Assembling lines into single buffer with newlines.
- Replacing file's content with buffer's content.

# On sight:

- BUG: insert on first character of line works incorrectly.

- Rework text rendering into SDL Text Object system. Unsure if I can call render per word or line.

- Refactor Rects into vectors (probably).

- Refactor time stuff into procs.
- Move procs in main to other files.

- BUG: Make half-page jumps work.

- NOTE: There are some subtle bugs with multi-column graphemes.


# Non-pressing:

- Hot reload.
- Line numbers.
- Resizeability.

- (Cursor) Jump tabs by tabstop increments (careful not to do so with spaces).
- Rethink margins. Inner margin (within text area) and outside margin?
- Setting right scroll limit relative to the longest line on screen.
- Background right limit.

- Double buffering
- Single draw call?

- Create UI library?

- Rethink Input config system.

- Frame drops printing.


# Wishlist:
- Emoji support / font fallback / font-atlas-based rendering.
- Syntax Highlighting (Treesitter?).

- LSP integration.
    - Go to definition.
    - Suggestions and autocomplete.
    - Renaming.

- Search and replace.

- File, function and section pins and traversal.

- Different cursor-view model (view follows cursor but cursor doesn't follow view.)
- Togglelable character/word/WORD/line/view cursor?

- Better comments.
- Info bar:
    - filename.
    - Error number.

- Multiple panels.

- Performance profiler.

- On command Line-coloring?


## Very Much Maybe.
- Function graph view.
- Sessionizer

- Integrated terminal.

- Settings menu.
- Variable-width fonts and wrapping.
