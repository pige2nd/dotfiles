local wezterm = require 'wezterm' --[[@as Wezterm]]

local M = {}

function M.apply(config)
  local tabline = wezterm.plugin.require 'https://github.com/michaelbrusegard/tabline.wez'
  local cpu_component = require 'tabline.components.window.cpu'

  -- 显示已使用内存百分比，避免修改 tabline 插件缓存中的 ram 组件。
  local memory_last_update = 0
  local memory_last_result = ''
  local function memory_percent()
    local now = os.time()
    if now - memory_last_update < 3 then
      return memory_last_result
    end

    local file = io.open('/proc/meminfo', 'r')
    if not file then
      return memory_last_result
    end

    local total, available
    for line in file:lines() do
      local key, value = line:match('^(%w+):%s+(%d+)')
      if key == 'MemTotal' then
        total = tonumber(value)
      elseif key == 'MemAvailable' then
        available = tonumber(value)
      end
    end
    file:close()

    if total and available and total > 0 then
      memory_last_result = string.format('%s %.0f%%', wezterm.nerdfonts.cod_server, (total - available) / total * 100)
      memory_last_update = now
    end

    return memory_last_result
  end

  -- 将内存和 CPU 合并为一个组件，避免两者之间被自动插入分隔符。
  local function memory_cpu(window)
    local cpu = cpu_component.update(window, cpu_component.default_opts)
    return memory_percent() .. ' ' .. wezterm.nerdfonts.oct_cpu .. ' ' .. cpu .. ' '
  end

  -- 只提供右侧资源区前面的底色，不输出文字。
  local function resource_lead()
    return ''
  end

  local mode_symbols = {
    NORMAL = '',
    COPY = '',
    SEARCH = '',
  }

  local function format_mode(mode)
    return (mode_symbols[mode] or '•') .. ' ' .. mode
  end

  -- 基于官方默认配置，仅隐藏 workspace 模块，避免显示无意义的 "default"。
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
      tabline_x = { resource_lead },
      tabline_y = { memory_cpu },
      tabline_z = { { 'domain', padding = { left = 0, right = 1 } } },
    },
  }
  tabline.apply_to_config(config)
end

return M
