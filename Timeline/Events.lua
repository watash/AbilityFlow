local addonName, ns = ...

local ipairs = ipairs
local pcall = pcall

local timeline = ns.timeline

timeline.PLACEHOLDER_ICON_FILE_ID = 134400

local DEMO_QUEUE_SECONDS = 20
local DEMO_RESUME_SECONDS = 3
local DEMO_PAUSE_AGAIN_REMAINING = 2
local DEMO_DANGER_INDEX = 2
local DEMO_SEVERITY = Enum.EncounterEventSeverity.Medium
local DEMO_LANE_INDEX = 3
local DEMO_LANE_SEVERITY = Enum.EncounterEventSeverity.High
local DEMO_PULL_SECONDS = 12
local STATE_PAUSED = Enum.EncounterTimelineEventState.Paused
local STATE_FINISHED = Enum.EncounterTimelineEventState.Finished
local STATE_CANCELED = Enum.EncounterTimelineEventState.Canceled
local HIDE_QUEUED_CVAR = "encounterTimelineHideQueuedCountdowns"
local TIMELINE_CVAR = "encounterTimelineEnabled"

local function keepTimelineOn()
    if C_CVar.GetCVar(TIMELINE_CVAR) ~= "1" then
        C_CVar.SetCVar(TIMELINE_CVAR, "1")
    end
end

local function hideEvent(eventID)
    timeline.CancelEvent(eventID)
end

local function isHiddenTrack(eventID, source)
    if source == Enum.EncounterTimelineEventSource.Script then
        return false
    end
    if source == Enum.EncounterTimelineEventSource.Encounter and ns.options.Get("hideGameEvents")
        and not timeline.HasOwnName(eventID) then
        return true
    end
    local track = C_EncounterTimeline.GetEventTrack(eventID)
    if not track or track == Enum.EncounterTimelineTrack.Indeterminate then
        return true
    end
    return C_EncounterTimeline.GetTrackType(track) == Enum.EncounterTimelineTrackType.Hidden
end

local function tryAddEvent(eventInfo)
    if isHiddenTrack(eventInfo.id, eventInfo.source) then
        return
    end
    timeline.AddEvent(eventInfo)
end

local blizzardHooked = false

local function applyBlizzardVisibility()
    local blizzardBar = EncounterTimeline
    if not blizzardBar or blizzardBar:IsForbidden() then
        return
    end
    if not blizzardHooked then
        blizzardHooked = true
        blizzardBar:HookScript("OnShow", function(self)
            if ns.options.Get("hideBlizzardTimeline") then
                self:Hide()
            end
        end)
    end
    if ns.options.Get("hideBlizzardTimeline") then
        blizzardBar:Hide()
    end
end

function timeline.RecheckEvent(eventID)
    local eventInfo = C_EncounterTimeline.GetEventInfo(eventID)
    if eventInfo and eventInfo.source == Enum.EncounterTimelineEventSource.Encounter then
        if isHiddenTrack(eventID, eventInfo.source) then
            hideEvent(eventID)
        else
            tryAddEvent(eventInfo)
        end
    end
end

local function refreshGameEvents()
    for _, eventID in ipairs(C_EncounterTimeline.GetEventList()) do
        timeline.RecheckEvent(eventID)
    end
end

local handlers = {
    CVAR_UPDATE = function(name, value)
        if name == HIDE_QUEUED_CVAR then
            timeline.SetQueuedHidden(value == "1")
        elseif name == TIMELINE_CVAR and value ~= "1" then
            C_Timer.After(0, keepTimelineOn)
        end
    end,

    ADDON_LOADED = keepTimelineOn,
    PLAYER_ENTERING_WORLD = keepTimelineOn,
    ENCOUNTER_START = keepTimelineOn,

    ENCOUNTER_TIMELINE_EVENT_ADDED = function(eventInfo)
        tryAddEvent(eventInfo)
    end,

    ENCOUNTER_TIMELINE_EVENT_REMOVED = function(eventID)
        if not timeline.IsFinishing(eventID) then
            hideEvent(eventID)
        end
    end,

    ENCOUNTER_TIMELINE_EVENT_STATE_CHANGED = function(eventID)
        local state = C_EncounterTimeline.GetEventState(eventID)
        timeline.SetEventPaused(eventID, state == STATE_PAUSED)
        if state == STATE_FINISHED then
            timeline.FinishEvent(eventID)
        elseif state == STATE_CANCELED then
            hideEvent(eventID)
        end
    end,

    ENCOUNTER_TIMELINE_EVENT_TRACK_CHANGED = function(eventID)
        local eventInfo = C_EncounterTimeline.GetEventInfo(eventID)
        if not eventInfo then
            return
        end
        if isHiddenTrack(eventID, eventInfo.source) then
            hideEvent(eventID)
        else
            tryAddEvent(eventInfo)
        end
    end,
}

