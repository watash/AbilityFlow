local addonName, ns = ...

local L = ns.L
local appearance = ns.appearance
local controls = ns.appearanceControls

local border = {}
ns.appearanceElements = ns.appearanceElements or {}
ns.appearanceElements.border = border

local THICKNESS_MIN = 1
local THICKNESS_MAX = 16
local THICKNESS_STEP = 1
local VALUE_BOX_WIDTH = 34

function border.Build(content, onChanged)
    local thicknessRow, colorRow, eventColorCheckbox

    local function refreshControls()
        local style = appearance.Get("border", "style")
        controls.SetRowEnabled(thicknessRow, style == "SOLID")
        controls.SetRowEnabled(colorRow, style == "SOLID")
        eventColorCheckbox:SetEnabled(style == "SOLID" or style == "BLIZZARD")
        eventColorCheckbox:SetChecked(appearance.Get("border", "useEventColor"))
    end

    local column = controls.IndentedColumn(content)
    local styleRow = controls.InlineDropdown(column, column, L.EVENT_APPEARANCE_BORDER_STYLE, {
        { text = L.NONE, value = "NONE" },
        { text = L.EVENT_APPEARANCE_BORDER_BLIZZARD, value = "BLIZZARD" },
        { text = L.EVENT_APPEARANCE_BORDER_SOLID, value = "SOLID" },
    }, appearance.Reader("border", "style"), function(value)
        appearance.Set("border", "style", value)
        appearance.Apply()
        refreshControls()
        onChanged()
    end, controls.WIDE_LIST_EXTRA)

    thicknessRow = controls.EditableSlider(column, styleRow, L.EVENT_APPEARANCE_BORDER_THICKNESS, THICKNESS_MIN,
        THICKNESS_MAX, THICKNESS_STEP, appearance.Reader("border", "thickness"), function(value)
            appearance.Set("border", "thickness", value)
            appearance.Apply()
            onChanged()
        end, controls.WIDE_SLIDER_EXTRA, nil, VALUE_BOX_WIDTH)

    colorRow = controls.InlineColor(column, thicknessRow, L.EVENT_APPEARANCE_TEXT_COLOR,
        appearance.Reader("border", "color"), function(red, green, blue)
            appearance.Set("border", "color", { r = red, g = green, b = blue, a = 1 })
            appearance.Apply()
            onChanged()
        end, false)

    eventColorCheckbox = controls.Checkbox(column, colorRow, L.EVENT_APPEARANCE_TEXT_EVENT_COLOR,
        appearance.Reader("border", "useEventColor"), function(checked)
            appearance.Set("border", "useEventColor", checked)
            appearance.Apply()
            refreshControls()
            onChanged()
        end, -controls.CHECKBOX_PICTURE_PADDING)
    controls.SetTooltip(eventColorCheckbox, L.EVENT_APPEARANCE_TIP_EVENT_COLOR)

    controls.AlignWhenShown(content, function()
        controls.AlignBoxEnds(styleRow, { thicknessRow })
    end)

    content.rows = { styleRow, thicknessRow, colorRow }

    refreshControls()
    return refreshControls
end
