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

return M