local eventFrame = CreateFrame("Frame")
eventFrame:SetScript("OnEvent", function(_, event, ...)
    handlers[event](...)
end)

function timeline.Enable()
    keepTimelineOn()
    timeline.ClearDemoEvents()

    applyBlizzardVisibility()
    timeline.SetTimeLimit(ns.options.Get("timeLimit"))
    timeline.SetQueuedHidden(C_CVar.GetCVar(HIDE_QUEUED_CVAR) == "1")
    ns.options.OnChanged(function(key, value)
        if key == "timeLimit" then
            timeline.SetTimeLimit(value)
        elseif key == "hideBlizzardTimeline" then
            applyBlizzardVisibility()
        elseif key == "hideGameEvents"
            or (key == "showBossModNames" and ns.options.Get("hideGameEvents")) then
            refreshGameEvents()
        end
    end)

    for eventName in pairs(handlers) do
        eventFrame:RegisterEvent(eventName)
    end
end

function timeline.AddDemoEvents(durations)
    local pool = {}
    for _, spellID in ipairs(ns.timerStyle.ICON_SPELLS) do
        pool[#pool + 1] = spellID
    end
    timeline.ClearDemoEvents()
    local showStates = #durations > 1
    for index, duration in ipairs(durations) do
        local spellID
        if #pool > 0 then
            spellID = table.remove(pool, math.random(#pool))
        end
        local eventID = C_EncounterTimeline.AddScriptEvent({
            duration = duration,
            maxQueueDuration = showStates and DEMO_QUEUE_SECONDS or 0,
            overrideName = spellID and C_Spell.GetSpellName(spellID) or addonName,
            spellID = 0,
            iconFileID = spellID and C_Spell.GetSpellTexture(spellID) or timeline.PLACEHOLDER_ICON_FILE_ID,
            severity = showStates and index == DEMO_LANE_INDEX and DEMO_LANE_SEVERITY or DEMO_SEVERITY,
            icons = showStates and index == DEMO_DANGER_INDEX and Enum.EncounterEventIconmask.DeadlyEffect or nil,
            paused = showStates and index == 1,
        })
        if eventID and showStates and index == 1 then
            local resumeAt = durations[3] and durations[3] > duration and durations[3] - duration or DEMO_RESUME_SECONDS
            local pausedAgainAt = resumeAt + duration - DEMO_PAUSE_AGAIN_REMAINING
            C_Timer.After(resumeAt, function()
                pcall(C_EncounterTimeline.ResumeScriptEvent, eventID)
            end)
            C_Timer.After(pausedAgainAt, function()
                pcall(C_EncounterTimeline.PauseScriptEvent, eventID)
            end)
            C_Timer.After(pausedAgainAt + DEMO_RESUME_SECONDS, function()
                pcall(C_EncounterTimeline.ResumeScriptEvent, eventID)
            end)
        end
        if eventID then
            AbilityFlowDB.demoEventIDs = AbilityFlowDB.demoEventIDs or {}
            table.insert(AbilityFlowDB.demoEventIDs, eventID)
        end
    end
    if showStates then
        ns.pullCountdown.Started(DEMO_PULL_SECONDS, UnitName("player"), UnitGUID("player"))
    end
end

function timeline.ToggleDemoPause()
    local eventID = AbilityFlowDB.demoEventIDs and AbilityFlowDB.demoEventIDs[1]
    if not eventID then
        return
    end
    if C_EncounterTimeline.GetEventState(eventID) == STATE_PAUSED then
        pcall(C_EncounterTimeline.ResumeScriptEvent, eventID)
    else
        pcall(C_EncounterTimeline.PauseScriptEvent, eventID)
    end
end

function timeline.ClearDemoEvents()
    for _, eventID in ipairs(AbilityFlowDB.demoEventIDs or {}) do
        pcall(C_EncounterTimeline.CancelScriptEvent, eventID)
    end
    AbilityFlowDB.demoEventIDs = nil
    ns.pullCountdown.Stopped()
end
