local addonName, ns = ...

local type = type
local pairs = pairs
local ipairs = ipairs

local appearance = ns.appearance
local DEFAULTS = appearance.DEFAULTS

function appearance.Saved()
    return ns.profiles.Current()
end

local saved = appearance.Saved

ns.profiles.OnComplete(function(data)
    ns.profiles.FillMissing(data, DEFAULTS)
end)

function appearance.Sanitize(data)
    local clean = {}
    for element, defaults in pairs(DEFAULTS) do
        local group = data[element]
        if type(group) == "table" then
            clean[element] = {}
            for field, default in pairs(defaults) do
                if ns.profiles.Matches(group[field], default) then
                    clean[element][field] = group[field]
                end
            end
        end
    end
    if type(data.timerStyle) == "table" then
        clean.timerStyle = ns.timerStyle.Sanitize(data.timerStyle)
    end
    if type(data.look) == "table" and ns.values then
        clean.look = ns.values.SanitizeLook(data.look)
    end
    if type(data.options) == "table" and ns.options then
        clean.options = ns.options.Sanitize(data.options)
    end
    return clean
end

function appearance.Get(element, field)
    local group = saved()[element]
    local value = group and group[field]
    if value == nil then
        return DEFAULTS[element][field]
    end
    local limits = field == "size" and appearance.SIZE_LIMITS[element]
    if limits and type(value) == "number" then
        return math.min(math.max(value, limits[1]), limits[2])
    end
    return value
end
local listeners = {}

function appearance.OnChanged(listener)
    listeners[#listeners + 1] = listener
end

function appearance.Notify()
    for _, listener in ipairs(listeners) do
        listener()
    end
end

function appearance.Reader(element, field)
    return function()
        return appearance.Get(element, field)
    end
end

function appearance.Set(element, field, value)
    appearance.ClearUndo()
    local values = saved()
    values[element] = values[element] or {}
    values[element][field] = value
    appearance.Notify()
end
