local addonName, ns = ...

local GetPlayerInfoByGUID = GetPlayerInfoByGUID
local UnitClass = UnitClass
local RAID_CLASS_COLORS = RAID_CLASS_COLORS

local L = ns.L

local playerName = {}
ns.playerName = playerName

local REALM_SEPARATOR_PATTERN = "^([^%-]+)"
local COLOR_START = "|c"
local COLOR_END = "|r"

local function classOf(name, guid)
    if type(guid) == "string" and not issecretvalue(guid) then
        local _, classFile = GetPlayerInfoByGUID(guid)
        if type(classFile) == "string" then
            return classFile
        end
    end
    local _, classFile = UnitClass(name)
    if type(classFile) == "string" and not issecretvalue(classFile) then
        return classFile
    end
    return nil
end

local function written(name, guid)
    local text = L.INITIATOR_CAPTION:format(name:match(REALM_SEPARATOR_PATTERN) or name)
    local color = ns.options.Get("useClassColors") and RAID_CLASS_COLORS[classOf(name, guid) or ""]
    if color and color.colorStr then
        text = COLOR_START .. color.colorStr .. text .. COLOR_END
    end
    return text
end

function playerName.Caption(name, guid)
    if type(name) ~= "string" or issecretvalue(name) or name == "" then
        return nil
    end
    local lastColors, lastText
    return function()
        if not ns.options.Get("showInitiator") then
            return nil
        end
        local colors = ns.options.Get("useClassColors")
        if lastText == nil or colors ~= lastColors then
            lastColors, lastText = colors, written(name, guid)
        end
        return lastText
    end
end
