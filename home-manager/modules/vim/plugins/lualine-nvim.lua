-- the status line will display the mode.
vim.opt.showmode = false

local lualine = require("lualine")
lualine.setup({
	options = {
		theme = "gruvbox",
	},
	sections = {
		lualine_b = { "diff" },
		lualine_c = { { "filename", path = 1 } },
		lualine_z = { "location", { "diagnostics", color = { bg = "#3c3836" } } },
	},
})
