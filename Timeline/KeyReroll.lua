local addonName, ns = ...

local CreateFrame = CreateFrame
local C_ChallengeMode = C_ChallengeMode
local C_MythicPlus = C_MythicPlus
local C_PartyInfo = C_PartyInfo
local Enum = Enum

local L = ns.L

local keyReroll = {}
ns.keyReroll = keyReroll

local REROLL_SECONDS = 300
local KEYSTONE_ICON_FILE_ID = 4352494

local slot = ns.eventSlot.New(L.KEY_REROLL)

local keyAtEnd

local function ownedKey()
    local mapID = C_MythicPlus.GetOwnedKeystoneChallengeMapID()
    local level = C_MythicPlus.GetOwnedKeystoneLevel()
    if not mapID or not level then
        return nil
    end
    return mapID .. ":" .. level
end

function keyReroll.Start()
    local key = ownedKey()
    if not ns.options.Get("showKeyReroll") or not key then
        return
    end
    slot.Start(REROLL_SECONDS, L.KEY_REROLL, KEYSTONE_ICON_FILE_ID, nil, Enum.EncounterEventIconmask.DeadlyEffect)
    keyAtEnd = key
end

function keyReroll.Completed()
    local info = C_ChallengeMode.GetChallengeCompletionInfo()
    if not info or issecretvalue(info.onTime) or not info.onTime then
        return
    end
    local isOwner = C_PartyInfo.IsChallengeModeKeystoneOwner()
    if issecretvalue(isOwner) or isOwner then
        return
    end
    keyReroll.Start()
end

function keyReroll.BagsChanged()
    if keyAtEnd and ownedKey() ~= keyAtEnd then
        keyReroll.Left()
    end
end

function keyReroll.Left()
    keyAtEnd = nil
    slot.Stop()
end

ns.options.OnChanged(function(key, value)
    if key == "showKeyReroll" and not value then
        slot.Stop()
    end
end)

local frame = CreateFrame("Frame")
frame:RegisterEvent("CHALLENGE_MODE_COMPLETED")
frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
frame:RegisterEvent("BAG_UPDATE_DELAYED")
frame:SetScript("OnEvent", function(_, event)
    if event == "CHALLENGE_MODE_COMPLETED" then
        keyReroll.Completed()
    elseif event == "BAG_UPDATE_DELAYED" then
        keyReroll.BagsChanged()
    else
        keyReroll.Left()
    end
end)
