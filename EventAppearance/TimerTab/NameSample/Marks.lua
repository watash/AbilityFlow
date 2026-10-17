local addonName, ns = ...

local CreateFrame = CreateFrame
local PixelUtil = PixelUtil
local ipairs = ipairs
local previewEvent = ns.timerTab.event
local nameSample = ns.timerTab.nameSample

local ARROW_TEXTURE = "Interface\\AddOns\\AbilityFlow\\Media\\Icons\\arrow-up.png"
local ARROW_RAISE = 0
local ARROW_UP_SHARE = 1
local SWATCH_GREY_ALPHA = 0.5
local SWATCH_TEXTURE = "Interface\\Buttons\\WHITE8X8"
local SWATCH_BORDER_PIXELS = 1
local SWATCH_VISIBLE_SHARE = 0.5
local SWATCH_OUTER_COLOR = { 1, 1, 1 }
local SWATCH_INNER_COLOR = { 0, 0, 0 }

local function newSwatch(parent)
    local swatch = CreateFrame("Frame", nil, parent)
    swatch:EnableMouse(false)
    local outer = swatch:CreateTexture(nil, "BACKGROUND", nil, -8)
    outer:SetTexture(SWATCH_TEXTURE)
    outer:SetVertexColor(SWATCH_OUTER_COLOR[1], SWATCH_OUTER_COLOR[2], SWATCH_OUTER_COLOR[3])
    outer:SetAllPoints()
    local inner = swatch:CreateTexture(nil, "BACKGROUND", nil, -7)
    inner:SetTexture(SWATCH_TEXTURE)
    inner:SetVertexColor(SWATCH_INNER_COLOR[1], SWATCH_INNER_COLOR[2], SWATCH_INNER_COLOR[3])
    swatch.Color = swatch:CreateTexture(nil, "ARTWORK")
    swatch.Color:SetTexture(SWATCH_TEXTURE)
    ns.appearanceControls.AddChecker(swatch)

    function swatch:SetSide(side)
        side = side * SWATCH_VISIBLE_SHARE
        self:SetSize(side, side)
        local pixel = PixelUtil.GetPixelToUIUnitFactor() / self:GetEffectiveScale()
        local border = SWATCH_BORDER_PIXELS * pixel
        inner:ClearAllPoints()
        inner:SetPoint("TOPLEFT", self, "TOPLEFT", border, -border)
        inner:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -border, border)
        self.Color:ClearAllPoints()
        self.Color:SetPoint("TOPLEFT", self, "TOPLEFT", 2 * border, -2 * border)
        self.Color:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -2 * border, 2 * border)
    end

    function swatch:SetColor(red, green, blue, alpha)
        self.Color:SetVertexColor(red, green, blue)
        self.Color:SetAlpha(alpha or 1)
    end
    return swatch
end

function previewEvent.PaintArrow(sample, arrow)
    sample.arrowExtra = 0
    previewEvent.PlaceNameText(sample)
    if not arrow then
        if sample.arrow then
            sample.arrow:Hide()
        end
        return
    end
    if not sample.arrow then
        sample.arrow = sample.nameHolder:CreateTexture(nil, "OVERLAY")
        sample.arrow:SetTexture(ARROW_TEXTURE)
    end
    local sign = sample.arrow
    local side = arrow.side
    local drawn = arrow.up and side * ARROW_UP_SHARE or side
    sign:SetSize(drawn, drawn)
    if arrow.up then
        sign:SetTexCoord(0, 1, 0, 1)
    else
        sign:SetTexCoord(0, 1, 1, 0)
    end
    sign:SetVertexColor(arrow.r, arrow.g, arrow.b, 1)
    sign:SetDesaturated(false)
    sign:ClearAllPoints()
    sign:SetPoint("LEFT", sample.texts.name, "RIGHT", nameSample.ARROW_GAP, ARROW_RAISE)
    sign:Show()
    sample.arrowExtra = nameSample.ARROW_GAP + side
    previewEvent.PlaceNameText(sample)
    for _, piece in ipairs({ sample.textBackgrounds.name, sample.nameBackdrop }) do
        local point, relativeTo, relativePoint, x, y = piece:GetPoint(2)
        if point then
            piece:SetPoint(point, relativeTo, relativePoint, x + sample.arrowExtra, y)
        end
    end
end

function previewEvent.HideSwatch(sample)
    if sample.swatch then
        sample.swatch:Hide()
    end
end

function previewEvent.PaintSwatch(sample, side, color)
    sample.texts.name:Hide()
    sample.textBackgrounds.name:Hide()
    ns.textBorder.Clear(sample.nameBackdrop)
    sample.arrowExtra = 0
    previewEvent.PlaceNameText(sample)
    if sample.arrow then
        sample.arrow:Hide()
    end
    if not sample.swatch then
        sample.swatch = newSwatch(sample.nameHolder)
    end
    local swatch = sample.swatch
    swatch:SetSide(side)
    swatch:ClearAllPoints()
    swatch:SetPoint("CENTER", sample.texts.name, "CENTER", 0, 0)
    swatch:SetAlpha(1)
    if color then
        swatch:SetColor(color.r, color.g, color.b, color.a)
    end
    if swatch.Color then
        swatch.Color:SetShown(color ~= nil)
    end
    if swatch.checker then
        swatch.checker:SetShown(color ~= nil)
    end
    swatch:Show()
end

function previewEvent.GreyMarks(sample, grey)
    if sample.arrow then
        sample.arrow:SetDesaturated(grey)
    end
    if sample.swatch then
        sample.swatch:SetAlpha(grey and SWATCH_GREY_ALPHA or 1)
    end
end
