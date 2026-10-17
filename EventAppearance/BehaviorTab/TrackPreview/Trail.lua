local addonName, ns = ...

local CreateColor = CreateColor
local CreateFrame = CreateFrame
local C_Texture = C_Texture
local ipairs = ipairs
local unpack = unpack
local math = math

local timeline = ns.timeline
local trackPreview = ns.appearanceTrackPreview
local state = trackPreview.state

local THRESHOLD = timeline.TRACK_SPAN_SECONDS
local TRAIL_LEVEL = 1
local TRAIL_FAR_SHARE = 0
local CORNERS_DOWN = { 1, 0, 0, 0, 1, 1, 0, 1 }
local CORNERS_UP = { 0, 0, 1, 0, 0, 1, 1, 1 }
local corners = {}

function trackPreview.BuildTrail(event)
    local info = C_Texture.GetAtlasInfo(timeline.TRAIL_ATLAS)
    if not info then
        return
    end
    local box = state.box
    local host = CreateFrame("Frame", nil, box)
    host:SetFrameLevel(box:GetFrameLevel() + TRAIL_LEVEL)
    host:SetClipsChildren(true)
    event.trailHost = host
    event.trailLayers = {}
    for layer, share in ipairs(timeline.TRAIL_LAYER_LENGTHS) do
        local trail = host:CreateTexture(nil, "OVERLAY")
        trail:SetAtlas(timeline.TRAIL_ATLAS)
        trail:SetBlendMode("ADD")
        trail:SetAlpha(0)
        event.trailLayers[layer] = { texture = trail, share = share }
    end
    event.trailNear, event.trailFar = CreateColor(1, 1, 1, 0), CreateColor(1, 1, 1, 0)
    event.trailLevel = 0
    event.trailInfo = info
end

function trackPreview.LayoutTrail(event)
    if not event.trailLayers then
        return
    end
    local direction, previewRatio = state.direction, state.previewRatio
    local info = event.trailInfo
    local unit = direction == 1 and CORNERS_DOWN or CORNERS_UP
    for index = 1, #unit, 2 do
        corners[index] = info.leftTexCoord + unit[index] * (info.rightTexCoord - info.leftTexCoord)
        corners[index + 1] = info.topTexCoord + unit[index + 1] * (info.bottomTexCoord - info.topTexCoord)
    end
    local length = previewRatio
        * (timeline.TRAIL_OVERLAP + timeline.GetTrackLength() * timeline.TRAIL_SECONDS / THRESHOLD)
    local overlap = timeline.TRAIL_OVERLAP * previewRatio
    for _, layer in ipairs(event.trailLayers) do
        layer.texture:SetTexCoord(unpack(corners))
        layer.texture:ClearAllPoints()
        layer.texture:SetSize(info.height * previewRatio, length * layer.share)
        if direction == 1 then
            layer.texture:SetPoint("BOTTOM", event, "TOP", 0, -overlap)
        else
            layer.texture:SetPoint("TOP", event, "BOTTOM", 0, overlap)
        end
    end
    event.trailGradientNearIsMin = direction == 1
    event.trailStale = true
end

function trackPreview.SetTrailLevel(event, level)
    if not event.trailLayers or (event.trailLevel == level and not event.trailStale) then
        return
    end
    event.trailStale = nil
    event.trailLevel = level
    event.trailNear:SetRGBA(1, 1, 1, level)
    event.trailFar:SetRGBA(1, 1, 1, level * TRAIL_FAR_SHARE)
    for _, layer in ipairs(event.trailLayers) do
        if event.trailGradientNearIsMin then
            layer.texture:SetGradient("VERTICAL", event.trailNear, event.trailFar)
        else
            layer.texture:SetGradient("VERTICAL", event.trailFar, event.trailNear)
        end
        layer.texture:SetAlpha(level > 0 and 1 or 0)
    end
end

function trackPreview.FollowTrail(event, onLine, ramp, step)
    if onLine then
        trackPreview.SetTrailLevel(event, math.min(math.max(ramp, 0), 1))
    elseif event.trailLevel and event.trailLevel > 0 then
        trackPreview.SetTrailLevel(event, math.max(event.trailLevel - step / timeline.TRAIL_FADE_SECONDS, 0))
    end
end
