# On sight:

- Cursor:
    - BUG: max lateral position isn't capped when view to the right.
    - Cap vertical location to first line on screen (take view overshoot into account).
    - Scroll when moving beyond view edge.

- Clean-up types.
- Refactor time stuff into procs.
- Move procs in main to other files.

-----------------------------------------------------

- Editing.

- Rethink margins. Inner margin (within text area) and outside margin?
- Setting right scroll limit relative to the longest line on screen.
- Background right limit.


# Non-pressing:

- Hot reload.
- Line numbers.
- Resizeability.

- SDL3 and SDL3_ttf bindings rework?

# Potential niceties:

- Double buffering
- Single draw call?



# Wishlist:
## Important
- Syntax Highlighting (Treesitter?).
- LSP integration.
    - Go to definition.
    - Suggestions and autocomplete.
    - Renaming.
- Integrated terminal.
- File and function pins.
- Improved comments.
- Line-coloring?
- Info bar:
    - filename.
    - Error number.
- Multiple panels.
- Search and replace.

## Very Much Maybe.
- Function graph view.
- Sessionizer

- Settings menu.
- Variable-width fonts and wrapping.
