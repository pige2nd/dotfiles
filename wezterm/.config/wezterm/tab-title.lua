local wezterm = require 'wezterm'

local M = {}
local title_marker = '\u{2060} '

local function with_override(value, key, item)
  return setmetatable({ [key] = item }, {
    __index = function(_, missing_key)
      return value[missing_key]
    end,
  })
end

local function needs_preserving(title)
  return title and title ~= '' and title:find('%s') ~= nil
end

function M.for_plugin(tab)
  if needs_preserving(tab.tab_title) then
    return with_override(tab, 'tab_title', title_marker .. tab.tab_title)
  end

  local pane = tab.active_pane
  if (not tab.tab_title or tab.tab_title == '')
    and pane
    and needs_preserving(pane.title)
  then
    local pane_override =
      with_override(pane, 'title', title_marker .. pane.title)
    return with_override(tab, 'active_pane', pane_override)
  end

  return tab
end

function M.bracket_text(rendered_text, separator)
  local start, finish = rendered_text:find(separator, 1, true)
  if start then
    rendered_text =
      rendered_text:sub(1, start - 1) .. rendered_text:sub(finish + 1)
  end

  rendered_text =
    rendered_text:gsub('^%s+', ''):gsub('%s+$', ''):gsub('%s+', ' ')
  return '[' .. rendered_text .. ']'
end

function M.bracket_from_elements(elements, separator)
  local fallback
  for _, element in ipairs(elements) do
    if element.Text and element.Text ~= '' then
      fallback = fallback or element.Text
      if element.Text:find(separator, 1, true) then
        return M.bracket_text(element.Text, separator)
      end
    end
  end

  return M.bracket_text(fallback or '?', separator)
end

function M.fit_bracket(label, width)
  if width <= 0 then
    return ''
  end
  if width == 1 then
    return wezterm.truncate_right(label, width)
  end

  local inner = label:match '^%[(.*)%]$' or label
  local outer_padding = width >= 4 and 2 or 0
  local inner_width = width - 2 - outer_padding
  inner = wezterm.truncate_right(inner, inner_width)

  local text = (outer_padding > 0 and ' ' or '') .. '[' .. inner .. ']'
  return text .. string.rep(' ', width - wezterm.column_width(text))
end

function M.pane_columns(panes)
  local columns = 0
  for _, pane in ipairs(panes or {}) do
    columns = math.max(columns, (pane.left or 0) + (pane.width or 0))
  end
  return columns
end

local function chrome_layout(
  max_width,
  tab_count,
  tab_max_width,
  status_width,
  window_width,
  new_tab_width
)
  if tab_count <= 0 or window_width <= 0 then
    return max_width, 0
  end

  local available =
    math.max(window_width - status_width - new_tab_width, tab_count)
  local width_cap = math.max(math.min(max_width, tab_max_width), 1)
  local width = math.min(width_cap, math.floor(available / tab_count))
  local used_width = math.min(available, width_cap * tab_count)
  return width, used_width - width * tab_count
end

function M.chrome_width(
  max_width,
  tab_count,
  tab_max_width,
  status_width,
  window_width,
  new_tab_width
)
  local width = chrome_layout(
    max_width,
    tab_count,
    tab_max_width,
    status_width,
    window_width,
    new_tab_width
  )
  return width
end

function M.chrome_width_for_tab(
  max_width,
  tab_index,
  tab_count,
  tab_max_width,
  status_width,
  window_width,
  new_tab_width
)
  local width, remainder = chrome_layout(
    max_width,
    tab_count,
    tab_max_width,
    status_width,
    window_width,
    new_tab_width
  )
  if tab_index < remainder then
    return width + 1
  end
  return width
end

return M
