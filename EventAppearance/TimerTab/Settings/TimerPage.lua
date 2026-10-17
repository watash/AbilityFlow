local addonName, ns = ...

local L = ns.L
local controls = ns.appearanceControls
local timerStyle = ns.timerStyle
local settings = ns.timerTab.settings
local ROW_GAP = settings.ROW_GAP
local SWATCH_BESIDE_GAP = settings.SWATCH_BESIDE_GAP
local WIDE_SLIDER_EXTRA = settings.WIDE_SLIDER_EXTRA
local DISABLED_ALPHA = settings.DISABLED_ALPHA
local FULL_ALPHA = settings.FULL_ALPHA
local WIDE_LIST_EXTRA = settings.WIDE_LIST_EXTRA
local ownColor = settings.ownColor
local TIMER_DEFAULT = timerStyle.TIMER_DEFAULT
local TIMER_SHOW = timerStyle.TIMER_SHOW
local TIMER_HIDE = timerStyle.TIMER_HIDE

function settings.builders.TIMER(page, templateOf, changedCallback)
    local controlsOf = {}
    local showTimer = controls.InlineDropdown(page, page, L.TIMER_STYLE_SHOW_TIMER, {
        { text = L.TIMER_STYLE_BACKGROUND_DEFAULT, value = TIMER_DEFAULT },
        { text = L.TIMER_STYLE_BACKGROUND_SHOW, value = TIMER_SHOW },
        { text = L.TIMER_STYLE_BACKGROUND_HIDE, value = TIMER_HIDE },
    }, function()
        return timerStyle.TimerModeOf(templateOf())
    end, function(value)
        local template = templateOf()
        template.timerMode = value ~= TIMER_DEFAULT and value or nil
        template.showTimer = nil
        changedCallback()
        controlsOf.refreshStates()
    end, WIDE_LIST_EXTRA)

    showTimer:ClearAllPoints()
    showTimer:SetPoint("TOPLEFT", page, "TOPLEFT", controls.LABEL_GAP + controls.CHECKBOX_PICTURE_PADDING, -controls.FIRST_ROW_OFFSET)

    local override = controls.Checkbox(page, showTimer, L.TIMER_STYLE_COLOR_OVERRIDE, function()
        return timerStyle.CountdownColor(templateOf()) ~= nil
    end, function(checked)
        local template = templateOf()
        template.colorOverride = checked
        if checked and not template.color then
            local current = ownColor(template)
            template.color = { r = current.r, g = current.g, b = current.b, a = 1 }
        end
        changedCallback()
        controlsOf.refresh()
    end, -controls.CHECKBOX_PICTURE_PADDING)
    local swatch = controls.Swatch(page)
    swatch:SetPoint("LEFT", override.label, "RIGHT", SWATCH_BESIDE_GAP, 0)
    swatch:SetScript("OnClick", function()
        local template = templateOf()
        controls.PickColor(ownColor(template), false, function(red, green, blue)
            template.color = { r = red, g = green, b = blue, a = 1 }
            template.colorOverride = true
            swatch:SetColor(red, green, blue)
            changedCallback()
            controlsOf.refreshStates()
        end, swatch)
    end)

    local scale = controls.EditableSlider(page, showTimer, L.TIMER_STYLE_TEXT_SCALE, timerStyle.TEXT_SCALE_MIN,
        timerStyle.TEXT_SCALE_MAX, 1, function()
            return templateOf().textScale
        end, function(value)
            templateOf().textScale = value
            changedCallback()
        end, WIDE_SLIDER_EXTRA, "%d%%", controls.VALUE_WIDTH)

    scale:ClearAllPoints()
    scale:SetPoint("TOPLEFT", override, "BOTTOMLEFT", controls.CHECKBOX_PICTURE_PADDING, -ROW_GAP)

    local tenths = controls.Checkbox(page, scale, L.TIMER_STYLE_TENTHS, function()
        return templateOf().tenths == true
    end, function(checked)
        templateOf().tenths = checked
        changedCallback()
    end, -controls.CHECKBOX_PICTURE_PADDING)

    controls.AlignWhenShown(page, function()
        controls.StretchListToBox(showTimer, scale)
    end)

    function controlsOf.refreshStates()
        local timerOn = timerStyle.TimerModeOf(templateOf()) ~= TIMER_HIDE
        local overridden = timerStyle.CountdownColor(templateOf()) ~= nil
        controls.SetCheckboxEnabled(override, timerOn)
        swatch:SetEnabled(timerOn)
        swatch:SetAlpha((timerOn and overridden) and FULL_ALPHA or DISABLED_ALPHA)
        override:SetChecked(overridden)
        controls.SetRowEnabled(scale, timerOn)
        controls.SetCheckboxEnabled(tenths, timerOn)
    end

    function controlsOf.refresh()
        local color = ownColor(templateOf())
        swatch:SetColor(color.r, color.g, color.b)
        controlsOf.refreshStates()
    end
    return controlsOf
end
