local addonName, ns = ...

local same = ns.tables.Same
local pairs = pairs
local ipairs = ipairs
local CopyTable = CopyTable

local appearance = ns.appearance
local DEFAULTS = appearance.DEFAULTS
local saved = appearance.Saved

local undo

local NUMBER_TOLERANCE = 1e-6

local TAB_MEMBERS = {
    icon = { "icon", "border", "dangerGlow" },
    behavior = { "states", "animations", "trail" },
    motion = { "animations", "trail" },
}

local function membersOf(element)
    return TAB_MEMBERS[element] or { element }
end

local function isDefaultElement(element)
    local group = saved()[element]
    if not group then
        return true
    end
    for field, default in pairs(DEFAULTS[element]) do
        if group[field] ~= nil and not same(group[field], default, NUMBER_TOLERANCE) then
            return false
        end
    end
    return true
end

function appearance.IsDefault(element)
    for _, member in ipairs(membersOf(element)) do
        if not isDefaultElement(member) then
            return false
        end
    end
    return true
end

local OTHER_TABS = { states = true, animations = true, trail = true }

function appearance.AllDefault()
    for element in pairs(DEFAULTS) do
        if not OTHER_TABS[element] and not isDefaultElement(element) then
            return false
        end
    end
    return true
end

function appearance.ClearUndo()
    undo = nil
end

function appearance.Reset(element)
    if DEFAULTS[element] or TAB_MEMBERS[element] then
        local dropped, any = {}, false
        for _, member in ipairs(membersOf(element)) do
            if saved()[member] then
                dropped[member] = CopyTable(saved()[member])
                any = any or not isDefaultElement(member)
            end
            saved()[member] = CopyTable(DEFAULTS[member])
        end
        undo = any and { element = element, dropped = dropped } or nil
        appearance.Apply()
        appearance.Notify()
    end
end

function appearance.UndoElement()
    return undo and undo.element or nil
end

function appearance.UndoReset()
    if undo then
        for member, group in pairs(undo.dropped) do
            saved()[member] = group
        end
        undo = nil
        appearance.Apply()
        appearance.Notify()
    end
end

function appearance.ResetAll()
    undo = nil
    for element in pairs(DEFAULTS) do
        if not OTHER_TABS[element] then
            saved()[element] = CopyTable(DEFAULTS[element])
        end
    end
    appearance.Apply()
    appearance.Notify()
end
