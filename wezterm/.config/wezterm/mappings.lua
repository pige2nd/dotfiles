local wezterm = require 'wezterm' --[[@as Wezterm]]

local M = {}

local is_windows = wezterm.target_triple:find('windows') ~= nil
local launcher_action = wezterm.action.ShowLauncher
if is_windows then
  launcher_action = wezterm.action.ShowLauncherArgs { flags = 'LAUNCH_MENU_ITEMS' }
end

local toggle_file = wezterm.config_dir .. '/wezterm_toggle'
local toggle_key = { key = '0', mods = 'CTRL|ALT' }

function M.read_toggle()
  local f = io.open(toggle_file, 'r')
  if f then
    local v = f:read '*l'
    f:close()
    return v == 'true'
  end

  -- 首次使用时默认开启自定义键位
  local wf = io.open(toggle_file, 'w')
  if wf then
    wf:write 'false\n'
    wf:close()
  end
  return false
end

local function write_toggle(value)
  local f = io.open(toggle_file, 'w')
  if f then
    f:write((value and 'true' or 'false') .. '\n')
    f:close()
  end
end

local my_toggle = M.read_toggle() -- toggle keybindings on/off, to work with tmux/ssh

wezterm.on('toggle-my-toggle', function(window, pane)
  my_toggle = not my_toggle
  write_toggle(my_toggle)
  window:perform_action(wezterm.action.ReloadConfiguration, pane)
end)

local smart_nav = require('smart-split').smart_nav

-- =========================================================
-- 鼠标绑定
-- =========================================================
local mouse_bindings = {
  -- Ctrl + 左键打开链接
  {
    event = { Up = { streak = 1, button = 'Left' } },
    mods = 'CTRL',
    action = wezterm.action.OpenLinkAtMouseCursor,
  },

  -- 右键：有选中文本则复制，否则粘贴
  {
    event = { Down = { streak = 1, button = 'Right' } },
    mods = 'NONE',
    action = wezterm.action_callback(function(window, pane)
      ---@diagnostic disable-next-line: redundant-parameter
      local has_selection = (window:get_selection_text_for_pane(pane) ~= '')
      if has_selection then
        window:perform_action(
          wezterm.action.CopyTo 'ClipboardAndPrimarySelection',
          pane
        )
        ---@diagnostic disable-next-line: param-type-mismatch
        window:perform_action(wezterm.action.ClearSelection, pane)
      else
        window:perform_action(wezterm.action { PasteFrom = 'Clipboard' }, pane)
      end
    end),
  },

  -- 滚轮逐行滚动（非 alt-screen 下）
  {
    event = { Down = { streak = 1, button = { WheelUp = 1 } } },
    mods = 'NONE',
    action = wezterm.action.ScrollByLine(-2),
    alt_screen = false,
  },
  {
    event = { Down = { streak = 1, button = { WheelDown = 1 } } },
    mods = 'NONE',
    action = wezterm.action.ScrollByLine(2),
    alt_screen = false,
  },
}

-- =========================================================
-- 全局快捷键
-- =========================================================
local keys = {
  -- ━━ 复制 / 粘贴 ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  { key = 'c', mods = 'CTRL|SHIFT', action = wezterm.action.CopyTo 'Clipboard' },
  { key = 'v', mods = 'CTRL|SHIFT', action = wezterm.action.PasteFrom 'Clipboard' },
  { key = 'v', mods = 'CTRL',       action = wezterm.action.PasteFrom 'Clipboard' },

  -- ━━ 标签页 ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  { key = 't', mods = 'CTRL|SHIFT', action = wezterm.action.SpawnTab 'CurrentPaneDomain' },
  { key = 'w', mods = 'CTRL|SHIFT', action = wezterm.action.CloseCurrentPane { confirm = true } },

  -- 标签切换
  { key = 'Tab',    mods = 'CTRL',     action = wezterm.action.ActivateTabRelative(1) },
  { key = 'Tab',    mods = 'CTRL|SHIFT', action = wezterm.action.ActivateTabRelative(-1) },
  { key = '1', mods = 'ALT', action = wezterm.action.ActivateTab(0) },
  { key = '2', mods = 'ALT', action = wezterm.action.ActivateTab(1) },
  { key = '3', mods = 'ALT', action = wezterm.action.ActivateTab(2) },
  { key = '4', mods = 'ALT', action = wezterm.action.ActivateTab(3) },
  { key = '5', mods = 'ALT', action = wezterm.action.ActivateTab(4) },
  { key = '6', mods = 'ALT', action = wezterm.action.ActivateTab(5) },
  { key = '7', mods = 'ALT', action = wezterm.action.ActivateTab(6) },
  { key = '8', mods = 'ALT', action = wezterm.action.ActivateTab(7) },
  { key = '9', mods = 'ALT', action = wezterm.action.ActivateTab(-1) },

  -- ━━ 搜索 / 命令面板 / 启动器 ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  { key = 'f', mods = 'CTRL|SHIFT', action = wezterm.action.Search { CaseInSensitiveString = '' } },
  { key = 'p', mods = 'CTRL|SHIFT', action = wezterm.action.ActivateCommandPalette },
  { key = 'l', mods = 'CTRL|SHIFT', action = launcher_action },

  -- ━━ 字体缩放 ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  { key = '=', mods = 'CTRL', action = wezterm.action.IncreaseFontSize },
  { key = '-', mods = 'CTRL', action = wezterm.action.DecreaseFontSize },
  { key = '0', mods = 'CTRL', action = wezterm.action.ResetFontSize },

  -- ━━ 配置 ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  { key = 'r', mods = 'CTRL|SHIFT', action = wezterm.action.ReloadConfiguration },

}

