-- A small, self-contained dark Material Design palette, used only for
-- recording media/demo.gif (see media/demo_init.lua / media/demo.tape).
-- Not part of the plugin itself — nvim-labels has no colorscheme opinion,
-- this just exists so the demo looks intentional rather than default-grey.

vim.cmd("highlight clear")
if vim.fn.exists("syntax_on") == 1 then
	vim.cmd("syntax reset")
end
vim.o.background = "dark"
vim.g.colors_name = "material_dark"

local c = {
	bg        = "#263238",
	bg_alt    = "#2c393f",
	fg        = "#eeffff",
	comment   = "#546e7a",
	selection = "#314549",
	red       = "#ff5370",
	orange    = "#f78c6c",
	yellow    = "#ffcb6b",
	green     = "#c3e88d",
	cyan      = "#89ddff",
	blue      = "#82aaff",
	purple    = "#c792ea",
	gutter    = "#37474f",
}

local function hl(group, opts)
	vim.api.nvim_set_hl(0, group, opts)
end

hl("Normal", { fg = c.fg, bg = c.bg })
hl("NormalFloat", { fg = c.fg, bg = c.bg_alt })
hl("FloatBorder", { fg = c.gutter, bg = c.bg_alt })
hl("Comment", { fg = c.comment, italic = true })
hl("Constant", { fg = c.orange })
hl("String", { fg = c.green })
hl("Character", { fg = c.green })
hl("Number", { fg = c.orange })
hl("Boolean", { fg = c.orange })
hl("Identifier", { fg = c.fg })
hl("Function", { fg = c.blue })
hl("Statement", { fg = c.purple })
hl("Conditional", { fg = c.purple })
hl("Repeat", { fg = c.purple })
hl("Keyword", { fg = c.purple })
hl("Operator", { fg = c.cyan })
hl("PreProc", { fg = c.purple })
hl("Type", { fg = c.yellow })
hl("StorageClass", { fg = c.purple })
hl("Structure", { fg = c.purple })
hl("Special", { fg = c.cyan })
hl("Delimiter", { fg = c.cyan })
hl("Underlined", { fg = c.blue, underline = true })
hl("Error", { fg = c.red, bold = true })
hl("Todo", { fg = c.yellow, bold = true })

hl("LineNr", { fg = c.gutter })
hl("CursorLineNr", { fg = c.yellow, bold = true })
hl("CursorLine", { bg = c.bg_alt })
hl("Visual", { bg = c.selection })
hl("StatusLine", { fg = c.fg, bg = c.bg_alt })
hl("StatusLineNC", { fg = c.comment, bg = c.bg_alt })
hl("VertSplit", { fg = c.gutter, bg = c.bg })
hl("SignColumn", { bg = c.bg })
hl("NonText", { fg = c.gutter })
hl("EndOfBuffer", { fg = c.bg })
hl("Pmenu", { fg = c.fg, bg = c.bg_alt })
hl("PmenuSel", { fg = c.bg, bg = c.blue })
hl("Search", { fg = c.bg, bg = c.yellow })
hl("IncSearch", { fg = c.bg, bg = c.orange })
hl("MatchParen", { fg = c.orange, bold = true })

-- nvim-labels' own highlights (both `default = true` upstream, so a
-- colorscheme setting them explicitly is exactly the intended override path).
hl("LabelPick", { fg = c.yellow, bg = c.bg, bold = true })
hl("LabelDim", { fg = c.comment })
