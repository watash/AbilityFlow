local addonName, ns = ...

local L = ns.L
local appearance = ns.appearance
local controls = ns.appearanceControls

local icon = {}
ns.appearanceElements = ns.appearanceElements or {}
ns.appearanceElements.icon = icon

local SIZE_MIN = appearance.ICON_SIZE_MIN
local SIZE_MAX = appearance.ICON_SIZE_MAX
local SIZE_STEP = 1
local ZOOM_MIN = 0
local ZOOM_MAX = 20
local ZOOM_STEP = 1
local VALUE_BOX_WIDTH = 34

function icon.Build(content, onChanged)
    local column = controls.IndentedColumn(content)
    local sizeRow = controls.EditableSlider(column, column, L.EVENT_APPEARANCE_SIZE, SIZE_MIN, SIZE_MAX, SIZE_STEP,
        appearance.Reader("icon", "size"), function(value)
            appearance.Set("icon", "size", value)
            appearance.Apply()
            onChanged()
        end, controls.WIDE_SLIDER_EXTRA, nil, VALUE_BOX_WIDTH)

    local zoomRow = controls.EditableSlider(column, sizeRow, L.EVENT_APPEARANCE_ZOOM, ZOOM_MIN, ZOOM_MAX, ZOOM_STEP,
        appearance.Reader("icon", "zoom"), function(value)
            appearance.Set("icon", "zoom", value)
            appearance.Apply()
            onChanged()
        end, controls.WIDE_SLIDER_EXTRA, "%d%%", VALUE_BOX_WIDTH)
    controls.SetTooltip(zoomRow, L.EVENT_APPEARANCE_TIP_ZOOM, zoomRow.slider)
    content.rows = { sizeRow, zoomRow }

    controls.AlignWhenShown(content, function()
        if sizeRow:GetLeft() then
            controls.AlignBoxEndsAt(sizeRow:GetLeft() + controls.INLINE_LABEL_WIDTH + controls.INLINE_GAP
                + controls.INLINE_DROPDOWN_WIDTH + controls.WIDE_LIST_EXTRA, { sizeRow, zoomRow })
        end
    end)
end
