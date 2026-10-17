local addonName, ns = ...

local CreateFrame = CreateFrame
local GameTooltip = GameTooltip
local C_Timer = C_Timer
local ipairs = ipairs
local math = math

local controls = ns.appearanceControls
local DISABLED_ALPHA = controls.DISABLED_ALPHA
local CHECKBOX_LABEL_GAP = controls.CHECKBOX_LABEL_GAP

controls.PANEL_INDENT = controls.CHECKBOX_PICTURE_PADDING

function controls.Column(content, left, width, top)
    local column = CreateFrame("Frame", nil, content)
    column:SetPoint("TOPLEFT", content, "TOPLEFT", left, -(top or 0))
    column:SetPoint("BOTTOMLEFT", content, "BOTTOMLEFT", left, 0)
    column:SetWidth(width)
    return column
end

function controls.IndentedColumn(panel)
    local column = CreateFrame("Frame", nil, panel)
    column:SetPoint("TOPLEFT", panel, "TOPLEFT", controls.PANEL_INDENT, 0)
    column:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", 0, 0)
    return column
end

function controls.FirstRowCenter(frame, panelTop, nearest)
    for _, region in ipairs({ frame:GetRegions() }) do
        if region:GetObjectType() == "FontString" and region:IsShown() and (region:GetText() or "") ~= "" then
            local top, bottom = region:GetTop(), region:GetBottom()
            if top and bottom then
                local distance = panelTop - (top + bottom) / 2
                if distance > 0 and (not nearest or distance < nearest) then
                    nearest = distance
                end
            end
        end
    end
    for _, sub in ipairs({ frame:GetChildren() }) do
        if sub:IsShown() then
            nearest = controls.FirstRowCenter(sub, panelTop, nearest)
        end
    end
    return nearest
end

function controls.SizeResetButton(button)
    button:SetSize(button:GetTextWidth() + 2 * controls.RESET_BUTTON_PADDING, controls.RESET_BUTTON_HEIGHT)
end

function controls.VisibleRight(frame)
    local farthest
    for _, region in ipairs({ frame:GetRegions() }) do
        local right = region:GetObjectType() == "Texture" and region:IsShown() and region:GetRight()
        if right and (not farthest or right > farthest) then
            farthest = right
        end
    end
    return farthest
end

local BOX_END_TOLERANCE = 0.5

function controls.AlignWhenShown(panel, align)
    panel:HookScript("OnShow", function()
        align()
        C_Timer.After(0, align)
    end)
end

function controls.AlignBoxEnds(listRow, sliderRows)
    controls.AlignBoxEndsAt(listRow:GetRight(), sliderRows)
end

function controls.StretchListToBox(listRow, sliderRow)
    local target = controls.VisibleRight(sliderRow.editBox)
    local current = listRow:GetRight()
    if not target or not current or math.abs(target - current) <= BOX_END_TOLERANCE then
        return
    end
    local dropdown = listRow.dropdown
    dropdown:SetWidth(dropdown:GetWidth() + target - current)
    listRow:SetWidth(listRow:GetWidth() + target - current)
end

function controls.AlignBoxEndsAt(target, sliderRows)
    if not target then
        return
    end
    for _, row in ipairs(sliderRows) do
        local current = controls.VisibleRight(row.editBox)
        if current and math.abs(target - current) > BOX_END_TOLERANCE then
            row.slider:SetWidth(row.slider:GetWidth() + target - current)
        end
    end
end

function controls.SetTooltip(owner, text, ...)
    local function show()
        GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
        GameTooltip:SetText(text, 1, 1, 1, 1, true)
        GameTooltip:Show()
    end
    local function hide()
        GameTooltip:Hide()
    end
    for _, frame in ipairs({ owner, ... }) do
        if not frame:IsMouseEnabled() then
            frame:EnableMouse(true)
        end
        frame:HookScript("OnEnter", show)
        frame:HookScript("OnLeave", hide)
    end
    if owner.label and owner.GetObjectType and owner:GetObjectType() == "CheckButton" then
        owner:SetHitRectInsets(0, -(owner.label:GetStringWidth() + CHECKBOX_LABEL_GAP), 0, 0)
    end
end

function controls.SetRowEnabled(row, enabled)
    local function apply(frame)
        if enabled then
            if frame.mouseBeforeDisable ~= nil then
                frame:EnableMouse(frame.mouseBeforeDisable)
                frame.mouseBeforeDisable = nil
            end
        else
            if frame.mouseBeforeDisable == nil then
                frame.mouseBeforeDisable = frame:IsMouseEnabled()
            end
            frame:EnableMouse(false)
        end
        for _, child in ipairs({ frame:GetChildren() }) do
            apply(child)
        end
    end
    apply(row)
    row:SetAlpha(enabled and 1 or DISABLED_ALPHA)
end

function controls.SetTextEnabled(text, enabled)
    text:SetAlpha(enabled and 1 or DISABLED_ALPHA)
end

function controls.SetCheckboxEnabled(checkbox, enabled)
    checkbox:SetEnabled(enabled)
    checkbox.label:SetAlpha(enabled and 1 or DISABLED_ALPHA)
end
