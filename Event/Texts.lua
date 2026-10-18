local addonName, ns = ...

local pcall = pcall
local math = math
local issecretvalue = issecretvalue
local C_EncounterTimeline = C_EncounterTimeline
local Enum = Enum

local eventStyle = ns.eventStyle
local state = eventStyle.state

local TEXT_SHADOW_OFFSET = 1
local PERCENT = 100
local BACKGROUND_BASE_RAISE = 0.02
local NAME_GAP = 4
eventStyle.NAME_GAP = NAME_GAP
local EVENT_COLOR_TRIGGER = Enum.EncounterEventColorTrigger.TextWarning

local colorSources = {}

function eventStyle.AddColorSource(source)
    colorSources[#colorSources + 1] = source
end

function eventStyle.OwnColor(event, kind)
    if not event.eventID then
        return nil
    end
    for _, source in ipairs(colorSources) do
        local color = source(event.eventID, kind)
        if color then
            return color
        end
    end
    return nil
end

function eventStyle.RefreshOwnColors(event)
    eventStyle.ApplyTextColour(event, "name")
    if state.border.style == "DEBUFF" or state.border.style == "BLIZZARD" then
        eventStyle.AssignBorderArt(event)
        eventStyle.ApplyBorder(event)
    end
end

function eventStyle.ApplyTextColour(event, key)
    local style = state.texts[key]
    local fontString = event.texts[key]
    local opacity = 1
    local ownColor = style.useEventColor and eventStyle.OwnColor(event, "text")
    if ownColor then
        fontString:SetTextColor(ownColor.r, ownColor.g, ownColor.b, ownColor.a * opacity)
        return
    end
    if style.useEventColor and event.debuffEntry then
        local color = event.debuffEntry.color
        fontString:SetTextColor(color.r, color.g, color.b, color.a * opacity)
        return
    end
    if style.useEventColor and event.debuffSecret and event.eventID then
        local ok, color = pcall(C_EncounterTimeline.GetEventColor, event.eventID, EVENT_COLOR_TRIGGER)
        if ok and color then
            fontString:SetTextColor(color.r, color.g, color.b, opacity)
            return
        end
    end
    local color = style.color
    fontString:SetTextColor(color.r, color.g, color.b, color.a)
end

function eventStyle.NameSide()
    return state.texts.name.mirrored and "RIGHT" or "LEFT"
end

function eventStyle.NameSideOf(event)
    local side = eventStyle.NameSide()
    if event.nameFlipped then
        return side == "LEFT" and "RIGHT" or "LEFT"
    end
    return side
end

function eventStyle.PlaceName(event)
    local side = eventStyle.NameSideOf(event)
    local name = event.texts.name
    local style = state.texts.name
    local shiftX, shiftY = style.shiftX * state.scale, style.shiftY * state.scale
    shiftY = shiftY + (event.nameLift or 0)
    name:ClearAllPoints()
    local gap = NAME_GAP + (event.flatReach or 0)
    if side == "LEFT" then
        name:SetPoint("RIGHT", event.nameAnchor, "LEFT", -gap - shiftX, shiftY)
    else
        name:SetPoint("LEFT", event.nameAnchor, "RIGHT", gap + shiftX, shiftY)
    end
end

local function placeCountdown(event)
    local style = state.texts.cooldown
    local countdown = event.texts.cooldown
    countdown:ClearAllPoints()
    countdown:SetPoint("CENTER", event, style.anchor, style.shiftX * state.scale, style.shiftY * state.scale)
end

local function limitReach(reach, extent)
    if issecretvalue(extent) then
        return reach
    end
    return math.max(reach, -extent / 2)
end

function eventStyle.PlaceTextBackground(event, key, size, padding, paddingY)
    local style = state.texts[key]
    local background = event.textBackgrounds[key]
    local fontString = event.texts[key]
    local offsetX, offsetY = padding or style.backgroundOffsetX, paddingY or padding or style.backgroundOffsetY
    if offsetX < 0 then
        offsetX = limitReach(offsetX, fontString:GetStringWidth())
    end
    if offsetY < 0 then
        offsetY = limitReach(offsetY, fontString:GetStringHeight())
    end
    local lift = size * (BACKGROUND_BASE_RAISE + style.backgroundRaise / PERCENT)
    background:ClearAllPoints()
    background:SetPoint("TOPLEFT", fontString, "TOPLEFT", -offsetX, offsetY + lift)
    background:SetPoint("BOTTOMRIGHT", fontString, "BOTTOMRIGHT", offsetX, -offsetY + lift)
    local backdrop = key == "name" and event.nameBackdrop
    if backdrop then
        local shift = -style.backgroundBorderOffset
        backdrop:ClearAllPoints()
        backdrop:SetPoint("TOPLEFT", fontString, "TOPLEFT", -offsetX + shift, offsetY + lift - shift)
        backdrop:SetPoint("BOTTOMRIGHT", fontString, "BOTTOMRIGHT", offsetX - shift, -offsetY + lift + shift)
    end
end

local function drawBackground(event, key, path, borderPath, color)
    local style = state.texts[key]
    local background = event.textBackgrounds[key]
    if key == "name" then
        event.backdropOnTop = style.backgroundOnTop
        ns.eventFrame.PlaceBackdrop(event)
        local backdrop = event.nameBackdrop
        if path and borderPath then
            ns.textBorder.Set(backdrop, borderPath, style.backgroundBorderThickness, style.backgroundBorderColor)
        else
            ns.textBorder.Clear(backdrop)
        end
    end
    if path then
        background:SetTexture(path)
        background:SetVertexColor(color.r, color.g, color.b, color.a)
        background:Show()
    else
        background:Hide()
    end
end

function eventStyle.PaintNameBackground(event, template)
    local style = state.texts.name
    local mode = template and template.nameBackground
    local shown
    if mode == ns.timerStyle.BACKGROUND_SHOW then
        shown = true
    elseif mode == ns.timerStyle.BACKGROUND_HIDE then
        shown = false
    else
        shown = style.backgroundPath ~= nil
    end
    local color = style.backgroundColor
    if template and template.nameBackgroundUseColor and template.nameBackgroundColor then
        color = template.nameBackgroundColor
    end
    drawBackground(event, "name", shown and (style.backgroundPath or style.backgroundAnyPath) or nil,
        shown and (style.backgroundBorderPath or style.backgroundAnyBorderPath) or nil, color)
end

function eventStyle.ApplyText(event, key)
    local style = state.texts[key]
    local fontString = event.texts[key]
    local size = style.size * state.scale
    event.nameSizeApplied = nil
    if not fontString:SetFont(style.path, size, style.outline) then
        fontString:SetFont(state.defaultFontPath, size, style.outline)
    end
    eventStyle.ApplyTextColour(event, key)
    if key == "name" then
        eventStyle.PlaceName(event)
    elseif key == "cooldown" then
        placeCountdown(event)
    end
    if style.shadow then
        fontString:SetShadowColor(0, 0, 0, 1)
        fontString:SetShadowOffset(TEXT_SHADOW_OFFSET, -TEXT_SHADOW_OFFSET)
    else
        fontString:SetShadowOffset(0, 0)
    end

    eventStyle.PlaceTextBackground(event, key, size)
    drawBackground(event, key, style.backgroundPath, style.backgroundBorderPath, style.backgroundColor)
end

local paintBase = {}
local paintEventSize = 0
local paintReach = 0

paintBase.restoreColor = function(event)
    eventStyle.ApplyTextColour(event, "cooldown")
end
paintBase.eventColor = function(event)
    if not state.texts.cooldown.useEventColor then
        return nil
    end
    return eventStyle.OwnColor(event, "text") or (event.debuffEntry and event.debuffEntry.color)
end
paintBase.badgeCenter = function(kind)
    return eventStyle.BadgeCenter(kind, paintEventSize, paintReach)
end
paintBase.paintNameBackground = eventStyle.PaintNameBackground

function eventStyle.PaintCountdown(event, template, iconSize)
    local style = state.texts.cooldown
    paintBase.fontPath = style.path
    paintBase.fallbackFontPath = state.defaultFontPath
    paintBase.fontSize = style.size * state.scale
    paintBase.outline = style.outline
    paintBase.color = style.color
    local nameStyle = state.texts.name
    paintBase.nameFontPath = nameStyle.path
    paintBase.nameFontSize = nameStyle.size * state.scale
    paintBase.nameOutline = nameStyle.outline
    paintBase.glowScale = state.scale
    paintEventSize = iconSize
    paintReach = event.flatReach or 0
    ns.timerPaint.Apply(event, template, paintBase)
end
