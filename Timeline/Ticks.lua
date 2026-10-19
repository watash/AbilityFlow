local addonName, ns = ...

local timeline = ns.timeline

local MARK_SECONDS = { 5, 10, 15, 20 }
local MARK_STEP_SINGLE = 0
local FIRST_MARK_SECONDS = 5
timeline.MARK_STEPS = { MARK_STEP_SINGLE, 5, 10 }
timeline.MARK_STEP_SINGLE = MARK_STEP_SINGLE
timeline.DEFAULT_MARK_STEP = MARK_STEP_SINGLE
local TICK_TEXT_OFFSET = 5
local PIP_SCALE = 1.5
local TEXT_SCALE = 1.5
local BAR_THICKNESS = 2
local MARK_SCALE_DEFAULT = 1
local BLIZZLIKE_MARK_ACROSS_SHARE = 1.2

local MARK_NONE = "NONE"
local MARK_ICON = "ICON"
local MARK_ICON_TEXT = "ICON_TEXT"
local MARK_BAR = "BAR"
local MARK_BAR_TEXT = "BAR_TEXT"
local MARK_ICON_BAR = "ICON_BAR"
local MARK_ALL = "ALL"

timeline.MARK_NONE = MARK_NONE
timeline.MARK_ICON = MARK_ICON
timeline.MARK_ICON_TEXT = MARK_ICON_TEXT
timeline.MARK_BAR = MARK_BAR
timeline.MARK_BAR_TEXT = MARK_BAR_TEXT
timeline.MARK_ICON_BAR = MARK_ICON_BAR
timeline.MARK_ALL = MARK_ALL

local MARK_PARTS = {
    [MARK_NONE] = {},
    [MARK_ICON] = { icon = true },
    [MARK_ICON_TEXT] = { icon = true, text = true },
    [MARK_BAR] = { bar = true },
    [MARK_BAR_TEXT] = { bar = true, text = true },
    [MARK_ICON_BAR] = { icon = true, bar = true },
    [MARK_ALL] = { icon = true, bar = true, text = true },
}

local markStyle = MARK_ICON_TEXT
local markScale = MARK_SCALE_DEFAULT
local markStep = MARK_STEP_SINGLE

local function hasTick(seconds)
    if markStep == MARK_STEP_SINGLE then
        return seconds == FIRST_MARK_SECONDS
    end
    return seconds % markStep == 0
end
local ticks = {}

local pipBaseWidth, pipBaseHeight, fontPath, fontBaseSize, fontFlags

for _, seconds in ipairs(MARK_SECONDS) do
    local tick = CreateFrame("Frame", nil, timeline.frame)
    tick:SetFrameLevel(timeline.frame:GetFrameLevel() + 1)

    local line = tick:CreateTexture(nil, "ARTWORK")
    line:SetAllPoints()
    line:SetColorTexture(1, 1, 1, 1)

    local pip = tick:CreateTexture(nil, "OVERLAY")
    pip:SetAtlas("combattimeline-pip", true)
    pipBaseWidth = pip:GetWidth() * PIP_SCALE
    pipBaseHeight = pip:GetHeight() * PIP_SCALE
    pip:SetPoint("CENTER", tick, "CENTER")

    local text = tick:CreateFontString(nil, "OVERLAY", "SystemFont_Shadow_Med3")
    text:SetText(tostring(seconds))
    fontPath, fontBaseSize, fontFlags = text:GetFont()

    table.insert(ticks, { frame = tick, line = line, pip = pip, text = text, seconds = seconds })
end

local function applyMarkScale()
    local pipWidth, pipHeight = pipBaseWidth * markScale, pipBaseHeight * markScale
    for _, tick in ipairs(ticks) do
        tick.pip:SetSize(pipWidth, pipHeight)
        tick.text:SetFont(fontPath, fontBaseSize * TEXT_SCALE * markScale, fontFlags)
    end
end

local function placeTicks()
    local length = timeline.TrackLength()
    local width = timeline.TrackWidth()
    local horizontal = timeline.Orientation() == timeline.ORIENTATION_HORIZONTAL
    local thickness = BAR_THICKNESS * markScale
    local across = width
    if timeline.IsBlizzlikeBackdrop and timeline.IsBlizzlikeBackdrop() then
        local icon = timeline.currentIconSize()
        across = math.min(width, (icon + 2 * ns.eventStyle.BorderThickness(icon)) * BLIZZLIKE_MARK_ACROSS_SHARE)
    end
    local widest = 0
    for _, tick in ipairs(ticks) do
        widest = math.max(widest, tick.text:GetStringWidth())
    end
    for _, tick in ipairs(ticks) do
        local position = tick.seconds / timeline.TRACK_SPAN_SECONDS * length
        local along = timeline.EntersFromStart() and position or (length - position)
        tick.frame:ClearAllPoints()
        tick.text:ClearAllPoints()
        if horizontal then
            tick.frame:SetSize(thickness, across)
            tick.frame:SetPoint("CENTER", timeline.frame, "LEFT", along, 0)
            tick.text:SetPoint("TOP", tick.frame, "BOTTOM", 0, -TICK_TEXT_OFFSET)
            tick.text:SetWidth(0)
            tick.text:SetJustifyH("CENTER")
        else
            tick.frame:SetSize(across, thickness)
            tick.frame:SetPoint("CENTER", timeline.frame, "BOTTOM", 0, along)
            tick.text:SetWidth(widest)
            tick.text:SetJustifyH("CENTER")
            if ns.eventStyle.NameSide() == "RIGHT" then
                tick.text:SetPoint("RIGHT", tick.line, "LEFT", -TICK_TEXT_OFFSET, 0)
            else
                tick.text:SetPoint("LEFT", tick.line, "RIGHT", TICK_TEXT_OFFSET, 0)
            end
        end
    end
end

local function applyStyle()
    local parts = MARK_PARTS[markStyle] or MARK_PARTS[MARK_ICON_TEXT]
    for _, tick in ipairs(ticks) do
        tick.frame:SetShown(markStyle ~= MARK_NONE and hasTick(tick.seconds) and tick.seconds <= timeline.TRACK_SPAN_SECONDS)
        tick.line:SetShown(parts.bar == true)
        tick.pip:SetShown(parts.icon == true)
        tick.text:SetShown(parts.text == true)
    end
end

timeline.onGeometryChanged = placeTicks
timeline.PlaceTicks = placeTicks
applyMarkScale()
placeTicks()
applyStyle()

function timeline.SetMarkStyle(style)
    markStyle = style
    applyStyle()
end

function timeline.SetMarkStep(step)
    markStep = step
    applyStyle()
end

function timeline.SetMarkScale(percent)
    markScale = percent / 100
    applyMarkScale()
    placeTicks()
end
