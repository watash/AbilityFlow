local addonName, ns = ...

local pairs = pairs

local timeline = ns.timeline

local presets = {}
ns.presets = presets

presets.BLIZZARD = "blizzard"
presets.PLAIN = "plain"

local PLAIN_VALUES = {
    animations = { intro = true, outro = true, shift = false, arrival = false, fade = false, speed = 100 },
    trail = { enabled = false },
    border = { style = "SOLID", thickness = 1, color = { r = 1, g = 1, b = 1, a = 1 }, useEventColor = false },
}
local PLAIN_LOOK = {
    blizzlikeBackdrops = false,
    markStyles = timeline.MARK_BAR_TEXT,
    borderThicknesses = 0,
}

local function setLook(look)
    for key in pairs(ns.values.LOOK_KEYS) do
        ns.values.Set(key, nil, look and look[key])
    end
    local active = timeline.ActiveLayoutName()
    if active then
        ns.values.ApplyLook(active)
    end
end

local function defaultValues()
    local values = {}
    for element, fields in pairs(PLAIN_VALUES) do
        values[element] = {}
        for field in pairs(fields) do
            values[element][field] = ns.appearance.DEFAULTS[element][field]
        end
    end
    return values
end

local function putLook(key)
    local plain = key == presets.PLAIN
    ns.profiles.Put(ns.profiles.Current(), ns.appearance.Sanitize(plain and PLAIN_VALUES or defaultValues()))
    ns.profiles.Current().timerStyle = ns.timerStyle.NewStyle(plain)
    ns.appearance.Apply()
    ns.appearance.Notify()
    setLook(plain and PLAIN_LOOK or nil)
end

function presets.Apply(key)
    ns.profiles.Select(ns.profiles.DEFAULT)
    putLook(key)
end

function presets.Create(key, name)
    ns.profiles.Create(name)
    putLook(key)
end
