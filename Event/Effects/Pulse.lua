local addonName, ns = ...

local GetTime = GetTime
local ipairs = ipairs
local math = math

local effects = ns.eventEffects

local PULSE_GROW = 1.1
local PULSE_SHRINK = 0.9
local PULSE_STEP = 0.2
local PULSE_HOLD = 0.6
local PULSE_CYCLE = 2 * PULSE_STEP + PULSE_HOLD
local TEXT_PULSE_GROW = 1.3
local TEXT_PULSE_MIN_GROWTH = 5
local BADGE_PULSE_GROW = 1.25
local BADGE_PULSE_KEEP = -0.2
local BADGES = {
    { kind = "debuff", holder = "debuffHolder", roles = false },
    { kind = "signs", holder = "signHolder", centerKind = "debuff", roles = false },
    { kind = "danger", holder = "dangerHolder", roles = false },
    { kind = "roles", holder = "rolesHolder", roles = true },
}

local function buildPulse(target, grow, shrink, shrinkFromPeak)
    local group = target:CreateAnimationGroup()
    group:SetLooping("REPEAT")

    local growStep = group:CreateAnimation("Scale")
    growStep:SetScaleFrom(1, 1)
    growStep:SetScaleTo(grow, grow)
    growStep:SetOrigin("CENTER", 0, 0)
    growStep:SetDuration(PULSE_STEP)
    growStep:SetSmoothing("IN")
    growStep:SetOrder(1)

    local from = shrinkFromPeak and grow or 1
    local shrinkStep = group:CreateAnimation("Scale")
    shrinkStep:SetScaleFrom(from, from)
    shrinkStep:SetScaleTo(shrink, shrink)
    shrinkStep:SetOrigin("CENTER", 0, 0)
    shrinkStep:SetDuration(PULSE_STEP)
    shrinkStep:SetSmoothing("OUT")
    shrinkStep:SetEndDelay(PULSE_HOLD)
    shrinkStep:SetOrder(2)

    return group, growStep, shrinkStep
end

local function addPulseShift(group, growSmoothing, shrinkSmoothing)
    local growShift = group:CreateAnimation("Translation")
    growShift:SetDuration(PULSE_STEP)
    growShift:SetSmoothing(growSmoothing)
    growShift:SetOrder(1)
    local shrinkShift = group:CreateAnimation("Translation")
    shrinkShift:SetDuration(PULSE_STEP)
    shrinkShift:SetSmoothing(shrinkSmoothing)
    shrinkShift:SetEndDelay(PULSE_HOLD)
    shrinkShift:SetOrder(2)
    return growShift, shrinkShift
end

local function placeTextHolder(event)
    local factor = 1
    local peak = event.textPulsePeak
    if peak and event.textPulse:IsPlaying() then
        if event.textPulseGrow:IsPlaying() then
            factor = 1 + (peak - 1) * event.textPulseGrow:GetSmoothProgress()
        elseif event.textPulseShrink:IsPlaying() then
            factor = peak + (1 - peak) * event.textPulseShrink:GetSmoothProgress()
        end
    end
    local holder = event.cooldownHolder
    if factor == 1 then
        if event.textHolderScaled then
            event.textHolderScaled = false
            holder:ClearAllPoints()
            holder:SetAllPoints(event)
            holder:SetScale(1)
        end
        return
    end
    if not event.textHolderScaled then
        event.textHolderScaled = true
        holder:ClearAllPoints()
        holder:SetPoint("CENTER", event, "CENTER")
    end
    holder:SetSize(event:GetWidth(), event:GetHeight())
    holder:SetScale(factor)
end

local function ensurePulses(event)
    if event.pulse then
        return
    end
    event.pulse, event.pulseGrow, event.pulseShrink = buildPulse(event.container, PULSE_GROW, PULSE_SHRINK, false)
    event.flashPulse, event.flashGrow, event.flashShrink = buildPulse(event.flashHolder, PULSE_GROW, PULSE_SHRINK, false)

    local textGroup, textGrow, textShrink = buildPulse(event.cooldownHolder, 1, 1, false)
    event.textPulse, event.textPulseGrow, event.textPulseShrink = textGroup, textGrow, textShrink
    textGroup:SetScript("OnUpdate", function()
        placeTextHolder(event)
    end)

    event.badgePulses = {}
    for _, badge in ipairs(BADGES) do
        local group, grow, shrink = buildPulse(event[badge.holder], BADGE_PULSE_GROW, 1, true)
        grow:SetSmoothing("OUT")
        shrink:SetSmoothing("IN_OUT")
        local growShift, shrinkShift = addPulseShift(group, "OUT", "IN_OUT")
        event.badgePulses[badge.kind] = {
            group = group, grow = grow, shrink = shrink, growShift = growShift, shrinkShift = shrinkShift,
        }
    end
end

local function playInPhase(group)
    group:Play(false, GetTime() % PULSE_CYCLE)
