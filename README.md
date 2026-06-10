A text editor made from scratch. I wanted to try my hand at making a serious tool, and being a programmer, I decided on a text editor. It's inspired by Vim in the sense that the modal editing model is pretty much the same as it stands, but it is a GUI application, built in the systems programming language Odin and the SDL3 library. It uses custom UI logic and I implemented Unicode support.

It allows to load a file (path currently hardcoded), edit it, as in adding or removing text and lines and you can save the edited textfile.

If you are know how to use Vim it will feel relatively familiar. If not it will be just as confusing as Vim.

Move cursor with 'h', 'j', 'k' and 'l'. You can scroll with shift plus one of the movement keys. Go into insert mode with 'i' and back to normal mode with 'Escape'. Save with ':' followed by 'w' and 'Enter'. You can exit the application with 'Ctrl' + 'q'. Some other Vim commands are currently supported.

> To run (requires Odin compiler):

```
Odin run src/
```
