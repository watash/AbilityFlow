local addonName, ns = ...

local L = ns.L
local appearance = ns.appearance
local controls = ns.appearanceControls
local media = ns.media

ns.appearanceElements = ns.appearanceElements or {}

local COLUMN_WIDTHS = { 330, 280, 330 }
local OUTLINE_LIST_EXTRA = -15
local OUTLINE_LABEL_WIDTH = 60
local FIRST_COLUMN_EXTRA = 60
local PLACE_SLIDER_EXTRA = 60
local PLACE_MIN = -64
local PLACE_MAX = 64
local PLACE_LIST_EXTRA = PLACE_SLIDER_EXTRA + 25
local FONT_LIST_EXTRA = FIRST_COLUMN_EXTRA + 25
local UNDER_COLOR_GAP = 14
local HIDE_CHECKBOX_NUDGE = 4
local CHECKBOX_COLUMN_NUDGE = 2
local CHECKBOX_COLUMN_DROP = 1

local FIRST_COLUMN_INDENT = controls.CHECKBOX_PICTURE_PADDING

local VALUE_BOX_WIDTH = 34

local SIZE_MIN = 6
local SIZE_MAX = 64
local SIZE_STEP = 1
local OFFSET_STEP = 1
local SHIFT_MIN = -50
local SHIFT_MAX = 50

local function makeColumn(content, index)
    local left = index == 1 and FIRST_COLUMN_INDENT or 0
    for before = 1, index - 1 do
        left = left + COLUMN_WIDTHS[before]
    end
    return controls.Column(content, left, COLUMN_WIDTHS[index])
end

