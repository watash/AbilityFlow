local addonName, ns = ...

local L = ns.L
local appearance = ns.appearance
local controls = ns.appearanceControls
local media = ns.media

local background = {}
ns.appearanceElements = ns.appearanceElements or {}
ns.appearanceElements.nameBackground = background

local GROUP = "nameBackground"
local ROW_GAP = 8
local FIRST_COLUMN_WIDTH = 460
local SLIDER_LABEL_WIDTH = 135
local VALUE_BOX_WIDTH = 34
local TIGHT_ROW_GAP = 6
local ON_TOP_GAP = 40
local OFFSET_MIN = -40
local OFFSET_MAX = 40
local OFFSET_STEP = 1
local BORDER_SHIFT_MIN = -32
local BORDER_SHIFT_MAX = 32
local BORDER_THICKNESS_MIN = 1
local BORDER_THICKNESS_MAX = 64
local BORDER_LIST_EXTRA = 80
local TEXTURE_LIST_EXTRA = BORDER_LIST_EXTRA + 60
local BORDER_SLIDER_EXTRA = 60
local RAISE_MIN = -50
local RAISE_MAX = 50
local RAISE_STEP = 1

local function shownTexture()
    local texture = appearance.Get(GROUP, "texture")
    return texture == media.NONE and media.DEFAULT_TEXT_BACKGROUND or texture
end

