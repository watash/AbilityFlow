local addonName, ns = ...

local CreateFrame = CreateFrame
local C_Texture = C_Texture
local math = math
local PixelUtil = PixelUtil

local eventFrame = {}
ns.eventFrame = eventFrame

local ROUNDING_MASK_ATLAS = "UI-HUD-CoolDownManager-Mask"

local LEVEL_CONTAINER = 1
local LEVEL_FLASH = 3
local LEVEL_NAME = 3
local LEVEL_BACKDROP_UNDER = 0
local LEVEL_BACKDROP_OVER = 2
local LEVEL_DEBUFF = 4
local LEVEL_DANGER = 4
local LEVEL_ROLES = 4
local LEVEL_COUNTDOWN = 5

local STATE_FILL_SUBLEVEL = 2
local DANGER_FILL_SUBLEVEL = 3
local DANGER_BAND_SUBLEVEL = 4
local STATE_TINT_SUBLEVEL = 1
local RING_MASK_TEXTURE = "Interface\\AddOns\\AbilityFlow\\Media\\Textures\\masks\\ring-mask.png"
local RING_MASK_HOLE_SHARE = 0.5
local RING_MASK_OVERLAP = 1
local PIXEL_BORDER_LIMIT = 1

local HOLDERS = {
    { field = "container", level = LEVEL_CONTAINER },
    { field = "flashHolder", level = LEVEL_FLASH },
    { field = "nameHolder", level = LEVEL_NAME },
    { field = "signHolder", level = LEVEL_DEBUFF },
    { field = "debuffHolder", level = LEVEL_DEBUFF, indicator = true },
    { field = "dangerHolder", level = LEVEL_DANGER, indicator = true },
    { field = "rolesHolder", level = LEVEL_ROLES, indicator = true },
    { field = "cooldownHolder", level = LEVEL_COUNTDOWN },
}

function eventFrame.NewRing(container, sublevel)
    local strip = container:CreateTexture(nil, "BACKGROUND", nil, sublevel)
    ns.eventIndicators.Smooth(strip)
    strip:Hide()
    return { strip }
end

function eventFrame.PlaceRing(ring, frame, outside)
    for _, strip in ipairs(ring) do
        strip:ClearAllPoints()
        strip:SetPoint("TOPLEFT", frame, "TOPLEFT", -outside, outside)
        strip:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", outside, -outside)
    end
end

function eventFrame.SmoothRingMask(event)
    if event.ringMask then
        ns.eventIndicators.Smooth(event.ringMask)
    end
end

local function ensureRingMask(event)
    if event.ringMask then
        return
    end
    event.ringMask = event.container:CreateMaskTexture()
    event.ringMask:SetTexture(RING_MASK_TEXTURE, "CLAMP", "CLAMP")
    eventFrame.SmoothRingMask(event)
end

function eventFrame.PlaceRingMask(event)
    ensureRingMask(event)
    local picture = event:GetWidth()
    if picture <= 0 then
        return
    end
    local hole = picture - 2 * RING_MASK_OVERLAP
    local reach = (hole / RING_MASK_HOLE_SHARE - picture) / 2
    event.ringMask:ClearAllPoints()
    event.ringMask:SetPoint("TOPLEFT", event.texture, "TOPLEFT", -reach, reach)
    event.ringMask:SetPoint("BOTTOMRIGHT", event.texture, "BOTTOMRIGHT", reach, -reach)
end

function eventFrame.MaskRing(event, ring, masked)
    ensureRingMask(event)
    for _, strip in ipairs(ring) do
        if masked and not strip.ringMasked then
            strip:AddMaskTexture(event.ringMask)
            strip.ringMasked = true
        elseif not masked and strip.ringMasked then
            strip:RemoveMaskTexture(event.ringMask)
            strip.ringMasked = false
        end
    end
end

function eventFrame.PaintRing(ring, color)
    for _, strip in ipairs(ring) do
        if color then
            strip:SetColorTexture(color.r, color.g, color.b, color.a or 1)
            ns.eventIndicators.Smooth(strip)
        end
        strip:SetShown(color ~= nil)
    end
end

