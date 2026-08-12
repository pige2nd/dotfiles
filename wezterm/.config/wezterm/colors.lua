local amber_manpage = require 'amber-manpage'

local M = {}

function M.apply(config)
  config.color_schemes = config.color_schemes or {}
  config.color_schemes['Amber Manpage'] = amber_manpage

  config.color_scheme = 'Amber Manpage'
end

return M
