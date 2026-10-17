local addonName, ns = ...

local math = math

local paint = {}
ns.timerPaint = paint

local function setGlowRounds(event, rounds)
    if (event.glowRounds or false) == rounds then
        return
    end
    event.glowRounds = rounds
    ns.eventFrame.SetRounded(event, ns.eventStyle.RoundingReach(event))
end

local function setDangerRound(event, round)
    if (event.dangerRound or false) == round then
        return
    end
    event.dangerRound = round
    if event.eventID and ns.deadlyGlow then
        ns.deadlyGlow.Apply(event)
    end
end

function paint.Apply(event, template, base)
    local countdown = event.texts.cooldown
    local mode = ns.timerStyle.TimerModeOf(template)
    countdown:SetShown(mode ~= ns.timerStyle.TIMER_HIDE)
    event.cooldownHolder:SetShown(mode == ns.timerStyle.TIMER_SHOW or ns.eventStyle.state.texts.cooldown.enabled)

    local own = ns.timerStyle.CountdownColor(template)
    if own then
        local color = own
        countdown:SetTextColor(color.r, color.g, color.b, color.a or 1)
    elseif base.restoreColor then
        base.restoreColor(event)
    else
        countdown:SetTextColor(base.color.r, base.color.g, base.color.b, base.color.a or 1)
    end

    local size = base.fontSize * (template and template.textScale or 100) / 100
    if not countdown:SetFont(base.fontPath, size, base.outline) then
        countdown:SetFont(base.fallbackFontPath, size, base.outline)
    end

    local name = event.texts.name
    if base.nameFontPath and name then
        local nameSize = base.nameFontSize * ns.timerStyle.NameScaleOf(template) / 100
        if event.nameSizeApplied ~= nameSize then
            if not name:SetFont(base.nameFontPath, nameSize, base.nameOutline) then
                name:SetFont(base.fallbackFontPath, nameSize, base.nameOutline)
            end
            event.nameSizeApplied = nameSize
            ns.eventStyle.PlaceTextBackground(event, "name", nameSize)
        end
    end

    if base.paintNameBackground and name then
        base.paintNameBackground(event, template)
    end

    if template and template.pulse then
        local strength = math.min(math.max(template.pulseStrength or ns.timerStyle.PULSE_STRENGTH_DEFAULT,
            ns.timerStyle.PULSE_STRENGTH_MIN), ns.timerStyle.PULSE_STRENGTH_MAX)
        ns.eventEffects.StartPulse(event, template.pulseScaleText == true, template.pulseIndicators == true,
            template.pulseRoles == true, base.badgeCenter, strength / ns.timerStyle.PULSE_STRENGTH_DEFAULT)
    else
        ns.eventEffects.StopPulse(event)
    end

    if not (template and template.useGlow) then
        event.flashFlipbook = nil
        setDangerRound(event, false)
    end

    if template and template.useGlow then
        local color = template.glowUseCustomColor and template.glowColor or ns.timerStyle.CountdownColor(template)
            or (base.eventColor and base.eventColor(event)) or base.color
        local coloured = (event.flatReach or 0) > 0
        local glowType, options = ns.glow.TimerGlow(template, coloured, coloured or event.flatBorder == true,
            coloured and event:GetWidth() + 2 * event.flatReach or nil)
        ns.glow.ApplyBacking(options, glowType, template, color, event.wantedColor, event.flatBorder == false)
        setGlowRounds(event, glowType == "Thin")
        event.flashFlipbook = glowType == "Thin" or glowType == "Medium"
        setDangerRound(event, event.flashFlipbook and event.flatBorder == true and (event.flatReach or 0) == 0)
        ns.glow.ScaleToEvents(glowType, options, base.glowScale or 1)
        if ns.glow.RING_GLOWS[glowType] and event.flatBorder == false then
            options.inset = event.borderWidth or 0
        end
        ns.glow.Show(event.container, glowType, color, options)
        if template.pulse then
            event.glowBreath = event.glowBreath or function()
                return ns.eventEffects.PulseFactor(event)
            end
            event.pulseSteps = event.pulseSteps or { event.pulseGrow, event.pulseShrink }
            ns.glow.Breathe(event.container, event.glowBreath, event.pulseSteps)
        else
            ns.glow.Breathe(event.container, nil)
        end
        if ns.eventEffects.FlashPlaying(event) or event.flashPreviewed then
            ns.glow.SetHeld(event.container, true)
        end
    else
        setGlowRounds(event, false)
        ns.glow.Stop(event.container)
    end
end

function paint.Stop(event)
    setDangerRound(event, false)
    event.flashFlipbook = nil
    setGlowRounds(event, false)
    ns.glow.Stop(event.container)
    ns.eventEffects.StopPulse(event)
    ns.eventEffects.StopFlash(event)
end
