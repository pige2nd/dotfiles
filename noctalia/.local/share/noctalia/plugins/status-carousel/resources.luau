local items = {
  { id = "ram", glyph = "database" },
  { id = "cpu", glyph = "cpu" },
}

local current = 1
local lastCycle = os.time()
local requestPending = false
local helperPath = nil

local function shellQuote(value)
  return "'" .. string.gsub(value, "'", "'\\''") .. "'"
end

local function helperCommand(item)
  if helperPath == nil then
    local pluginDir = noctalia.pluginDir()
    if pluginDir == nil then
      return nil
    end
    helperPath = pluginDir .. "/status-carousel"
  end

  return "sh " .. shellQuote(helperPath) .. " read " .. shellQuote(item.id)
end

local function setUnavailable(item)
  barWidget.setGlyph(item.glyph)
  barWidget.setText("—")
  barWidget.setTooltip(noctalia.tr("tooltip.unavailable", {
    item = noctalia.tr("item." .. item.id),
  }))
end

local function refresh()
  if requestPending then
    return
  end

  local item = items[current]
  local command = helperCommand(item)
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

    barWidget.setGlyph(item.glyph)
    barWidget.setText(value .. "%")
    barWidget.setTooltip(noctalia.tr("tooltip.status", {
      item = noctalia.tr("item." .. item.id),
      value = value,
      state = noctalia.tr("state." .. state),
    }))
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
  advance(1)
end

function onScroll(axis, steps)
  if axis == "vertical" and steps ~= 0 then
    advance(steps > 0 and 1 or -1)
  end
end
