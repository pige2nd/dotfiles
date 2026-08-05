-- Pull in the wezterm API
local wezterm = require 'wezterm' --[[@as Wezterm]]
local is_windows = wezterm.target_triple:find("windows") ~= nil

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

if is_windows then
  -- Windows WezTerm 默认从 CMD 进入；需要 Linux 时再打开 WSL。
  config.default_prog = { "cmd.exe" }

  -- 无论从哪个 Windows 目录选择 WSL，都从 Linux 用户主目录开始。
  local wsl_domains = wezterm.default_wsl_domains()
  for _, domain in ipairs(wsl_domains) do
    domain.default_cwd = "~"
  end
  config.wsl_domains = wsl_domains
else
  -- Ubuntu 笔记本继续使用原来的 zsh。
  config.default_prog = { "/usr/bin/zsh", "-l" }

  -- 仅 Linux 需要处理 Wayland/XWayland。
  config.enable_wayland = false
end
-- 不使用 WezTerm 自己的版本更新弹窗
config.check_for_updates = false

-- 保持兼容性较好的 TERM
config.term = 'xterm-256color'

-- =========================================================
-- 字体
-- =========================================================

-- Windows 使用 SF Mono；Ubuntu 保持原字体。
local primary_font =
  is_windows and "SF Mono" or "JetBrainsMono Nerd Font"

-- Windows 当前已有微软雅黑；Ubuntu 使用 Noto CJK。
local cjk_font =
  is_windows and "Microsoft YaHei UI" or "Noto Sans Mono CJK SC"

config.font = wezterm.font_with_fallback {
  { family = primary_font, weight = "Regular" },
  cjk_font,
  "Noto Color Emoji",
}

config.font_size = 12.5
config.line_height = 1.08

-- 禁用连字。
config.harfbuzz_features = {
  "calt=0",
  "clig=0",
  "liga=0",
}

-- 两个平台分别使用各自主字体的真实字重。
config.font_rules = {
  {
    intensity = "Bold",
    italic = false,
    font = wezterm.font_with_fallback {
      { family = primary_font, weight = "DemiBold" },
      cjk_font,
    },
  },
  {
    intensity = "Normal",
    italic = true,
    font = wezterm.font_with_fallback {
      {
        family = primary_font,
        weight = "Regular",
        style = "Italic",
      },
      cjk_font,
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

-- 点击系统关闭按钮时直接退出，不再显示确认框。
config.window_close_confirmation = 'NeverPrompt'

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
