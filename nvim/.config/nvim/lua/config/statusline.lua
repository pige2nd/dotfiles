-- 深蓝灰底；不同模式使用独立的圆角色块。
vim.cmd.packadd("heirline.nvim")
local utils = require("heirline.utils")
local conditions = require("heirline.conditions")

local colors = {
  fg = "#dce3ed", bg = "#242832", muted = "#8895a8",
  inactive = "#1a1e26", mode_fg = "#161b25", scroll_bg = "#465269",
  blue = "#7db4ff", green = "#9ed49f", yellow = "#e8c27d",
  red = "#f28b94", purple = "#c4a0ed", mint = "#7bd9c8",
}

local icons = {
  python = "", dockerfile = "", markdown = "", lua = "",
  sh = "", bash = "", zsh = "", json = "", jsonc = "",
  yaml = "", toml = "", conf = "", dosini = "",
}
local scroll = { "▔", "▀", "▄", "▂", "▁" }

local modes = {
  n = { "NORMAL", "blue" }, i = { "INSERT", "mint" },
  v = { "VISUAL", "purple" }, V = { "VISUAL LINE", "purple" },
  ["\22"] = { "VISUAL BLOCK", "purple" }, R = { "REPLACE", "red" },
  c = { "COMMAND", "yellow" }, s = { "SELECT", "purple" },
  S = { "SELECT LINE", "purple" }, ["\19"] = { "SELECT BLOCK", "purple" },
  t = { "TERMINAL", "green" },
}

local function escape(text)
  return (text:gsub("%%", "%%%%"))
end

require("heirline").setup({
  opts = { colors = colors },
  statusline = {
    init = function(self)
      self.active = conditions.is_active()
      self.width = vim.api.nvim_win_get_width(0)
      self.mode = modes[vim.fn.mode(1):sub(1, 1)] or { "NORMAL", "blue" }
      local name = vim.api.nvim_buf_get_name(0)
      local path = vim.fn.fnamemodify(name, ":~:.")
      self.in_cwd = vim.fn.fnamemodify(name, ":."):sub(1, 1) ~= "/"
      self.directory = vim.fn.fnamemodify(path, ":h")
      self.filename = name == "" and "[No Name]" or vim.fn.fnamemodify(path, ":t")
    end,
    hl = function(self)
      return { fg = self.active and "fg" or "muted", bg = self.active and "bg" or "inactive", bold = false }
    end,
    {
      condition = function(self) return self.active end,
      utils.surround({ "", "" }, function(self) return self.mode[2] end, {
        provider = function(self) return " " .. self.mode[1] .. " " end,
        hl = { fg = "mode_fg", bold = true },
      }),
      { provider = " " },
    },
    {
      condition = function(self) return self.width >= 50 end,
      provider = function() return (icons[vim.bo.filetype] or "") .. " " end,
      hl = function(self) return { fg = self.active and "blue" or "muted" } end,
    },
    { provider = "%< " },
    {
      condition = function(self) return self.width >= 100 and self.in_cwd end,
      provider = function() return escape(vim.fn.fnamemodify(vim.fn.getcwd(), ":~")) .. "/" end,
      hl = { fg = "muted" },
    },
    {
      condition = function(self) return self.width >= 65 and self.directory ~= "." end,
      provider = function(self) return escape(self.directory) .. "/" end,
      hl = function(self) return { fg = self.active and "green" or "muted" } end,
    },
    {
      provider = function(self) return escape(self.filename) end,
      hl = function(self) return { fg = self.active and "fg" or "muted" } end,
    },
    { provider = "%m%r ", hl = { fg = "yellow" } },
    { provider = "%=" },
    {
      condition = function(self) return self.width >= 70 end,
      provider = function() return vim.bo.filetype .. "  " end,
      hl = function(self) return { fg = self.active and "blue" or "muted" } end,
    },
    {
      provider = function(self) return self.width >= 85 and "%l:%L  %c " or "%l:%c " end,
    },
    {
      condition = function(self) return self.active and self.width >= 85 end,
      provider = function()
        local fraction = (vim.fn.line(".") - 1) / math.max(vim.fn.line("$") - 1, 1)
        return scroll[math.floor(fraction * (#scroll - 1)) + 1]
      end,
      hl = { fg = "fg", bg = "scroll_bg" },
    },
    {
      condition = function(self) return self.width >= 85 end,
      provider = " %p%% ",
    },
  },
})

local group = vim.api.nvim_create_augroup("PersonalStatusline", { clear = true })
vim.api.nvim_create_autocmd("ModeChanged", {
  group = group,
  callback = function() vim.cmd.redrawstatus() end,
})
vim.api.nvim_create_autocmd("ColorScheme", {
  group = group,
  callback = function() utils.on_colorscheme(colors) end,
})
