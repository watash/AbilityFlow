local addonName, ns = ...

local CreateFrame = CreateFrame
local IsEncounterInProgress = IsEncounterInProgress

local L = ns.L

local pullCountdown = {}
ns.pullCountdown = pullCountdown

local slot = ns.eventSlot.New(L.PULL_TIMER)

local MIN_PULL_SECONDS = 3
local PULL_ICON_FILE_ID = 132337

function pullCountdown.Started(seconds, initiator, guid)
    if not ns.options.Get("showPullTimer") or IsEncounterInProgress() or type(seconds) ~= "number" or seconds < MIN_PULL_SECONDS then
        return
    end
    slot.Start(seconds, L.PULL_TIMER, PULL_ICON_FILE_ID, ns.playerName.Caption(initiator, guid))
end

function pullCountdown.Stopped()
    slot.Stop()
end

ns.options.OnChanged(function(key, value)
    if key == "showPullTimer" and not value then
        slot.Stop()
    end
end)

local frame = CreateFrame("Frame")
frame:RegisterEvent("START_PLAYER_COUNTDOWN")
frame:RegisterEvent("CANCEL_PLAYER_COUNTDOWN")
frame:RegisterEvent("ENCOUNTER_START")
frame:SetScript("OnEvent", function(_, event, ...)
    if event == "START_PLAYER_COUNTDOWN" then
        local guid, seconds, _, _, initiator = ...
        if not issecretvalue(seconds) then
            pullCountdown.Started(seconds, not issecretvalue(initiator) and initiator or nil,
                not issecretvalue(guid) and guid or nil)
        end
    else
        pullCountdown.Stopped()
    end
end)
