local wezterm = require 'wezterm' --[[@as Wezterm]]

local M = {}

function M.apply(config)
  local tabs =
    wezterm.plugin.require 'https://github.com/yriveiro/wezterm-tabs'

  -- 插件只在 color_schemes 表中查找主题；把当前 WezTerm 内置主题
  -- 显式注册进去，避免 format-tab-title 在运行时读取到 nil。
  local scheme =
    assert(wezterm.color.get_builtin_schemes()[config.color_scheme])
  config.color_schemes = config.color_schemes or {}
  config.color_schemes[config.color_scheme] = scheme

  tabs.apply_to_config(config, {
    tabs = {
      tab_bar_at_bottom = false,
      hide_tab_bar_if_only_one_tab = false,
      tab_max_width = 24,
      unzoom_on_switch_pane = true,
    },
    ui = {
      tab = {
        -- 不读取 mux pane 状态，只显示静态的索引、图标和标题。
        zoom_indicator = {
          enabled = false,
          type = 'icon',
        },
      },
    },
  })

  config.show_new_tab_button_in_tab_bar = true

  -- 插件仅注册 format-tab-title，没有周期性 update-status；
  -- 两端继续使用系统标题栏与窗口按钮。
  config.window_decorations = 'TITLE | RESIZE'
end

return M
