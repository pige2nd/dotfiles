local wezterm = require 'wezterm' --[[@as Wezterm]]
local tab_label = require 'tab-label'

local M = {}
local max_tab_label_width = 12

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

  local function format_domain(domain)
    return domain == 'Ubuntu' and 'WSL' or domain
  end

  local function compact_tab_label(label)
    return tab_label.compact(label, max_tab_label_width)
  end

  local function compact_active_directory(tab)
    return tab_label.active_directory(tab, max_tab_label_width)
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
      tab_active = {
        { 'index', padding = 0 },
        compact_active_directory,
        { 'zoomed', padding = 0 },
      },
      tab_inactive = {
        { 'index', padding = 0 },
        { 'process', fmt = compact_tab_label, padding = { left = 1, right = 1 } },
      },
      tabline_x = {},
      tabline_y = {},
      tabline_z = {
        {
          'domain',
          domain_to_icon = { wsl = wezterm.nerdfonts.linux_ubuntu },
          fmt = format_domain,
          padding = { left = 0, right = 1 },
        },
      },
    },
  }
  tabline.apply_to_config(config)

  -- tabline.wez 会改写窗口装饰；两端都恢复系统标题栏与窗口按钮。
  config.window_decorations = 'TITLE | RESIZE'
end

return M
