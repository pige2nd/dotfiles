-- 复用现有 tmux 脚本，保持中文编码和 Windows 剪贴板行为一致。
local scripts = vim.env.HOME .. "/dotfiles/tmux/scripts/"
vim.g.clipboard = {
  name = "WSL Windows clipboard",
  copy = {
    ["+"] = { scripts .. "clipboard-copy" },
    ["*"] = { scripts .. "clipboard-copy" },
  },
  paste = {
    ["+"] = { scripts .. "clipboard-paste" },
    ["*"] = { scripts .. "clipboard-paste" },
  },
  cache_enabled = 0,
}

-- 普通 y/d/p 使用 Vim 寄存器；带空格前缀时使用 Windows 剪贴板。
vim.keymap.set({ "n", "x" }, "<leader>y", '"+y', { desc = "Copy to Windows clipboard" })
vim.keymap.set("n", "<leader>Y", '"+yy', { desc = "Copy line to Windows clipboard" })
vim.keymap.set("n", "<leader>p", '"+p', { desc = "Paste Windows clipboard after cursor" })
vim.keymap.set("n", "<leader>P", '"+P', { desc = "Paste Windows clipboard before cursor" })
