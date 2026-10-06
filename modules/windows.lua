-- Windows-style window management: windows float, Super+Left/Right snap
-- them to screen halves, and minimized windows wait on a special workspace
-- until the taskbar brings them back. Hyprland ignores the minimize request
-- of an app's own title-bar button, so only Temple can minimize.

hl.window_rule({ name = "temple-float", match = { class = ".*" }, float = true })

-- Steam and launcher menus are unnamed XWayland floats that close once focused.
hl.window_rule({
  name = "temple-xwayland-menus",
  match = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
  no_focus = true,
})

hl.window_rule({
  name = "temple-games",
  match = { class = "^(steam_app_[0-9]+|gamescope)$" },
  fullscreen = true,
  idle_inhibit = "fullscreen",
})

-- Click to focus (input.follow_mouse = 2), and the focused window comes to the front.
hl.on("window.active", function()
  hl.dispatch(hl.dsp.window.bring_to_top())
end)

temple = {}

local minimized = "special:minimized"

local function selector(address)
  return "address:" .. (address:match("^0x") and address or "0x" .. address)
end

local function workarea(monitor)
  local reserved = monitor.reserved
  return {
    x = monitor.x + reserved.left,
    y = monitor.y + reserved.top,
    w = monitor.width - reserved.left - reserved.right,
    h = monitor.height - reserved.top - reserved.bottom,
  }
end

-- The closest screen on one side that shares rows with this one.
local function neighbour(monitor, side)
  local best
  for _, other in ipairs(hl.get_monitors()) do
    local beside = (side < 0 and other.x + other.width <= monitor.x) or (side > 0 and other.x >= monitor.x + monitor.width)
    local overlaps = other.y < monitor.y + monitor.height and other.y + other.height > monitor.y
    if beside and overlaps and (not best or math.abs(other.x - monitor.x) < math.abs(best.x - monitor.x)) then
      best = other
    end
  end
  return best
end

local function half(monitor, side)
  local area = workarea(monitor)
  local width = math.floor(area.w / 2)
  if side < 0 then
    return { x = area.x, y = area.y, w = width, h = area.h }
  end
  return { x = area.x + width, y = area.y, w = area.w - width, h = area.h }
end

local function place(box)
  hl.dispatch(hl.dsp.window.resize({ x = box.w, y = box.h }))
  hl.dispatch(hl.dsp.window.move({ x = box.x, y = box.y }))
end

-- Clients may round their size a few pixels, so geometry matches loosely.
local function occupies(window, box)
  local function near(a, b)
    return math.abs(a - b) <= 2
  end
  return near(window.at.x, box.x) and near(window.at.y, box.y) and near(window.size.x, box.w) and near(window.size.y, box.h)
end

-- Snapped windows: the screen half each one holds and the geometry it had before.
local snapped = {}

local function snap_to(window, monitor, side, restore)
  if monitor.name ~= window.monitor.name then
    hl.dispatch(hl.dsp.window.move({ monitor = monitor.name }))
  end
  local box = half(monitor, side)
  place(box)
  snapped[window.address] = { monitor = monitor.name, side = side, box = box, restore = restore }
end

-- Each press moves one half-screen that way: a free window takes the half on
-- that side, a left half becomes the right half, and a right half crosses to
-- the left half of the next screen. Super+Down restores the original size.
function temple.snap(side)
  return function()
    local window = hl.get_active_window()
    if not window or not window.monitor then
      return
    end
    if window.fullscreen ~= 0 then
      hl.dispatch(hl.dsp.window.fullscreen({ mode = "maximized", action = "unset" }))
    end
    if not window.floating then
      hl.dispatch(hl.dsp.window.float({ action = "set" }))
    end
    window = hl.get_active_window()
    local state = snapped[window.address]
    if state and not occupies(window, state.box) then
      state = nil
    end
    if not state then
      snap_to(window, window.monitor, side, { x = window.at.x, y = window.at.y, w = window.size.x, h = window.size.y })
    elseif state.side ~= side then
      snap_to(window, hl.get_monitor(state.monitor), side, state.restore)
    else
      local next = neighbour(hl.get_monitor(state.monitor), side)
      if next then
        snap_to(window, next, -side, state.restore)
      end
    end
  end
