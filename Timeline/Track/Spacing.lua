local addonName, ns = ...

local math = math

local timeline = ns.timeline
local state = timeline.state

local PERCENT = 100
local ARRIVAL_LEAD_SECONDS = 0.5
local ARRIVAL_JUMP_SECONDS = 0.01

local NO_ARRIVAL_DIVIDER_GAP = 20
timeline.NO_ARRIVAL_DIVIDER_GAP = NO_ARRIVAL_DIVIDER_GAP
local NO_ARRIVAL_FIRST_SHARE = 1.05

local NO_SHIFT_DIVIDER_GAP = 20
timeline.NO_SHIFT_DIVIDER_GAP = NO_SHIFT_DIVIDER_GAP
local NO_SHIFT_FIRST_SHARE = 1.05

local WAITING_FIRST_GAP_FACTOR = 2
local WAITING_FIRST_GAP_MIN = 10
local WAITING_FIRST_DISTANCE_MAX = 1
local CLOSE_ROOM_GAP_SHARE = 0.5
local LONG_TRACK_PLACES = 2
local QUEUED_TRACK_PLACES = 2
local EXIT_AREA_GAP = 22

function timeline.FlatBorderReach(size)
    if ns.eventStyle.state.border.style == "BLIZZARD" then
        return 0
    end
    return ns.eventStyle.BorderThickness(size)
end

function timeline.WaitingStep(size)
    return size * (1 + state.waitingGap / PERCENT) + 2 * timeline.FlatBorderReach(size)
end

function timeline.EntryDividerGap()
    if timeline.IsArrivalAnimated() then
        return timeline.DIVIDER_GAP
    end
    return NO_ARRIVAL_DIVIDER_GAP
end

function timeline.ArrivalLead()
    if not timeline.IsArrivalAnimated() then
        return ARRIVAL_JUMP_SECONDS
    end
    return ARRIVAL_LEAD_SECONDS / timeline.AnimationSpeed()
end

local function firstDistanceShare()
    local gap = math.max(state.waitingGap, WAITING_FIRST_GAP_MIN)
    return math.min(WAITING_FIRST_GAP_FACTOR * gap / PERCENT, WAITING_FIRST_DISTANCE_MAX)
end

local function closeFirstShare(dividerShare)
    local share = 1 + CLOSE_ROOM_GAP_SHARE * state.waitingGap / PERCENT
    if timeline.IsBlizzlikeBackdrop() then
        return math.max(dividerShare, share)
    end
    return share
end

function timeline.EntryFirstShare()
    return closeFirstShare(NO_ARRIVAL_FIRST_SHARE)
end

function timeline.HeldFirstShare()
    return closeFirstShare(NO_SHIFT_FIRST_SHARE)
end

function timeline.ExitDividerGap()
    if timeline.IsShiftAnimated() then
        return timeline.DIVIDER_GAP
    end
    return NO_SHIFT_DIVIDER_GAP
end

function timeline.EntryFirstOffset()
    local size = timeline.currentIconSize()
    if not timeline.IsArrivalAnimated() or not timeline.IsBlizzlikeBackdrop() then
        return size * timeline.EntryFirstShare() + timeline.GetBorderReach() + timeline.FlatBorderReach(size)
    end
    return timeline.DIVIDER_GAP + size / 2 + size * firstDistanceShare() + timeline.FlatBorderReach(size)
end

function timeline.ExitFirstOffset()
    local size = timeline.currentIconSize()
    if not timeline.IsShiftAnimated() or not timeline.IsBlizzlikeBackdrop() then
        return size * timeline.HeldFirstShare() + timeline.GetBorderReach() + timeline.FlatBorderReach(size)
    end
    return timeline.GetEndReach() + EXIT_AREA_GAP + size / 2 + timeline.FlatBorderReach(size)
end

function timeline.GetWaitingExtents()
    local size = timeline.currentIconSize()
    local step = timeline.WaitingStep(size)
    local entryReach = timeline.EntryFirstOffset() + (LONG_TRACK_PLACES - 1) * step + step / 2
    local exitReach = timeline.ExitFirstOffset() + (QUEUED_TRACK_PLACES - 1) * step + step / 2
    if timeline.queuedHidden then
        exitReach = timeline.GetEndReach()
    end
    return entryReach, exitReach
end