-- 全局 Pane 导航：不在 Leader 下，进入 Vim 后无需多按一层前缀。
-- 当前 pane 是 Neovim 时透传给 Neovim，否则由 WezTerm 切换/调整 pane。
for _, key in ipairs { 'h', 'j', 'k', 'l' } do
  table.insert(keys, smart_nav('move', key))
  table.insert(keys, smart_nav('resize', key))
end

-- ━━ Leader 快捷键（Alt+B） ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local leader_keys = {
  -- 标签操作
  { key = 'c', action = wezterm.action.SpawnTab 'CurrentPaneDomain' },
  { key = 'X', action = wezterm.action.CloseCurrentTab { confirm = true } },
  { key = 'x', action = wezterm.action.CloseCurrentPane { confirm = true } },

  -- 标签切换
  { key = 'n', action = wezterm.action.ActivateTabRelative(1) },
  { key = 'p', action = wezterm.action.ActivateTabRelative(-1) },
  { key = '[', action = wezterm.action.ActivateCopyMode },
  { key = ']', action = wezterm.action.Search { CaseInSensitiveString = '' } },
  { key = 'l', action = launcher_action },

  -- 分屏
  { key = '|', mods = 'SHIFT', action = wezterm.action.SplitHorizontal { domain = 'CurrentPaneDomain' } },
  { key = '-', action = wezterm.action.SplitVertical { domain = 'CurrentPaneDomain' } },

  -- 放大/恢复当前窗格
  { key = 'z', action = wezterm.action.TogglePaneZoomState },

  -- Shift + hjkl 调整窗格大小
  { key = 'H', mods = 'SHIFT', action = wezterm.action.AdjustPaneSize { 'Left', 5 } },
  { key = 'J', mods = 'SHIFT', action = wezterm.action.AdjustPaneSize { 'Down', 3 } },
  { key = 'K', mods = 'SHIFT', action = wezterm.action.AdjustPaneSize { 'Up', 3 } },
  { key = 'L', mods = 'SHIFT', action = wezterm.action.AdjustPaneSize { 'Right', 5 } },
}

-- 添加 Leader + 1~9 标签跳转
for i = 1, 9 do
  table.insert(leader_keys, {
    key = tostring(i),
    action = wezterm.action.ActivateTab(i - 1),
  })
end

-- 给所有 leader_keys 加上 leader 修饰符
for _, k in ipairs(leader_keys) do
  if k.mods then
    k.mods = 'LEADER|' .. k.mods
  else
    k.mods = 'LEADER'
  end
  table.insert(keys, k)
end

-- =========================================================
-- 应用配置
-- =========================================================
function M.apply(config)
  if not my_toggle then
    -- Leader: Alt+B；进入 tmux 前可切换到裸模式，避免本地快捷键被截获。
    config.leader = { key = 'b', mods = 'ALT', timeout_milliseconds = 800 }
    -- 使用副本，避免重载配置时反复插入 toggle 绑定。
    config.keys = {}
    for _, key in ipairs(keys) do
      table.insert(config.keys, key)
    end
  else
    config.keys = {}
  end
  config.mouse_bindings = mouse_bindings

  -- Ctrl+Alt+0 切换完整键位 / 裸模式；不再和 Ctrl+0 的字体重置冲突。
  table.insert(config.keys, {
    key = toggle_key.key,
    mods = toggle_key.mods,
    action = wezterm.action.EmitEvent 'toggle-my-toggle',
  })

  -- Copy Mode 专用键表
  config.key_tables = {
    copy_mode = {
      -- 方向键导航
      { key = 'LeftArrow',  action = wezterm.action.CopyMode 'MoveLeft' },
      { key = 'RightArrow', action = wezterm.action.CopyMode 'MoveRight' },
      { key = 'UpArrow',    action = wezterm.action.CopyMode 'MoveUp' },
      { key = 'DownArrow',  action = wezterm.action.CopyMode 'MoveDown' },
      { key = 'LeftArrow',  mods = 'SHIFT', action = wezterm.action.CopyMode 'MoveLeft' },
      { key = 'RightArrow', mods = 'SHIFT', action = wezterm.action.CopyMode 'MoveRight' },
      { key = 'UpArrow',    mods = 'SHIFT', action = wezterm.action.CopyMode 'MoveUp' },
      { key = 'DownArrow',  mods = 'SHIFT', action = wezterm.action.CopyMode 'MoveDown' },
      { key = 'h', action = wezterm.action.CopyMode 'MoveLeft' },
      { key = 'j', action = wezterm.action.CopyMode 'MoveDown' },
      { key = 'k', action = wezterm.action.CopyMode 'MoveUp' },
      { key = 'l', action = wezterm.action.CopyMode 'MoveRight' },
      { key = 'Space', action = wezterm.action.CopyMode { SetSelectionMode = 'Cell' } },
      { key = 'q', action = wezterm.action.CopyMode 'Close' },
      { key = 'Escape', action = wezterm.action.CopyMode 'Close' },
      -- 选中后回车复制并退出
      { key = 'Enter', action = wezterm.action.Multiple {
        { CopyTo = 'ClipboardAndPrimarySelection' },
        { CopyMode = 'Close' },
      }},
    },
  }
end

return M
