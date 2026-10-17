local addonName, ns = ...

local C_Spell = C_Spell
local CreateFrame = CreateFrame
local GetTime = GetTime
local select = select

local L = ns.L
local timeline = ns.timeline

local respawnName = {}
ns.respawnName = respawnName

local RESPAWN_SPELL_ID = 1262959

local respawns = {}
local wipeAt

function respawnName.NameOf(eventID)
    if not respawns[eventID] then
        return nil
    end
    local name = C_Spell.GetSpellName(RESPAWN_SPELL_ID)
    return type(name) == "string" and name ~= "" and name or L.RESPAWN_EVENT
end

function respawnName.Enable()
    C_Spell.RequestLoadSpellData(RESPAWN_SPELL_ID)
    timeline.AddNameSource(respawnName.NameOf, true)
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("ENCOUNTER_END")
    frame:RegisterEvent("ENCOUNTER_START")
    frame:RegisterEvent("ENCOUNTER_TIMELINE_EVENT_ADDED")
    frame:SetScript("OnEvent", function(_, event, first, ...)
        if event == "ENCOUNTER_END" then
            local success = select(4, ...)
            wipeAt = success ~= 1 and GetTime() or nil
        elseif event == "ENCOUNTER_START" then
            respawns = {}
            wipeAt = nil
        elseif first.source == Enum.EncounterTimelineEventSource.Encounter and wipeAt == GetTime() then
            respawns[first.id] = true
            timeline.RefreshEventName(first.id)
            if ns.options.Get("hideGameEvents") then
                timeline.RecheckEvent(first.id)
            end
        end
    end)
end
