local addonName, ns = ...

local UIParent = UIParent
local min = math.min
local max = math.max
local appearance = ns.appearance
local media = ns.media
local L = ns.L
local previewEvent = ns.timerTab.event
local nameSample = ns.timerTab.nameSample

local NAME_SAMPLE_GAP = 8
local NAME_MIN_GAP = 4
local NAME_SPACE_SHARE = 0.8
local TEXT_SCALE_MAX = 3
local NOTE_SCALE_MIN = 0.05
local NOTE_WIDEST = "%d%%"
local NOTE_REFERENCE_SIZE = 64
local NOTE_SPACE_SHARE = 1.1
previewEvent.NOTE_ARROW_SHARE = 0.42
previewEvent.NOTE_NAME_PERCENT = 62
local NOTE_FIT_TRIES = 4
local measure

local function measureText(text, percent)
    measure = measure or UIParent:CreateFontString(nil, "ARTWORK")
    measure:SetAlpha(0)
    local path = media.FontPath(appearance.Get("name", "font")) or media.FontPath(media.DEFAULT_FONT)
    local size = appearance.Get("name", "size") * percent / nameSample.PERCENT
    if not measure:SetFont(path, size, appearance.FontFlags("name")) then
        measure:SetFont(media.FontPath(media.DEFAULT_FONT), size, appearance.FontFlags("name"))
    end
    measure:SetText(text)
    return measure
end

local function measureName()
    return measureText(L.TIMER_STYLE_SAMPLE_NAME, ns.timerStyle.NAME_SCALE_MAX)
end

local function nameWidth()
    return measureName():GetStringWidth() + 2 * nameSample.SIDE_PADDING
end

function previewEvent.SetTextScale(pitch)
    nameSample.textScale = min(TEXT_SCALE_MAX, NAME_SPACE_SHARE * (pitch - NAME_MIN_GAP) / nameWidth())
end

previewEvent.NAME_MIN_GAP = NAME_MIN_GAP

local noteMeasure

local function widestNoteWidth(scale)
    noteMeasure = noteMeasure or previewEvent.CreateNameSample(UIParent)
    noteMeasure:Hide()
    noteMeasure:SetScale(scale)
    local arrowSide = appearance.Get("name", "size") * previewEvent.NOTE_ARROW_SHARE * scale
    previewEvent.PaintName(noteMeasure, nil, NOTE_WIDEST:format(ns.timerStyle.NAME_SCALE_MAX), nil,
        { up = true, r = 1, g = 1, b = 1, side = arrowSide / scale }, previewEvent.NOTE_NAME_PERCENT)
    return previewEvent.NameSampleWidth(noteMeasure) * scale
end

function previewEvent.SetPinTextScale(pitch, room, width)
    local size = appearance.Get("name", "size")
    local note = measureText(NOTE_WIDEST:format(ns.timerStyle.NAME_SCALE_MAX),
        NOTE_REFERENCE_SIZE / size * previewEvent.NOTE_NAME_PERCENT)
    local noteWidth = note:GetStringWidth() + nameSample.ARROW_GAP + NOTE_REFERENCE_SIZE * previewEvent.NOTE_ARROW_SHARE
    local byWidth = (width - 2 * nameSample.SIDE_PADDING) / noteWidth
    local byHeight = room / note:GetStringHeight()
    local scale = max(NOTE_SCALE_MIN, min(byWidth, byHeight)) * NOTE_REFERENCE_SIZE / size
    for _ = 1, NOTE_FIT_TRIES do
        local drawn = widestNoteWidth(scale)
        if drawn <= width then
            break
        end
        scale = max(NOTE_SCALE_MIN, scale * width / drawn)
    end
    nameSample.pinScale = scale
    nameSample.pinPitch = pitch
end

function previewEvent.PinTextScale()
    return nameSample.pinScale or nameSample.textScale
end

function previewEvent.PinTextWidth()
    return ((nameSample.pinPitch or 0) - NAME_MIN_GAP) * NOTE_SPACE_SHARE
end

function previewEvent.TextScale()
    return nameSample.textScale
end

function previewEvent.NameHeight()
    return (measureName():GetStringHeight() + 2 * nameSample.PADDING + NAME_SAMPLE_GAP) * nameSample.textScale
end

previewEvent.NAME_SAMPLE_GAP = NAME_SAMPLE_GAP
