-- Pull in the wezterm API
local wezterm = require 'wezterm' --[[@as Wezterm]]
local is_windows = wezterm.target_triple:find('windows') ~= nil
local is_macos = wezterm.target_triple:find('apple%-darwin') ~= nil

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
  -- Windows 默认进入 CMD；需要 Linux 时再从 Launcher 打开 WSL。
  config.default_prog = { 'cmd.exe' }

  -- 只展示常用入口，避免与 WezTerm 自动生成的 domain 列表重复。
  config.launch_menu = {
    {
      label = 'CMD',
      args = { 'cmd.exe' },
    },
    {
      label = 'PowerShell',
      args = { 'powershell.exe', '-NoLogo' },
    },
    {
      label = 'WSL (Ubuntu)',
      domain = { DomainName = 'WSL:Ubuntu' },
    },
  }

  -- 从 Windows 文件夹打开 WSL 时也始终落到 Linux 用户主目录。
  local wsl_domains = wezterm.default_wsl_domains()
  for _, domain in ipairs(wsl_domains) do
    domain.default_cwd = '~'
  end
  config.wsl_domains = wsl_domains
elseif is_macos then
  config.default_prog = { '/bin/zsh', '-l' }
else
  config.default_prog = { '/usr/bin/zsh', '-l' }

  -- 原生 Wayland 与 niri/DMS 的窗口高度协商会把最后一行画到裁剪区外。
  -- 使用 XWayland 可让终端内容、圆角和焦点边框保持在同一窗口几何内。
  config.enable_wayland = false
end

-- 不使用 WezTerm 自己的版本更新弹窗
config.check_for_updates = false

-- 保持兼容性较好的 TERM
config.term = 'xterm-256color'

-- =========================================================
-- 字体
-- =========================================================

local primary_font = 'SF Mono'
local cjk_font = 'Noto Sans Mono CJK SC'
local emoji_font = 'Noto Color Emoji'
if is_windows then
  cjk_font = 'PingFang SC'
  emoji_font = 'Segoe UI Emoji'
elseif is_macos then
  config.font_dirs = { wezterm.home_dir .. '/Library/Fonts' }
  cjk_font = 'PingFang SC'
  emoji_font = 'Apple Color Emoji'
end
local symbol_font = { family = 'JetBrainsMono Nerd Font' }

local function font_with_fallback(primary)
  return wezterm.font_with_fallback {
    primary,
    cjk_font,
    symbol_font,
    emoji_font,
  }
end

config.font =
  font_with_fallback { family = primary_font, weight = 'Regular' }

config.font_size = is_macos and 15.5 or 12.5

-- 字体行高
config.line_height = 1.08

-- 禁用连字
config.harfbuzz_features = {
  'calt=0',
  'clig=0',
  'liga=0',
}

-- 使用 SF Mono 自带的真实粗体和斜体，其他字符继续走相同回退链。
config.font_rules = {
  {
    intensity = 'Bold',
    italic = false,
    font = font_with_fallback {
      family = primary_font,
      weight = 'DemiBold',
    },
  },
  {
    intensity = 'Normal',
    italic = true,
    font = font_with_fallback {
      family = primary_font,
      weight = 'Regular',
      style = 'Italic',
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

-- 点击系统关闭按钮时直接退出；pane/tab 是否确认由各自快捷键决定。
config.window_close_confirmation = 'NeverPrompt'

-- 需要确认的关闭动作不按进程名跳过确认。
config.skip_close_confirmation_for_processes_named = {}

-- 滚动历史
config.scrollback_lines = 10000

-- Windows 显示可拖动滚动条
config.enable_scroll_bar = is_windows

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
require('tab').apply(config)
require('mappings').apply(config)
require('command_palette').apply()
-- require('plugins').apply(config)


return config
