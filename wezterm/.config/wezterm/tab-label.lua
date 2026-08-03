local wezterm = require 'wezterm'

local M = {}

function M.compact(label, max_width)
  if wezterm.column_width(label) <= max_width then
    return label
  end

  return wezterm.truncate_right(label, max_width - 1) .. '…'
end

function M.active_directory(tab, max_width)
  local cwd_uri = tab.active_pane.current_working_dir
  if not cwd_uri then
    return '  '
  end

  local file_path = cwd_uri.file_path:gsub('\\', '/')
  local directory = file_path:match('([^/]+)/?$') or ''
  return ' ' .. M.compact(directory, max_width) .. ' '
end

return M
