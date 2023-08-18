function ColorMySlate(color)
	color = color or "tokyonight-night"
  -- vim.o.background = "dark"
	vim.cmd.colorscheme(color)

	vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
	vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
end

ColorMySlate()
