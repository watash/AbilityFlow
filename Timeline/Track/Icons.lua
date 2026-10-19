local addonName, ns = ...

local timeline = ns.timeline
local state = timeline.state
local frame = timeline.frame

local TENTHS_PER_SECOND = 10
local EVENT_LEVEL_BLOCK = 20
timeline.EVENT_LEVEL_BLOCK = EVENT_LEVEL_BLOCK
local ORIENTATION_HORIZONTAL = timeline.ORIENTATION_HORIZONTAL
local PHASE_CANCELING = timeline.PHASE_CANCELING

local eventsMade = 0

local function resetFlow(event)
    event.flow = {
        phase = timeline.PHASE_LIVE,
        zone = nil,
        remaining = nil,
        paused = false,
        severity = nil,
        level = nil,
        lane = 0,
        laneShift = 0,
        blocked = false,
        lastRemaining = nil,
        docked = nil,
        drawn = nil,
        exitFrom = nil,
        dimmed = nil,
        slideFrom = nil,
        slideStart = nil,
        slideLeft = nil,
        introStart = nil,
        introDone = nil,
        cancelStart = nil,
        shownSeconds = nil,
        shownTenths = nil,
        showTenths = nil,
        countdownHidden = nil,
    }
end

local applyTimerStyle

local function applyEventAppearance(event)
    local size = timeline.currentIconSize()
    event:SetSize(size, size)
    local crop = timeline.currentCrop()
    event.texture:SetTexCoord(crop, 1 - crop, crop, 1 - crop)
    ns.eventStyle.Apply(event)
    ns.statusMark.Layout(event)
    ns.deadlyGlow.Layout(event)
    event.cooldownHolder:SetShown(ns.eventStyle.state.texts.cooldown.enabled)
    ns.eventStyle.ShowName(event, state.orientation ~= ORIENTATION_HORIZONTAL and ns.eventStyle.state.texts.name.enabled)
    if event.flow.lastRemaining then
        applyTimerStyle(event, event.flow.lastRemaining)
    end
end

function timeline.applyToAllEvents()
    for _, event in pairs(state.activeEvents) do
        applyEventAppearance(event)
    end
    for _, event in ipairs(state.eventPool) do
        applyEventAppearance(event)
    end
end

local function createEvent()
    local level = frame:GetFrameLevel() + 2 + (eventsMade + 1) * EVENT_LEVEL_BLOCK
    local event = ns.eventFrame.Create(frame, level)
    event.baseLevel = level
    eventsMade = eventsMade + 1
    resetFlow(event)
    ns.eventStyle.Decorate(event)
    timeline.setupTooltip(event)
    timeline.buildFinishAnimation(event)

    applyEventAppearance(event)
    return event
end

function applyTimerStyle(event, remaining)
    if ns.statusMark.IsOn(event) then
        return
    end
    local template = ns.timerStyle.TemplateFor(remaining)
    event.flow.showTenths = template ~= nil and template.tenths == true
    ns.eventStyle.PaintCountdown(event, template, timeline.currentIconSize())
end

local function stopTimerStyle(event)
    event.flow.showTenths, event.flow.shownTenths = nil, nil
    ns.timerPaint.Stop(event)
end

function timeline.updateCountdown(event, remaining)
    local flow = event.flow
    if ns.statusMark.HasSign(event) then
        if not flow.countdownHidden then
            flow.countdownHidden = true
            flow.shownSeconds = nil
            flow.lastRemaining = nil
            event.texts.cooldown:SetText("")
            stopTimerStyle(event)
        end
        return
    end
    flow.countdownHidden = nil
    local seconds = math.ceil(remaining)
    if event.flow.shownSeconds ~= seconds then
        local previous = event.flow.shownSeconds
        event.flow.shownSeconds = seconds
        event.flow.lastRemaining = remaining
        event.texts.cooldown:SetText(seconds > 0 and ns.countdownFormat.Of(seconds) or "")
        event.flow.shownTenths = nil
        applyTimerStyle(event, remaining)
        if previous and ns.timerStyle.FlashesAt(seconds) then
            ns.eventEffects.PlayFlash(event, state.iconBaseSize)
        end
    end
end

function timeline.updateTenths(event, remaining)
    if event.flow.countdownHidden or not event.flow.showTenths then
        return
    end
    local tenths = math.ceil(remaining * TENTHS_PER_SECOND)
    if event.flow.shownTenths ~= tenths then
        event.flow.shownTenths = tenths
        event.texts.cooldown:SetText(tenths > 0 and ("%.1f"):format(tenths / TENTHS_PER_SECOND) or "")
    end
