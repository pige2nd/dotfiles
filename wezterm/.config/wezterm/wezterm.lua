-- Pull in the wezterm API
local wezterm = require 'wezterm' --[[@as Wezterm]]

-- This table will hold the configuration.
local config = {}

-- In newer versions of wezterm, use the config_builder which will
-- help provide clearer error messages
if wezterm.config_builder then
  config = wezterm.config_builder()
end

-- =========================================================
-- 基础
-- =========================================================

-- 配置文件修改后自动重载
config.automatically_reload_config = true

-- 设置zsh
config.default_prog = { '/usr/bin/zsh', '-l'}
-- 使用 XWayland，让 GNOME 提供独立的标题栏和最小化/最大化/关闭按钮。
-- 原生 Wayland 下，当前桌面环境不会为 TITLE | RESIZE 绘制这组按钮。
config.enable_wayland = false

-- 不使用 WezTerm 自己的版本更新弹窗
config.check_for_updates = false

-- 保持兼容性较好的 TERM
config.term = 'xterm-256color'

-- =========================================================
-- 字体
-- =========================================================

config.font = wezterm.font_with_fallback {
  { family = 'JetBrainsMono Nerd Font', weight = 'Regular' },
  'Noto Sans Mono CJK SC',
  'Noto Color Emoji',
}

config.font_size = 12.5

-- 字体行高
config.line_height = 1.08

-- 禁用连字
config.harfbuzz_features = { 'calt=0', 'clig=0', 'liga=0' }

-- 避免粗体过粗
config.font_rules = {
  {
    intensity = 'Bold',
    italic = false,
    font = wezterm.font_with_fallback {
      { family = 'JetBrainsMono Nerd Font', weight = 'DemiBold' },
      'Noto Sans Mono CJK SC',
    },
  },
  {
    intensity = 'Normal',
    italic = true,
    font = wezterm.font_with_fallback {
      { family = 'JetBrainsMono Nerd Font', weight = 'Regular', style = 'Italic' },
      'Noto Sans Mono CJK SC',
    },
  },
}

-- =========================================================
-- 窗口
-- =========================================================

config.initial_cols = 120
config.initial_rows = 34

config.window_padding = {
  left = 10,
  right = 10,
  top = 8,
  bottom = 8,
}

-- 使用桌面环境自己的独立标题栏和窗口按钮。
config.window_decorations = 'TITLE | RESIZE'

-- 关闭窗口时确认，避免误关掉整组标签页
config.window_close_confirmation = 'AlwaysPrompt'

-- 标签 / pane 关闭时也始终确认；默认情况下 bash、zsh、tmux 等进程会跳过确认。
config.skip_close_confirmation_for_processes_named = {}

-- 滚动历史
config.scrollback_lines = 10000

-- 隐藏滚动条
config.enable_scroll_bar = false

-- 输入时隐藏鼠标
config.hide_mouse_cursor_when_typing = true

-- 窗口背景透明度
config.window_background_opacity = 1.0

-- =========================================================
-- 标签栏
-- =========================================================

config.enable_tab_bar = true

-- 导航栏始终显示，即使当前只有一个标签
config.hide_tab_bar_if_only_one_tab = false

-- =========================================================
-- 光标与选择
-- =========================================================

config.default_cursor_style = 'BlinkingBar'
config.cursor_blink_rate = 600

config.selection_word_boundary =
  " \t\n{}[]()\"'`,;:@│┃|"

-- =========================================================
-- 模块
-- =========================================================

require('colors').apply(config)
require('mappings').apply(config)
require('tab').apply(config)
require('command_palette').apply()
-- require('plugins').apply(config)


return config
