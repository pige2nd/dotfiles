local map = vim.keymap.set

local function smart_nav(vim_dir, tmux_dir)
  local before = vim.api.nvim_get_current_win()
  vim.cmd.wincmd(vim_dir)

  if before == vim.api.nvim_get_current_win() and vim.env.TMUX then
    vim.fn.system({ "tmux", "select-pane", "-" .. tmux_dir })
  end
end

local opts = { noremap = true, silent = true }

map({ "n", "x", "o" }, "i", "k", vim.tbl_extend("force", opts, { desc = "Move up" }))
map({ "n", "x", "o" }, "j", "h", vim.tbl_extend("force", opts, { desc = "Move left" }))
map({ "n", "x", "o" }, "k", "j", vim.tbl_extend("force", opts, { desc = "Move down" }))

map("n", "h", "i", vim.tbl_extend("force", opts, { desc = "Insert" }))
map({ "x", "o" }, "h", "i", vim.tbl_extend("force", opts, { desc = "Inner text object" }))

map("n", "<M-i>", function() smart_nav("k", "U") end, { silent = true, desc = "Move to upper split/pane" })
map("n", "<M-j>", function() smart_nav("h", "L") end, { silent = true, desc = "Move to left split/pane" })
map("n", "<M-k>", function() smart_nav("j", "D") end, { silent = true, desc = "Move to lower split/pane" })
map("n", "<M-l>", function() smart_nav("l", "R") end, { silent = true, desc = "Move to right split/pane" })
