local addonName, ns = ...

local ipairs = ipairs
local pcall = pcall
local C_EncounterTimeline = C_EncounterTimeline
local C_Texture = C_Texture

local deadlyGlow = {}
ns.deadlyGlow = deadlyGlow

local BASE_ATLAS = "combattimeline-fx-deadlyglow-base"
local LIGHT_ATLAS = "combattimeline-fx-deadlyglow-overlay"
local ICON_REFERENCE_SIZE = 35
local GLOW_SIDE = 7 / ICON_REFERENCE_SIZE
local GLOW_TOP = 7 / ICON_REFERENCE_SIZE
local GLOW_BOTTOM = 6.4 / ICON_REFERENCE_SIZE
local HAZE_RED = 1
local HAZE_GREEN = 0.2
local HAZE_BLUE = 0.1
local BASE_SUBLEVEL = 2
local LIGHT_SUBLEVEL = 4
local BAND_RED = 1
local BAND_GREEN = 196 / 255
local BAND_BLUE = 68 / 255
local WARM_HUE_MAX = 75
local WARM_HUE_MIN = 330
local FULL_TURN = 360
local HUE_SECTORS = 6
local DEGREES_PER_SECTOR = 60
local LIGHT_WHITENESS = 0.4
local LIGHT_LAYERS = 1

