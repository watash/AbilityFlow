local addonName, ns = ...

local GetTime = GetTime

local timeline = ns.timeline
local state = timeline.state

local INTRO_FADE_SECONDS = 0.2
local INTRO_SLIDE_SECONDS = 0.35
local INTRO_SLIDE_FRACTION = 25 / 35
local FINISH_SECONDS = 0.2
local OUTRO_SLIDE_SECONDS = 0.35
local FINISH_GROWTH = 1.35
local LANDING_SECONDS = 0.4
local DROP_SECONDS = 0.45
local PERCENT = 100
local SPEED_MIN = 50
local SPEED_MAX = 200
local ORIENTATION_HORIZONTAL = timeline.ORIENTATION_HORIZONTAL
local PHASE_LIVE = timeline.PHASE_LIVE
local PHASE_FINISHING = timeline.PHASE_FINISHING
local PHASE_CANCELING = timeline.PHASE_CANCELING

local animations = { intro = true, outro = true, shift = true, arrival = true, fade = true, speed = 1 }

function timeline.SetAnimations(intro, outro, shift, arrival, fade, speedPercent)
    local layoutChanged = animations.arrival ~= arrival or animations.shift ~= shift
    animations.intro, animations.outro, animations.shift, animations.arrival = intro, outro, shift, arrival
    animations.fade = fade
    animations.speed = math.min(math.max(tonumber(speedPercent) or PERCENT, SPEED_MIN), SPEED_MAX) / PERCENT
    if layoutChanged and timeline.onGeometryChanged then
        timeline.onGeometryChanged()
    end
end

function timeline.IsShiftAnimated()
    return animations.shift
end

function timeline.IsFadeAnimated()
    return animations.fade
end

function timeline.IsArrivalAnimated()
    return animations.arrival
end

function timeline.AnimationFlags()
    return animations.intro, animations.outro, animations.shift, animations.arrival
end

function timeline.AnimationSpeed()
    return animations.speed
end

local function slideSign()
    if state.orientation == ORIENTATION_HORIZONTAL then
        return 1
    end
    return ns.eventStyle.NameSide() == "LEFT" and -1 or 1
end

timeline.slideSign = slideSign

function timeline.IntroSlideSeconds()
    if not animations.intro then
        return 0
    end
    return INTRO_SLIDE_SECONDS / animations.speed
end

local function introProgress(elapsed)
    if not animations.intro then
        return 1, 1
    end
    return math.min(elapsed * animations.speed / INTRO_FADE_SECONDS, 1),
        math.min(elapsed * animations.speed / INTRO_SLIDE_SECONDS, 1)
end
timeline.IntroProgress = introProgress

function timeline.OutroProgress(elapsed)
    if not animations.outro then
        return 0, 1, 1
    end
    local share = math.min(elapsed * animations.speed / FINISH_SECONDS, 1)
    local growth = 1 + (FINISH_GROWTH - 1) * (1 - (1 - share) * (1 - share))
    return 1 - share, growth, math.min(elapsed * animations.speed / OUTRO_SLIDE_SECONDS, 1)
end

function timeline.DropProgress(elapsed)
    if not animations.intro then
        return 1, 0
    end
    return math.min(elapsed * animations.speed / INTRO_FADE_SECONDS, 1),
        1 - math.min(elapsed * animations.speed / DROP_SECONDS, 1)
end

timeline.SLIDE_FRACTION = INTRO_SLIDE_FRACTION

function timeline.introOffset(event, falling)
    if event.flow.introDone then
        return 0, 0
    end
    local now = GetTime()
    event.flow.introStart = event.flow.introStart or now
    if falling then
        local fade, left = timeline.DropProgress(now - event.flow.introStart)
        event:SetAlpha(fade)
        if fade >= 1 and left <= 0 then
            event.flow.introDone = true
            return 0, 0
        end
        local step = timeline.WaitingStep(timeline.currentIconSize())
        return 0, (timeline.EntersFromStart() and 1 or -1) * step * left
    end
    local fade, slide = introProgress(now - event.flow.introStart)
    event:SetAlpha(fade)
    if fade >= 1 and slide >= 1 then
        event.flow.introDone = true
        return 0, 0
    end
    local distance = timeline.currentIconSize() * INTRO_SLIDE_FRACTION * (1 - slide)
    local sign = state.orientation == ORIENTATION_HORIZONTAL and 1 or -slideSign()
    return sign * distance, 0
end

