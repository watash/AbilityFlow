local addonName, ns = ...

local pairs = pairs
local pcall = pcall

local dbmColors = {}
ns.dbmColors = dbmColors

local SETTING_KEY = "showBossModColors"
local FIRST_OWN_COLOR = 1
local FULL_OPACITY = 1

local kinds = {}

function dbmColors.Remember(eventID, colorKind, ofGame)
    kinds[eventID] = type(colorKind) == "number" and { kind = colorKind, ofGame = ofGame } or nil
end

function dbmColors.Forget(eventID)
    kinds[eventID] = nil
end

function dbmColors.ForgetGameEvents()
    for eventID, entry in pairs(kinds) do
        if entry.ofGame then
            kinds[eventID] = nil
        end
    end
end

function dbmColors.ColorOf(eventID)
    local entry = kinds[eventID]
    if not entry or entry.kind < FIRST_OWN_COLOR or not ns.options.Get(SETTING_KEY) then
        return nil
    end
    local bars = _G.DBT
    if type(bars) ~= "table" or not bars.GetColorForType or type(bars.Options) ~= "table" or not bars.Options.ColorByType then
        return nil
    end
    local ok, red, green, blue = pcall(bars.GetColorForType, bars, entry.kind)
    if not ok or type(red) ~= "number" or type(green) ~= "number" or type(blue) ~= "number" then
        return nil
    end
    return { r = red, g = green, b = blue, a = FULL_OPACITY }
end

function dbmColors.Enable()
    ns.eventStyle.AddColorSource(dbmColors.ColorOf)
    ns.options.OnChanged(function(key)
        if key == SETTING_KEY then
            for eventID in pairs(kinds) do
                ns.timeline.RefreshEventName(eventID)
            end
        end
    end)
end
