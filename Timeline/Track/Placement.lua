local addonName, ns = ...

local C_EncounterTimeline = C_EncounterTimeline
local Enum = Enum
local issecretvalue = issecretvalue
local ipairs = ipairs
local math = math
local pairs = pairs
local pcall = pcall
local table = table

local timeline = ns.timeline
local state = timeline.state

local PERCENT = 100
local TRACK_QUEUED = Enum.EncounterTimelineTrack.Queued
local TRACK_SHORT = Enum.EncounterTimelineTrack.Short
local TRACK_MEDIUM = Enum.EncounterTimelineTrack.Medium
local TRACK_LONG = Enum.EncounterTimelineTrack.Long
local TRACK_TYPE_HIDDEN = Enum.EncounterTimelineTrackType.Hidden
local ZONE_QUEUE = "queue"
local ZONE_ARRIVING = "arriving"
local ZONE_TRACK = timeline.ZONE_TRACK
local ZONE_EXIT = "exit"
local ZONE_HELD = "held"
local LANE_TRAIL_TOLERANCE = timeline.LANE_TRAIL_TOLERANCE
local TRACK_SPAN_SECONDS = timeline.TRACK_SPAN_SECONDS
local ORIENTATION_HORIZONTAL = timeline.ORIENTATION_HORIZONTAL
local PHASE_LIVE = timeline.PHASE_LIVE
local PHASE_FINISHING = timeline.PHASE_FINISHING
local PHASE_CANCELING = timeline.PHASE_CANCELING
local PLACE_ENTRY = timeline.PLACE_ENTRY
local PLACE_EXIT = timeline.PLACE_EXIT
local frame = timeline.frame

local queue = {}
local queueRemaining = {}
local held = {}
local heldIndex = {}

local function placeAlong(event, horizontal, along, across, slideAcross, slideAlong)
    slideAcross, slideAlong = slideAcross or 0, slideAlong or 0
    across = (across or 0) + slideAcross
    event.flow.drawn = along
    event:ClearAllPoints()
    if horizontal then
        event:SetPoint("CENTER", frame, "LEFT", along + slideAlong, across)
    else
        event:SetPoint("CENTER", frame, "BOTTOM", across, along + slideAlong)
    end
    if event.flow.nameCounter ~= slideAcross then
        event.flow.nameCounter = slideAcross
        local x, y = -slideAcross, 0
        if horizontal then
            x, y = 0, -slideAcross
        end
        event.nameAnchor:ClearAllPoints()
        event.nameAnchor:SetPoint("TOPLEFT", event, "TOPLEFT", x, y)
        event.nameAnchor:SetPoint("BOTTOMRIGHT", event, "BOTTOMRIGHT", x, y)
    end
end

local function zoneOf(eventID)
    local remaining = C_EncounterTimeline.GetEventTimeRemaining(eventID)
    if remaining == nil then
        return nil
    end
    local place = state.longEvents[eventID]
    if place == PLACE_EXIT then
        return ZONE_EXIT, remaining
    elseif place == PLACE_ENTRY then
        if remaining >= TRACK_SPAN_SECONDS + timeline.ArrivalLead() then
            return ZONE_QUEUE, remaining
        elseif remaining >= TRACK_SPAN_SECONDS then
            return ZONE_ARRIVING, remaining
        end
        return ZONE_TRACK, remaining
    end
    local track, sortIndex = C_EncounterTimeline.GetEventTrack(eventID)
    if track == TRACK_SHORT then
        return ZONE_TRACK, remaining
    elseif track == TRACK_MEDIUM then
        return ZONE_ARRIVING, remaining
    elseif track == TRACK_LONG or (track and remaining >= TRACK_SPAN_SECONDS
        and C_EncounterTimeline.GetTrackType(track) == TRACK_TYPE_HIDDEN) then
        if remaining > state.timeLimit then
            return nil
        end
        if remaining < TRACK_SPAN_SECONDS + timeline.ArrivalLead() then
            return ZONE_ARRIVING, remaining
        end
        return ZONE_QUEUE, remaining
    elseif track == TRACK_QUEUED then
        return ZONE_HELD, remaining, sortIndex
    end
    return nil
end

local function soonerFirst(a, b)
    local remainingA, remainingB = queueRemaining[a], queueRemaining[b]
    if remainingA ~= remainingB then
        return remainingA < remainingB
    end
    return a < b
end

local function nearerFirst(a, b)
    local indexA, indexB = heldIndex[a], heldIndex[b]
    if indexA ~= indexB then
        return indexA < indexB
    end
    return a > b
end

