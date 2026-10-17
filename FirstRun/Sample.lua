local addonName, ns = ...

local CreateFrame = CreateFrame
local C_Texture = C_Texture
local CopyTable = CopyTable
local ipairs = ipairs
local unpack = unpack
local math = math

local L = ns.L
local timeline = ns.timeline
local media = ns.media
local values = ns.values

local sample = {}
ns.firstRunSample = sample

local GROUND_WIDTH = 300
local GROUND_HEIGHT = 260
local PLATE_PADDING = 18
local ICON_SIZE = 50
local NAME_MARGIN = 6
local END_ROOM = 36
local TEXT_SHARE = 0.6
local LINE_BOOST = 1.3
local BACKGROUND_BOOST = 1.35
local LINE_REFERENCE_SIZE = 45
local DIVIDER_GAP_SHARE = 0.5
local DIVIDER_BOOST = 1.8
local LINE_ZERO_ATLAS = "combattimeline-line-right"
local LINE_FAR_ATLAS = "combattimeline-line-left"
local LINE_ZERO_SHARE = 0.25
local LINE_FAR_SHARE = 0.75
local VERTICAL_CORNERS = { 0, 1, 1, 1, 0, 0, 1, 0 }
local PLAIN_ICON_BORDER_THICKNESS = 1
local PLAIN_ICON_BORDER_COLOR = { r = 1, g = 1, b = 1, a = 1 }
local COUNTDOWN_SIZE_RATIO = 0.42
local ICON_SECONDS = { 11, 6, 1 }
local ICON_TYPES = { "MAGIC", "BLEED", "CURSE" }
local ICON_FIRST_LEVEL = 3
local GROUND_COLOR = 0.08

local function placeOf(seconds, top, length)
    return top + (1 - seconds / timeline.TRACK_SPAN_SECONDS) * length
end

local function drawBlizzlike(ground, top, length, ratio, trackX)
    for _, spec in ipairs({ { LINE_ZERO_ATLAS, LINE_ZERO_SHARE }, { LINE_FAR_ATLAS, LINE_FAR_SHARE } }) do
        local half = ground:CreateTexture(nil, "ARTWORK", nil, 1)
        half:SetAtlas(spec[1], true)
        local thickness = half:GetHeight() * ratio * LINE_BOOST
        half:SetTexCoord(unpack(VERTICAL_CORNERS))
        half:ClearAllPoints()
        half:SetSize(thickness, length / 2)
        half:SetPoint("CENTER", ground, "TOPLEFT", trackX, -placeOf(timeline.TRACK_SPAN_SECONDS * spec[2], top, length))
    end
    if not C_Texture.GetAtlasInfo(timeline.DIVIDER_ATLAS) then
        return
    end
    local gap = timeline.DIVIDER_GAP * ratio * DIVIDER_GAP_SHARE
    for _, edge in ipairs({ top - gap, top + length + gap }) do
        local divider = ns.appearanceTrackPreview.BuildDivider(ground)
        divider:SetAlpha(1)
        local across, along = divider:GetSize()
        divider:SetSize(across * DIVIDER_BOOST, along * DIVIDER_BOOST)
        divider:SetPoint("CENTER", ground, "TOPLEFT", trackX, -edge)
    end
end

local function drawPlain(ground, top, length, ratio, trackX)
    local reach = ICON_SIZE / 2
    local width = values.Default("trackWidths") * ratio * BACKGROUND_BOOST
    local background = ground:CreateTexture(nil, "ARTWORK", nil, 0)
    background:SetTexture(media.BackgroundPath(values.Default("backgroundTextures")), "REPEAT", "REPEAT")
    local color = values.Default("backgroundColors")
    background:SetVertexColor(color.r, color.g, color.b, color.a)
    local first = math.max(top - reach, PLATE_PADDING)
    local last = math.min(top + length + reach, GROUND_HEIGHT - PLATE_PADDING)
    background:SetSize(width, last - first)
    background:SetPoint("TOPLEFT", ground, "TOPLEFT", trackX - width / 2, -first)
end

