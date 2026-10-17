local addonName, ns = ...

local L = ns.L
local controls = ns.appearanceControls
local timerStyle = ns.timerStyle
local settings = ns.timerTab.settings
local WIDE_SLIDER_EXTRA = settings.WIDE_SLIDER_EXTRA

local SECOND_COLUMN_LEFT = settings.SECOND_COLUMN_LEFT
local FLASH_PREVIEW_INTERVAL = 1.5

local previewTicker

local function stopFlashPreview()
    if previewTicker then
        previewTicker:Cancel()
        previewTicker = nil
        ns.timerTab.templates.EndFlashPreview()
        ns.timerTab.pins.EndFlashPreview()
    end
end

local function startFlashPreview()
    stopFlashPreview()
    local function play()
        local templateID = settings.ShownID()
        if templateID then
            ns.timerTab.templates.FlashOne(templateID)
            ns.timerTab.pins.FlashTemplate(templateID)
        end
    end
    play()
    previewTicker = C_Timer.NewTicker(FLASH_PREVIEW_INTERVAL, play)
end

function settings.builders.EFFECTS(page, templateOf, changedCallback)
    local controlsOf = {}
    local pulse = controls.Checkbox(page, page, L.TIMER_STYLE_PULSE, function()
        return templateOf().pulse == true
    end, function(checked)
        templateOf().pulse = checked
        changedCallback()
        controlsOf.refreshStates()
    end)
    controlsOf.pulseText = controls.Checkbox(page, pulse, L.TIMER_STYLE_PULSE_TEXT, function()
        return templateOf().pulseScaleText == true
    end, function(checked)
        templateOf().pulseScaleText = checked
        changedCallback()
    end)
    controlsOf.pulseIndicators = controls.Checkbox(page, controlsOf.pulseText, L.TIMER_STYLE_PULSE_INDICATORS, function()
        return templateOf().pulseIndicators == true
    end, function(checked)
        templateOf().pulseIndicators = checked
        changedCallback()
    end)
    controlsOf.pulseRoles = controls.Checkbox(page, controlsOf.pulseIndicators, L.TIMER_STYLE_PULSE_ROLES, function()
        return templateOf().pulseRoles == true
    end, function(checked)
        templateOf().pulseRoles = checked
        changedCallback()
    end)
    controlsOf.pulseStrength = controls.EditableSlider(page, controlsOf.pulseRoles, L.TIMER_STYLE_PULSE_STRENGTH,
        timerStyle.PULSE_STRENGTH_MIN, timerStyle.PULSE_STRENGTH_MAX, 1, function()
            return templateOf().pulseStrength or timerStyle.PULSE_STRENGTH_DEFAULT
        end, function(value)
            templateOf().pulseStrength = value
            changedCallback()
        end, WIDE_SLIDER_EXTRA, "%d%%", controls.VALUE_WIDTH)
    controlsOf.pulseStrength:ClearAllPoints()
    controlsOf.pulseStrength:SetPoint("TOPLEFT", controlsOf.pulseRoles, "BOTTOMLEFT",
        controls.CHECKBOX_PICTURE_PADDING, -controls.LABEL_GAP)
    controlsOf.flash = controls.Checkbox(page, page, L.TIMER_STYLE_FLASH, function()
        return templateOf().flash == true
    end, function(checked)
        templateOf().flash = checked
        changedCallback()
    end)
    controlsOf.flash:ClearAllPoints()
    controlsOf.flash:SetPoint("LEFT", pulse, "LEFT", SECOND_COLUMN_LEFT, 0)
    controls.SetTooltip(controlsOf.flash, L.TIMER_STYLE_FLASH_TOOLTIP)
    controlsOf.flash:HookScript("OnEnter", startFlashPreview)
    controlsOf.flash:HookScript("OnLeave", stopFlashPreview)
    controlsOf.flash:HookScript("OnHide", stopFlashPreview)

    function controlsOf.refreshStates()
        local pulseOn = templateOf().pulse == true
        controls.SetCheckboxEnabled(controlsOf.pulseText, pulseOn)
        controls.SetCheckboxEnabled(controlsOf.pulseIndicators, pulseOn)
        controls.SetCheckboxEnabled(controlsOf.pulseRoles, pulseOn)
        controls.SetRowEnabled(controlsOf.pulseStrength, pulseOn)
    end

    controlsOf.refresh = controlsOf.refreshStates
    return controlsOf
end