local function build(event)
    local glow = { textures = {}, lights = {} }
    glow.base = event.container:CreateTexture(nil, "OVERLAY", nil, BASE_SUBLEVEL)
    glow.textures[1] = glow.base
    for layer = 1, LIGHT_LAYERS do
        local light = event.container:CreateTexture(nil, "OVERLAY", nil, LIGHT_SUBLEVEL)
        glow.lights[layer] = light
        glow.textures[#glow.textures + 1] = light
    end
    for _, texture in ipairs(glow.textures) do
        texture:SetSnapToPixelGrid(false)
        texture:SetTexelSnappingBias(0)
    end
    return glow
end

function deadlyGlow.Layout(event)
    ns.eventStyle.PlaceFlatFills(event)
    local glow = event.deadlyGlow
    if not glow then
        return
    end
    local width = event:GetWidth()
    for _, texture in ipairs(glow.textures) do
        texture:ClearAllPoints()
        texture:SetPoint("TOPLEFT", event.container, "TOPLEFT", -width * GLOW_SIDE, width * GLOW_TOP)
        texture:SetPoint("BOTTOMRIGHT", event.container, "BOTTOMRIGHT", width * GLOW_SIDE, -width * GLOW_BOTTOM)
    end
end

local function hueOf(red, green, blue)
    local most, least = math.max(red, green, blue), math.min(red, green, blue)
    local spread = most - least
    if spread == 0 then
        return 0
    end
    local hue
    if most == red then
        hue = ((green - blue) / spread) % HUE_SECTORS
    elseif most == green then
        hue = (blue - red) / spread + 2
    else
        hue = (red - green) / spread + 4
    end
    return hue * DEGREES_PER_SECTOR % FULL_TURN
end

local function isCold(color)
    local hue = hueOf(color.r, color.g, color.b)
    local saturated = math.max(color.r, color.g, color.b) - math.min(color.r, color.g, color.b) > 0
    return saturated and hue > WARM_HUE_MAX and hue < WARM_HUE_MIN
end

local function tint(glow)
    local color = ns.appearance.Get("dangerGlow", "color")
    local own = type(color.r) == "number" and type(color.g) == "number" and type(color.b) == "number"
    local grey = false
    local red, green, blue = 1, 1, 1
    if own then
        grey = isCold(color)
        if grey then
            red, green, blue = color.r, color.g, color.b
        else
            red, green, blue = math.min(color.r / BAND_RED, 1), math.min(color.g / BAND_GREEN, 1),
                math.min(color.b / BAND_BLUE, 1)
        end
    end
    for _, texture in ipairs(glow.textures) do
        texture:SetDesaturated(grey)
    end
    glow.base:SetVertexColor(red, green, blue)
    for _, light in ipairs(glow.lights) do
        light:SetVertexColor(red + (1 - red) * LIGHT_WHITENESS, green + (1 - green) * LIGHT_WHITENESS,
            blue + (1 - blue) * LIGHT_WHITENESS)
    end
end

local function flatColors()
    local color = ns.appearance.Get("dangerGlow", "color")
    if type(color) ~= "table" or type(color.r) ~= "number" or type(color.g) ~= "number" or type(color.b) ~= "number" then
        return { r = BAND_RED, g = BAND_GREEN, b = BAND_BLUE }, { r = HAZE_RED, g = HAZE_GREEN, b = HAZE_BLUE }
    end
    if isCold(color) then
        return color, color
    end
    return color, {
        r = HAZE_RED * math.min(color.r / BAND_RED, 1),
        g = HAZE_GREEN * math.min(color.g / BAND_GREEN, 1),
        b = HAZE_BLUE * math.min(color.b / BAND_BLUE, 1),
    }
end

local function paintFlat(event, fromGame)
    local band, haze = flatColors()
    ns.eventFrame.PaintRing(event.dangerRing, nil)
    local halo = event.dangerHalo
    event.haloTexture = nil
    halo:SetVertexColor(haze.r, haze.g, haze.b)
    halo:Show()
    event.dangerBand:SetVertexColor(band.r, band.g, band.b)
    event.dangerBand:Show()
    if not fromGame then
        for _, strip in ipairs(event.dangerRing) do
            strip:SetAlpha(1)
        end
        halo:SetAlpha(1)
        event.dangerBand:SetAlpha(1)
    end
    deadlyGlow.Layout(event)
end

local function hideFlat(event)
    ns.eventFrame.PaintRing(event.dangerRing, nil)
    event.dangerHalo:Hide()
    event.dangerBand:Hide()
end

local function setShown(glow, shown)
    for _, texture in ipairs(glow.textures) do
        texture:SetShown(shown)
    end
end

function deadlyGlow.Apply(event)
    local glow = event.deadlyGlow
    if not ns.appearance.Get("dangerGlow", "enabled") or not event.eventID then
        if glow then
            setShown(glow, false)
        end
        hideFlat(event)
        return
    end
    if event.flatBorder and not event.dangerRound then
        if glow then
            setShown(glow, false)
        end
        for _, strip in ipairs(event.dangerRing) do
            pcall(C_EncounterTimeline.SetEventIconTextures, event.eventID, ns.eventIndicators.MASK_DANGER, { strip })
        end
        pcall(C_EncounterTimeline.SetEventIconTextures, event.eventID, ns.eventIndicators.MASK_DANGER, { event.dangerHalo })
        pcall(C_EncounterTimeline.SetEventIconTextures, event.eventID, ns.eventIndicators.MASK_DANGER, { event.dangerBand })
        paintFlat(event, true)
        return
    end
    hideFlat(event)
    if not glow then
        if not C_Texture.GetAtlasInfo(BASE_ATLAS) then
            return
        end
        glow = build(event)
        event.deadlyGlow = glow
    end
    for _, texture in ipairs(glow.textures) do
        pcall(C_EncounterTimeline.SetEventIconTextures, event.eventID, ns.eventIndicators.MASK_DANGER, { texture })
    end
    glow.base:SetAtlas(BASE_ATLAS)
    for _, light in ipairs(glow.lights) do
        light:SetAtlas(LIGHT_ATLAS)
        light:SetBlendMode("ADD")
    end
    tint(glow)
    setShown(glow, true)
    deadlyGlow.Layout(event)
end

function deadlyGlow.Preview(event, shown)
    local glow = event.deadlyGlow
    if not shown then
        if glow then
            setShown(glow, false)
        end
        hideFlat(event)
        return
    end
    if event.flatBorder and not event.dangerRound then
        if glow then
            setShown(glow, false)
        end
        paintFlat(event, false)
        return
    end
    hideFlat(event)
    if not glow then
        if not C_Texture.GetAtlasInfo(BASE_ATLAS) then
            return
        end
        glow = build(event)
        event.deadlyGlow = glow
    end
    glow.base:SetAtlas(BASE_ATLAS)
    for _, light in ipairs(glow.lights) do
        light:SetAtlas(LIGHT_ATLAS)
        light:SetBlendMode("ADD")
    end
    for _, texture in ipairs(glow.textures) do
        texture:SetAlpha(1)
    end
    tint(glow)
    setShown(glow, true)
    deadlyGlow.Layout(event)
end

function deadlyGlow.Clear(event)
    local glow = event.deadlyGlow
    if glow then
        setShown(glow, false)
    end
    hideFlat(event)
end
