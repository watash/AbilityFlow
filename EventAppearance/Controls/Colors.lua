local addonName, ns = ...

local CreateFrame = CreateFrame
local C_Texture = C_Texture
local max = math.max

local controls = ns.appearanceControls
local LABEL_GAP = controls.LABEL_GAP
local FIRST_ROW_OFFSET = controls.FIRST_ROW_OFFSET
local INLINE_LABEL_WIDTH = controls.INLINE_LABEL_WIDTH
local INLINE_GAP = controls.INLINE_GAP
local DISABLED_ALPHA = controls.DISABLED_ALPHA
local resolve = controls.Resolve

local PICKER_GAP = 10
local SWATCH_SIZE = 32
local CHECKER_ATLAS = "colorpicker-checkerboard"
local CHECKER_ATLAS_ROWS = 8
local CHECKER_ROWS_SHOWN = 2
local INLINE_SWATCH_NUDGE = -6

function controls.PickColor(color, hasOpacity, onChanged, anchor)
    local start = { r = color.r, g = color.g, b = color.b, a = color.a }
    local function apply()
        local red, green, blue = ColorPickerFrame:GetColorRGB()
        local alpha
        if hasOpacity then
            alpha = ColorPickerFrame:GetColorAlpha() or start.a or 1
        end
        onChanged(red, green, blue, alpha)
    end
    ColorPickerFrame:SetupColorPickerAndShow({
        r = start.r,
        g = start.g,
        b = start.b,
        opacity = hasOpacity and (start.a or 1) or nil,
        hasOpacity = hasOpacity,
        swatchFunc = apply,
        opacityFunc = apply,
        cancelFunc = function()
            onChanged(start.r, start.g, start.b, hasOpacity and (start.a or 1) or nil)
        end,
    })
    if anchor then
        ColorPickerFrame:ClearAllPoints()
        ColorPickerFrame:SetPoint("TOP", anchor, "BOTTOM", 0, -PICKER_GAP)
    end
end

function controls.AddChecker(swatch)
    local colour = swatch.Color
    local atlas = C_Texture.GetAtlasInfo(CHECKER_ATLAS)
    if not colour or not atlas then
        return nil
    end
    local layer, sublevel = colour:GetDrawLayer()
    local checker = swatch:CreateTexture(nil, layer, nil, max(-8, sublevel - 1))
    checker:SetAllPoints(colour)
    checker:SetTexture(atlas.file or atlas.filename)
    checker:SetTexCoord(atlas.leftTexCoord, atlas.rightTexCoord, atlas.topTexCoord,
        atlas.topTexCoord + (atlas.bottomTexCoord - atlas.topTexCoord) * CHECKER_ROWS_SHOWN / CHECKER_ATLAS_ROWS)
    swatch.checker = checker
    return checker
end

function controls.Swatch(parent)
    local swatch = CreateFrame("Button", nil, parent, "ColorSwatchTemplate")
    swatch:SetSize(SWATCH_SIZE, SWATCH_SIZE)

    controls.AddChecker(swatch)

    function swatch:SetColor(red, green, blue, alpha)
        self:SetColorRGB(red, green, blue)
        if self.Color then
            self.Color:SetAlpha(alpha or 1)
        end
    end

    local setEnabled = swatch.SetEnabled
    function swatch:SetEnabled(enabled)
        setEnabled(self, enabled)
        self:SetAlpha(enabled and 1 or DISABLED_ALPHA)
    end

    return swatch
end

function controls.InlineColor(parent, anchorTo, labelText, color, onChanged, hasOpacity, labelWidth)
    labelWidth = labelWidth or INLINE_LABEL_WIDTH
    if hasOpacity == nil then
        hasOpacity = true
    end
    local getter
    getter, color = resolve(color)
    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(labelWidth + INLINE_GAP + SWATCH_SIZE, SWATCH_SIZE)
    if anchorTo == parent then
        row:SetPoint("TOPLEFT", parent, "TOPLEFT", LABEL_GAP, -FIRST_ROW_OFFSET)
    else
        row:SetPoint("TOPLEFT", anchorTo, "BOTTOMLEFT", 0, -LABEL_GAP)
    end

    local label = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("LEFT", row, "LEFT", 0, 0)
    label:SetWidth(labelWidth)
    label:SetJustifyH("LEFT")
    label:SetText(labelText)

    local swatch = controls.Swatch(row)
    swatch:SetPoint("LEFT", label, "RIGHT", INLINE_GAP + INLINE_SWATCH_NUDGE, 0)
    swatch:SetColor(color.r, color.g, color.b, color.a)
    swatch:SetScript("OnClick", function()
        controls.PickColor(color, hasOpacity, function(red, green, blue, alpha)
            alpha = alpha or 1
            color = { r = red, g = green, b = blue, a = alpha }
            swatch:SetColor(red, green, blue, alpha)
            onChanged(red, green, blue, alpha)
        end)
    end)

    row.label = label
    row.swatch = swatch
    if getter then
        row.Resync = function()
            color = getter()
            swatch:SetColor(color.r, color.g, color.b, color.a)
        end
    end
    return row
end
