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

return M
