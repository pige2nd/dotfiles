if vim then
  package.preload.wezterm = function()
    return {
      column_width = vim.fn.strdisplaywidth,
      truncate_right = function(text, width)
        local result = ''
        for index = 0, vim.fn.strchars(text) - 1 do
          local character = vim.fn.strcharpart(text, index, 1)
          if vim.fn.strdisplaywidth(result .. character) > width then
            break
          end
          result = result .. character
        end
        return result
      end,
    }
  end
end

local wezterm = require 'wezterm'

local repo_dir = assert(os.getenv 'NYXNIRI_REPO_DIR', 'NYXNIRI_REPO_DIR is required')
local domain_status =
  dofile(repo_dir .. '/wezterm/.config/wezterm/domain-status.lua')
local tab_title = dofile(repo_dir .. '/wezterm/.config/wezterm/tab-title.lua')

assert(domain_status.label {
  domain_name = 'local',
  target_triple = 'x86_64-pc-windows-msvc',
} == 'WINDOWS')
assert(domain_status.label {
  domain_name = 'local',
  process_info = {
    executable = 'C:\\Windows\\System32\\WindowsPowerShell\\v1.0\\powershell.exe',
    argv = { 'powershell.exe', '-NoLogo' },
  },
  target_triple = 'x86_64-pc-windows-msvc',
} == 'WINDOWS')
assert(domain_status.label {
  domain_name = 'local',
  target_triple = 'aarch64-apple-darwin',
} == 'MACOS')
assert(domain_status.label {
  domain_name = 'local',
  target_triple = 'x86_64-unknown-linux-gnu',
} == 'LINUX')
assert(domain_status.label {
  domain_name = 'WSL:Ubuntu',
  target_triple = 'x86_64-pc-windows-msvc',
} == 'UBUNTU')
assert(domain_status.label {
  domain_name = 'WSL:Debian',
} == 'DEBIAN')
assert(domain_status.label {
  domain_name = 'SSH:build-server',
} == 'SSH build-server')
assert(domain_status.label {
  domain_name = 'production',
} == 'REMOTE production')
assert(domain_status.label {
  domain_name = 'local',
  process_info = {
    executable = 'C:\\Windows\\System32\\OpenSSH\\ssh.exe',
    argv = { 'ssh.exe', '-p', '2222', 'deploy@192.0.2.10' },
  },
  target_triple = 'x86_64-pc-windows-msvc',
} == 'SSH deploy@192.0.2.10')
assert(domain_status.label {
  domain_name = 'WSL:Ubuntu',
  process_info = {
    executable = '/usr/bin/ssh',
    argv = { 'ssh', '-o', 'ServerAliveInterval=30', 'server-alias' },
  },
} == 'SSH server-alias')
assert(domain_status.label {
  domain_name = 'local',
  process_info = {
    executable = '/usr/bin/ssh',
    argv = { 'ssh' },
  },
  cwd_host = 'remote.example.com',
} == 'SSH remote.example.com')

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

local wide_tab = tab_title.fit_bracket('[2 Build Logs]', 18)
assert(wide_tab == ' [2 Build Logs]   ')
assert(wezterm.column_width(wide_tab) == 18)
assert(tab_title.fit_bracket('[2 Build Logs]', 10) == ' [2 Buil] ')
assert(tab_title.fit_bracket('[2 Build Logs]', 3) == '[2]')
assert(tab_title.fit_bracket('[2 Build Logs]', 0) == '')
assert(tab_title.fit_bracket('[2 构建日志]', 10) == ' [2 构建] ')

assert(tab_title.pane_columns({
  { left = 0, width = 40 },
  { left = 41, width = 39 },
}) == 80)
assert(tab_title.chrome_width(24, 3, 24, 19, 94, 3) == 24)
assert(tab_title.chrome_width(24, 3, 24, 19, 77, 3) == 18)
assert(tab_title.chrome_width(17, 8, 24, 19, 92, 3) == 8)

local distributed_widths = {}
local distributed_total = 0
for tab_index = 0, 7 do
  local width = tab_title.chrome_width_for_tab(
    24,
    tab_index,
    8,
    24,
    9,
    71,
    3
  )
  table.insert(distributed_widths, width)
  distributed_total = distributed_total + width
end
assert(table.concat(distributed_widths, ',') == '8,8,8,7,7,7,7,7')
assert(distributed_total == 71 - 9 - 3)

if wezterm.config_builder then
  return wezterm.config_builder()
end
