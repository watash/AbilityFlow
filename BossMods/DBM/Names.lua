local addonName, ns = ...

local C_Timer = C_Timer
local CreateFrame = CreateFrame
local GetFileIDFromPath = GetFileIDFromPath
local GetTime = GetTime
local ipairs = ipairs
local issecretvalue = issecretvalue
local math = math
local pairs = pairs
local tonumber = tonumber

local timeline = ns.timeline

local dbmNames = {}
ns.dbmNames = dbmNames

local CALLBACK_BEGIN = "DBM_TimerBegin"
local SETTING_KEY = "showBossModNames"
local SKIPPED_KINDS = { pull = true, ["break"] = true }
local SKIPPED_IDS = { DBMLFGTimer = true, DBMBFSTimer = true }
local LENGTH_TOLERANCE = 0.55

local names = {}
local addedEvents = {}
local addedAt
local waiting = {}

function dbmNames.NameOf(eventID)
    if ns.options.Get(SETTING_KEY) then
        return names[eventID]
    end
    return nil
end

local function sameLength(seconds, length)
    return math.abs(seconds - length) <= LENGTH_TOLERANCE
end

local function setName(eventID, text, colorKind)
    names[eventID] = text
    ns.dbmColors.Remember(eventID, colorKind, true)
    timeline.RefreshEventName(eventID)
    if ns.options.Get("hideGameEvents") and ns.options.Get(SETTING_KEY) then
        timeline.RecheckEvent(eventID)
    end
end

local function iconFile(icon)
    if type(icon) == "number" and not issecretvalue(icon) then
        return icon
    end
    if type(icon) == "string" and not issecretvalue(icon) then
        local number = tonumber(icon)
        if number then
            return number
        end
        if GetFileIDFromPath then
            local file = GetFileIDFromPath(icon)
            if type(file) == "number" then
                return file
            end
        end
    end
    return timeline.PLACEHOLDER_ICON_FILE_ID
end

local function flushWaiting()
    local timers = waiting
    waiting = {}
    for _, timer in ipairs(timers) do
        ns.dbmTimers.Start(timer.id, timer.text, timer.seconds, timer.icon, timer.colorKind)
    end
end

local function onBegin(_, timerID, text, seconds, icon, kind, _, colorKind, _, _, _, _, _, _, _, _, _, barEnabled, textOnly)
    colorKind = type(colorKind) == "number" and colorKind or nil
    if type(timerID) ~= "string" or SKIPPED_IDS[timerID] or SKIPPED_KINDS[kind] then
        return
    end
    if not barEnabled and not textOnly then
        return
    end
    ns.dbmTimers.Stop(timerID)
    if type(text) ~= "string" or issecretvalue(text) or text == "" or type(seconds) ~= "number" or issecretvalue(seconds) then
        return
    end
    local now = GetTime()
    if addedAt == now then
        for index = #addedEvents, 1, -1 do
            local event = addedEvents[index]
            if not event.named and sameLength(seconds, event.duration) then
                event.named = true
                setName(event.id, text, colorKind)
                return
            end
        end
    end
    waiting[#waiting + 1] = { id = timerID, text = text, seconds = seconds, icon = iconFile(icon), colorKind = colorKind,
        at = now }
    if #waiting == 1 then
        C_Timer.After(0, flushWaiting)
    end
end

local function onEventAdded(eventInfo)
    if eventInfo.source ~= Enum.EncounterTimelineEventSource.Encounter or issecretvalue(eventInfo.duration) then
        return
    end
    local now = GetTime()
    if addedAt ~= now then
        addedEvents = {}
        addedAt = now
    end
    for index, timer in ipairs(waiting) do
        if timer.at == now and sameLength(timer.seconds, eventInfo.duration) then
            table.remove(waiting, index)
            addedEvents[#addedEvents + 1] = { id = eventInfo.id, duration = eventInfo.duration, named = true }
            setName(eventInfo.id, timer.text, timer.colorKind)
            return
        end
    end
    addedEvents[#addedEvents + 1] = { id = eventInfo.id, duration = eventInfo.duration }
end

function dbmNames.Enable()
    if ns.bossMods.Active() ~= ns.bossMods.DBM then
        return
    end
    _G.DBM:RegisterCallback(CALLBACK_BEGIN, onBegin)
    timeline.AddNameSource(dbmNames.NameOf)
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("ENCOUNTER_TIMELINE_EVENT_ADDED")
    frame:RegisterEvent("ENCOUNTER_START")
    frame:SetScript("OnEvent", function(_, event, eventInfo)
        if event == "ENCOUNTER_START" then
            names = {}
            ns.dbmColors.ForgetGameEvents()
        else
            onEventAdded(eventInfo)
        end
    end)
    ns.options.OnChanged(function(key)
        if key == SETTING_KEY then
            for eventID in pairs(names) do
                timeline.RefreshEventName(eventID)
            end
        end
    end)
end

function dbmNames.BarsHiddenInDbm()
    local options = type(_G.DBM) == "table" and _G.DBM.Options
    return type(options) == "table" and options.HideDBMBars == true and not options.TextTimersEnabled
end

function dbmNames.IsAvailable()
    local addon = _G.DBM
    return type(addon) == "table" and addon.RegisterCallback ~= nil
end
