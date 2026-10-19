local addonName, ns = ...

local ipairs = ipairs
local math = math

local timeline = ns.timeline
local trackPreview = ns.appearanceTrackPreview
local state = trackPreview.state

local ICON_SIZE = trackPreview.ICON_SIZE
local TRACK_CENTER_X = trackPreview.TRACK_CENTER_X
local RATE = trackPreview.RATE
local TWIN_DELAY_SECONDS = trackPreview.TWIN_DELAY_SECONDS
local TWIN_ENTER_SECONDS = trackPreview.TWIN_ENTER_SECONDS
local THRESHOLD = timeline.TRACK_SPAN_SECONDS
local PERCENT = 100
local PARTS = trackPreview.PARTS
local PART_WAIT = trackPreview.PART.WAIT
local PART_ARRIVE = trackPreview.PART.ARRIVE
local PART_ALONG = trackPreview.PART.ALONG
local PART_PAUSE = trackPreview.PART.PAUSE
local PART_BLOCKED = trackPreview.PART.BLOCKED
local PART_LAND = trackPreview.PART.LAND
local PART_HELD = trackPreview.PART.HELD
local PART_FINISH = trackPreview.PART.FINISH
local PART_GAP = trackPreview.PART.GAP

local function poseIcon(event, shown, alpha, growth, x, y, mode, blocked)
    event:SetShown(shown)
    event:SetAlpha(alpha)
    trackPreview.SetGrowth(event, growth)
    trackPreview.PutIcon(event, x, y)
    ns.statusMark.Set(event, mode, blocked)
    trackPreview.KeepBorderType(event)
end

