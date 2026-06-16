# Elk

A GUI text editor written from scratch in Odin using SDL3.

Elk is a personal project where I wanted to explore building a serious tool from the ground up, and I decided on a text editor. I also wanted to explore the Odin system's programming language, which is a modern alternative to C, and SDL3 which is a low-level windowing, rendering and input management library.

The editor takes inspiration from Vim’s modal editing model while remaining a graphical application with custom UI logic.

Current implementation includes Unicode support, text editing, line manipulation, file loading, and saving to disk.

## Features

* Vim-inspired modal editing
* Custom GUI implementation using SDL3
* Unicode text support
* Text insertion and deletion
* Line editing
* File loading and saving

> **Note:** file loading currently uses a hardcoded path.

## Controls

If you are know Vim, it will feel relatively familiar. If not, it will be just as confusing as Vim.

| Action                | Key                    |
| --------------------- | ---------------------- |
| Move cursor           | `h`, `j`, `k`, `l`     |
| Scroll                | `Shift` + movement key |
| Enter insert mode     | `i`                    |
| Return to normal mode | `Escape`               |
| Save file             | `:`, `w`, `Enter`      |
| Quit                  | `Ctrl + q`             |

Some additional Vim commands are currently supported.

## Running

Requires the Odin compiler.

```sh
odin run src/
```
