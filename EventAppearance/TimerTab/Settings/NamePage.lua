local addonName, ns = ...

local L = ns.L
local controls = ns.appearanceControls
local timerStyle = ns.timerStyle
local appearance = ns.appearance
local settings = ns.timerTab.settings
local SWATCH_BESIDE_GAP = settings.SWATCH_BESIDE_GAP
local WIDE_SLIDER_EXTRA = settings.WIDE_SLIDER_EXTRA
local WIDE_LIST_EXTRA = settings.WIDE_LIST_EXTRA
local DISABLED_ALPHA = settings.DISABLED_ALPHA
local FULL_ALPHA = settings.FULL_ALPHA

local BACKGROUND_DEFAULT = timerStyle.BACKGROUND_DEFAULT
local BACKGROUND_SHOW = timerStyle.BACKGROUND_SHOW
local BACKGROUND_HIDE = timerStyle.BACKGROUND_HIDE

function settings.builders.NAME(page, templateOf, changedCallback)
    local controlsOf = {}
    local nameScale = controls.EditableSlider(page, page, L.TIMER_STYLE_NAME_SCALE, timerStyle.NAME_SCALE_MIN,
        timerStyle.NAME_SCALE_MAX, 1, function()
            return timerStyle.NameScaleOf(templateOf())
        end, function(value)
            templateOf().nameScale = value
            changedCallback()
        end, WIDE_SLIDER_EXTRA, "%d%%", controls.VALUE_WIDTH)

    nameScale:ClearAllPoints()
    nameScale:SetPoint("TOPLEFT", page, "TOPLEFT", controls.LABEL_GAP + controls.CHECKBOX_PICTURE_PADDING, -controls.FIRST_ROW_OFFSET)

    local backgroundRow = controls.InlineDropdown(page, nameScale, L.EVENT_APPEARANCE_ELEMENT_NAMEBACKGROUND, {
        { text = L.TIMER_STYLE_BACKGROUND_DEFAULT, value = BACKGROUND_DEFAULT },
        { text = L.TIMER_STYLE_BACKGROUND_SHOW, value = BACKGROUND_SHOW },
        { text = L.TIMER_STYLE_BACKGROUND_HIDE, value = BACKGROUND_HIDE },
    }, function()
        return templateOf().nameBackground or BACKGROUND_DEFAULT
    end, function(value)
        templateOf().nameBackground = value ~= BACKGROUND_DEFAULT and value or nil
        changedCallback()
        controlsOf.refreshStates()
    end, WIDE_LIST_EXTRA)

    local function backgroundColor()
        return templateOf().nameBackgroundColor or appearance.Get("nameBackground", "color")
    end
    local custom = controls.Checkbox(page, backgroundRow, L.TIMER_STYLE_NAME_BACKGROUND_COLOR, function()
        return templateOf().nameBackgroundUseColor == true
    end, function(checked)
        templateOf().nameBackgroundUseColor = checked
        changedCallback()
        controlsOf.refreshStates()
    end, -controls.CHECKBOX_PICTURE_PADDING)
    local swatch = controls.Swatch(page)
    swatch:SetPoint("LEFT", custom.label, "RIGHT", SWATCH_BESIDE_GAP, 0)
    swatch:SetScript("OnClick", function()
        local template = templateOf()
        controls.PickColor(backgroundColor(), true, function(red, green, blue, alpha)
            template.nameBackgroundColor = { r = red, g = green, b = blue, a = alpha }
            template.nameBackgroundUseColor = true
            swatch:SetColor(red, green, blue, alpha)
            changedCallback()
            controlsOf.refreshStates()
        end, swatch)
    end)

    controls.AlignWhenShown(page, function()
        controls.StretchListToBox(backgroundRow, nameScale)
    end)

    function controlsOf.refreshStates()
        local template = templateOf()
        local shown = template.nameBackground ~= BACKGROUND_HIDE
        custom:SetChecked(template.nameBackgroundUseColor == true)
        controls.SetCheckboxEnabled(custom, shown)
        swatch:SetEnabled(shown)
        swatch:SetAlpha((shown and template.nameBackgroundUseColor) and FULL_ALPHA or DISABLED_ALPHA)
    end

    function controlsOf.refresh()
        local color = backgroundColor()
        swatch:SetColor(color.r, color.g, color.b, color.a)
        controlsOf.refreshStates()
    end
    return controlsOf
end
