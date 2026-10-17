local addonName, ns = ...

local tonumber = tonumber

local dbm = {}
ns.DBM = dbm

local CALLBACK_TIMER_BEGIN = "DBM_TimerBegin"
local CALLBACK_TIMER_STOP = "DBM_TimerStop"
local KIND_BREAK = "break"

local breakTimerID

local function iconFile(icon)
    if type(icon) == "number" then
        return icon
    end
    return type(icon) == "string" and tonumber(icon) or nil
end

local function onTimerBegin(_, id, text, seconds, icon, kind, _, _, _, _, _, _, _, _, _, _, _, _, barEnabled)
    if kind ~= KIND_BREAK or not barEnabled then
        return
    end
    breakTimerID = id
    ns.breakTimer.Start(seconds, text, iconFile(icon))
end

local function onTimerStop(_, id)
    if breakTimerID and id == breakTimerID then
        breakTimerID = nil
        ns.breakTimer.Stop()
    end
end

function dbm.Enable()
    local addon = _G.DBM
    if not addon or not addon.RegisterCallback then
        return
    end
    addon:RegisterCallback(CALLBACK_TIMER_BEGIN, onTimerBegin)
    addon:RegisterCallback(CALLBACK_TIMER_STOP, onTimerStop)
end