local function buildText(element, content, onChanged)
    local function set(field, value)
        appearance.Set(element, field, value)
        appearance.Apply()
        onChanged()
    end
    local function colorSetter(field)
        return function(red, green, blue, alpha)
            set(field, { r = red, g = green, b = blue, a = alpha })
        end
    end

    local dependentRows, dependentBoxes, dependentTexts = {}, {}, {}
    local function refreshDependents()
        local on = appearance.Get(element, "hidden") ~= true
        for _, row in ipairs(dependentRows) do
            controls.SetRowEnabled(row, on)
        end
        for _, box in ipairs(dependentBoxes) do
            controls.SetCheckboxEnabled(box, on)
        end
        for _, text in ipairs(dependentTexts) do
            controls.SetTextEnabled(text, on)
        end
    end

    local fontColumn = makeColumn(content, 1)
    local hasPlace = appearance.HasBackground(element)
    local hideCheckbox = controls.Checkbox(fontColumn, fontColumn,
        hasPlace and L.EVENT_APPEARANCE_TEXT_HIDE or L.EVENT_APPEARANCE_COUNTDOWN_HIDE, appearance.Reader(element, "hidden"),
        function(checked)
            set("hidden", checked)
            refreshDependents()
        end, -HIDE_CHECKBOX_NUDGE)
    local fontDropdown = controls.InlineDropdown(fontColumn, hideCheckbox, L.EVENT_APPEARANCE_TEXT_FONT, media.FontOptions(),
        appearance.Reader(element, "font"), function(value)
            set("font", value)
        end, FONT_LIST_EXTRA)
    fontDropdown:ClearAllPoints()
    fontDropdown:SetPoint("TOPLEFT", hideCheckbox, "BOTTOMLEFT", HIDE_CHECKBOX_NUDGE, -controls.ROW_INDENT)

    local sizeSlider = controls.EditableSlider(fontColumn, fontDropdown, L.EVENT_APPEARANCE_SIZE, SIZE_MIN, SIZE_MAX,
        SIZE_STEP, appearance.Reader(element, "size"), function(value)
            set("size", value)
        end, FIRST_COLUMN_EXTRA, nil, VALUE_BOX_WIDTH)

    local colorSwatch = controls.InlineColor(fontColumn, sizeSlider, L.EVENT_APPEARANCE_TEXT_COLOR,
        appearance.Reader(element, "color"), colorSetter("color"), false)

    local eventColorCheckbox = controls.Checkbox(fontColumn, colorSwatch, L.EVENT_APPEARANCE_TEXT_EVENT_COLOR,
        appearance.Reader(element, "useEventColor"), function(checked)
            set("useEventColor", checked)
        end)
    eventColorCheckbox:ClearAllPoints()
    eventColorCheckbox:SetPoint("TOPLEFT", colorSwatch, "BOTTOMLEFT", -HIDE_CHECKBOX_NUDGE, -UNDER_COLOR_GAP)
    controls.SetTooltip(eventColorCheckbox, L.EVENT_APPEARANCE_TIP_EVENT_COLOR)

    local lookColumn = makeColumn(content, 2)
    local outlineDropdown = controls.InlineDropdown(lookColumn, lookColumn, L.EVENT_APPEARANCE_TEXT_OUTLINE, {
        { text = L.NONE, value = "NONE" },
        { text = L.EVENT_APPEARANCE_OUTLINE, value = "OUTLINE" },
        { text = L.EVENT_APPEARANCE_THICK_OUTLINE, value = "THICKOUTLINE" },
    }, appearance.Reader(element, "outline"), function(value)
        set("outline", value)
    end, OUTLINE_LIST_EXTRA, OUTLINE_LABEL_WIDTH)

    local shadowCheckbox = controls.Checkbox(lookColumn, outlineDropdown, L.EVENT_APPEARANCE_TEXT_SHADOW,
        appearance.Reader(element, "shadow"), function(checked)
            set("shadow", checked)
        end, -CHECKBOX_COLUMN_NUDGE, -CHECKBOX_COLUMN_DROP)

    local monochromeCheckbox = controls.Checkbox(lookColumn, shadowCheckbox, L.EVENT_APPEARANCE_TEXT_MONOCHROME,
        appearance.Reader(element, "monochrome"), function(checked)
            set("monochrome", checked)
        end)

    local slugCheckbox
    if appearance.SLUG_SUPPORTED then
        slugCheckbox = controls.Checkbox(lookColumn, monochromeCheckbox, L.EVENT_APPEARANCE_TEXT_SLUG,
            appearance.Reader(element, "slug"), function(checked)
                set("slug", checked)
            end)
    end

    local placeColumn = makeColumn(content, 3)
    local placeHeading = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    placeHeading:SetText(L.EVENT_APPEARANCE_TEXT_PLACE_TITLE)

    local anchorRow, mirrorCheckbox
    if hasPlace then
        mirrorCheckbox = controls.Checkbox(placeColumn, placeColumn, L.EVENT_APPEARANCE_TEXT_MIRROR,
            appearance.Reader(element, "mirrored"), function(checked)
                set("mirrored", checked)
            end, -HIDE_CHECKBOX_NUDGE)
        controls.SetTooltip(mirrorCheckbox, L.EVENT_APPEARANCE_TIP_MIRROR)
    else
        anchorRow = controls.InlineDropdown(placeColumn, placeColumn, L.EVENT_APPEARANCE_ANCHOR,
            controls.PointOptions(ns.eventIndicators.ANCHOR_POINTS), appearance.Reader(element, "anchor"), function(value)
                set("anchor", value)
            end, PLACE_LIST_EXTRA)
    end
    local shiftMin, shiftMax = hasPlace and SHIFT_MIN or PLACE_MIN, hasPlace and SHIFT_MAX or PLACE_MAX
    local offsetXRow = controls.EditableSlider(placeColumn, anchorRow or mirrorCheckbox, L.EVENT_APPEARANCE_OFFSET_X, shiftMin,
        shiftMax, OFFSET_STEP, appearance.Reader(element, "shiftX"), function(value)
            set("shiftX", value)
        end, PLACE_SLIDER_EXTRA, nil, VALUE_BOX_WIDTH)
    local offsetYRow = controls.EditableSlider(placeColumn, offsetXRow, L.EVENT_APPEARANCE_OFFSET_Y, shiftMin, shiftMax,
        OFFSET_STEP, appearance.Reader(element, "shiftY"), function(value)
            set("shiftY", value)
        end, PLACE_SLIDER_EXTRA, nil, VALUE_BOX_WIDTH)

    local firstRows = {
        { hideCheckbox, FIRST_COLUMN_INDENT + controls.ROW_INDENT - HIDE_CHECKBOX_NUDGE },
        { fontDropdown, FIRST_COLUMN_INDENT + controls.ROW_INDENT },
        { sizeSlider, FIRST_COLUMN_INDENT + controls.ROW_INDENT },
        { colorSwatch, FIRST_COLUMN_INDENT + controls.ROW_INDENT },
    }
    local secondRows = {
        { outlineDropdown, controls.ROW_INDENT },
        { shadowCheckbox, controls.ROW_INDENT - CHECKBOX_COLUMN_NUDGE },
        { monochromeCheckbox, controls.ROW_INDENT - CHECKBOX_COLUMN_NUDGE },
        { slugCheckbox, controls.ROW_INDENT - CHECKBOX_COLUMN_NUDGE },
    }
    local thirdRows = {
        { anchorRow or mirrorCheckbox, anchorRow and controls.ROW_INDENT or controls.ROW_INDENT - HIDE_CHECKBOX_NUDGE },
        { offsetXRow, controls.ROW_INDENT },
        { offsetYRow, controls.ROW_INDENT },
    }
    local function levelWithFirst(rows, columnIndex, skipped)
        local columnLeft = 0
        for before = 1, columnIndex - 1 do
            columnLeft = columnLeft + COLUMN_WIDTHS[before]
        end
        for index, entry in ipairs(rows) do
            local row, start = entry[1], entry[2]
            local reference = firstRows[index + (skipped or 0)]
            if row and reference then
                row:ClearAllPoints()
                row:SetPoint("LEFT", reference[1], "LEFT", columnLeft + start - reference[2], 0)
            end
        end
    end
    levelWithFirst(secondRows, 2)
    levelWithFirst(thirdRows, 3, 1)
    placeHeading:ClearAllPoints()
    placeHeading:SetPoint("LEFT", hideCheckbox, "LEFT",
        COLUMN_WIDTHS[1] + COLUMN_WIDTHS[2] + controls.ROW_INDENT - (FIRST_COLUMN_INDENT + controls.ROW_INDENT - HIDE_CHECKBOX_NUDGE), 0)

    local function addTo(list, item)
        if item then
            list[#list + 1] = item
        end
    end
    addTo(dependentRows, fontDropdown)
    addTo(dependentRows, sizeSlider)
    addTo(dependentRows, colorSwatch)
    addTo(dependentRows, outlineDropdown)
    addTo(dependentRows, anchorRow)
    addTo(dependentRows, offsetXRow)
    addTo(dependentRows, offsetYRow)
    addTo(dependentBoxes, eventColorCheckbox)
    addTo(dependentBoxes, shadowCheckbox)
    addTo(dependentBoxes, monochromeCheckbox)
    addTo(dependentBoxes, slugCheckbox)
    addTo(dependentBoxes, mirrorCheckbox)
    addTo(dependentTexts, placeHeading)
    refreshDependents()

    controls.AlignWhenShown(content, function()
        controls.AlignBoxEnds(fontDropdown, { sizeSlider })
        if anchorRow then
            controls.AlignBoxEnds(anchorRow, { offsetXRow, offsetYRow })
        elseif offsetXRow:GetLeft() then
            controls.AlignBoxEndsAt(offsetXRow:GetLeft() + controls.INLINE_LABEL_WIDTH + controls.INLINE_GAP
                + controls.INLINE_DROPDOWN_WIDTH + PLACE_LIST_EXTRA, { offsetXRow, offsetYRow })
        end
    end)
    return refreshDependents
end

for _, element in ipairs(appearance.TEXT_ELEMENTS) do
    ns.appearanceElements[element] = {
        Build = function(content, onChanged)
            return buildText(element, content, onChanged)
        end,
    }
end
