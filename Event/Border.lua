local addonName, ns = ...

local ipairs = ipairs
local pcall = pcall
local math = math
local C_EncounterTimeline = C_EncounterTimeline
local C_Texture = C_Texture

local eventStyle = ns.eventStyle
local state = eventStyle.state

local FRAME_OUTSET_RATIO = 0.06
local MASK_REACH_RATIO = 0.5
local TYPE_FILL_SUBLEVEL = 1
local OUTLINE_ATLAS = "UI-HUD-CoolDownManager-IconOverlay"
local OUTLINE_GROWTH = 1.1
local OUTLINE_SIDE_RATIO = 7 / 35 * OUTLINE_GROWTH
local OUTLINE_TOP_RATIO = 6 / 35 * OUTLINE_GROWTH
local OUTLINE_SUBLEVEL = -1
local OUTLINE_LAYERS = 2
local BARE_FRAME_WIDTH = 2
local HALO_STEPS = {
    { thickness = 2, reach = 0.13 },
    { thickness = 4, reach = 0.15 },
    { thickness = 7, reach = 0.17 },
    { thickness = 11, reach = 0.20 },
    { thickness = math.huge, reach = 0.24 },
}
local HALO_TEXTURE = "Interface\\AddOns\\AbilityFlow\\Media\\Textures\\danger-glow\\reach-%02d.png"
local PERCENT = 100
local BAND_REACH = 0.08

local function applyOutline(event, shown)
    if shown and not event.outlines and C_Texture.GetAtlasInfo(OUTLINE_ATLAS) then
        event.outlines = {}
        for layer = 1, OUTLINE_LAYERS do
            local outline = event.container:CreateTexture(nil, "BACKGROUND", nil, OUTLINE_SUBLEVEL)
            outline:SetAtlas(OUTLINE_ATLAS)
            outline:SetSnapToPixelGrid(false)
            outline:SetTexelSnappingBias(0)
            event.outlines[layer] = outline
        end
    end
    if not event.outlines then
        return
    end
    local width = event:GetWidth()
    local markOn = ns.statusMark and ns.statusMark.IsFramed(event)
    for _, outline in ipairs(event.outlines) do
        outline:SetShown(shown and not markOn)
        if shown then
            outline:ClearAllPoints()
            outline:SetPoint("TOPLEFT", event.texture, "TOPLEFT", -width * OUTLINE_SIDE_RATIO, width * OUTLINE_TOP_RATIO)
            outline:SetPoint("BOTTOMRIGHT", event.texture, "BOTTOMRIGHT", width * OUTLINE_SIDE_RATIO,
                -width * OUTLINE_SIDE_RATIO)
        end
    end
end

eventStyle.ownFrameAtlas = "UI-HUD-CoolDownManager-Debuff-Poison"

local function applyOwnFrame(event)
    local border = state.border
    local blizzard = border.style == "BLIZZARD"
    local color = blizzard and border.typeFrames and eventStyle.OwnColor(event, "border") or nil
    local hideTypes = color ~= nil or (blizzard and not border.typeFrames)
    if color and not event.ownFrame then
        event.ownFrame = event.container:CreateTexture(nil, "OVERLAY")
        event.ownFrame:SetAllPoints(event.container)
    end
    local wasShown = event.ownFrameShown == true
    event.ownFrameShown = color ~= nil
    local markOn = ns.statusMark and ns.statusMark.IsFramed(event)
    if event.ownFrame then
        if color then
            event.ownFrame:SetAtlas(eventStyle.ownFrameAtlas)
            event.ownFrame:SetDesaturated(true)
            event.ownFrame:SetVertexColor(color.r, color.g, color.b)
            ns.eventIndicators.Smooth(event.ownFrame)
        end
        event.ownFrame:SetShown(color ~= nil and not markOn)
    end
    local wereHidden = event.typeFillsHidden == true
    event.typeFillsHidden = hideTypes
    if (hideTypes or wereHidden or wasShown) and not markOn then
        for _, fills in ipairs(event.debuffBorders or {}) do
            for _, fill in ipairs(fills) do
                fill:SetShown(not hideTypes and event.debuffBorderShown == true)
            end
        end
    end
end

function eventStyle.MaskReach(outset)
    return outset * MASK_REACH_RATIO
end

function eventStyle.RoundingReach(event)
    local width = event:GetWidth()
    if state.border.style == "BLIZZARD" then
        return eventStyle.MaskReach(eventStyle.BorderThickness(width))
    end
    if (event.glowRounds or event.flashRounds) and (event.flatReach or 0) == 0 then
        return eventStyle.MaskReach(eventStyle.FrameOutset(width))
    end
    return nil
end

function eventStyle.FrameOutset(width)
    return math.max(1, math.floor(width * FRAME_OUTSET_RATIO + 0.5))
end

function eventStyle.BorderThickness(width)
    local border = state.border
    if border.style == "BLIZZARD" then
        return eventStyle.FrameOutset(width)
    end
    if border.style == "SOLID" or border.style == "DEBUFF" then
        return math.max(1, math.floor(border.thickness * state.scale + 0.5))
    end
    return 0
