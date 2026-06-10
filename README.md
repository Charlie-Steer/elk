A text editor made from scratch. I wanted to try my hand at making a serious tool, and being a programmer, I decided on a text editor. It's inspired by Vim in the sense that the modal editing model is pretty much the same as it stands, but it is a GUI application, built in the systems programming language Odin and the SDL3 library.

It uses custom UI logic and I implemented Unicode support.

It allows to load a file (path currently hardcoded), edit it, as in adding or removing text and lines, and you can save the edited textfile to disk.

If you are know how to use Vim it will feel relatively familiar. If not it will be just as confusing as Vim.

## Controls

* Move cursor: `h`, `j`, `k`, `l`
* Scroll: `Shift` + movement key
* Enter insert mode: `i`
* Return to normal mode: `Escape`
* Save file: `:w` + `Enter`
* Quit: `Ctrl + q`

Some other Vim commands are currently supported.

# Running:
Requires Odin compiler.

```
Odin run src/
```
