vim.g.mapleader = " "

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.cursorline = true
vim.opt.scrolloff = 6
vim.opt.sidescrolloff = 6
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.hlsearch = true
vim.opt.incsearch = true
vim.opt.expandtab = true
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
vim.opt.softtabstop = -1
vim.opt.wrap = false
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.termguicolors = true
vim.opt.laststatus = 2
vim.opt.showmode = false

-- 退出再打开文件后，仍能使用撤销历史。
vim.fn.mkdir(vim.fn.stdpath("state") .. "/undo", "p")
vim.opt.undofile = true

local group = vim.api.nvim_create_augroup("PersonalEditing", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
  group = group,
  pattern = { "python", "sh", "bash", "zsh", "dockerfile", "markdown", "json", "jsonc", "yaml", "toml", "lua" },
  callback = function(event)
    local width = vim.bo[event.buf].filetype == "python" and 4 or 2
    vim.bo[event.buf].expandtab = true
    vim.bo[event.buf].shiftwidth = width
    vim.bo[event.buf].tabstop = width
  end,
})
vim.api.nvim_create_autocmd("FileType", {
  group = group,
  pattern = "markdown",
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.linebreak = true
    vim.opt_local.breakindent = true
  end,
})

vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })
