local addonName, ns = ...

local ipairs = ipairs
local unpack = unpack
local math = math

local timeline = ns.timeline
local trackPreview = ns.appearanceTrackPreview
local state = trackPreview.state

local ICON_SIZE = trackPreview.ICON_SIZE
local TRACK_CENTER_X = trackPreview.TRACK_CENTER_X
local MIN_TRACK_LENGTH = trackPreview.MIN_TRACK_LENGTH
local LINE_REFERENCE_SIZE = trackPreview.LINE_REFERENCE_SIZE
local DIVIDER_ALPHA = trackPreview.DIVIDER_ALPHA
local THRESHOLD = timeline.TRACK_SPAN_SECONDS
local ICON_MARGIN = 10
local MAX_TRACK_WIDTH = 2 * TRACK_CENTER_X
local ZONE_LABEL_MARGIN = 6
local ZONE_LABEL_END_OFFSET = 30
local VERTICAL_CORNERS = { 0, 1, 1, 1, 0, 0, 1, 0 }

function trackPreview.BuildDivider(parent)
    local bar = parent:CreateTexture(nil, "ARTWORK", nil, 1)
    bar:SetAtlas(timeline.DIVIDER_ATLAS, true)
    local columns, rows = bar:GetSize()
    local barShare = timeline.DIVIDER_BAR_COLUMNS / columns
    bar:SetSize(rows, columns * barShare)
    local from, span = 1 - barShare, barShare
    bar:SetTexCoord(from, 0, from + span, 0, from, 1, from + span, 1)
    bar:SetAlpha(DIVIDER_ALPHA)
    return bar
end

function trackPreview.LayoutPlain()
    local box, plainBackground, plainBorder = state.box, state.plainBackground, state.plainBorder
    local previewRatio, trackTop, trackLength = state.previewRatio, state.trackTop, state.trackLength
    local scale = box:GetEffectiveScale()
    local function snap(value)
        return math.floor(value * scale + 0.5) / scale
    end
    local width = snap(math.min(timeline.GetTrackWidth() * previewRatio, MAX_TRACK_WIDTH))
    local reach = timeline.GetPlainEndReach() * previewRatio
    local top = snap(trackTop - reach)
    local bottom = snap(trackTop + trackLength + reach)
    local path = timeline.GetBackgroundTexture()
    plainBackground:SetTexture(path, "REPEAT", "REPEAT")
    plainBackground:SetVertexColor(timeline.GetBackgroundColor())
    plainBackground:SetShown(path ~= nil)
    plainBackground:ClearAllPoints()
    plainBackground:SetSize(width, bottom - top)
    plainBackground:SetPoint("TOPLEFT", box, "TOPLEFT", snap(TRACK_CENTER_X - width / 2), -top)
    local borderPath, offset, thickness, color = timeline.GetBorder()
    if borderPath and thickness > 0 then
        offset = snap(offset * previewRatio)
        plainBorder:SetBackdrop({ edgeFile = borderPath, edgeSize = math.max(snap(thickness * previewRatio), 1 / scale) })
        plainBorder:SetBackdropBorderColor(color.r, color.g, color.b, color.a)
        plainBorder:ClearAllPoints()
        plainBorder:SetPoint("TOPLEFT", plainBackground, "TOPLEFT", -offset, offset)
        plainBorder:SetPoint("BOTTOMRIGHT", plainBackground, "BOTTOMRIGHT", offset, -offset)
        plainBorder:Show()
    else
        plainBorder:Hide()
    end
end

function trackPreview.LayoutTrack()
    local box, direction = state.box, state.direction
    local placeOf = trackPreview.PlaceOf
    local placesRoom = trackPreview.WaitingStep() + ICON_SIZE / 2 + ICON_MARGIN
    local entryReserve = math.max(trackPreview.EntryFirstOffset(true), trackPreview.EntryFirstOffset(false)) + placesRoom
    local exitReserve = math.max(trackPreview.HeldFirstOffset(true), trackPreview.HeldFirstOffset(false)) + placesRoom
    local startReserve = direction == 1 and entryReserve or exitReserve
    local endReserve = direction == 1 and exitReserve or entryReserve
    state.trackLength = math.max(box:GetHeight() - startReserve - endReserve, MIN_TRACK_LENGTH)
    state.trackTop = startReserve
    local trackLength, trackTop = state.trackLength, state.trackTop
    trackPreview.PlanStory()
    for _, event in ipairs(state.icons) do
        if event.trailHost then
            event.trailHost:ClearAllPoints()
            event.trailHost:SetPoint("TOPLEFT", box, "TOPLEFT", 0, -trackTop)
            event.trailHost:SetSize(box:GetWidth(), trackLength)
        end
    end
    local mirrored = direction ~= 1
    for _, half in ipairs(state.halves) do
        half.texture:SetAtlas(half.atlas, true)
        local thickness = half.texture:GetHeight() * timeline.GetLineScale() * ICON_SIZE / LINE_REFERENCE_SIZE
        local corners = {}
        for index, value in ipairs(VERTICAL_CORNERS) do
            corners[index] = (mirrored and index % 2 == 1) and 1 - value or value
        end
        half.texture:SetTexCoord(unpack(corners))
        half.texture:ClearAllPoints()
        half.texture:SetSize(thickness, trackLength / 2)
        half.texture:SetPoint("CENTER", box, "TOPLEFT", TRACK_CENTER_X, -placeOf(THRESHOLD * half.share))
    end
    for index, divider in ipairs(state.dividers) do
        local atEnd = index == 1
        local edge = placeOf(atEnd and 0 or THRESHOLD)
        local gap = atEnd and trackPreview.DividerGap() or trackPreview.EntryDividerGap()
        divider:ClearAllPoints()
        divider:SetPoint("CENTER", box, "TOPLEFT", TRACK_CENTER_X, -(edge + (atEnd and direction or -direction) * gap))
    end
    local zoneLabelY = {
        placeOf(THRESHOLD) - direction * ZONE_LABEL_END_OFFSET,
        placeOf(THRESHOLD / 2),
        placeOf(0) + direction * ZONE_LABEL_END_OFFSET,
    }
    for index, label in ipairs(state.zoneLabels) do
        label:ClearAllPoints()
        label:SetPoint("RIGHT", box, "TOPRIGHT", -ZONE_LABEL_MARGIN, -zoneLabelY[index])
    end
    local blizzlike = timeline.IsBlizzlikeBackdrop()
    state.laidOutBlizzlike = blizzlike
    for _, half in ipairs(state.halves) do
        half.texture:SetShown(blizzlike)
    end
    for _, divider in ipairs(state.dividers) do
        divider:SetShown(blizzlike)
    end
    state.plainBackground:SetShown(not blizzlike)
    state.plainBorder:SetShown(not blizzlike)
    if not blizzlike then
        trackPreview.LayoutPlain()
    end
end
