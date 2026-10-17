local addonName, ns = ...

local Enum = Enum
local ipairs = ipairs
local pairs = pairs
local math = math
local table = table

local timeline = ns.timeline
local state = timeline.state

local LANE_OVERLAP_SHARE = 0.15
local LANE_GAP_SHARE = 0.1
local LANE_SPEED = 14
local ICON_LEVEL_OFFSET = 2
local INDICATOR_LEVEL_BLOCK = 10
local TRACK_SPAN_SECONDS = timeline.TRACK_SPAN_SECONDS
local PHASE_LIVE = timeline.PHASE_LIVE
local ZONE_TRACK = timeline.ZONE_TRACK
local LANE_TRAIL_TOLERANCE = timeline.LANE_TRAIL_TOLERANCE
local ORDINARY_SEVERITY = Enum.EncounterEventSeverity.Medium
local frame = timeline.frame

local levelEvents = {}

local function lowerFirst(a, b)
    local pausedA, pausedB = a.flow.paused and 0 or 1, b.flow.paused and 0 or 1
    if pausedA ~= pausedB then
        return pausedA < pausedB
    end
    local severityA, severityB = a.flow.severity or ORDINARY_SEVERITY, b.flow.severity or ORDINARY_SEVERITY
    if severityA ~= severityB then
        return severityA < severityB
    end
    return a.baseLevel < b.baseLevel
end

function timeline.AssignLevels()
    local count = 0
    for _, event in pairs(state.activeEvents) do
        count = count + 1
        levelEvents[count] = event
    end
    for index = #levelEvents, count + 1, -1 do
        levelEvents[index] = nil
    end
    table.sort(levelEvents, lowerFirst)
    local lowest = frame:GetFrameLevel() + ICON_LEVEL_OFFSET
    local indicatorsLowest = lowest + #levelEvents * timeline.EVENT_LEVEL_BLOCK
    for rank, event in ipairs(levelEvents) do
        local level = lowest + (rank - 1) * timeline.EVENT_LEVEL_BLOCK
        local indicatorLevel = indicatorsLowest + (rank - 1) * INDICATOR_LEVEL_BLOCK
        if event.flow.level ~= level or event.flow.indicatorLevel ~= indicatorLevel then
            event.flow.level, event.flow.indicatorLevel = level, indicatorLevel
            ns.eventFrame.SetLevel(event, level, indicatorLevel)
        end
    end
end

local laneEvents = {}
local laneOf = {}

local function fartherFromEnd(a, b)
    if a.flow.remaining ~= b.flow.remaining then
        return a.flow.remaining > b.flow.remaining
    end
    return (a.eventID or 0) < (b.eventID or 0)
end

local function keepsLine(a, b)
    local severityA, severityB = a.flow.severity or ORDINARY_SEVERITY, b.flow.severity or ORDINARY_SEVERITY
    if severityA ~= severityB then
        return severityA > severityB
    end
    if a.flow.remaining ~= b.flow.remaining then
        return a.flow.remaining < b.flow.remaining
    end
    return (a.eventID or 0) < (b.eventID or 0)
end

local function flipName(event, flipped)
    if (event.nameFlipped == true) ~= flipped then
        event.nameFlipped = flipped or nil
        ns.eventStyle.PlaceName(event)
        ns.statusMark.Layout(event)
    end
end

local function setLane(event, lane)
    event.flow.lane = lane
    flipName(event, lane == 1)
end

function timeline.AssignLanes(step, horizontal)
    local size = timeline.currentIconSize()
    local follow = timeline.IsShiftAnimated() and math.min(LANE_SPEED * step * timeline.AnimationSpeed(), 1) or 1
    local pixelsPerSecond = state.trackLength / TRACK_SPAN_SECONDS
    local count = 0
    for _, event in pairs(state.activeEvents) do
        local flow = event.flow
        if flow.phase == PHASE_LIVE and flow.zone == ZONE_TRACK and flow.remaining > 0 and not flow.paused then
            count = count + 1
            laneEvents[count] = event
        elseif flow.phase == PHASE_LIVE then
            if flow.paused then
                flipName(event, false)
            end
            flow.laneShift = flow.laneShift * (1 - follow)
            if math.abs(flow.laneShift) < LANE_TRAIL_TOLERANCE then
                flow.laneShift = 0
                if flow.lane ~= 0 then
                    setLane(event, 0)
                end
            end
        end
    end
    for index = #laneEvents, count + 1, -1 do
        laneEvents[index] = nil
    end
    table.sort(laneEvents, fartherFromEnd)
    local lastPlace = { math.huge, math.huge }
    local inLine
    local reach = size * LANE_OVERLAP_SHARE
    for _, event in ipairs(laneEvents) do
        local place = math.min(event.flow.remaining, TRACK_SPAN_SECONDS) * pixelsPerSecond
        laneOf[event] = 0
        if inLine and lastPlace[1] - place < reach and lastPlace[2] - place >= reach then
            if keepsLine(event, inLine) and lastPlace[2] - lastPlace[1] >= reach then
                laneOf[inLine] = 1
                lastPlace[2] = lastPlace[1]
            else
                laneOf[event] = 1
            end
        end
        if laneOf[event] == 0 then
            lastPlace[1] = place
            inLine = event
        else
            lastPlace[2] = place
        end
    end
    local asideSign = horizontal and 1 or -timeline.slideSign()
    local aside = asideSign * (size * (1 + LANE_GAP_SHARE) + 2 * ns.eventStyle.BorderThickness(size))
    for _, event in ipairs(laneEvents) do
        local flow = event.flow
        local lane = laneOf[event]
        laneOf[event] = nil
        if flow.lane ~= lane then
            setLane(event, lane)
        end
        local target = lane == 1 and (event.trailLevel or 0) == 0 and aside or 0
        flow.laneShift = flow.laneShift + (target - flow.laneShift) * follow
    end
end
