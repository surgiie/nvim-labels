-- nvim --clean -u tests/minimal_init.lua <file>
-- Then \j to jump, or <C-\> for character shortcuts.
-- (mapleader is "\" under --clean)

local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
vim.opt.runtimepath:prepend(root)

require("nvim-labels").setup({
  char_shortcuts = {
    "(", ")", "[", "]", "{", "}", "<", ">",
    "-", "_", "=", "+", "*", "/", "\\", "|",
    "&", "^", "%", "$", "#", "@", "!", "~",
    "`", ":", ";", "'", "\"", ",", ".", "?",
  },
})

vim.opt.number = true
vim.opt.termguicolors = true