local function placeWaiting(event, horizontal, remaining, along, alpha)
    if event.flow.docked and event.flow.docked ~= along then
        timeline.startSlide(event, event.flow.docked - along)
    end
    event.flow.docked = along
    if event.flow.dimmed ~= alpha then
        event.flow.dimmed = alpha
        event.container:SetAlpha(alpha)
        event.cooldownHolder:SetAlpha(alpha)
    end
    placeAlong(event, horizontal, timeline.slidAlong(event, along), event.flow.laneShift,
        timeline.introOffset(event, event.flow.zone == ZONE_QUEUE))
    event:Show()
    timeline.updateCountdown(event, remaining)
end

local function placeArriving(event, horizontal, remaining, queueStart, trackStart)
    local lead = timeline.ArrivalLead()
    local progress = math.min(math.max((TRACK_SPAN_SECONDS + lead - remaining) / lead, 0), 1)
    local waitingAlpha = 1 - state.waitingTransparency / PERCENT
    local alpha = waitingAlpha + (1 - waitingAlpha) * progress
    event.container:SetAlpha(alpha)
    event.cooldownHolder:SetAlpha(alpha)
    event.flow.dimmed = waitingAlpha
    event.flow.docked, event.flow.slideStart, event.flow.slideLeft = nil, nil, nil
    local trackStep = (timeline.EntersFromStart() and -1 or 1) * state.trackLength / TRACK_SPAN_SECONDS * lead
    local along = queueStart + (trackStart - queueStart) * progress * progress * (3 - 2 * progress)
        + trackStep * progress * progress * (progress - 1)
    placeAlong(event, horizontal, along, nil, timeline.introOffset(event))
    event:Show()
    timeline.updateCountdown(event, remaining)
end

local function placeDocked(horizontal)
    local size = timeline.currentIconSize()
    local trackLength = state.trackLength
    local fromStart = timeline.EntersFromStart()
    local entryStep = timeline.WaitingStep(size)
    local trackStart = fromStart and trackLength or 0

    local count, heldCount = 0, 0
    for eventID, event in pairs(state.activeEvents) do
        local zone, remaining, sortIndex
        local swept = false
        if event.flow.phase == PHASE_LIVE then
            zone, remaining, sortIndex = zoneOf(eventID)
        end
        if event.flow.phase == PHASE_LIVE and zone == nil and (event.flow.zone == ZONE_HELD
            or (event.flow.zone == ZONE_TRACK and (event.flow.remaining or math.huge) <= timeline.END_REACHED_SECONDS)) then
            timeline.CancelEvent(eventID, true)
        elseif event.flow.phase == PHASE_LIVE and zone == ZONE_HELD and timeline.queuedHidden then
            timeline.CancelEvent(eventID, true)
            swept = true
        end
        if state.activeEvents[eventID] == event then
            event.flow.zone, event.flow.remaining = zone, remaining
            if event.flow.phase == PHASE_LIVE then
                local mode = nil
                if event.flow.paused then
                    mode = ns.statusMark.MODE_PAUSED
                elseif zone == ZONE_HELD or zone == ZONE_EXIT then
                    mode = ns.statusMark.MODE_QUEUED
                end
                local ok, blocked = pcall(C_EncounterTimeline.IsEventBlocked, eventID)
                if not ok or issecretvalue(blocked) then
                    blocked = event.flow.blocked
                end
                event.flow.blocked = blocked
                ns.statusMark.Set(event, mode, blocked, state.captions[eventID])
            end
            if zone == ZONE_QUEUE or zone == ZONE_ARRIVING then
                count = count + 1
                queue[count] = eventID
                queueRemaining[eventID] = remaining
            elseif zone == ZONE_HELD and not swept then
                heldCount = heldCount + 1
                held[heldCount] = eventID
                heldIndex[eventID] = sortIndex or math.huge
            end
        end
    end
    for index = #queue, count + 1, -1 do
        queue[index] = nil
    end
    for index = #held, heldCount + 1, -1 do
        held[index] = nil
    end
    table.sort(queue, soonerFirst)
    table.sort(held, nearerFirst)

    local entryOffset = trackLength + timeline.EntryFirstOffset()
    for _, eventID in ipairs(queue) do
        local event = state.activeEvents[eventID]
        local place = fromStart and entryOffset or (trackLength - entryOffset)
        if event.flow.zone == ZONE_ARRIVING then
            placeArriving(event, horizontal, event.flow.remaining, place, trackStart)
        else
            placeWaiting(event, horizontal, event.flow.remaining, place, 1 - state.waitingTransparency / PERCENT)
        end
        queueRemaining[eventID] = nil
        entryOffset = entryOffset + entryStep
    end

    local exitOffset = timeline.ExitFirstOffset()
    local exitStep = entryStep
    for _, eventID in ipairs(state.longOrder) do
        local event = state.activeEvents[eventID]
        if event and event.flow.zone == ZONE_EXIT then
            placeWaiting(event, horizontal, event.flow.remaining, fromStart and -exitOffset or (trackLength + exitOffset), 1)
            exitOffset = exitOffset + exitStep
        end
    end
    for _, eventID in ipairs(held) do
        local event = state.activeEvents[eventID]
        if not event.flow.docked then
            event.flow.docked = event.flow.exitFrom or event.flow.drawn
        end
        event.flow.exitFrom = nil
        placeWaiting(event, horizontal, event.flow.remaining, fromStart and -exitOffset or (trackLength + exitOffset), 1)
        exitOffset = exitOffset + exitStep
        heldIndex[eventID] = nil
    end
