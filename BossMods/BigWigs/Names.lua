local addonName, ns = ...

local C_Timer = C_Timer
local CreateFrame = CreateFrame
local GetTime = GetTime
local ipairs = ipairs
local issecretvalue = issecretvalue
local math = math
local pairs = pairs
local select = select

local bigWigsNames = {}
ns.bigWigsNames = bigWigsNames

local MESSAGE_START_BAR = "BigWigs_StartBar"
local EVENT_ID_PLACE = 9
local KEY_PLACE = 2
local TEXT_PLACE = 3
local SECONDS_PLACE = 4
local ICON_PLACE = 5
local LENGTH_TOLERANCE = 0.05
local SETTING_KEY = "showBossModNames"
local TIMELINE_NAMESPACE = "BigWigs_Plugins_Timeline"
local OWN_TIMER_MODES = { enhanced = true, dev = true }

local names = {}
local waitingBars = {}
local addedEvents = {}
local addedAt
local receiver = {}

function bigWigsNames.NameOf(eventID)
    if ns.options.Get(SETTING_KEY) then
        return names[eventID]
    end
    return nil
end

local function setName(eventID, text)
    names[eventID] = text
    ns.timeline.RefreshEventName(eventID)
    if ns.options.Get("hideGameEvents") and ns.options.Get(SETTING_KEY) then
        ns.timeline.RecheckEvent(eventID)
    end
end

local function sameLength(seconds, length)
    return math.abs(seconds - length) <= LENGTH_TOLERANCE
end

local function flushWaitingBars()
    local bars = waitingBars
    waitingBars = {}
    for _, bar in ipairs(bars) do
        ns.bigWigsTimers.Start(bar.sender, bar.text, bar.seconds, bar.icon)
    end
end

local function onStartBar(_, ...)
    local sender = ...
    local text = select(TEXT_PLACE, ...)
    if type(text) ~= "string" or issecretvalue(text) or text == "" or ns.bigWigsTimers.IsSkipped(sender) then
        return
    end
    ns.bigWigsTimers.Stop(text)
    local eventID = select(EVENT_ID_PLACE, ...)
    if type(eventID) == "number" then
        ns.bigWigsColors.Remember(eventID, sender, select(KEY_PLACE, ...), true)
        setName(eventID, text)
        return
    end
    local seconds = select(SECONDS_PLACE, ...)
    local icon = select(ICON_PLACE, ...)
    if type(seconds) ~= "number" or issecretvalue(seconds) then
        return
    end
    local key = select(KEY_PLACE, ...)
    if key ~= nil then
        ns.bigWigsTimers.Start(sender, text, seconds, icon, key)
        return
    end
    if addedAt == GetTime() then
        for id, length in pairs(addedEvents) do
            if sameLength(seconds, length) then
                setName(id, text)
                return
            end
        end
    end
    waitingBars[#waitingBars + 1] = { sender = sender, text = text, seconds = seconds, icon = icon, at = GetTime() }
    if #waitingBars == 1 then
        C_Timer.After(0, flushWaitingBars)
    end
end

local function onEventAdded(eventInfo)
    if eventInfo.source ~= Enum.EncounterTimelineEventSource.Encounter or issecretvalue(eventInfo.duration) then
        return
    end
    local now = GetTime()
    for index, bar in ipairs(waitingBars) do
        if bar.at == now and sameLength(bar.seconds, eventInfo.duration) then
            setName(eventInfo.id, bar.text)
            table.remove(waitingBars, index)
            return
        end
    end
    if addedAt ~= now then
        addedEvents = {}
        addedAt = now
    end
    addedEvents[eventInfo.id] = eventInfo.duration
end

function bigWigsNames.Enable()
    local loader = _G.BigWigsLoader
    if not loader or not loader.RegisterMessage then
        return
    end
    loader.RegisterMessage(receiver, MESSAGE_START_BAR, onStartBar)
    ns.timeline.AddNameSource(bigWigsNames.NameOf)
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("ENCOUNTER_TIMELINE_EVENT_ADDED")
    frame:RegisterEvent("ENCOUNTER_START")
    frame:SetScript("OnEvent", function(_, event, eventInfo)
        if event == "ENCOUNTER_START" then
            names = {}
            ns.bigWigsColors.ForgetGameEvents()
        else
            onEventAdded(eventInfo)
        end
    end)
    ns.options.OnChanged(function(key)
        if key == SETTING_KEY then
            for eventID in pairs(names) do
                ns.timeline.RefreshEventName(eventID)
            end
        end
    end)
end

function bigWigsNames.IsAvailable()
    local loader = _G.BigWigsLoader
    return loader ~= nil and loader.RegisterMessage ~= nil
end

function bigWigsNames.UsesOwnTimers()
    local loader = _G.BigWigsLoader
    local saved = _G.BigWigs3DB
    if not loader or not loader.db or not loader.db.GetCurrentProfile or type(saved) ~= "table" then
        return true
    end
    local namespace = type(saved.namespaces) == "table" and saved.namespaces[TIMELINE_NAMESPACE]
    local profiles = type(namespace) == "table" and namespace.profiles
    local profile = type(profiles) == "table" and profiles[loader.db:GetCurrentProfile()]
    local mode = type(profile) == "table" and profile.timersMode or nil
    return mode == nil or OWN_TIMER_MODES[mode] == true
end
