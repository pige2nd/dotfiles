vim.cmd.packadd("tokyonight.nvim")
require("tokyonight").setup({
  style = "moon",
  terminal_colors = false,
  plugins = { all = false, auto = false },
  on_colors = function(colors)
    colors.bg = "#000000"
  end,
  on_highlights = function(highlights)
    highlights.LineNr.fg = "#9aa8c7"
    highlights.LineNrAbove = { fg = "#9aa8c7" }
    highlights.LineNrBelow = { fg = "#9aa8c7" }
  end,
})
vim.cmd.colorscheme("tokyonight-moon")