end

function eventStyle.AssignBorderArt(event)
    local blizzardStyle = state.border.style == "BLIZZARD"
    local ownColor = state.border.style == "DEBUFF" and eventStyle.OwnColor(event, "border") or nil
    for index, entry in ipairs(ns.debuff.TYPES) do
        for _, fill in ipairs(event.debuffBorders[index]) do
            if event.eventID then
                pcall(C_EncounterTimeline.SetEventIconTextures, event.eventID, entry.mask, { fill })
            end
            fill:SetTexture(nil)
            if blizzardStyle then
                fill:SetDrawLayer("OVERLAY")
            else
                fill:SetDrawLayer("BACKGROUND", TYPE_FILL_SUBLEVEL)
            end
            if blizzardStyle and fill ~= event.debuffBorders[index][1] then
                fill:SetTexture(nil)
            elseif blizzardStyle and C_Texture.GetAtlasInfo(entry.frameAtlas) then
                fill:SetAtlas(entry.frameAtlas)
            else
                local color = ownColor or entry.color
                fill:SetColorTexture(color.r, color.g, color.b, color.a)
            end
            ns.eventIndicators.Smooth(fill)
        end
    end
    event.borderArtStyle = state.border.style
end

function eventStyle.PlaceFlatFills(event)
    local container = event.container
    local outset = (event.flatReach or 0) > 0 and 0 or math.max(1, math.floor(BARE_FRAME_WIDTH * state.scale + 0.5))
    local flat = event.flatBorder == true
    if flat then
        ns.eventFrame.PlaceRingMask(event)
    end
    ns.eventFrame.PlaceRing(event.borderRing, container, 0)
    ns.eventFrame.MaskRing(event, event.borderRing, flat)
    ns.eventFrame.PlaceRing(event.stateRing, container, outset)
    ns.eventFrame.MaskRing(event, event.stateRing, flat)
    ns.eventFrame.PlaceRing(event.dangerRing, container, outset)
    ns.eventFrame.MaskRing(event, event.dangerRing, flat)
    for _, fills in ipairs(event.debuffBorders or {}) do
        ns.eventFrame.PlaceRing(fills, container, 0)
        ns.eventFrame.MaskRing(event, fills, flat)
    end
    local halo = event.dangerHalo
    local step = HALO_STEPS[#HALO_STEPS]
    for _, candidate in ipairs(HALO_STEPS) do
        if (event.flatReach or 0) <= candidate.thickness then
            step = candidate
            break
        end
    end
    local texture = HALO_TEXTURE:format(math.floor(step.reach * PERCENT + 0.5))
    if event.haloTexture ~= texture then
        event.haloTexture = texture
        halo:SetTexture(texture)
    end
    local size = event:GetWidth() + 2 * (event.flatReach or 0)
    local reach = size * step.reach
    halo:ClearAllPoints()
    halo:SetPoint("TOPLEFT", container, "TOPLEFT", -reach, reach)
    halo:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", reach, -reach)
    local band = event.dangerBand
    local bandReach = size * BAND_REACH
    band:SetTexture(HALO_TEXTURE:format(math.floor(BAND_REACH * PERCENT + 0.5)))
    band:ClearAllPoints()
    band:SetPoint("TOPLEFT", container, "TOPLEFT", -bandReach, bandReach)
    band:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", bandReach, -bandReach)
end

function eventStyle.ApplyBorder(event)
    local border = state.border
    local thickness = eventStyle.BorderThickness(event:GetWidth())
    local typeStyle = border.style == "DEBUFF" or border.style == "BLIZZARD"
    local hasColor = border.style == "SOLID" or border.style == "DEBUFF"
    event.flatReach = hasColor and thickness or 0
    event.flatBorder = border.style ~= "BLIZZARD"
    event.ringBorder = event.flatBorder
    local color = border.style == "DEBUFF" and eventStyle.OwnColor(event, "border") or border.color
    ns.eventFrame.SetBorder(event, thickness, hasColor and color or nil)
    local bare = event.flatReach == 0
    if event.dangerFlat ~= event.flatBorder or event.dangerBare ~= bare then
        event.dangerFlat, event.dangerBare = event.flatBorder, bare
        if event.eventID and ns.deadlyGlow then
            ns.deadlyGlow.Apply(event)
        end
    end
    ns.eventFrame.SetRounded(event, eventStyle.RoundingReach(event))
    applyOutline(event, border.style == "BLIZZARD")
    if typeStyle then
        if not event.debuffBorderShown or event.borderArtStyle ~= border.style then
            event.debuffBorderShown = true
            eventStyle.AssignBorderArt(event)
        end
        eventStyle.PlaceFlatFills(event)
    elseif event.debuffBorderShown then
        event.debuffBorderShown = false
        for _, fills in ipairs(event.debuffBorders) do
            for _, fill in ipairs(fills) do
                fill:Hide()
            end
        end
    end
    applyOwnFrame(event)
end
