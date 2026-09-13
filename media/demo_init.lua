-- Used only by media/demo.tape to record media/demo.gif.
-- tests/minimal_init.lua remains the documented manual-test entrypoint —
-- this just adds a colorscheme (media/colors/material_dark.lua) on top so
-- the recording doesn't render on Neovim's plain default colors.

local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
vim.opt.runtimepath:prepend(root)
vim.opt.runtimepath:append(root .. "/media")

require("nvim-labels").setup({
	char_shortcuts = {
		"(", ")", "[", "]", "{", "}", "<", ">",
		"-", "_", "=", "+", "*", "/", "\\", "|",
	},
})

vim.opt.number = true
vim.opt.termguicolors = true
vim.cmd.colorscheme("material_dark")
