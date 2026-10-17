local addonName, ns = ...

local math = math

local timeline = ns.timeline
local trackPreview = ns.appearanceTrackPreview
local state = trackPreview.state

local ICON_SIZE = trackPreview.ICON_SIZE
local LINE_REFERENCE_SIZE = trackPreview.LINE_REFERENCE_SIZE
local RATE = trackPreview.RATE
local THRESHOLD = timeline.TRACK_SPAN_SECONDS
local PERCENT = 100
local HELD_OFFSET_SHARE = 1.2

function trackPreview.DividerGap()
    return timeline.NO_SHIFT_DIVIDER_GAP * ICON_SIZE / LINE_REFERENCE_SIZE
end

function trackPreview.EntryDividerGap()
    return timeline.NO_ARRIVAL_DIVIDER_GAP * ICON_SIZE / LINE_REFERENCE_SIZE
end

local function maxDividerGap()
    return timeline.DIVIDER_GAP * ICON_SIZE / LINE_REFERENCE_SIZE
end

function trackPreview.WaitingStep()
    return ICON_SIZE * (1 + timeline.state.waitingGap / PERCENT) + 2 * timeline.FlatBorderReach(ICON_SIZE)
end

local function borderReach()
    return timeline.GetBorderReach() * ICON_SIZE / math.max(timeline.currentIconSize(), 1)
end

function trackPreview.EntryFirstOffset(animated)
    if animated == nil then
        animated = timeline.IsArrivalAnimated()
    end
    if not animated or not timeline.IsBlizzlikeBackdrop() then
        return ICON_SIZE * timeline.EntryFirstShare() + borderReach() + timeline.FlatBorderReach(ICON_SIZE)
    end
    return maxDividerGap() + ICON_SIZE + timeline.FlatBorderReach(ICON_SIZE)
end

function trackPreview.HeldFirstOffset(animated)
    if animated == nil then
        animated = timeline.IsShiftAnimated()
    end
    if animated and timeline.IsBlizzlikeBackdrop() then
        return ICON_SIZE * HELD_OFFSET_SHARE + timeline.FlatBorderReach(ICON_SIZE)
    end
    return ICON_SIZE * timeline.HeldFirstShare() + borderReach() + timeline.FlatBorderReach(ICON_SIZE)
end

function trackPreview.PlaceOf(remaining)
    local share = remaining / THRESHOLD
    return state.trackTop + (state.direction == 1 and 1 - share or share) * state.trackLength
end

function trackPreview.WaitingPlace(slot, left)
    local offset = trackPreview.EntryFirstOffset() + ((slot or 0) + (left or 0)) * trackPreview.WaitingStep()
    return trackPreview.PlaceOf(THRESHOLD) - state.direction * offset
end

function trackPreview.HeldPlace(slot)
    local first = trackPreview.HeldFirstOffset()
    return trackPreview.PlaceOf(0) + state.direction * (first + (slot or 0) * trackPreview.WaitingStep())
end

function trackPreview.ArrivalPlace(slot, progress)
    local from, to = trackPreview.WaitingPlace(slot), trackPreview.PlaceOf(THRESHOLD)
    local trackStep = state.direction * RATE * state.trackLength / THRESHOLD * trackPreview.ArriveSeconds()
    return from + (to - from) * progress * progress * (3 - 2 * progress) + trackStep * progress * progress * (progress - 1)
end
