local addonName, ns = ...

local Ambiguate = Ambiguate
local C_ChatInfo = C_ChatInfo
local CreateFrame = CreateFrame
local IsEncounterInProgress = IsEncounterInProgress
local UnitIsGroupAssistant = UnitIsGroupAssistant
local UnitIsGroupLeader = UnitIsGroupLeader

local L = ns.L

local breakMessages = {}
ns.breakMessages = breakMessages

local noBossMod = false
local PREFIX_BIGWIGS = "BigWigs"
local PREFIX_DBM = "D5"
local PATTERNS = {
    [PREFIX_BIGWIGS] = "^P%^Break%^(%d+)",
    [PREFIX_DBM] = "^[^\t]*\t[^\t]*\tBT\t(%d+)",
}
local MAX_BREAK_SECONDS = 3600
local CHANNELS = { RAID = true, PARTY = true, INSTANCE_CHAT = true }

function breakMessages.SecondsOf(prefix, text)
    local pattern = PATTERNS[prefix]
    local seconds = pattern and type(text) == "string" and tonumber(text:match(pattern))
    if seconds and seconds >= 0 and seconds <= MAX_BREAK_SECONDS then
        return seconds
    end
    return nil
end

local function onMessage(prefix, text, channel, sender)
    if not CHANNELS[channel] or issecretvalue(text) or issecretvalue(sender) then
        return
    end
    local seconds = breakMessages.SecondsOf(prefix, text)
    if not seconds or IsEncounterInProgress() then
        return
    end
    local name = Ambiguate(sender, "none")
    if not (UnitIsGroupLeader(name) or UnitIsGroupAssistant(name)) then
        return
    end
    if seconds == 0 then
        ns.breakTimer.Stop()
    else
        ns.breakTimer.Start(seconds, L.BREAK_TIMER, nil, name, UnitGUID(name), noBossMod)
    end
end

function breakMessages.Enable()
    local hasBigWigs = _G.BigWigsLoader ~= nil
    local hasDBM = _G.DBM ~= nil
    noBossMod = not hasBigWigs and not hasDBM
    local prefixes = {}
    if not hasBigWigs then
        prefixes[#prefixes + 1] = PREFIX_BIGWIGS
    end
    if not hasBigWigs and not hasDBM then
        prefixes[#prefixes + 1] = PREFIX_DBM
    end
    if #prefixes == 0 then
        return
    end
    for _, prefix in ipairs(prefixes) do
        C_ChatInfo.RegisterAddonMessagePrefix(prefix)
    end
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("CHAT_MSG_ADDON")
    frame:SetScript("OnEvent", function(_, _, prefix, text, channel, sender)
        onMessage(prefix, text, channel, sender)
    end)
end
