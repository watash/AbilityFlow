local addonName, ns = ...

local ipairs = ipairs
local CreateColor = CreateColor
local CreateFrame = CreateFrame
local C_Texture = C_Texture
local unpack = unpack
local math = math

local timeline = ns.timeline

local TRAIL_ATLAS = "combattimeline-line-icontrail"
local TRAIL_OVERLAP = 1
local TRAIL_SECONDS = 0.525
local TRAIL_FAR_SHARE = 0
local TRAIL_MAX_ALPHA = 1
local TRAIL_FULL_SHARE = 0.1
local TRAIL_FADE_SECONDS = 0.15
local TRAIL_FRAME_SECONDS = 1 / 60
local TRAIL_LAYER_LENGTHS = { 1, 0.6 }
local TRAIL_THICKNESS_FOLLOW = 1
local TRAIL_LEVEL = 1
local TRAIL_SUBLEVEL = -1
timeline.TRAIL_ATLAS = TRAIL_ATLAS
timeline.TRAIL_OVERLAP = TRAIL_OVERLAP
timeline.TRAIL_SECONDS = TRAIL_SECONDS
timeline.TRAIL_LAYER_LENGTHS = TRAIL_LAYER_LENGTHS
timeline.TRAIL_FADE_SECONDS = TRAIL_FADE_SECONDS
timeline.TRAIL_FULL_SHARE = TRAIL_FULL_SHARE
local ORIENTATION_HORIZONTAL = timeline.ORIENTATION_HORIZONTAL
local TRACK_SPAN_SECONDS = timeline.TRACK_SPAN_SECONDS

local function trailOf(event)
    if not event.trail then
        local info = C_Texture.GetAtlasInfo(TRAIL_ATLAS)
        if not info then
            return nil
        end
        event.trailHost = CreateFrame("Frame", nil, timeline.frame)
        event.trailHost:SetFrameLevel(timeline.frame:GetFrameLevel() + TRAIL_LEVEL)
        event.trailHost:SetAllPoints(timeline.frame)
        event.trailHost:SetClipsChildren(true)
        event.trails = {}
        for layer = 1, #TRAIL_LAYER_LENGTHS do
            local texture = event.trailHost:CreateTexture(nil, "OVERLAY", nil, TRAIL_SUBLEVEL)
            texture:SetAtlas(TRAIL_ATLAS)
            texture:SetBlendMode("ADD")
            texture:SetSnapToPixelGrid(false)
            texture:SetTexelSnappingBias(0)
            texture:SetAlpha(0)
            event.trails[layer] = texture
        end
        event.trail = event.trails[1]
        event.trailLevel = 0
        event.trailNear, event.trailFar = CreateColor(1, 1, 1, 0), CreateColor(1, 1, 1, 0)
        event.trailLength, event.trailThickness = info.width, info.height
        event.trailArea = info
    end
    return event.trail
end

local function setCorners(event, trail, ...)
    local area = event.trailArea
    local corners = { ... }
    for index = 1, #corners, 2 do
        corners[index] = area.leftTexCoord + corners[index] * (area.rightTexCoord - area.leftTexCoord)
        corners[index + 1] = area.topTexCoord + corners[index + 1] * (area.bottomTexCoord - area.topTexCoord)
    end
    trail:SetTexCoord(unpack(corners))
end

local function layout(event)
    local horizontal = timeline.GetOrientation() == ORIENTATION_HORIZONTAL
    local behindIsHigher = timeline.EntersFromStart()
    local lineScale = timeline.GetLineScale and timeline.GetLineScale() or 1
    local trackLength = timeline.GetTrackLength()
    local width = event:GetWidth()
    local laid = event.trailLaid
    if not laid then
        laid = {}
        event.trailLaid = laid
    elseif laid.horizontal == horizontal and laid.behindIsHigher == behindIsHigher and laid.width == width
        and laid.lineScale == lineScale and laid.trackLength == trackLength then
        return
    end
    laid.horizontal, laid.behindIsHigher, laid.width = horizontal, behindIsHigher, width
    laid.lineScale, laid.trackLength = lineScale, trackLength
    local overlap = TRAIL_OVERLAP
    local across, along = event.trailThickness * (1 + (lineScale - 1) * TRAIL_THICKNESS_FOLLOW), overlap + trackLength * TRAIL_SECONDS / TRACK_SPAN_SECONDS
    for layer, trail in ipairs(event.trails) do
        local layerAlong = along * TRAIL_LAYER_LENGTHS[layer]
        trail:ClearAllPoints()
        if horizontal then
            trail:SetSize(layerAlong, across)
            if behindIsHigher then
                trail:SetPoint("LEFT", event, "RIGHT", -overlap, 0)
                event.trailOrientation, event.trailNearIsMin = "HORIZONTAL", true
                setCorners(event, trail, 0, 0, 0, 1, 1, 0, 1, 1)
            else
                trail:SetPoint("RIGHT", event, "LEFT", overlap, 0)
                event.trailOrientation, event.trailNearIsMin = "HORIZONTAL", false
                setCorners(event, trail, 1, 0, 1, 1, 0, 0, 0, 1)
            end
        else
            trail:SetSize(across, layerAlong)
            if behindIsHigher then
                trail:SetPoint("BOTTOM", event, "TOP", 0, -overlap)
                event.trailOrientation, event.trailNearIsMin = "VERTICAL", true
                setCorners(event, trail, 1, 0, 0, 0, 1, 1, 0, 1)
            else
                trail:SetPoint("TOP", event, "BOTTOM", 0, overlap)
                event.trailOrientation, event.trailNearIsMin = "VERTICAL", false
                setCorners(event, trail, 0, 0, 1, 0, 0, 1, 1, 1)
            end
        end
    end
end

local function setLevel(event, level)
    event.trailLevel = level
    event.trailNear:SetRGBA(1, 1, 1, level)
    event.trailFar:SetRGBA(1, 1, 1, level * TRAIL_FAR_SHARE)
    for _, trail in ipairs(event.trails) do
        if event.trailNearIsMin then
            trail:SetGradient(event.trailOrientation, event.trailNear, event.trailFar)
        else
            trail:SetGradient(event.trailOrientation, event.trailFar, event.trailNear)
        end
        trail:SetShown(level > 0)
    end
end

local trailOn = true

function timeline.SetTrail(value)
    trailOn = value
end

function timeline.updateTrail(event, remaining, step)
    local trail = event.trail
    if not trailOn or not timeline.IsBlizzlikeBackdrop() then
        if trail and event.trailLevel ~= 0 then
            setLevel(event, 0)
        end
        return
    end
    if not remaining and (not trail or (event.trailLevel or 0) == 0) then
        return
    end
    if trail and not event:IsShown() then
        setLevel(event, 0)
        return
    end
    trail = trail or trailOf(event)
    if not trail then
        return
    end
    layout(event)
    if remaining then
        local share = 1 - math.min(math.max(remaining, 0), TRACK_SPAN_SECONDS) / TRACK_SPAN_SECONDS
        setLevel(event, math.min(share / TRAIL_FULL_SHARE, 1) * TRAIL_MAX_ALPHA)
    else
        local frameSeconds = step and step > 0 and step or TRAIL_FRAME_SECONDS
        setLevel(event, math.max(event.trailLevel - TRAIL_MAX_ALPHA * frameSeconds / TRAIL_FADE_SECONDS, 0))
    end
end

function timeline.clearTrail(event)
    if event.trail then
        setLevel(event, 0)
    end
end
