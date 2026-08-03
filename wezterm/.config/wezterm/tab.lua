local wezterm = require 'wezterm' --[[@as Wezterm]]

local M = {}

function M.apply(config)
  local tabline = wezterm.plugin.require 'https://github.com/michaelbrusegard/tabline.wez'

  local mode_symbols = {
    NORMAL = '',
    COPY = '',
    SEARCH = '',
  }

  local function format_mode(mode)
    return (mode_symbols[mode] or '•') .. ' ' .. mode
  end

  -- 右侧只保留当前 domain（本机会显示 local）。
  tabline.setup {
    options = {
      theme_overrides = {
        normal_mode = {
          x = { fg = '#cdd6f4', bg = '#1e1e2e' },
          y = { fg = '#cdd6f4', bg = '#313244' },
          z = { fg = '#1e1e2e', bg = '#89b4fa' },
        },
        copy_mode = {
          x = { fg = '#cdd6f4', bg = '#1e1e2e' },
          y = { fg = '#cdd6f4', bg = '#313244' },
          z = { fg = '#1e1e2e', bg = '#89b4fa' },
        },
        search_mode = {
          x = { fg = '#cdd6f4', bg = '#1e1e2e' },
          y = { fg = '#cdd6f4', bg = '#313244' },
          z = { fg = '#1e1e2e', bg = '#89b4fa' },
        },
      },
      section_separators = {
        left = wezterm.nerdfonts.ple_right_half_circle_thick,
        right = wezterm.nerdfonts.ple_left_half_circle_thick,
      },
      component_separators = {
        left = wezterm.nerdfonts.ple_right_half_circle_thin,
        right = '',
      },
      tab_separators = {
        left = wezterm.nerdfonts.ple_right_half_circle_thick,
        right = wezterm.nerdfonts.ple_left_half_circle_thick,
      },
    },
    sections = {
      tabline_a = { { 'mode', fmt = format_mode, padding = { left = 1, right = 0 } } },
      tabline_b = {},
      tabline_x = {},
      tabline_y = {},
      tabline_z = { { 'domain', padding = { left = 0, right = 1 } } },
    },
  }
  tabline.apply_to_config(config)
end

return M
