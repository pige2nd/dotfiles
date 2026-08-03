local wezterm = require 'wezterm'

local repo_dir = assert(os.getenv 'NYXNIRI_REPO_DIR', 'NYXNIRI_REPO_DIR is required')
local tab_label = dofile(repo_dir .. '/wezterm/.config/wezterm/tab-label.lua')

assert(tab_label.compact('abcdefghijkl', 12) == 'abcdefghijkl')
assert(tab_label.compact('abcdefghijklm', 12) == 'abcdefghijk…')
assert(tab_label.compact('中文标签测试', 12) == '中文标签测试')

local compact_chinese = tab_label.compact('中文标签测试七', 12)
assert(wezterm.column_width(compact_chinese) <= 12)
assert(compact_chinese:sub(-3) == '…')

local active_directory = tab_label.active_directory({
  active_pane = {
    current_working_dir = {
      file_path = '/home/xx/中文标签测试七',
    },
  },
}, 12)
assert(active_directory:sub(1, 1) == ' ')
assert(active_directory:sub(-1) == ' ')
assert(wezterm.column_width(active_directory) <= 14)

return wezterm.config_builder()
