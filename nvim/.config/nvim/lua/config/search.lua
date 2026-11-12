vim.cmd.packadd("fzf-lua")
local fzf = require("fzf-lua")

fzf.setup({
  winopts = { border = "rounded" },
  keymap = {
    fzf = { ["ctrl-p"] = "up", ["ctrl-n"] = "down", ["esc"] = "abort" },
  },
  files = { file_icons = false, hidden = true },
  grep = {
    file_icons = false,
    rg_opts = "--column --line-number --no-heading --color=always --smart-case --hidden --glob '!.git' --max-columns=4096 -e",
  },
})

-- 优先使用当前文件所在的 Git 项目；普通目录使用 Neovim 的 cwd。
local function search_root()
  local file = vim.api.nvim_buf_get_name(0)
  return vim.fs.root(file ~= "" and file or vim.fn.getcwd(), ".git") or vim.fn.getcwd()
end

vim.keymap.set("n", "<leader>ff", function()
  fzf.files({ cwd = search_root() })
end, { desc = "Find project files" })

vim.keymap.set("n", "<leader>fg", function()
  fzf.live_grep({ cwd = search_root() })
end, { desc = "Search project text" })
