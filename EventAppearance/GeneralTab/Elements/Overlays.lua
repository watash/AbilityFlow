local addonName, ns = ...

local L = ns.L
local appearance = ns.appearance
local controls = ns.appearanceControls
local overlays = ns.eventIndicators

ns.appearanceElements = ns.appearanceElements or {}

local SIZE_MIN = appearance.SMALL_ICON_SIZE_MIN
local SIZE_STEP = 1
local OFFSET_MIN = -64
local OFFSET_MAX = 64
local OFFSET_STEP = 1
local FIRST_COLUMN_WIDTH = 360
local SECOND_COLUMN_WIDTH = 400
local COLUMN_GAP = 104
local SWITCH_DROP = 3
local SWITCH_NUDGE = 4
local TEXT_SHIFT = 2
local GAP_MIN = 0
local GAP_MAX = 50
local GAP_STEP = 1
local VALUE_BOX_WIDTH = 34

local KINDS = {
    debuff = {},
    danger = {},
    roles = { row = true },
}

local function buildOverlay(kind, content, onChanged)
    local spec = KINDS[kind]
    local function set(field, value)
        appearance.Set(kind, field, value)
        appearance.Apply()
        onChanged()
    end

    local function addSize(parent, anchorTo)
        return controls.EditableSlider(parent, anchorTo, L.EVENT_APPEARANCE_SIZE, SIZE_MIN, appearance.SIZE_LIMITS[kind][2],
            SIZE_STEP,
            appearance.Reader(kind, "size"), function(value)
                set("size", value)
            end, controls.WIDE_SLIDER_EXTRA, nil, VALUE_BOX_WIDTH)
    end

    local function addPlacement(parent, anchorTo)
        local anchorRow = controls.InlineDropdown(parent, anchorTo, L.EVENT_APPEARANCE_ANCHOR,
            controls.PointOptions(overlays.ANCHOR_POINTS), appearance.Reader(kind, "anchor"), function(value)
                set("anchor", value)
            end, controls.WIDE_LIST_EXTRA)
        local offsetXRow = controls.EditableSlider(parent, anchorRow, L.EVENT_APPEARANCE_OFFSET_X, OFFSET_MIN, OFFSET_MAX,
            OFFSET_STEP, appearance.Reader(kind, "offsetX"), function(value)
                set("offsetX", value)
            end, controls.WIDE_SLIDER_EXTRA, nil, VALUE_BOX_WIDTH)
        local offsetYRow = controls.EditableSlider(parent, offsetXRow, L.EVENT_APPEARANCE_OFFSET_Y, OFFSET_MIN,
            OFFSET_MAX, OFFSET_STEP, appearance.Reader(kind, "offsetY"), function(value)
                set("offsetY", value)
            end, controls.WIDE_SLIDER_EXTRA, nil, VALUE_BOX_WIDTH)
        return anchorRow, offsetXRow, offsetYRow
    end

    local dependentRows, dependentCheckbox
    local function refreshDependents()
        local on = appearance.Get(kind, "enabled") == true
        for _, row in ipairs(dependentRows or {}) do
            controls.SetRowEnabled(row, on)
        end
        if dependentCheckbox then
            controls.SetCheckboxEnabled(dependentCheckbox, on)
        end
    end

    local firstColumn = controls.Column(content, controls.PANEL_INDENT + TEXT_SHIFT, FIRST_COLUMN_WIDTH)
    local enabledCheckbox = controls.Checkbox(firstColumn, firstColumn, L.EVENT_APPEARANCE_HIDE_INDICATOR,
        function()
            return not appearance.Get(kind, "enabled")
        end, function(checked)
            set("enabled", not checked)
            refreshDependents()
        end, -(SWITCH_NUDGE + TEXT_SHIFT), -SWITCH_DROP)
    local last = enabledCheckbox
    local verticalCheckbox
    if spec.row then
        verticalCheckbox = controls.Checkbox(firstColumn, last, L.ORIENTATION_VERTICAL, appearance.Reader(kind, "vertical"),
            function(checked)
                set("vertical", checked)
            end)
        last = verticalCheckbox
    end
    local sizeRow = addSize(firstColumn, last)

    local secondColumn = controls.Column(content, FIRST_COLUMN_WIDTH + COLUMN_GAP, SECOND_COLUMN_WIDTH)
    local anchorRow, offsetXRow, offsetYRow = addPlacement(secondColumn, secondColumn)

    sizeRow:ClearAllPoints()
    sizeRow:SetPoint("TOPLEFT", spec.row and offsetYRow or offsetXRow, "TOPLEFT", -(FIRST_COLUMN_WIDTH + COLUMN_GAP) + controls.PANEL_INDENT + TEXT_SHIFT, 0)

    local gapRow
    if spec.row then
        gapRow = controls.EditableSlider(secondColumn, offsetYRow, L.EVENT_APPEARANCE_GAP, GAP_MIN, GAP_MAX, GAP_STEP,
            appearance.Reader(kind, "gap"), function(value)
                set("gap", value)
            end, controls.WIDE_SLIDER_EXTRA, nil, VALUE_BOX_WIDTH)
    end

    dependentRows = { sizeRow, anchorRow, offsetXRow, offsetYRow }
    if gapRow then
        dependentRows[#dependentRows + 1] = gapRow
    end
    dependentCheckbox = verticalCheckbox
    refreshDependents()

    controls.AlignWhenShown(content, function()
        controls.AlignBoxEnds(anchorRow, spec.row and { offsetXRow, offsetYRow, gapRow } or { offsetXRow, offsetYRow })
        if sizeRow:GetLeft() then
            controls.AlignBoxEndsAt(sizeRow:GetLeft() + controls.INLINE_LABEL_WIDTH + controls.INLINE_GAP
                + controls.INLINE_DROPDOWN_WIDTH + controls.WIDE_LIST_EXTRA, { sizeRow })
        end
    end)
    return refreshDependents
end

for kind in pairs(KINDS) do
    ns.appearanceElements[kind] = {
        Build = function(content, onChanged)
            return buildOverlay(kind, content, onChanged)
        end,
    }
end
