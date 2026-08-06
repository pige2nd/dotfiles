local wezterm = require 'wezterm'

local repo_dir = assert(os.getenv 'NYXNIRI_REPO_DIR', 'NYXNIRI_REPO_DIR is required')
local tab_title = dofile(repo_dir .. '/wezterm/.config/wezterm/tab-title.lua')

local function plugin_custom_title(title)
  local _, custom = title:match '^(%S+)%s*%-?%s*%s*(.*)$'
  return custom
end

local explicit = {
  tab_title = 'Alpha Project',
  active_pane = { title = 'zsh' },
}
local normalized_explicit = tab_title.for_plugin(explicit)
assert(plugin_custom_title(normalized_explicit.tab_title) == 'Alpha Project')
assert(explicit.tab_title == 'Alpha Project')

local pane = {
  tab_title = '',
  active_pane = { title = 'Build Logs' },
}
local normalized_pane = tab_title.for_plugin(pane)
assert(plugin_custom_title(normalized_pane.active_pane.title) == 'Build Logs')
assert(pane.active_pane.title == 'Build Logs')

local single_word = {
  tab_title = '',
  active_pane = { title = 'zsh' },
}
assert(tab_title.for_plugin(single_word) == single_word)

return wezterm.config_builder()