function background.Build(content, onChanged)
    local rows = {}
    local borderRows = {}
    local function set(field, value)
        appearance.Set(GROUP, field, value)
        appearance.Apply()
        onChanged()
    end
    local function refreshBorderRows()
        local enabled = appearance.Get(GROUP, "enabled")
        local hasTexture = appearance.Get(GROUP, "borderTexture") ~= media.NONE
        for index, row in ipairs(borderRows) do
            controls.SetRowEnabled(row, enabled and (index == 1 or hasTexture))
        end
    end
    local heading
    local function refreshRows()
        local enabled = appearance.Get(GROUP, "enabled")
        if heading then
            controls.SetTextEnabled(heading, enabled)
        end
        for _, row in ipairs(rows) do
            controls.SetRowEnabled(row, enabled)
        end
        if rows.onTop then
            controls.SetCheckboxEnabled(rows.onTop, enabled)
        end
        refreshBorderRows()
    end

    local firstColumn = controls.Column(content, 0, FIRST_COLUMN_WIDTH)
    local borderColumn = controls.Column(content, FIRST_COLUMN_WIDTH, FIRST_COLUMN_WIDTH)
    heading = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    heading:SetText(L.EVENT_APPEARANCE_ELEMENT_BORDER)
    local switch = controls.Checkbox(firstColumn, firstColumn, L.EVENT_APPEARANCE_TEXT_BACKGROUND_SHOW,
        appearance.Reader(GROUP, "enabled"), function(checked)
            set("enabled", checked)
            refreshRows()
        end)

    local textureRow = controls.InlineDropdown(firstColumn, switch, L.EVENT_APPEARANCE_TEXT_BACKGROUND,
        media.TextBackgroundOptions(), shownTexture, function(value)
            set("texture", value)
        end, TEXTURE_LIST_EXTRA, SLIDER_LABEL_WIDTH)
    textureRow:ClearAllPoints()
    textureRow:SetPoint("TOPLEFT", switch, "BOTTOMLEFT", controls.CHECKBOX_PICTURE_PADDING, -ROW_GAP)

    local colorRow = controls.InlineColor(firstColumn, textureRow, L.BACKGROUND_COLOR,
        appearance.Reader(GROUP, "color"), function(red, green, blue, alpha)
            set("color", { r = red, g = green, b = blue, a = alpha })
        end, nil, SLIDER_LABEL_WIDTH)
    local sliderExtra = textureRow:GetWidth() - SLIDER_LABEL_WIDTH - controls.INLINE_GAP - controls.EDITABLE_SLIDER_WIDTH

    local offsetXRow = controls.EditableSlider(firstColumn, colorRow, L.EVENT_APPEARANCE_BACKGROUND_REACH_X, OFFSET_MIN,
        OFFSET_MAX, OFFSET_STEP, appearance.Reader(GROUP, "offsetX"), function(value)
            set("offsetX", value)
        end, sliderExtra, nil, VALUE_BOX_WIDTH, nil, SLIDER_LABEL_WIDTH)
    local offsetYRow = controls.EditableSlider(firstColumn, offsetXRow, L.EVENT_APPEARANCE_BACKGROUND_REACH_Y, OFFSET_MIN,
        OFFSET_MAX, OFFSET_STEP, appearance.Reader(GROUP, "offsetY"), function(value)
            set("offsetY", value)
        end, sliderExtra, nil, VALUE_BOX_WIDTH, nil, SLIDER_LABEL_WIDTH)
    local raiseRow = controls.EditableSlider(firstColumn, offsetYRow, L.EVENT_APPEARANCE_BACKGROUND_RAISE, RAISE_MIN,
        RAISE_MAX, RAISE_STEP, appearance.Reader(GROUP, "raise"), function(value)
            set("raise", value)
        end, sliderExtra, "%d%%", VALUE_BOX_WIDTH, nil, SLIDER_LABEL_WIDTH)

    local previous = textureRow
    for _, row in ipairs({ colorRow, offsetXRow, offsetYRow, raiseRow }) do
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, -TIGHT_ROW_GAP)
        previous = row
    end

    local onTop = controls.Checkbox(firstColumn, switch, L.EVENT_APPEARANCE_BACKGROUND_ON_TOP,
        appearance.Reader(GROUP, "onTop"), function(checked)
            set("onTop", checked)
        end)
    onTop:ClearAllPoints()
    onTop:SetPoint("LEFT", switch.label, "RIGHT", ON_TOP_GAP, 0)
    controls.SetTooltip(onTop, L.EVENT_APPEARANCE_TIP_BACKGROUND_ON_TOP)

    local borderTextureRow = controls.InlineDropdown(borderColumn, borderColumn, L.EVENT_APPEARANCE_BACKGROUND_BORDER_TEXTURE,
        media.BorderOptions(), appearance.Reader(GROUP, "borderTexture"), function(value)
            set("borderTexture", value)
            refreshBorderRows()
        end, BORDER_LIST_EXTRA)
    local borderColorRow = controls.InlineColor(borderColumn, borderTextureRow, L.EVENT_APPEARANCE_BORDER_COLOR,
        appearance.Reader(GROUP, "borderColor"), function(red, green, blue, alpha)
            set("borderColor", { r = red, g = green, b = blue, a = alpha })
        end)
    local borderShiftRow = controls.EditableSlider(borderColumn, borderColorRow, L.EVENT_APPEARANCE_BACKGROUND_BORDER_SHIFT,
        BORDER_SHIFT_MIN, BORDER_SHIFT_MAX, OFFSET_STEP, appearance.Reader(GROUP, "borderOffset"), function(value)
            set("borderOffset", value)
        end, BORDER_SLIDER_EXTRA, nil, VALUE_BOX_WIDTH)
    local borderThicknessRow = controls.EditableSlider(borderColumn, borderShiftRow,
        L.EVENT_APPEARANCE_BORDER_THICKNESS, BORDER_THICKNESS_MIN, BORDER_THICKNESS_MAX, OFFSET_STEP,
        appearance.Reader(GROUP, "borderThickness"), function(value)
            set("borderThickness", value)
        end, BORDER_SLIDER_EXTRA, nil, VALUE_BOX_WIDTH)
    local columnOffset = FIRST_COLUMN_WIDTH
    heading:ClearAllPoints()
    heading:SetPoint("LEFT", switch, "LEFT", FIRST_COLUMN_WIDTH + controls.CHECKBOX_PICTURE_PADDING, 0)
    borderTextureRow:ClearAllPoints()
    borderTextureRow:SetPoint("LEFT", textureRow, "LEFT", columnOffset, 0)
    borderColorRow:ClearAllPoints()
    borderColorRow:SetPoint("LEFT", colorRow, "LEFT", columnOffset, 0)
    borderShiftRow:ClearAllPoints()
    borderShiftRow:SetPoint("LEFT", offsetXRow, "LEFT", columnOffset, 0)
    borderThicknessRow:ClearAllPoints()
    borderThicknessRow:SetPoint("LEFT", offsetYRow, "LEFT", columnOffset, 0)
    borderRows = { borderTextureRow, borderColorRow, borderShiftRow, borderThicknessRow }

    local function alignBoxEnds()
        controls.AlignBoxEnds(textureRow, { offsetXRow, offsetYRow, raiseRow })
        controls.AlignBoxEnds(borderTextureRow, { borderShiftRow, borderThicknessRow })
        local target, left = textureRow:GetRight(), switch:GetLeft()
        if target and left then
            local width = onTop:GetWidth() + controls.CHECKBOX_LABEL_GAP + onTop.label:GetStringWidth()
            onTop:ClearAllPoints()
            onTop:SetPoint("LEFT", switch, "LEFT", target - left - width, 0)
        end
    end
    controls.AlignWhenShown(content, alignBoxEnds)

    rows = { textureRow, colorRow, offsetXRow, offsetYRow, raiseRow, onTop = onTop }
    refreshRows()
    return refreshRows
end
