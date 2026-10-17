local addonName, ns = ...

local C_EncounterTimeline = C_EncounterTimeline
local Enum = Enum
local pairs = pairs
local pcall = pcall

local timeline = ns.timeline

local dbmTimers = {}
ns.dbmTimers = dbmTimers

local CALLBACK_STOP = "DBM_TimerStop"
local CALLBACK_PAUSE = "DBM_TimerPause"
local CALLBACK_RESUME = "DBM_TimerResume"
local CALLBACK_UPDATE = "DBM_TimerUpdate"
local SETTING_KEY = "showBossModTimers"
local SEVERITY = Enum.EncounterEventSeverity.High

local shown = {}

function dbmTimers.Stop(timerID)
    local entry = shown[timerID]
    if not entry then
        return
    end
    shown[timerID] = nil
    ns.dbmColors.Forget(entry.id)
    if C_EncounterTimeline.GetEventInfo(entry.id) then
        C_EncounterTimeline.CancelScriptEvent(entry.id)
    end
    if AbilityFlowDB.dbmTimerIDs then
        AbilityFlowDB.dbmTimerIDs[entry.id] = nil
    end
end

function dbmTimers.Start(timerID, text, seconds, icon, colorKind)
    dbmTimers.Stop(timerID)
    if not ns.options.Get(SETTING_KEY) or seconds <= 0 then
        return
    end
    local id = C_EncounterTimeline.AddScriptEvent({
        duration = seconds,
        maxQueueDuration = 0,
        overrideName = text,
        spellID = 0,
        iconFileID = icon,
        severity = SEVERITY,
        paused = false,
    })
    if not id then
        return
    end
    timeline.MarkLongEvent(id)
    shown[timerID] = { id = id, text = text, icon = icon, colorKind = colorKind }
    ns.dbmColors.Remember(id, colorKind)
    timeline.RefreshEventName(id)
    AbilityFlowDB.dbmTimerIDs = AbilityFlowDB.dbmTimerIDs or {}
    AbilityFlowDB.dbmTimerIDs[id] = true
end

local function setPaused(timerID, pause)
    local entry = type(timerID) == "string" and shown[timerID]
    if entry then
        pcall(pause and C_EncounterTimeline.PauseScriptEvent or C_EncounterTimeline.ResumeScriptEvent, entry.id)
    end
end

local function onUpdate(_, timerID, elapsed, total)
    local entry = type(timerID) == "string" and shown[timerID]
    if entry and type(elapsed) == "number" and type(total) == "number" then
        dbmTimers.Start(timerID, entry.text, total - elapsed, entry.icon, entry.colorKind)
    end
end

function dbmTimers.Enable()
    for id in pairs(AbilityFlowDB.dbmTimerIDs or {}) do
        pcall(C_EncounterTimeline.CancelScriptEvent, id)
    end
    AbilityFlowDB.dbmTimerIDs = nil
    if ns.bossMods.Active() ~= ns.bossMods.DBM then
        return
    end
    local addon = _G.DBM
    addon:RegisterCallback(CALLBACK_STOP, function(_, timerID)
        if type(timerID) == "string" then
            dbmTimers.Stop(timerID)
        end
    end)
    addon:RegisterCallback(CALLBACK_PAUSE, function(_, timerID)
        setPaused(timerID, true)
    end)
    addon:RegisterCallback(CALLBACK_RESUME, function(_, timerID)
        setPaused(timerID, false)
    end)
    addon:RegisterCallback(CALLBACK_UPDATE, onUpdate)
    ns.options.OnChanged(function(key, value)
        if key == SETTING_KEY and not value then
            for timerID in pairs(shown) do
                dbmTimers.Stop(timerID)
            end
        end
    end)
end
