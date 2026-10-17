local addonName, ns = ...

local ipairs = ipairs
local math = math

local timeline = ns.timeline
local trackPreview = ns.appearanceTrackPreview
local state = trackPreview.state

local ICON_SIZE = trackPreview.ICON_SIZE
local RATE = trackPreview.RATE
local ACTOR_COUNT = trackPreview.ACTOR_COUNT
local TWIN_ENTER_SECONDS = trackPreview.TWIN_ENTER_SECONDS
local THRESHOLD = timeline.TRACK_SPAN_SECONDS

local QUIET_SECONDS = 1.2

local PART_WAIT = "wait"
local PART_ARRIVE = "arrive"
local PART_ALONG = "along"
local PART_PAUSE = "pause"
local PART_RESUME = "resume"
local PART_BLOCKED = "blocked"
local PART_FURTHER = "further"
local PART_END = "end"
local PART_LAND = "land"
local PART_HELD = "held"
local PART_FINISH = "finish"
local PART_GAP = "gap"
local ARRIVE_SECONDS = 0.5
local CLEAR_SIZES = 1.15
local LAND_SECONDS = 0.7
local PARTS = {
    { key = PART_WAIT, seconds = 2.6 },
    { key = PART_ARRIVE, seconds = ARRIVE_SECONDS },
    { key = PART_ALONG, seconds = 3, moving = true },
    { key = PART_PAUSE },
    { key = PART_RESUME, seconds = 1, moving = true },
    { key = PART_BLOCKED, seconds = 1.6, moving = true },
    { key = PART_FURTHER, seconds = 1.4, moving = true },
    { key = PART_END, moving = true },
    { key = PART_LAND, seconds = LAND_SECONDS },
    { key = PART_HELD, seconds = 2.2 },
    { key = PART_FINISH, seconds = 0.4 },
    { key = PART_GAP, seconds = 0.8 },
}
local ARRIVE_INDEX = 2

trackPreview.PART = {
    WAIT = PART_WAIT,
    ARRIVE = PART_ARRIVE,
    ALONG = PART_ALONG,
    PAUSE = PART_PAUSE,
    RESUME = PART_RESUME,
    BLOCKED = PART_BLOCKED,
    FURTHER = PART_FURTHER,
    END = PART_END,
    LAND = PART_LAND,
    HELD = PART_HELD,
    FINISH = PART_FINISH,
    GAP = PART_GAP,
}
trackPreview.PARTS = PARTS

function trackPreview.ArriveSeconds()
    return PARTS[ARRIVE_INDEX].seconds
end

function trackPreview.PlanStory()
    local starts, remainingAtStart = state.starts, state.remainingAtStart
    local clock, remaining = 0, THRESHOLD
    for _, part in ipairs(PARTS) do
        if part.key == PART_END then
            part.seconds = remaining / RATE
        elseif part.key == PART_ARRIVE then
            part.seconds = timeline.ArrivalLead()
        elseif part.key == PART_LAND then
            part.seconds = math.max(LAND_SECONDS, timeline.LandingSeconds())
        elseif part.key == PART_PAUSE then
            local clearTrackSeconds = CLEAR_SIZES * ICON_SIZE / state.trackLength * THRESHOLD
            part.seconds = TWIN_ENTER_SECONDS + (THRESHOLD - remaining + clearTrackSeconds) / RATE
        end
        starts[part.key] = clock
        remainingAtStart[part.key] = remaining
        clock = clock + part.seconds
        if part.moving then
            remaining = remaining - RATE * part.seconds
        end
    end
    state.totalSeconds = clock
    state.lagSeconds = clock / ACTOR_COUNT
    state.roundSeconds = clock + (ACTOR_COUNT - 1) * state.lagSeconds + QUIET_SECONDS
end
trackPreview.PlanStory()
