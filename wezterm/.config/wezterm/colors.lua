-- 只改这一行即可切换主题；自定义主题在下方统一注册。
local selected_scheme = 'Amber Manpage'

local M = {}
local custom_schemes = {
  ['Amber Manpage'] = require 'amber-manpage',
}

function M.apply(config)
  config.color_schemes = config.color_schemes or {}
  for name, scheme in pairs(custom_schemes) do
    config.color_schemes[name] = scheme
  end

  config.color_scheme = selected_scheme
end

return M
