local addonName, ns = ...

local same = ns.tables.Same
local values = ns.values

local NUMBER_TOLERANCE = 0.01

local undo = {}
ns.editModeUndo = undo

local function copyValue(value)
    if type(value) == "table" then
        return CopyTable(value)
    end
    return value
end

function undo.Begin(layoutName)
    local start = { layoutName = layoutName, profile = ns.profiles.CurrentName(), values = {} }
    if layoutName then
        for _, key in ipairs(values.Keys) do
            start.values[key] = copyValue(values.Raw(key, layoutName))
        end
    end
    return start
end

local function isOtherProfile(start, key)
    return values.LOOK_KEYS[key] and start.profile ~= ns.profiles.CurrentName()
end

function undo.Restore(start)
    if not start.layoutName then
        return
    end
    for _, key in ipairs(values.Keys) do
        if not isOtherProfile(start, key) then
            values.Set(key, start.layoutName, copyValue(start.values[key]))
        end
    end
end

function undo.HasChanges(start)
    if not start.layoutName then
        return false
    end
    for _, key in ipairs(values.Keys) do
        local before = start.values[key]
        if before == nil then
            before = values.Default(key)
        end
        if not isOtherProfile(start, key) and not same(values.Get(key, start.layoutName), before, NUMBER_TOLERANCE) then
            return true
        end
    end
    return false
end
