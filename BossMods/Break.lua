local addonName, ns = ...

local C_Timer = C_Timer
local CreateFrame = CreateFrame
local PlaySound = PlaySound

local L = ns.L

local slot = ns.eventSlot.New(L.BREAK_TIMER)

local breakTimer = {}
ns.breakTimer = breakTimer

local BREAK_ICON_FILE_ID = 134062
local START_SOUND_KIT = 8959
local END_SOUND_KIT = 8960
local SOUND_CHANNEL = "Master"

local endTimer

local function cancelEndSound()
    if endTimer then
        endTimer:Cancel()
        endTimer = nil
    end
end

function breakTimer.Start(seconds, text, icon, initiator, guid, withSound)
    if not ns.options.Get("showBreak") then
        return
    end
    cancelEndSound()
    slot.Start(seconds, text, icon or BREAK_ICON_FILE_ID, ns.playerName.Caption(initiator, guid))
    if withSound and type(seconds) == "number" and seconds > 0 then
        PlaySound(START_SOUND_KIT, SOUND_CHANNEL)
        endTimer = C_Timer.NewTimer(seconds, function()
            endTimer = nil
            PlaySound(END_SOUND_KIT, SOUND_CHANNEL)
        end)
    end
end

function breakTimer.Stop()
    cancelEndSound()
    slot.Stop()
end

ns.options.OnChanged(function(key, value)
    if key == "showBreak" and not value then
        breakTimer.Stop()
    end
end)

local frame = CreateFrame("Frame")
frame:RegisterEvent("ENCOUNTER_START")
frame:SetScript("OnEvent", breakTimer.Stop)
