local wezterm = require 'wezterm' --[[@as Wezterm]]

local M = {}

function M.apply()
  wezterm.on('augment-command-palette', function(_, _)
    return {
      {
        brief = 'Rename tab',
        icon = 'md_rename_box',
        action = wezterm.action.PromptInputLine {
          description = 'Enter new name for tab',
          initial_value = '',
          action = wezterm.action_callback(function(window, _, line)
            if line and line ~= '' then
              window:active_tab():set_title(line)
            end
          end),
        },
      },
    }
  end)
end

return M
