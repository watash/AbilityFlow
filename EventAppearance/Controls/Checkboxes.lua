local addonName, ns = ...

local CreateFrame = CreateFrame

local controls = ns.appearanceControls
local LABEL_GAP = controls.LABEL_GAP
local FIRST_ROW_OFFSET = controls.FIRST_ROW_OFFSET
local CHECKBOX_LABEL_GAP = controls.CHECKBOX_LABEL_GAP
local resolve = controls.Resolve

local CHECKBOX_FIRST_ROW_RAISE = 9

function controls.Checkbox(parent, anchorTo, labelText, checked, onChanged, offsetX, offsetY)
    local getter
    getter, checked = resolve(checked)
    local checkbox = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    offsetX = offsetX or 0
    offsetY = offsetY or 0
    if anchorTo == parent then
        checkbox:SetPoint("TOPLEFT", parent, "TOPLEFT", LABEL_GAP + offsetX,
            -FIRST_ROW_OFFSET + CHECKBOX_FIRST_ROW_RAISE + offsetY)
    else
        checkbox:SetPoint("TOPLEFT", anchorTo, "BOTTOMLEFT", offsetX, -LABEL_GAP + offsetY)
    end
    checkbox:SetChecked(checked)
    checkbox:SetScript("OnClick", function(self)
        onChanged(not not self:GetChecked())
    end)

    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("LEFT", checkbox, "RIGHT", CHECKBOX_LABEL_GAP, 0)
    label:SetText(labelText)
    checkbox.label = label
    if getter then
        checkbox.Resync = function()
            checkbox:SetChecked(getter())
        end
    end

    return checkbox
end
