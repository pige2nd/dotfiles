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

assert(
  tab_title.bracket_text(' 2   Build Logs ', '')
    == '[2 Build Logs]'
)

assert(
  tab_title.bracket_from_elements({
    { Background = { Color = '#000000' } },
    { Foreground = { Color = '#ffffff' } },
    { Attribute = { Intensity = 'Bold' } },
    { Text = ' 2   Build Logs ' },
    { Text = '' },
  }, '') == '[2 Build Logs]'
)

assert(
  tab_title.bracket_from_elements({
    { Text = ' 3 Database ' },
    { Text = '' },
  }, '') == '[3 Database]'
)

return wezterm.config_builder()