end

local function placeOnTrack(event, horizontal)
    local remaining = event.flow.remaining
    if remaining < 0 then
        remaining = 0
    elseif remaining > TRACK_SPAN_SECONDS then
        remaining = TRACK_SPAN_SECONDS
    end
    if not event.flow.introDone and not event.flow.paused then
        event.flow.introHold = event.flow.introHold or math.max(remaining - timeline.IntroSlideSeconds(), 0)
        remaining = math.min(remaining, event.flow.introHold)
    else
        event.flow.introHold = nil
    end
    local offset = remaining / TRACK_SPAN_SECONDS * state.trackLength
    local along = timeline.EntersFromStart() and offset or (state.trackLength - offset)
    event.flow.exitFrom = remaining <= 0 and along or nil
    if event.flow.docked then
        timeline.startSlide(event, event.flow.docked - along)
        event.flow.docked = nil
    end
    if event.flow.dimmed then
        event.flow.dimmed = nil
        event.container:SetAlpha(1)
        event.cooldownHolder:SetAlpha(1)
    end
    placeAlong(event, horizontal, timeline.slidAlong(event, along), event.flow.laneShift, timeline.introOffset(event))
    event:Show()
    timeline.updateCountdown(event, remaining)
    timeline.updateTenths(event, remaining)
end

local lastOrientation, lastFromStart

local function forgetPlaces()
    local orientation, fromStart = state.orientation, timeline.EntersFromStart()
    if orientation == lastOrientation and fromStart == lastFromStart then
        return
    end
    lastOrientation, lastFromStart = orientation, fromStart
    for _, event in pairs(state.activeEvents) do
        local flow = event.flow
        flow.docked, flow.slideStart, flow.slideLeft, flow.exitFrom = nil, nil, nil, nil
        if flow.phase == PHASE_LIVE then
            flow.drawn = nil
        end
    end
end

function timeline.updateEvents(_, step)
    local horizontal = state.orientation == ORIENTATION_HORIZONTAL
    forgetPlaces()
    placeDocked(horizontal)
    timeline.AssignLanes(step or 0, horizontal)
    timeline.AssignLevels()
    for _, event in pairs(state.activeEvents) do
        if event.flow.phase == PHASE_CANCELING then
            placeAlong(event, horizontal, event.flow.drawn, timeline.outroOffset(event))
        elseif event.flow.phase ~= PHASE_FINISHING then
            if event.flow.zone == ZONE_TRACK then
                placeOnTrack(event, horizontal)
            elseif event.flow.zone == nil then
                event:Hide()
            end
        end
        local onTrack = event.flow.phase == PHASE_LIVE and event.flow.zone == ZONE_TRACK and not event.flow.paused
            and event.flow.remaining > 0 and event.flow.introDone
            and event.flow.lane == 0 and math.abs(event.flow.laneShift) < LANE_TRAIL_TOLERANCE
        if event.flow.phase == PHASE_CANCELING then
            timeline.clearTrail(event)
        else
            timeline.updateTrail(event, onTrack and event.flow.remaining or nil, step or 0)
        end
    end
end

function timeline.MarkLongEvent(eventID, place, caption)
    state.captions[eventID] = caption
    if not state.longEvents[eventID] then
        state.longEvents[eventID] = place or PLACE_ENTRY
        state.longOrder[#state.longOrder + 1] = eventID
    end
end

function timeline.restartWaitingEvents()
    for _, event in pairs(state.activeEvents) do
        local flow = event.flow
        if flow.zone == ZONE_QUEUE or flow.zone == ZONE_EXIT or flow.zone == ZONE_HELD then
            flow.docked, flow.slideStart, flow.slideLeft, flow.exitFrom = nil, nil, nil, nil
            if flow.phase == PHASE_LIVE then
                flow.drawn = nil
            end
            flow.introStart, flow.introDone, flow.introHold = nil, nil, nil
        end
    end
end
