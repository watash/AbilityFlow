local addonName, ns = ...

local L = ns.L
local controls = ns.appearanceControls
local appearance = ns.appearance

local elements = ns.appearanceElements
local iconBuild = elements.icon.Build
local borderBuild = elements.border.Build

local LEFT_WIDTH = 440
local RIGHT_LEFT = 460
local RIGHT_WIDTH = 460
local ROWS_TOP = 46
local HEADING_TOP = 19

local function makeHeading(content, left, text)
    local heading = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    heading:SetPoint("TOPLEFT", content, "TOPLEFT", left + controls.PANEL_INDENT + controls.ROW_INDENT, -HEADING_TOP)
    heading:SetText(text)
end

elements.icon = {
    Build = function(content, onChanged)
        local iconColumn = controls.Column(content, 0, LEFT_WIDTH, ROWS_TOP)
        local borderColumn = controls.Column(content, RIGHT_LEFT, RIGHT_WIDTH, ROWS_TOP)
        makeHeading(content, 0, L.EVENT_APPEARANCE_ELEMENT_ICON)
        makeHeading(content, RIGHT_LEFT, L.EVENT_APPEARANCE_ELEMENT_BORDER)
        iconBuild(iconColumn, onChanged)
        local rows = iconColumn.rows
        local colorRow
        local glowCheckbox = controls.Checkbox(iconColumn, rows[#rows], L.EVENT_APPEARANCE_DEADLY_GLOW, function()
            return appearance.Get("dangerGlow", "enabled")
        end, function(checked)
            appearance.Set("dangerGlow", "enabled", checked)
            appearance.Apply()
            controls.SetRowEnabled(colorRow, checked)
            ns.appearancePreview.SetGlowHint(true)
        end, -controls.CHECKBOX_PICTURE_PADDING)
        colorRow = controls.InlineColor(iconColumn, glowCheckbox, L.EVENT_APPEARANCE_DEADLY_GLOW_COLOR,
            appearance.Reader("dangerGlow", "color"), function(red, green, blue)
                appearance.Set("dangerGlow", "color", { r = red, g = green, b = blue, a = 1 })
                appearance.Apply()
                ns.appearancePreview.SetGlowHint(true)
            end, false)
        colorRow:ClearAllPoints()
        colorRow:SetPoint("TOPLEFT", glowCheckbox, "BOTTOMLEFT", controls.CHECKBOX_PICTURE_PADDING, -controls.LABEL_GAP)
        local function showGlowHint()
            ns.appearancePreview.SetGlowHint(true)
        end
        local function hideGlowHint()
            if not ColorPickerFrame:IsShown() then
                ns.appearancePreview.SetGlowHint(false)
            end
        end
        glowCheckbox:SetHitRectInsets(0, -(glowCheckbox.label:GetStringWidth() + controls.CHECKBOX_LABEL_GAP), 0, 0)
        colorRow:EnableMouse(true)
        for _, pointed in ipairs({ glowCheckbox, colorRow, colorRow.swatch }) do
            pointed:HookScript("OnEnter", showGlowHint)
            pointed:HookScript("OnLeave", hideGlowHint)
            pointed:HookScript("OnHide", function()
                ns.appearancePreview.SetGlowHint(false)
            end)
        end
        ColorPickerFrame:HookScript("OnHide", function()
            ns.appearancePreview.SetGlowHint(false)
        end)
        controls.SetRowEnabled(colorRow, appearance.Get("dangerGlow", "enabled"))
        local refreshBorder = borderBuild(borderColumn, onChanged)
        for index, iconRow in ipairs(iconColumn.rows) do
            local borderRow = borderColumn.rows[index]
            if borderRow then
                borderRow:ClearAllPoints()
                borderRow:SetPoint("LEFT", iconRow, "LEFT", RIGHT_LEFT, 0)
            end
        end
        return function()
            refreshBorder()
            controls.SetRowEnabled(colorRow, appearance.Get("dangerGlow", "enabled"))
        end
    end,
}
