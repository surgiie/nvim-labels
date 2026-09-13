
# Regenerate with:
#   nix shell nixpkgs#vhs --command vhs media/demo.tape
# (or: vhs media/demo.tape, if you already have vhs installed)
# Run from the repo root.

Output media/demo.gif

Require nvim

Set Shell "bash"
Set FontSize 20
Set Width 1100
Set Height 700
Set Padding 20
Set TypingSpeed 60ms
Set Theme "MaterialDark"

Hide
Type "nvim --clean -n -u media/demo_init.lua media/demo.js"
Enter
Sleep 500ms
Show

Sleep 800ms

# Jump to the start of `ShoppingCart`.
Type "\j"
Sleep 900ms
Type "f"
Sleep 1000ms

# Jump again, this time into the `Cart` sub-word of the same identifier.
Type "\j"
Sleep 900ms
Type "j"
Sleep 1200ms

# One more jump, further down the file — a 2-key label this time, since
# there are more visible targets than single keys to cover them.
Type "\j"
Sleep 900ms
Type "vo"
Sleep 1300ms

# Character shortcuts: pick one from the floating picker.
Ctrl+\
Sleep 900ms
Type "f"
Sleep 1000ms
Escape

Sleep 800ms