local function applyPlainIconBorder(event)
    ns.eventFrame.SetBorder(event, PLAIN_ICON_BORDER_THICKNESS, PLAIN_ICON_BORDER_COLOR)
    ns.eventFrame.SetRounded(event, nil)
    for _, outline in ipairs(event.outlines or {}) do
        outline:Hide()
    end
    for _, fills in ipairs(event.debuffBorders) do
        for _, fill in ipairs(fills) do
            fill:Hide()
        end
    end
end

local function useDefaultBorder()
    local border = ns.eventStyle.state.border
    local style, thickness, color, typeFrames = border.style, border.thickness, CopyTable(border.color), border.typeFrames
    local default = ns.appearance.DEFAULTS.border
    ns.eventStyle.SetBorder(default.style, default.thickness, default.color, default.useEventColor)
    return function()
        ns.eventStyle.SetBorder(style, thickness, color, typeFrames)
    end
end

function sample.Create(parent, plain, seeThrough, plate)
    local ground = CreateFrame("Frame", nil, parent)
    ground:SetSize(GROUND_WIDTH, GROUND_HEIGHT)
    ground:SetClipsChildren(true)
    if not seeThrough then
        local back = ground:CreateTexture(nil, "BACKGROUND")
        back:SetAllPoints()
        if plate then
            back:SetTexture(plate)
        else
            back:SetColorTexture(GROUND_COLOR, GROUND_COLOR, GROUND_COLOR, 1)
        end
    end

    local top = END_ROOM
    local length = GROUND_HEIGHT - 2 * END_ROOM

    local spells = #ns.timerStyle.ICON_SPELLS
    local events = {}
    local widest = 0
    local putBorderBack = not plain and useDefaultBorder()
    local reach = values.Default("trackWidths") * ICON_SIZE / timeline.DEFAULT_ICON_SIZE * BACKGROUND_BOOST / 2
    for index in ipairs(ICON_SECONDS) do
        local level = ground:GetFrameLevel() + ICON_FIRST_LEVEL + (index - 1) * timeline.EVENT_LEVEL_BLOCK
        local event = ns.appearanceTrackPreview.BuildSampleIcon(ground, level, (index - 1) % spells + 1,
            ICON_TYPES[index], ICON_SIZE)
        if plain then
            applyPlainIconBorder(event)
        end
        event.nameFlipped = ns.eventStyle.NameSide() == "LEFT"
        ns.eventStyle.PlaceName(event)
        event.texts.cooldown:SetText(ns.countdownFormat.Of(ICON_SECONDS[index]))
        local countdownFont, _, countdownFlags = event.texts.cooldown:GetFont()
        if countdownFont then
            event.texts.cooldown:SetFont(countdownFont, ICON_SIZE * COUNTDOWN_SIZE_RATIO, countdownFlags)
        end
        local name = event.texts.name
        name:SetText(L.STATES_SAMPLE_NAME:format(index))
        local path, size, flags = name:GetFont()
        if path then
            name:SetFont(path, size * TEXT_SHARE, flags)
        end
        ns.statusMark.Layout(event)
        ns.eventStyle.PlaceName(event)
        widest = math.max(widest, name:GetStringWidth())
        events[index] = event
    end
    if putBorderBack then
        putBorderBack()
    end
    local trackX = (GROUND_WIDTH - (2 * reach + NAME_MARGIN + widest)) / 2 + reach

    if plain then
        drawPlain(ground, top, length, ICON_SIZE / timeline.DEFAULT_ICON_SIZE, trackX)
    else
        drawBlizzlike(ground, top, length, ICON_SIZE / LINE_REFERENCE_SIZE, trackX)
    end
    for index, event in ipairs(events) do
        local y = -placeOf(ICON_SECONDS[index], top, length)
        event:SetPoint("CENTER", ground, "TOPLEFT", trackX, y)
        local name = event.texts.name
        name:ClearAllPoints()
        if ns.eventStyle.NameSideOf(event) == "LEFT" then
            name:SetPoint("RIGHT", ground, "TOPLEFT", trackX - reach - NAME_MARGIN, y)
        else
            name:SetPoint("LEFT", ground, "TOPLEFT", trackX + reach + NAME_MARGIN, y)
        end
    end
    return ground
end