end

local nameSources = {}

local function ownName(eventID)
    for _, source in ipairs(nameSources) do
        local name = source(eventID)
        if name ~= nil then
            return name
        end
    end
    return nil
end

local function nameOf(eventID, gameName)
    return ownName(eventID) or gameName
end

function timeline.AddNameSource(source, first)
    table.insert(nameSources, first and 1 or #nameSources + 1, source)
end

function timeline.HasOwnName(eventID)
    return ownName(eventID) ~= nil
end

function timeline.RefreshEventName(eventID)
    local event = state.activeEvents[eventID]
    local eventInfo = event and C_EncounterTimeline.GetEventInfo(eventID)
    if eventInfo then
        event.texts.name:SetText(nameOf(eventID, eventInfo.spellName))
        ns.eventStyle.RefreshOwnColors(event)
        if event.flow.lastRemaining then
            applyTimerStyle(event, event.flow.lastRemaining)
        end
    end
end

function timeline.AddEvent(eventInfo)
    local eventID = eventInfo.id
    local existing = state.activeEvents[eventID]
    if existing then
        if existing.flow.phase ~= PHASE_CANCELING then
            return
        end
        timeline.RemoveEvent(eventID)
    end

    local event = table.remove(state.eventPool) or createEvent()
    event.texture:SetTexture(eventInfo.iconFileID)
    event.texts.name:SetText(nameOf(eventID, eventInfo.spellName))
    event.spellID = eventInfo.spellID
    event.texts.cooldown:SetText("")
    resetFlow(event)
    event:SetAlpha(1)
    stopTimerStyle(event)
    ns.eventStyle.Assign(event, eventInfo)
    ns.deadlyGlow.Apply(event)
    event:Hide()

    event.flow.paused = C_EncounterTimeline.GetEventState(eventID) == Enum.EncounterTimelineEventState.Paused
    if not issecretvalue(eventInfo.severity) then
        event.flow.severity = eventInfo.severity
    end
    state.activeEvents[eventID] = event
    state.activeCount = state.activeCount + 1
    if state.activeCount == 1 then
        timeline.appear()
        frame:SetScript("OnUpdate", timeline.updateEvents)
    end
end

function timeline.SetEventPaused(eventID, paused)
    local event = state.activeEvents[eventID]
    if event then
        event.flow.paused = paused
    end
end

function timeline.HasEvents()
    return state.activeCount > 0
end

function timeline.RemoveEvent(eventID)
    local event = state.activeEvents[eventID]
    if not event then
        return
    end

    state.activeEvents[eventID] = nil
    state.activeCount = state.activeCount - 1
    state.captions[eventID] = nil
    state.limitedEvents[eventID] = nil
    if state.longEvents[eventID] then
        state.longEvents[eventID] = nil
        for index, markedID in ipairs(state.longOrder) do
            if markedID == eventID then
                table.remove(state.longOrder, index)
                break
            end
        end
    end
    event.eventID = nil
    event.spellID = nil
    timeline.clearTooltip(event)
    if event.nameFlipped then
        event.nameFlipped = nil
        ns.eventStyle.PlaceName(event)
    end
    if event.flow.level and (event.flow.level ~= event.baseLevel or event.flow.indicatorLevel) then
        ns.eventFrame.SetLevel(event, event.baseLevel)
    end
    resetFlow(event)
    ns.statusMark.Clear(event)
    timeline.clearTrail(event)
    ns.deadlyGlow.Clear(event)
    event.finishFade:Stop()
    event.finishGrow:Stop()
    event.container:SetScale(1)
    event.container:SetAlpha(1)
    event.cooldownHolder:SetAlpha(1)
    event:SetAlpha(1)
    stopTimerStyle(event)
    event:Hide()
    table.insert(state.eventPool, event)

    if state.activeCount == 0 then
        frame:SetScript("OnUpdate", nil)
        timeline.disappear()
    end
end

function timeline.RefreshDeadlyGlow()
    for _, event in pairs(state.activeEvents) do
        ns.deadlyGlow.Apply(event)
    end
end

function timeline.RefreshTimerStyle()
    for _, event in pairs(state.activeEvents) do
        if event.flow.lastRemaining then
            applyTimerStyle(event, event.flow.lastRemaining)
        end
    end
end