function eventFrame.Create(parent, level)
    local event = CreateFrame("Frame", nil, parent)
    event:SetScript("OnSizeChanged", function(self)
        if self.ringBorder and self.flatBorder then
            eventFrame.PlaceRingMask(self)
        end
    end)
    if level then
        event:SetFrameLevel(level)
    end
    for _, holder in ipairs(HOLDERS) do
        local child = CreateFrame("Frame", nil, event)
        child:SetAllPoints()
        child:SetFrameLevel(event:GetFrameLevel() + holder.level)
        event[holder.field] = child
    end
    event.container.glowSize = function()
        local reach = 2 * (event.borderWidth or 0)
        return event:GetWidth() + reach, event:GetHeight() + reach
    end

    event.borderFill = event.container:CreateTexture(nil, "BACKGROUND")
    event.borderFill:SetAllPoints()
    ns.eventIndicators.Smooth(event.borderFill)
    event.borderFill:Hide()
    event.borderRing = eventFrame.NewRing(event.container, 0)
    event.stateRing = eventFrame.NewRing(event.container, STATE_FILL_SUBLEVEL)
    event.dangerRing = eventFrame.NewRing(event.container, DANGER_FILL_SUBLEVEL)
    event.dangerHalo = event.container:CreateTexture(nil, "BACKGROUND", nil, DANGER_FILL_SUBLEVEL)
    ns.eventIndicators.Smooth(event.dangerHalo)
    event.dangerHalo:Hide()
    event.dangerBand = event.container:CreateTexture(nil, "BACKGROUND", nil, DANGER_BAND_SUBLEVEL)
    ns.eventIndicators.Smooth(event.dangerBand)
    event.dangerBand:Hide()

    event.texture = event.container:CreateTexture(nil, "ARTWORK")
    event.texture:SetAllPoints()
    event.texture:SetSnapToPixelGrid(false)
    event.texture:SetTexelSnappingBias(0)
    if C_Texture.GetAtlasInfo(ROUNDING_MASK_ATLAS) then
        event.pictureMask = event.container:CreateMaskTexture()
        event.pictureMask:SetAtlas(ROUNDING_MASK_ATLAS)
    end

    event.stateTint = event.container:CreateTexture(nil, "ARTWORK", nil, STATE_TINT_SUBLEVEL)
    event.stateTint:SetAllPoints(event.texture)
    ns.eventIndicators.Smooth(event.stateTint)
    event.stateTint:Hide()

    event.texts = { cooldown = event.cooldownHolder:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall") }
    event.texts.cooldown:SetPoint("CENTER", event, "CENTER")

    event.debuffIndicator = event.debuffHolder:CreateTexture(nil, "OVERLAY")
    ns.eventIndicators.Smooth(event.debuffIndicator)

    ns.eventEffects.BuildFlash(event)
    return event
end

function eventFrame.SetStrata(event, strata)
    event:SetFrameStrata(strata)
    for _, holder in ipairs(HOLDERS) do
        event[holder.field]:SetFrameStrata(strata)
    end
    if event.nameBackdrop then
        event.nameBackdrop:SetFrameStrata(strata)
    end
end

function eventFrame.SetLevel(event, level, indicatorLevel)
    local moved = event:GetFrameLevel() ~= level
    event:SetFrameLevel(level)
    event.indicatorLevel = indicatorLevel
    for _, holder in ipairs(HOLDERS) do
        event[holder.field]:SetFrameLevel((holder.indicator and indicatorLevel or level) + holder.level)
    end
    eventFrame.PlaceBackdrop(event)
    if moved then
        ns.glow.Relevel(event.container)
    end
end

function eventFrame.PlaceBackdrop(event)
    if event.nameBackdrop then
        local over = event.backdropOnTop == true
        local base = over and event.indicatorLevel or event:GetFrameLevel()
        event.nameBackdrop:SetFrameLevel(base + (over and LEVEL_BACKDROP_OVER or LEVEL_BACKDROP_UNDER))
        event.nameHolder:SetFrameLevel(base + LEVEL_NAME)
    end
end

local function pixelInFrameUnits(event)
    local scale = event:GetEffectiveScale()
    return PixelUtil.GetPixelToUIUnitFactor() / ((scale and scale > 0) and scale or 1)
end

local function syncGlowSnapping(event)
    ns.glow.SetRingSmooth(event.container, true)
end

function eventFrame.SetBorder(event, thickness, color)
    local container, texture = event.container, event.texture
    event.wantedThickness, event.wantedColor = thickness, color
    if color and thickness > 0 and event.flatBorder then
        local inPixels = math.min(thickness, PIXEL_BORDER_LIMIT)
        thickness = inPixels * pixelInFrameUnits(event) + (thickness - inPixels)
    end
    if color and thickness > 0 and event.pulsing then
        thickness = math.max(thickness, pixelInFrameUnits(event)) / ns.eventEffects.PulseLow(event)
    end
    container:ClearAllPoints()
    texture:ClearAllPoints()
    if thickness > 0 then
        container:SetPoint("TOPLEFT", event, "TOPLEFT", -thickness, thickness)
        container:SetPoint("BOTTOMRIGHT", event, "BOTTOMRIGHT", thickness, -thickness)
        texture:SetPoint("TOPLEFT", container, "TOPLEFT", thickness, -thickness)
        texture:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", -thickness, thickness)
    else
        container:SetAllPoints()
        texture:SetAllPoints()
    end
    event.borderWidth = thickness
    syncGlowSnapping(event)
    if event.ringBorder then
        event.borderFill:Hide()
        eventFrame.PaintRing(event.borderRing, color and thickness > 0 and color or nil)
        for _, strip in ipairs(event.borderRing) do
            ns.eventIndicators.Smooth(strip)
        end
        eventFrame.SmoothRingMask(event)
        ns.eventStyle.PlaceFlatFills(event)
        return
    end
    eventFrame.PaintRing(event.borderRing, nil)
    if color and thickness > 0 then
        event.borderFill:SetColorTexture(color.r, color.g, color.b, color.a)
        ns.eventIndicators.Smooth(event.borderFill)
        event.borderFill:Show()
    elseif not event.borderIsFrame then
        event.borderFill:Hide()
    end
end

function eventFrame.SetPulsing(event, pulsing)
    if (event.pulsing or false) == pulsing then
        return
    end
    event.pulsing = pulsing
    syncGlowSnapping(event)
    if event.wantedThickness then
        eventFrame.SetBorder(event, event.wantedThickness, event.wantedColor)
    end
end

function eventFrame.SetRounded(event, reach)
    if reach == nil then
        if event.pictureRounded then
            event.texture:RemoveMaskTexture(event.pictureMask)
            event.pictureRounded = false
        end
        return
    end
    if not event.pictureMask then
        return
    end
    if event.pictureMaskReach ~= reach then
        event.pictureMaskReach = reach
        event.pictureMask:ClearAllPoints()
        event.pictureMask:SetPoint("TOPLEFT", event.texture, "TOPLEFT", -reach, reach)
        event.pictureMask:SetPoint("BOTTOMRIGHT", event.texture, "BOTTOMRIGHT", reach, -reach)
    end
    if not event.pictureRounded then
        event.texture:AddMaskTexture(event.pictureMask)
        event.pictureRounded = true
        ns.eventEffects.Resync(event)
    end
end
