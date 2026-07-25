local items = {
  {
    id = "battery",
    glyph = "battery",
    stateGlyphs = { Charging = "battery-charging" },
  },
  {
    id = "volume",
    glyph = "volume",
    stateGlyphs = { muted = "volume-off" },
    adjustCommand = "volume",
    middleCommand = "noctalia msg volume-mute",
  },
  {
    id = "brightness",
    glyph = "brightness-up",
    adjustCommand = "brightness",
    adjustTarget = "current",
  },
}

local current = 1
local lastCycle = os.time()
local requestPending = false
local helperPath = nil

local function shellQuote(value)
  return "'" .. string.gsub(value, "'", "'\\''") .. "'"
end

local function helperCommand(...)
  if helperPath == nil then
    local pluginDir = noctalia.pluginDir()
    if pluginDir == nil then
      return nil
    end
    helperPath = pluginDir .. "/status-carousel"
  end

  local parts = { "sh", shellQuote(helperPath) }
  for _, value in ipairs({ ... }) do
    table.insert(parts, shellQuote(tostring(value)))
  end
  return table.concat(parts, " ")
end

local function setUnavailable(item)
  barWidget.setGlyph(item.glyph)
  barWidget.setText("—")
  barWidget.setTooltip(noctalia.tr("tooltip.unavailable", {
    item = noctalia.tr("item." .. item.id),
  }))
end

local function render(item, value, state)
  local glyph = item.glyph
  if item.stateGlyphs ~= nil and item.stateGlyphs[state] ~= nil then
    glyph = item.stateGlyphs[state]
  end

  barWidget.setGlyph(glyph)
  barWidget.setText(value .. "%")
  barWidget.setTooltip(noctalia.tr("tooltip.status", {
    item = noctalia.tr("item." .. item.id),
    value = value,
    state = noctalia.tr("state." .. state),
  }))
end

local function refresh()
  if requestPending then
    return
  end

  local item = items[current]
  local command = helperCommand("read", item.id)
  if command == nil then
    setUnavailable(item)
    return
  end

  requestPending = true
  if not noctalia.runAsync(command, function(result)
    requestPending = false
    if item ~= items[current] then
      refresh()
      return
    end
    if result.exitCode ~= 0 then
      setUnavailable(item)
      return
    end

    local kind, value, state = string.match(
      noctalia.string.trim(result.stdout),
      "^([^|]+)|([0-9]+)|([^|]+)$"
    )
    if kind ~= item.id or value == nil or state == nil then
      setUnavailable(item)
      return
    end
    render(item, value, state)
  end) then
    requestPending = false
    setUnavailable(item)
  end
end

local function advance(direction)
  current = ((current - 1 + direction) % #items) + 1
  lastCycle = os.time()
  refresh()
end

local function adjust(item, delta)
  local direction = delta > 0 and "up" or "down"
  local amount = math.abs(delta)
  local target = item.adjustTarget ~= nil and (" " .. item.adjustTarget) or ""
  local command = "noctalia msg " .. item.adjustCommand .. "-" .. direction
    .. target .. " " .. tostring(amount)

  noctalia.runAsync(command, function(_result)
    refresh()
  end)
end

noctalia.setUpdateInterval(1000)
refresh()

function update()
  local cycleSeconds = noctalia.getConfig("cycle_seconds")
  if os.time() - lastCycle >= cycleSeconds then
    advance(1)
  else
    refresh()
  end
end

function onClick()
  advance(1)
end

function onRightClick()
  noctalia.runAsync("noctalia msg panel-toggle control-center")
end

function onMiddleClick()
  local item = items[current]
  if item.middleCommand ~= nil then
    noctalia.runAsync(item.middleCommand, function(_result)
      refresh()
    end)
  else
    advance(1)
  end
end

function onScroll(axis, steps)
  if axis ~= "vertical" or steps == 0 then
    return
  end

  local item = items[current]
  if item.adjustCommand == nil then
    advance(steps > 0 and 1 or -1)
    return
  end

  local adjustStep = noctalia.getConfig("adjust_step")
  adjust(item, -steps * adjustStep)
  lastCycle = os.time()
end