local function partAt(sceneTime)
    local starts = state.starts
    for _, candidate in ipairs(PARTS) do
        if sceneTime < starts[candidate.key] + candidate.seconds then
            return candidate, sceneTime - starts[candidate.key]
        end
    end
    local last = PARTS[#PARTS]
    return last, sceneTime - starts[last.key]
end

local function waitingAlpha()
    return 1 - timeline.WaitingTransparency() / PERCENT
end

local function mainPose(part, elapsed, remaining, finishAtZero)
    local placeOf, heldPlace = trackPreview.PlaceOf, trackPreview.HeldPlace
    local key = part.key
    local x, y, alpha, growth, shown = TRACK_CENTER_X, placeOf(remaining), 1, 1, true
    if key == PART_WAIT then
        local fade, left = timeline.DropProgress(elapsed)
        alpha = fade * waitingAlpha()
        y = trackPreview.WaitingPlace(0, left)
    elseif key == PART_ARRIVE then
        local progress = math.min(elapsed / part.seconds, 1)
        alpha = waitingAlpha() + (1 - waitingAlpha()) * progress
        y = trackPreview.ArrivalPlace(0, progress)
    elseif finishAtZero and (key == PART_LAND or key == PART_HELD or key == PART_FINISH) then
        y = placeOf(0)
        shown = false
        if key == PART_LAND then
            alpha, growth = timeline.OutroProgress(elapsed)
            shown = alpha > 0
        end
    elseif key == PART_LAND then
        y = heldPlace(0) + (placeOf(0) - heldPlace(0)) * timeline.LandingLeft(elapsed)
    elseif key == PART_HELD then
        y = heldPlace(0)
    elseif key == PART_FINISH then
        local _, outSlide
        y = heldPlace(0)
        alpha, _, outSlide = timeline.OutroProgress(elapsed)
        x = TRACK_CENTER_X + outSlide * ICON_SIZE * timeline.SLIDE_FRACTION
        shown = alpha > 0
    elseif key == PART_GAP then
        shown = false
    end
    return shown, alpha, growth, x, y
end

local function passingPose(key, sceneTime, finishAtZero)
    local placeOf, waitingPlace, heldPlace, arrivalPlace =
        trackPreview.PlaceOf, trackPreview.WaitingPlace, trackPreview.HeldPlace, trackPreview.ArrivalPlace
    local starts = state.starts
    local remaining = THRESHOLD
    local shown
    local alpha, growth, x, y = 1, 1, TRACK_CENTER_X, placeOf(THRESHOLD)
    local mode
    local onLine = false
    local dropTime = sceneTime - starts[PART_WAIT] - TWIN_DELAY_SECONDS
    local trackTime = sceneTime - starts[PART_PAUSE] - TWIN_ENTER_SECONDS
    local zeroTime = trackTime - THRESHOLD / RATE
    local arriveSeconds = trackPreview.ArriveSeconds()
    if dropTime < 0 or key == PART_GAP then
        shown = false
    elseif sceneTime < starts[PART_ALONG] then
        shown = true
        local fade, left = timeline.DropProgress(dropTime)
        alpha, y = fade * waitingAlpha(), waitingPlace(1, left)
    elseif trackTime < -arriveSeconds then
        shown = true
        alpha = waitingAlpha()
        y = waitingPlace(timeline.LandingLeft(sceneTime - starts[PART_ALONG]))
    elseif trackTime < 0 then
        shown = true
        local progress = (trackTime + arriveSeconds) / arriveSeconds
        alpha = waitingAlpha() + (1 - waitingAlpha()) * progress
        y = arrivalPlace(0, progress)
    else
        shown = true
        remaining = THRESHOLD - RATE * trackTime
        if remaining > 0 then
            onLine = true
            y = placeOf(remaining)
        else
            remaining = 0
            if finishAtZero then
                alpha, growth = timeline.OutroProgress(zeroTime)
                shown = alpha > 0
                y = placeOf(0)
            else
                mode = ns.statusMark.MODE_QUEUED
                local slot = sceneTime >= starts[PART_LAND] and 1 - timeline.LandingLeft(sceneTime - starts[PART_LAND]) or 0
                y = heldPlace(slot) + (placeOf(0) - heldPlace(slot)) * timeline.LandingLeft(zeroTime)
                if sceneTime >= starts[PART_FINISH] then
                    local _, outSlide
                    alpha, _, outSlide = timeline.OutroProgress(sceneTime - starts[PART_FINISH])
                    x = TRACK_CENTER_X + outSlide * ICON_SIZE * timeline.SLIDE_FRACTION
                    shown = alpha > 0
                end
            end
        end
    end
    local countdown = trackTime < 0 and THRESHOLD - RATE * trackTime or remaining
    return shown, alpha, growth, x, y, mode, remaining, countdown, onLine
end

function trackPreview.DrawActor(actor, sceneTime, finishAtZero, step)
    local starts = state.starts
    local mainEvent, passingEvent = actor.main, actor.passing
    local part, elapsed = partAt(sceneTime)
    local key = part.key
    local remaining = state.remainingAtStart[key] - (part.moving and RATE * elapsed or 0)
    local shown, alpha, growth, x, y = mainPose(part, elapsed, remaining, finishAtZero)
    local mode, blocked
    if key == PART_PAUSE then
        mode = ns.statusMark.MODE_PAUSED
    elseif (key == PART_HELD or key == PART_LAND) and not finishAtZero then
        mode = ns.statusMark.MODE_QUEUED
    elseif key == PART_BLOCKED then
        blocked = true
    end
    poseIcon(mainEvent, shown, alpha, growth, x, y, mode, blocked)
    local countdown = remaining
    if sceneTime < starts[PART_ALONG] then
        countdown = THRESHOLD + RATE * (starts[PART_ALONG] - sceneTime)
    elseif starts[key] >= starts[PART_LAND] then
        countdown = 0
    end
    trackPreview.ShowCountdown(mainEvent, countdown)

    local trailOn = ns.appearance.Get("trail", "enabled") and state.laidOutBlizzlike
    local rampPerShare = 1 / timeline.TRAIL_FULL_SHARE
    if remaining >= THRESHOLD and not part.moving then
        trackPreview.SetTrailLevel(mainEvent, 0)
    end
    trackPreview.FollowTrail(mainEvent, trailOn and part.moving, (1 - remaining / THRESHOLD) * rampPerShare, step)

    local passingRemaining, passingCountdown, onLine
    shown, alpha, growth, x, y, mode, passingRemaining, passingCountdown, onLine = passingPose(key, sceneTime, finishAtZero)
    poseIcon(passingEvent, shown, alpha, growth, x, y, mode)
    if passingRemaining == 0 then
        trackPreview.SetTrailLevel(passingEvent, 0)
    end
    trackPreview.ShowCountdown(passingEvent, passingCountdown)
    trackPreview.FollowTrail(passingEvent, trailOn and onLine, (1 - passingRemaining / THRESHOLD) * rampPerShare, step)
end

function trackPreview.HideActor(actor)
    actor.main:Hide()
    actor.passing:Hide()
    trackPreview.SetTrailLevel(actor.main, 0)
    trackPreview.SetTrailLevel(actor.passing, 0)
end