end

-- Dropping a dragged window on a screen edge snaps it like Windows: the top
-- edge maximizes, the left and right edges take a half, corners a quarter.
-- Dragging a snapped window off its spot gives it back its earlier size.
local edge = 4
-- Window positions when the button went down. Focus moves on click, so the
-- dragged window is only known at release: it is the active one, if it moved.
local positions

function temple.press()
  positions = {}
  for _, window in ipairs(hl.get_windows()) do
    positions[window.address] = { x = window.at.x, y = window.at.y }
  end
end

function temple.release()
  local before = positions
  positions = nil
  local window = hl.get_active_window()
  local start = before and window and before[window.address]
  if not start or not window.floating or (window.at.x == start.x and window.at.y == start.y) then
    return
  end
  local cursor = hl.get_cursor_pos()
  local monitor = cursor and hl.get_monitor_at(cursor.x, cursor.y)
  if not monitor then
    return
  end
  local left = cursor.x <= monitor.x + edge
  local right = cursor.x >= monitor.x + monitor.width - 1 - edge
  local top = cursor.y <= monitor.y + edge
  local bottom = cursor.y >= monitor.y + monitor.height - 1 - edge
  local state = snapped[window.address]
  local restore = state and state.restore or { x = window.at.x, y = window.at.y, w = window.size.x, h = window.size.y }
  if (left or right) and (top or bottom) then
    local area = workarea(monitor)
    local w, h = math.floor(area.w / 2), math.floor(area.h / 2)
    local box = {
      x = left and area.x or area.x + w,
      y = top and area.y or area.y + h,
      w = left and w or area.w - w,
      h = top and h or area.h - h,
    }
    if monitor.name ~= window.monitor.name then
      hl.dispatch(hl.dsp.window.move({ monitor = monitor.name }))
    end
    place(box)
    snapped[window.address] = { monitor = monitor.name, box = box, restore = restore }
  elseif left or right then
    snap_to(window, monitor, left and -1 or 1, restore)
  elseif top then
    snapped[window.address] = nil
    hl.dispatch(hl.dsp.window.fullscreen({ mode = "maximized", action = "set" }))
  elseif state then
    snapped[window.address] = nil
    hl.dispatch(hl.dsp.window.resize({ x = state.restore.w, y = state.restore.h }))
  end
end

-- Every left click passes through untouched; these only watch for drags.
hl.bind("mouse:272", temple.press, { non_consuming = true, ignore_mods = true })
hl.bind("mouse:272", temple.release, { non_consuming = true, ignore_mods = true, release = true })

function temple.minimize(address)
  hl.dispatch(hl.dsp.window.move({ workspace = minimized, follow = false, window = selector(address) }))
end

function temple.restore(address)
  hl.dispatch(hl.dsp.window.move({ workspace = tostring(hl.get_active_workspace().id), window = selector(address) }))
  hl.dispatch(hl.dsp.focus({ window = selector(address) }))
end

function temple.focus(address)
  hl.dispatch(hl.dsp.focus({ window = selector(address) }))
end

-- A maximized window restores, a snapped one returns to its size before the
-- snap, and any other window minimizes.
function temple.down()
  local window = hl.get_active_window()
  if not window then
    return
  end
  local state = snapped[window.address]
  if window.fullscreen ~= 0 then
    hl.dispatch(hl.dsp.window.fullscreen({ mode = "maximized", action = "unset" }))
  elseif state and occupies(window, state.box) then
    snapped[window.address] = nil
    place(state.restore)
  else
    temple.minimize(window.address)
  end
end