end

local function resetScale(target)
    target:SetScale(1)
end

local function tunePicturePulse(event, strength)
    local grow = 1 + (PULSE_GROW - 1) * strength
    local shrink = 1 - (1 - PULSE_SHRINK) * strength
    event.pulseGrow:SetScaleTo(grow, grow)
    event.pulseShrink:SetScaleTo(shrink, shrink)
    event.flashGrow:SetScaleTo(grow, grow)
    event.flashShrink:SetScaleTo(shrink, shrink)
    event.pulsePeak, event.pulseLow = grow, shrink
end

function effects.PulseLow(event)
    return math.min(1, (event.pulsePeak or 1) * (event.pulseLow or PULSE_SHRINK))
end

local function tuneTextPulse(event, strength)
    local _, fontHeight = event.texts.cooldown:GetFont()
    fontHeight = fontHeight or 0
    local peak = TEXT_PULSE_GROW
    if fontHeight > 0 then
        peak = math.max(TEXT_PULSE_GROW, 1 + TEXT_PULSE_MIN_GROWTH / fontHeight)
    end
    peak = 1 + (peak - 1) * strength
    event.textPulsePeak = peak
end

local function tuneBadgePulse(pulse, centerX, centerY, strength)
    local peak = 1 + (BADGE_PULSE_GROW - 1) * strength
    pulse.grow:SetScaleTo(peak, peak)
    pulse.shrink:SetScaleFrom(1, 1)
    pulse.shrink:SetScaleTo(1 / peak, 1 / peak)
    local share = (1 - peak) * BADGE_PULSE_KEEP
    pulse.growShift:SetOffset(centerX * share, centerY * share)
    pulse.shrinkShift:SetOffset(-centerX * share, -centerY * share)
end

function effects.StartPulse(event, scaleText, scaleMarks, scaleRoles, badgeCenter, strength)
    ensurePulses(event)
    strength = strength or effects.FULL_STRENGTH
    if event.pulse:IsPlaying() and (event.pulseScaleText ~= scaleText or event.pulseScaleMarks ~= scaleMarks
        or event.pulseScaleRoles ~= scaleRoles or event.pulseStrength ~= strength) then
        effects.StopPulse(event)
    end
    event.pulseScaleText, event.pulseScaleMarks, event.pulseScaleRoles = scaleText, scaleMarks, scaleRoles
    event.pulseStrength = strength
    if not event.pulse:IsPlaying() then
        tunePicturePulse(event, strength)
        ns.eventFrame.SetPulsing(event, true)
        resetScale(event.container)
        playInPhase(event.pulse)
        resetScale(event.flashHolder)
        playInPhase(event.flashPulse)
    end
    if scaleText and not event.textPulse:IsPlaying() then
        tuneTextPulse(event, strength)
        resetScale(event.cooldownHolder)
        playInPhase(event.textPulse)
    end
    for _, badge in ipairs(BADGES) do
        local pulse = event.badgePulses[badge.kind]
        local wanted = badge.roles and scaleRoles or not badge.roles and scaleMarks
        if wanted and not pulse.group:IsPlaying() then
            local centerX, centerY = badgeCenter(badge.centerKind or badge.kind)
            tuneBadgePulse(pulse, centerX, centerY, strength)
            resetScale(event[badge.holder])
            playInPhase(pulse.group)
        end
    end
end

function effects.Resync(event)
    if not (event.pulse and event.pulse:IsPlaying()) then
        return
    end
    event.pulse:Stop()
    resetScale(event.container)
    playInPhase(event.pulse)
    event.flashPulse:Stop()
    resetScale(event.flashHolder)
    playInPhase(event.flashPulse)
end

function effects.PulseFactor(event)
    if not event.pulse or not event.pulse:IsPlaying() then
        return 1
    end
    if event.pulseGrow:IsPlaying() then
        return 1 + (event.pulsePeak - 1) * event.pulseGrow:GetSmoothProgress()
    elseif event.pulseShrink:IsPlaying() then
        return event.pulsePeak * (1 + (event.pulseLow - 1) * event.pulseShrink:GetSmoothProgress())
    end
    return 1
end

function effects.StopPulse(event)
    if not event.pulse then
        return
    end
    for _, group in ipairs({ event.pulse, event.flashPulse, event.textPulse }) do
        if group:IsPlaying() then
            group:Stop()
        end
    end
    for _, badge in ipairs(BADGES) do
        local group = event.badgePulses[badge.kind].group
        if group:IsPlaying() then
            group:Stop()
        end
        resetScale(event[badge.holder])
    end
    for _, holder in ipairs({ event.container, event.flashHolder, event.cooldownHolder }) do
        resetScale(holder)
    end
    placeTextHolder(event)
    event.pulseScaleText, event.pulseScaleMarks, event.pulseScaleRoles, event.pulseStrength = nil, nil, nil, nil
    ns.eventFrame.SetPulsing(event, false)
end
