local addonName, ns = ...

local CreateFrame = CreateFrame
local C_Spell = C_Spell

local L = ns.L

local readyCheck = {}
ns.readyCheck = readyCheck

local slot = ns.eventSlot.New(L.READY_CHECK, ns.timeline.PLACE_EXIT)

local READY_CHECK_ICON_SPELL_ID = 97462

function readyCheck.Started(initiator, seconds)
    if not ns.options.Get("showReadyCheck") or type(seconds) ~= "number" then
        return
    end
    local caption = ns.playerName.Caption(initiator)
    slot.Start(seconds, L.READY_CHECK, C_Spell.GetSpellTexture(READY_CHECK_ICON_SPELL_ID), caption)
end

function readyCheck.Finished()
    slot.Stop()
end

ns.options.OnChanged(function(key, value)
    if key == "showReadyCheck" and not value then
        slot.Stop()
    end
end)

local frame = CreateFrame("Frame")
frame:RegisterEvent("READY_CHECK")
frame:RegisterEvent("READY_CHECK_FINISHED")
frame:SetScript("OnEvent", function(_, event, initiator, seconds)
    if event == "READY_CHECK" then
        readyCheck.Started(not issecretvalue(initiator) and initiator or nil, not issecretvalue(seconds) and seconds or nil)
    else
        readyCheck.Finished()
    end
end)
