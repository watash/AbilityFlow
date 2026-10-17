local addonName, ns = ...

local effects = ns.eventEffects

local FLASH_GLOW_SUBLEVEL = -3
local FLASH_SWIRL_SUBLEVEL = -2

local FLASH_SQUARE_OUTSET = 13.5 / (86 - 2 * 13.5)
local FLASH_BLIZZARD_SIDE = 8 / 35
local FLASH_GLOW_ALPHA = 0.7
local FLASH_MASK_OUTSET = 1
local SQUARE_HALO = "Interface\\AddOns\\AbilityFlow\\Media\\Textures\\flash\\halo.png"
local RIM_MASK = "Interface\\AddOns\\AbilityFlow\\Media\\Textures\\flash\\rim-mask.png"
local FLASH_ICON_SIZE = 35
local FLASH_FADE = 0.2
local FLASH_SWIRL_TURN = 0.6
local FLASH_SWIRL_FADE_DELAY = 0.4
local FLASH_SWIRL_DEGREES = -180

function effects.BuildFlash(event)
    local holder = event.flashHolder
    event.flashGlow = holder:CreateTexture(nil, "OVERLAY", nil, FLASH_GLOW_SUBLEVEL)
    event.flashGlow:SetAtlas("combattimeline-fx-highlight", false, nil, nil, "CLAMP", "CLAMP")
    event.flashGlow:SetAlpha(0)

    event.flashSwirl = holder:CreateTexture(nil, "OVERLAY", nil, FLASH_SWIRL_SUBLEVEL)
    event.flashSwirl:SetAtlas("combattimeline-fx-highlight-fx", true)
    event.flashSwirl:SetBlendMode("ADD")
    event.flashSwirl:SetPoint("CENTER", event.container, "CENTER")
    event.flashSwirlWidth, event.flashSwirlHeight = event.flashSwirl:GetSize()
    event.flashSwirl:SetAlpha(0)

    local mask = holder:CreateMaskTexture(nil, "OVERLAY", nil, -2)
    mask:SetAtlas("combattimeline-fx-highlight-mask", true, nil, nil, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    event.flashSwirl:AddMaskTexture(mask)
    event.flashMask = mask
    event.flashMaskRim = holder:CreateMaskTexture(nil, "OVERLAY", nil, -2)
    event.flashMaskRim:SetTexture(RIM_MASK, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    event.flashMaskRim:SetAllPoints(event.container)
    event.flashMaskKind = "game"

    local group = holder:CreateAnimationGroup()
    group:SetToFinalAlpha(true)
    group:SetScript("OnFinished", function()
        effects.RoundForFlash(event, false)
        if not event.flashPreviewed then
            ns.glow.SetHeld(event.container, false)
        end
    end)

    local turn = group:CreateAnimation("Rotation")
    turn:SetTarget(event.flashSwirl)
    turn:SetDuration(FLASH_SWIRL_TURN)
    turn:SetOrder(1)
    turn:SetSmoothing("OUT")
    turn:SetDegrees(FLASH_SWIRL_DEGREES)
    turn:SetOrigin("CENTER", 0, 0)

    local swirlFade = group:CreateAnimation("Alpha")
    swirlFade:SetTarget(event.flashSwirl)
    swirlFade:SetDuration(FLASH_FADE)
    swirlFade:SetOrder(1)
    swirlFade:SetStartDelay(FLASH_SWIRL_FADE_DELAY)
    swirlFade:SetSmoothing("OUT")
    swirlFade:SetFromAlpha(1)
    swirlFade:SetToAlpha(0)

    local glowIn = group:CreateAnimation("Alpha")
    glowIn:SetTarget(event.flashGlow)
    glowIn:SetDuration(FLASH_FADE)
    glowIn:SetOrder(1)
    glowIn:SetSmoothing("IN")
    glowIn:SetFromAlpha(0)
    glowIn:SetToAlpha(FLASH_GLOW_ALPHA)

    local glowOut = group:CreateAnimation("Alpha")
    glowOut:SetTarget(event.flashGlow)
    glowOut:SetDuration(FLASH_FADE)
    glowOut:SetOrder(2)
    glowOut:SetSmoothing("OUT")
    glowOut:SetFromAlpha(FLASH_GLOW_ALPHA)
    glowOut:SetToAlpha(0)

    event.flash = group
end

local function setSwirlMask(event, kind)
    if event.flashMaskKind == kind then
        return
    end
    event.flashMaskKind = kind
    event.flashSwirl:RemoveMaskTexture(kind == "game" and event.flashMaskRim or event.flashMask)
    event.flashSwirl:AddMaskTexture(kind == "game" and event.flashMask or event.flashMaskRim)
    effects.Resync(event)
end

local function setHaloArt(event, kind)
    if event.flashHaloKind == kind then
        return
    end
    event.flashHaloKind = kind
    local halo = event.flashGlow
    if kind == "game" then
        halo:SetAtlas("combattimeline-fx-highlight", false, nil, nil, "CLAMP", "CLAMP")
    else
        halo:SetTexture(SQUARE_HALO, "CLAMP", "CLAMP")
        halo:SetTexCoord(0, 1, 0, 1)
    end
end

function effects.RoundForFlash(event, on)
    if (event.flashRounds or false) == on then
        return
    end
    event.flashRounds = on
    ns.eventFrame.SetRounded(event, ns.eventStyle.RoundingReach(event))
end

function effects.FlashPlaying(event)
    return event.flash ~= nil and event.flash:IsPlaying()
end

function effects.PlayFlash(event, referenceSize)
    event.flashGlow:ClearAllPoints()
    local gameBorder = ns.eventStyle.state.border.style == "BLIZZARD"
    local shown = ns.glow.ShownOn(event.container)
    local flipbook = event.flashFlipbook == true or shown == "Thin" or shown == "Medium"
    local gameLook = gameBorder or (flipbook and (event.flatReach or 0) == 0)
    setHaloArt(event, gameLook and "game" or "square")
    if gameLook then
        local width = event:GetWidth()
        event.flashGlow:SetPoint("TOPLEFT", event.texture, "TOPLEFT", -width * FLASH_BLIZZARD_SIDE, width * FLASH_BLIZZARD_SIDE)
        event.flashGlow:SetPoint("BOTTOMRIGHT", event.texture, "BOTTOMRIGHT", width * FLASH_BLIZZARD_SIDE,
            -width * FLASH_BLIZZARD_SIDE)
    else
        local width, height = event.container:GetSize()
        local outset = FLASH_SQUARE_OUTSET
        local outsetX, outsetY = width * outset, height * outset
        event.flashGlow:SetPoint("TOPLEFT", event.container, "TOPLEFT", -outsetX, outsetY)
        event.flashGlow:SetPoint("BOTTOMRIGHT", event.container, "BOTTOMRIGHT", outsetX, -outsetY)
    end
    local grow = referenceSize and event:GetWidth() / referenceSize or 1
    local maskReach = FLASH_MASK_OUTSET + (gameLook and not gameBorder and ns.eventStyle.FrameOutset(event:GetWidth()) or 0)
    if event.flashMaskReach ~= maskReach then
        event.flashMaskReach = maskReach
        event.flashMask:ClearAllPoints()
        event.flashMask:SetPoint("TOPLEFT", event.container, "TOPLEFT", -maskReach, maskReach)
        event.flashMask:SetPoint("BOTTOMRIGHT", event.container, "BOTTOMRIGHT", maskReach, -maskReach)
        effects.Resync(event)
    end
    setSwirlMask(event, (gameBorder or flipbook) and "game" or "rim")
    effects.RoundForFlash(event, not gameBorder and flipbook and (event.flatReach or 0) == 0)
    if not gameLook then
        grow = event.container:GetWidth() / FLASH_ICON_SIZE
    end
    event.flashSwirl:SetSize(event.flashSwirlWidth * grow, event.flashSwirlHeight * grow)
    event.flashSwirl:SetAlpha(1)
    ns.glow.SetHeld(event.container, true)
    event.flash:Play()
end

function effects.HoldForPreview(event, previewed)
    event.flashPreviewed = previewed or nil
    if not previewed and not effects.FlashPlaying(event) then
        ns.glow.SetHeld(event.container, false)
    end
end

function effects.StopFlash(event)
    event.flashPreviewed = nil
    effects.RoundForFlash(event, false)
    ns.glow.SetHeld(event.container, false)
    event.flash:Stop()
    event.flashSwirl:SetAlpha(0)
    event.flashGlow:SetAlpha(0)
end