function timeline.outroOffset(event)
    local slide = math.min((GetTime() - event.flow.cancelStart) * animations.speed / OUTRO_SLIDE_SECONDS, 1)
    local sign = slideSign()
    if event.flow.swept and state.orientation ~= ORIENTATION_HORIZONTAL then
        sign = -sign
    end
    return sign * timeline.currentIconSize() * INTRO_SLIDE_FRACTION * slide
end

function timeline.startSlide(event, from)
    if not animations.shift then
        event.flow.slideStart, event.flow.slideLeft = nil, nil
        return
    end
    event.flow.slideFrom = from + (event.flow.slideStart and event.flow.slideLeft or 0)
    event.flow.slideStart = GetTime()
end

function timeline.slidAlong(event, along)
    if not event.flow.slideStart then
        return along
    end
    local progress = (GetTime() - event.flow.slideStart) * animations.speed / LANDING_SECONDS
    if progress >= 1 then
        event.flow.slideStart, event.flow.slideLeft = nil, nil
        return along
    end
    event.flow.slideLeft = event.flow.slideFrom * (1 - progress * progress)
    return along + event.flow.slideLeft
end

function timeline.LandingLeft(elapsed)
    if not animations.shift then
        return 0
    end
    local progress = math.min(elapsed * animations.speed / LANDING_SECONDS, 1)
    return 1 - progress * progress
end

function timeline.LandingSeconds()
    return LANDING_SECONDS / animations.speed
end

function timeline.buildFinishAnimation(event)
    local fade = event:CreateAnimationGroup()
    local fadeOut = fade:CreateAnimation("Alpha")
    fadeOut:SetDuration(FINISH_SECONDS)
    fadeOut:SetFromAlpha(1)
    fadeOut:SetToAlpha(0)
    event.finishFadeStep = fadeOut
    fade:SetScript("OnFinished", function()
        if event.flow.phase ~= PHASE_LIVE and event.eventID then
            timeline.RemoveEvent(event.eventID)
        end
    end)
    event.finishFade = fade

    local grow = event.container:CreateAnimationGroup()
    local growStep = grow:CreateAnimation("Scale")
    growStep:SetSmoothing("OUT")
    growStep:SetDuration(FINISH_SECONDS)
    growStep:SetScaleFrom(1, 1)
    growStep:SetScaleTo(FINISH_GROWTH, FINISH_GROWTH)
    event.finishGrowStep = growStep
    event.finishGrow = grow
end

timeline.END_REACHED_SECONDS = 0.5

timeline.queuedHidden = false

function timeline.SetQueuedHidden(value)
    if timeline.queuedHidden == value then
        return
    end
    timeline.queuedHidden = value
    if timeline.onGeometryChanged then
        timeline.onGeometryChanged()
    end
end

function timeline.FinishEvent(eventID)
    local event = state.activeEvents[eventID]
    if not event or event.flow.phase ~= PHASE_LIVE then
        return
    end

    if not event:IsShown() then
        timeline.RemoveEvent(eventID)
        return
    end
    if not animations.outro then
        timeline.RemoveEvent(eventID)
        return
    end
    event.flow.phase = PHASE_FINISHING
    ns.eventEffects.StopPulse(event)
    event.container:SetScale(1)
    event.finishGrowStep:SetDuration(FINISH_SECONDS / animations.speed)
    event.finishFadeStep:SetDuration(FINISH_SECONDS / animations.speed)
    event.finishFade:Play()
    event.finishGrow:Play()
    if ns.glow.ShownOn(event.container) then
        event.finishBreath = event.finishBreath or function()
            return 1 + (FINISH_GROWTH - 1) * event.finishGrowStep:GetSmoothProgress()
        end
        event.finishSteps = event.finishSteps or { event.finishGrowStep }
        ns.glow.Breathe(event.container, event.finishBreath, event.finishSteps)
    end
end

function timeline.CancelEvent(eventID, sweep)
    local event = state.activeEvents[eventID]
    if not event or event.flow.phase ~= PHASE_LIVE then
        return
    end
    if not event:IsShown() then
        timeline.RemoveEvent(eventID)
        return
    end
    if not animations.outro then
        timeline.RemoveEvent(eventID)
        return
    end
    if sweep == nil and (event.flow.remaining or math.huge) <= timeline.END_REACHED_SECONDS then
        sweep = true
    end
    event.flow.phase = PHASE_CANCELING
    event.flow.swept = sweep or nil
    event.flow.cancelStart = GetTime()
    ns.eventEffects.StopPulse(event)
    event.finishFadeStep:SetDuration(FINISH_SECONDS / animations.speed)
    event.finishFade:Play()
end

function timeline.IsFinishing(eventID)
    local event = state.activeEvents[eventID]
    return event ~= nil and event.flow.phase ~= PHASE_LIVE
end
