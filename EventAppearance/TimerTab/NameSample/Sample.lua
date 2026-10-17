local addonName, ns = ...

local math = math
local CreateFrame = CreateFrame
local pairs = pairs
local appearance = ns.appearance
local media = ns.media
local L = ns.L
local previewEvent = ns.timerTab.event
local nameSample = ns.timerTab.nameSample

local NAME_SAMPLE_TEXT_LEVEL = 3
local NAME_SHADOW_OFFSET = 1

function previewEvent.CreateNameSample(parent, strata, above)
    local sample = CreateFrame("Frame", nil, parent)
    if strata then
        sample:SetFrameStrata(strata)
    end
    sample:SetSize(1, 1)
    sample.nameHolder = CreateFrame("Frame", nil, sample)
    sample.nameHolder:SetAllPoints()
    sample.nameHolder:SetFrameLevel(sample:GetFrameLevel() + NAME_SAMPLE_TEXT_LEVEL)
    sample.texts = {}
    ns.eventStyle.DecorateName(sample)
    previewEvent.SetNameSide(sample, above)
    return sample
end

function previewEvent.SetNameSide(sample, above)
    sample.nameSide = above and "BOTTOM" or "TOP"
    previewEvent.PlaceNameText(sample)
end

function previewEvent.PlaceNameText(sample)
    local side = sample.nameSide or "TOP"
    sample.texts.name:ClearAllPoints()
    sample.texts.name:SetPoint(side, sample, side, -(sample.arrowExtra or 0) / 2, 0)
end

function previewEvent.SetNameLevel(sample, level)
    sample:SetFrameLevel(level)
    sample.nameHolder:SetFrameLevel(level + NAME_SAMPLE_TEXT_LEVEL)
    ns.eventFrame.PlaceBackdrop(sample)
end

function previewEvent.SetNameDesaturated(sample, grey)
    if grey then
        previewEvent.greyText(sample.texts.name)
    end
    previewEvent.GreyMarks(sample, grey)
    sample.textBackgrounds.name:SetDesaturated(grey)
    if sample.nameBackdrop.borderPieces then
        for _, piece in pairs(sample.nameBackdrop.borderPieces) do
            piece:SetDesaturated(grey)
        end
    end
end

local function paddingOf(sample, pixels)
    return pixels / math.max(1, sample:GetScale())
end

function previewEvent.NameSampleWidth(sample)
    return sample.texts.name:GetStringWidth() + 2 * paddingOf(sample, nameSample.SIDE_PADDING) + (sample.arrowExtra or 0)
end

function previewEvent.PaintName(sample, template, text, textColor, arrow, percent)
    local eventStyle = ns.eventStyle
    local event = sample
    local name = sample.texts.name
    local scale = (percent or ns.timerStyle.NameScaleOf(template)) / nameSample.PERCENT
    local size = appearance.Get("name", "size") * scale
    local path = media.FontPath(appearance.Get("name", "font")) or media.FontPath(media.DEFAULT_FONT)
    if not name:SetFont(path, size, appearance.FontFlags("name")) then
        name:SetFont(media.FontPath(media.DEFAULT_FONT), size, appearance.FontFlags("name"))
    end
    name:SetText(text or L.TIMER_STYLE_SAMPLE_NAME)
    local color = appearance.Get("name", "color")
    if appearance.Get("name", "useEventColor") then
        color = ns.debuff.ColorOf("MAGIC") or color
    end
    color = textColor or color
    name:SetTextColor(color.r, color.g, color.b, color.a or 1)
    if appearance.Get("name", "shadow") then
        name:SetShadowColor(0, 0, 0, 1)
        name:SetShadowOffset(NAME_SHADOW_OFFSET, -NAME_SHADOW_OFFSET)
    else
        name:SetShadowOffset(0, 0)
    end
    eventStyle.PlaceTextBackground(event, "name", size, paddingOf(sample, nameSample.SIDE_PADDING),
        paddingOf(sample, nameSample.PADDING))
    previewEvent.PaintArrow(sample, arrow)
    previewEvent.HideSwatch(sample)
    eventStyle.PaintNameBackground(event, template)
    name:Show()
end
