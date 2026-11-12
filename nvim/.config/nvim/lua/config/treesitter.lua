vim.cmd.packadd("nvim-treesitter")

require("nvim-treesitter.configs").setup({
  ensure_installed = {
    "python", "bash", "dockerfile", "markdown", "markdown_inline",
    "json", "yaml", "toml", "lua",
  },
  auto_install = false,
  highlight = {
    enable = true,
    additional_vim_regex_highlighting = false,
  },
  indent = { enable = false },
})
