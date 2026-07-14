local wezterm = require 'wezterm' --[[@as Wezterm]]

local M = {}

function M.apply(config)
  -- Catppuccin Mocha 内置主题
  config.color_scheme = 'Catppuccin Mocha'
end

return M
