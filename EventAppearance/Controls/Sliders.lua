local addonName, ns = ...

local CreateFrame = CreateFrame
local math = math
local tonumber = tonumber

local controls = ns.appearanceControls
local LABEL_GAP = controls.LABEL_GAP
local FIRST_ROW_OFFSET = controls.FIRST_ROW_OFFSET
local INLINE_LABEL_WIDTH = controls.INLINE_LABEL_WIDTH
local INLINE_GAP = controls.INLINE_GAP
local EDITABLE_SLIDER_WIDTH = controls.EDITABLE_SLIDER_WIDTH
local resolve = controls.Resolve

local SLIDER_WIDTH = 220
local EDITABLE_ROW_HEIGHT = 32
local EDIT_BOX_OVERHANG = 5

local function makeSlider(parent, labelText, valueFormat, minValue, maxValue, valueStep, value, onChanged, whiteValue)
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")

    local function updateLabel(current)
        label:SetText(("%s: %s"):format(labelText, whiteValue and ns.text.White(valueFormat:format(current)) or valueFormat:format(current)))
    end
    updateLabel(value)

    local slider = CreateFrame("Frame", nil, parent, "MinimalSliderWithSteppersTemplate")
    slider:SetWidth(SLIDER_WIDTH)
    slider:Init(value, minValue, maxValue, (maxValue - minValue) / valueStep)
    slider:RegisterCallback(MinimalSliderWithSteppersMixin.Event.OnValueChanged, function(_, newValue)
        local rounded = math.floor(newValue + 0.5)
        updateLabel(rounded)
        onChanged(rounded)
    end, slider)

    slider.rowLabel = label
    return label, slider
end

function controls.EditableSlider(parent, anchorTo, labelText, minValue, maxValue, valueStep, value, onChanged,
                                 extraWidth, valueFormat, valueWidth, decimals, labelWidth)
    local getter
    getter, value = resolve(value)
    labelWidth = labelWidth or INLINE_LABEL_WIDTH
    local sliderWidth = EDITABLE_SLIDER_WIDTH + (extraWidth or 0)
    local unit = 10 ^ (decimals or 0)
    local function toValue(inner)
        if not decimals then
            return math.floor(inner + 0.5)
        end
        local steps = math.floor(inner / (valueStep * unit) + 0.5)
        return tonumber(("%." .. decimals .. "f"):format(steps * valueStep))
    end
    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(labelWidth + INLINE_GAP + sliderWidth, EDITABLE_ROW_HEIGHT)
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

    local slider = CreateFrame("Frame", nil, row, "MinimalSliderWithSteppersTemplate")
    slider:SetWidth(sliderWidth)
    slider:SetPoint("LEFT", label, "RIGHT", INLINE_GAP, 0)
    slider.MinText:Hide()
    slider.MaxText:Hide()
    slider.RightText:SetTextColor(WHITE_FONT_COLOR:GetRGB())
    slider.RightText:SetWidth(valueWidth or controls.VALUE_WIDTH)
    slider.RightText:SetJustifyH("CENTER")
    local formatValue = valueFormat and function(shown)
        if type(valueFormat) == "function" then
            return valueFormat(toValue(shown))
        end
        return valueFormat:format(toValue(shown))
    end
    local formatters = {
        [MinimalSliderWithSteppersMixin.Label.Right] = CreateMinimalSliderFormatter(
            MinimalSliderWithSteppersMixin.Label.Right, formatValue),
    }
    slider:Init(value * unit, minValue * unit, maxValue * unit, (maxValue - minValue) / valueStep, formatters)
    local resyncing = false
    slider:RegisterCallback(MinimalSliderWithSteppersMixin.Event.OnValueChanged, function(_, newValue)
        if not resyncing then
            onChanged(toValue(newValue))
        end
    end, slider)
    row.slider = slider
    if getter then
        row.Resync = function()
            resyncing = true
            slider:SetValue(getter() * unit)
            resyncing = false
        end
    end

    local editBox = CreateFrame("EditBox", nil, row, "InputBoxTemplate")
    editBox:SetAutoFocus(false)
    editBox:SetJustifyH("CENTER")
    editBox:SetFontObject("GameFontHighlight")
    row.editBox = editBox
    local function placeOverValue()
        editBox:ClearAllPoints()
        editBox:SetPoint("TOPLEFT", slider.RightText)
        editBox:SetPoint("BOTTOMLEFT", slider.RightText)
        editBox:SetPoint("RIGHT", slider.RightText, EDIT_BOX_OVERHANG, 0)
    end
    placeOverValue()
    local function endEditing()
        slider:Show()
        editBox:SetText("")
        editBox:ClearFocus()
        placeOverValue()
    end
    editBox:SetScript("OnEditFocusGained", function(self)
        slider:Hide()
        self:ClearAllPoints()
        self:SetPoint("RIGHT", slider.RightText, EDIT_BOX_OVERHANG, 0)
        self:SetPoint("TOPLEFT", slider)
        self:SetPoint("BOTTOMLEFT", slider)
        self:SetText(toValue(slider.Slider:GetValue()))
        self:SetCursorPosition(0)
    end)
    editBox:SetScript("OnEnterPressed", function(self)
        local typed = tonumber(self:GetText())
        if typed then
            slider:SetValue(math.min(math.max(typed, minValue), maxValue) * unit)
        end
        self:ClearFocus()
    end)
    editBox:SetScript("OnEscapePressed", endEditing)
    editBox:SetScript("OnEditFocusLost", endEditing)

    return row
end

function controls.InlineSlider(parent, labelText, valueFormat, minValue, maxValue, valueStep, value, onChanged)
    return makeSlider(parent, labelText, valueFormat, minValue, maxValue, valueStep, value, onChanged, true)
end
