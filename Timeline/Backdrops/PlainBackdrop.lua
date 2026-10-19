local addonName, ns = ...

local PixelUtil = PixelUtil

local timeline = ns.timeline
local frame = timeline.frame

local BACKGROUND_TEXTURE_DEFAULT_PATH = "Interface\\DialogFrame\\UI-DialogBox-Background"
timeline.BACKGROUND_TEXTURE_DEFAULT_PATH = BACKGROUND_TEXTURE_DEFAULT_PATH

frame.background = frame:CreateTexture(nil, "BACKGROUND")
frame.background:SetTexture(BACKGROUND_TEXTURE_DEFAULT_PATH, "REPEAT", "REPEAT")
frame.background:SetVertexColor(1, 1, 1, 1)

function timeline.PlainEndReach()
    return math.floor(timeline.currentIconSize() / 2 + 0.5)
end

local function placeBackground()
    local horizontal = timeline.Orientation() == timeline.ORIENTATION_HORIZONTAL
    local length = timeline.TrackLength() + 2 * timeline.PlainEndReach()
    local width = timeline.TrackWidth()
    local across, along = width, length
    local sizeX, sizeY = along, across
    if not horizontal then
        sizeX, sizeY = across, along
    end
    local scale = frame:GetEffectiveScale()
    sizeX = PixelUtil.GetNearestPixelSize(sizeX, scale, 1)
    sizeY = PixelUtil.GetNearestPixelSize(sizeY, scale, 1)
    local shiftX, shiftY = 0, 0
    local centerX, centerY = frame:GetCenter()
    if centerX and scale > 0 then
        local pixel = PixelUtil.GetPixelToUIUnitFactor() / scale
        local cornerX, cornerY = centerX - sizeX / 2, centerY - sizeY / 2
        shiftX = math.floor(cornerX / pixel + 0.5) * pixel - cornerX
        shiftY = math.floor(cornerY / pixel + 0.5) * pixel - cornerY
    end
    frame.background:ClearAllPoints()
    frame.background:SetPoint("CENTER", frame, "CENTER", shiftX, shiftY)
    frame.background:SetSize(sizeX, sizeY)
end
placeBackground()

local watcher = CreateFrame("Frame", nil, frame)
local watchedX, watchedY
watcher:SetScript("OnUpdate", function()
    local centerX, centerY = frame:GetCenter()
    if centerX ~= watchedX or centerY ~= watchedY then
        watchedX, watchedY = centerX, centerY
        placeBackground()
    end
end)

local previousGeometry = timeline.onGeometryChanged
timeline.onGeometryChanged = function()
    if previousGeometry then
        previousGeometry()
    end
    placeBackground()
end

local border = CreateFrame("Frame", nil, frame, "BackdropTemplate")
local BORDER_LEVEL_OVER_TRACK = 2
local BORDER_PIECES = {
    "TopLeftCorner", "TopRightCorner", "BottomLeftCorner", "BottomRightCorner", "TopEdge", "BottomEdge", "LeftEdge", "RightEdge",
}
border:SetFrameLevel(frame:GetFrameLevel() + BORDER_LEVEL_OVER_TRACK)
border:Hide()
local borderPath
local borderOffset = 0
local borderThickness = 0
local borderColor = { r = 1, g = 1, b = 1, a = 1 }
local borderSuppressed = false

function timeline.SnapBorder(backdrop)
    for _, key in ipairs(BORDER_PIECES) do
        local piece = backdrop[key]
        if piece then
            piece:SetSnapToPixelGrid(true)
            piece:SetTexelSnappingBias(0)
        end
    end
end

local function applyBorder()
    if borderPath and borderThickness > 0 and not borderSuppressed then
        local thickness = PixelUtil.GetNearestPixelSize(borderThickness, border:GetEffectiveScale(), 1)
        border:SetBackdrop({ edgeFile = borderPath, edgeSize = thickness })
        border:SetBackdropBorderColor(borderColor.r, borderColor.g, borderColor.b, borderColor.a)
        timeline.SnapBorder(border)
        border:ClearAllPoints()
        border:SetPoint("TOPLEFT", frame.background, "TOPLEFT", -borderOffset, borderOffset)
        border:SetPoint("BOTTOMRIGHT", frame.background, "BOTTOMRIGHT", borderOffset, -borderOffset)
        border:Show()
    else
        border:Hide()
    end
    if timeline.RefreshBackdropReach then
        timeline.RefreshBackdropReach()
    end
end

local backgroundPath = BACKGROUND_TEXTURE_DEFAULT_PATH

function timeline.SetBackgroundTexture(path)
    backgroundPath = path
    frame.background:SetTexture(path or BACKGROUND_TEXTURE_DEFAULT_PATH, "REPEAT", "REPEAT")
    frame.background:SetAlpha(path and 1 or 0)
end

function timeline.BackgroundTexture()
    return backgroundPath
end

local backgroundColor = { r = 1, g = 1, b = 1, a = 1 }

function timeline.SetBackgroundColor(red, green, blue, alpha)
    backgroundColor.r, backgroundColor.g, backgroundColor.b, backgroundColor.a = red, green, blue, alpha
    frame.background:SetVertexColor(red, green, blue, alpha)
    if timeline.onBackgroundColorChanged then
        timeline.onBackgroundColorChanged()
    end
end

function timeline.BackgroundColor()
    return backgroundColor.r, backgroundColor.g, backgroundColor.b, backgroundColor.a
end

function timeline.SetBorder(path, offset, thickness, red, green, blue, alpha)
    borderPath = path
    borderOffset = offset
    borderThickness = thickness
    borderColor.r, borderColor.g, borderColor.b, borderColor.a = red, green, blue, alpha
    applyBorder()
end

function timeline.PlainBorder()
    return borderPath, borderOffset, borderThickness, borderColor
end

function timeline.BorderFrame()
    return border
end

function timeline.BorderReach()
    if borderSuppressed or not borderPath or borderThickness <= 0 then
        return 0
    end
    return math.max(borderOffset, 0)
end

function timeline.SetBorderSuppressed(value)
    borderSuppressed = value
    applyBorder()
end
