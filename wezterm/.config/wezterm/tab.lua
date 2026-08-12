local wezterm = require 'wezterm' --[[@as Wezterm]]
local domain_status = require 'domain-status'
local tab_title = require 'tab-title'

local M = {}
local tab_separator = '\u{e0b1}'
local new_tab_width = 3
local status_widths = {}

local function status_text(label)
  return ' ' .. wezterm.nerdfonts[domain_status.icon(label)]
    .. ' ' .. label .. ' '
end

local default_status_width = wezterm.column_width(status_text(
  domain_status.label { target_triple = wezterm.target_triple }
))

local function status_width(tabs)
  for _, candidate in ipairs(tabs) do
    if candidate.is_active and candidate.active_pane then
      return status_widths[tostring(candidate.active_pane.pane_id)]
        or default_status_width
    end
  end
  return default_status_width
end

local function bracket_tab(callback, tab, tabs, panes, config, hover, max_width)
  local rendered = callback(
    tab_title.for_plugin(tab),
    tabs,
    panes,
    config,
    hover,
    max_width
  )
  local palette = config.resolved_palette.tab_bar
  local colors =
    tab.is_active and palette.active_tab or palette.inactive_tab
  local width = tab_title.chrome_width_for_tab(
    max_width,
    tab.tab_index,
    #tabs,
    config.tab_max_width,
    status_width(tabs),
    tab_title.pane_columns(panes),
    new_tab_width
  )

  return {
    { Background = { Color = colors.bg_color } },
    { Foreground = { Color = colors.fg_color } },
    { Attribute = { Intensity = tab.is_active and 'Bold' or 'Normal' } },
    {
      Text = tab_title.fit_bracket(
        tab_title.bracket_from_elements(rendered, tab_separator),
        width
      ),
    },
  }
end

local function call_pane(pane, method)
  local ok, value = pcall(function()
    return pane[method](pane)
  end)
  return ok and value or nil
end

local function cwd_host(pane)
  local cwd = call_pane(pane, 'get_current_working_dir')
  if type(cwd) == 'userdata' then
    return cwd.host
  end
  if type(cwd) == 'string' then
    return cwd:match '^%w+://([^/]+)'
  end
end

local function set_dynamic_status(window, pane)
  local label = domain_status.label {
    domain_name = call_pane(pane, 'get_domain_name'),
    process_info = call_pane(pane, 'get_foreground_process_info'),
    cwd_host = cwd_host(pane),
    target_triple = wezterm.target_triple,
  }
  local right_status_text = status_text(label)
  local pane_id = call_pane(pane, 'pane_id')
  if pane_id then
    status_widths[tostring(pane_id)] = wezterm.column_width(right_status_text)
  end

  local palette = window:effective_config().resolved_palette
  local active_tab = palette.tab_bar.active_tab
  local attributes = {
    { Background = { Color = active_tab.bg_color } },
    { Foreground = { Color = active_tab.fg_color } },
    { Attribute = { Intensity = 'Bold' } },
  }

  local function block(text)
    local elements = {}
    for _, attribute in ipairs(attributes) do
      table.insert(elements, attribute)
    end
    table.insert(elements, { Text = text })
    return wezterm.format(elements)
  end

  window:set_right_status(block(right_status_text))
end

local function load_tabs()
  -- wezterm-tabs 会把多词标题的第一个词误判为进程名。只在插件注册
  -- format-tab-title 时包装它的输入，保留完整标题和原有渲染逻辑。
  local original_on = wezterm.on
  wezterm.on = function(event, callback)
    if event == 'format-tab-title' then
      return original_on(event, function(tab, tabs, panes, config, hover, max_width)
        return bracket_tab(
          callback,
          tab,
          tabs,
          panes,
          config,
          hover,
          max_width
        )
      end)
    end
    return original_on(event, callback)
  end

  local ok, tabs = pcall(
    wezterm.plugin.require,
    'https://github.com/yriveiro/wezterm-tabs'
  )
  wezterm.on = original_on
  if not ok then
    error(tabs)
  end
  return tabs
end

function M.apply(config)
  local tabs = load_tabs()

  wezterm.on('update-right-status', function(window, pane)
    set_dynamic_status(window, pane)
  end)

  -- 插件只在 color_schemes 表中查找主题；把当前 WezTerm 内置主题
  -- 显式注册进去，避免 format-tab-title 在运行时读取到 nil。
  local scheme = config.color_schemes[config.color_scheme]
    or wezterm.color.get_builtin_schemes()[config.color_scheme]
  assert(scheme, 'Unknown color scheme: ' .. config.color_scheme)
  config.color_schemes = config.color_schemes or {}
  config.color_schemes[config.color_scheme] = scheme

  tabs.apply_to_config(config, {
    tabs = {
      tab_bar_at_bottom = false,
      hide_tab_bar_if_only_one_tab = false,
      tab_max_width = 24,
      unzoom_on_switch_pane = true,
    },
    ui = {
      separators = {
        arrow_thin_left = tab_separator,
      },
      tab = {
        -- 不读取 mux pane 状态，只显示静态的索引、图标和标题。
        zoom_indicator = {
          enabled = false,
          type = 'icon',
        },
      },
    },
  })

  config.show_new_tab_button_in_tab_bar = true

  -- 标签和右侧环境状态都由事件驱动更新。
  config.window_decorations = 'TITLE | RESIZE'
end

return M
