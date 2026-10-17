local addonName, ns = ...

local eventColors = {}
ns.eventColors = eventColors

local TRIGGER = Enum.EncounterEventColorTrigger.TextWarning

local coloured = {}
local enabled = false
local defaultColor = { r = 1, g = 1, b = 1, a = 1 }

local function apply()
    for _, encounterEventID in ipairs(C_EncounterEvents.GetEventList()) do
        local info = C_EncounterEvents.GetEventInfo(encounterEventID)
        local mask = info and info.icons
        local color = defaultColor
        if mask and not issecretvalue(mask) and mask ~= 0 then
            local entry = ns.debuff.FindType(mask)
            color = entry and entry.color or defaultColor
        end
        C_EncounterEvents.SetEventColor(encounterEventID, TRIGGER, CreateColor(color.r, color.g, color.b, color.a))
        coloured[encounterEventID] = true
    end
end

local function reset()
    for encounterEventID in pairs(coloured) do
        C_EncounterEvents.SetEventColor(encounterEventID, TRIGGER)
    end
    wipe(coloured)
end

function eventColors.SetEnabled(value, textColor)
    local changed = false
    if textColor and (textColor.r ~= defaultColor.r or textColor.g ~= defaultColor.g or textColor.b ~= defaultColor.b
        or textColor.a ~= defaultColor.a) then
        defaultColor = { r = textColor.r, g = textColor.g, b = textColor.b, a = textColor.a }
        changed = true
    end
    if value == enabled and not (value and changed) then
        return
    end
    enabled = value
    if value then
        apply()
    else
        reset()
    end
end
