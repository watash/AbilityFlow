local addonName, ns = ...

local GameTooltip = GameTooltip

local L = ns.L

local dialog = {}
ns.editModeDialog = dialog

local VALUE_BOX_WIDTH = 48
local DROPDOWN_LABEL_WIDTH = 130
local SLIDER_LABEL_WIDTH = 130
local SLIDER_WIDTH = 157
local DROPDOWN_RIGHT_MARGIN = 5
local ACTION_GAP = 6
local SCREEN_FIT_SHARE = 0.95
local SELECTION_MARK = "AF"
local LIBRARY_BUTTONS_GAP = 12
local LIBRARY_SWATCH_GAP = 5
local BUTTONS_GAP = 2
local DIVIDER_LINE_HEIGHT = 16
local DIVIDER_ROW_HEIGHT = 34
local WIDTH_PADDING = 64
local SELECTION_MARK_FONT = "GameFontHighlight"

local ownSelection
local libraryPadding

function dialog.SetOwnSelection(selection)
    ownSelection = selection
end

local function isOwn(libDialog)
    return ownSelection ~= nil and libDialog.selection == ownSelection
end

local ALIGNED_NAMES = {
    [L.TRACK_LENGTH] = true,
    [L.TRACK_WIDTH] = true,
    [L.EVENT_SCALE] = true,
    [L.WAITING_GAP] = true,
    [L.WAITING_TRANSPARENCY] = true,
    [L.OVERALL_TRANSPARENCY] = true,
    [_G.HUD_EDIT_MODE_SETTING_ENCOUNTER_EVENTS_ORIENTATION or L.ORIENTATION] = true,
    [L.BACKGROUND_STYLE] = true,
    [L.BACKGROUND_TEXTURE] = true,
    [L.MARK_STYLE] = true,
    [L.MARK_STEP] = true,
    [L.MARK_SCALE] = true,
    [_G.HUD_EDIT_MODE_SETTING_ENCOUNTER_EVENTS_TOOLTIPS or L.TOOLTIPS] = true,
    [L.BORDER_TEXTURE] = true,
    [L.BORDER_OFFSET] = true,
    [L.BORDER_THICKNESS] = true,
}

local TYPED_NAMES = {
    [L.TRACK_LENGTH] = true,
    [L.TRACK_WIDTH] = true,
}

dialog.VALUE_BOX_WIDTH = VALUE_BOX_WIDTH
dialog.DROPDOWN_RIGHT_MARGIN = DROPDOWN_RIGHT_MARGIN

local function rowsOf(libDialog)
    return libDialog.Settings and { libDialog.Settings:GetChildren() } or {}
end

local libraryResetSize
local actionRow

local function findButton(parent, text)
    for _, child in ipairs({ parent:GetChildren() }) do
        if child.GetText and child:GetText() == text then
            return child
        end
    end
end

local function placeActions(libDialog, own)
    local settings, buttons = libDialog.Settings, libDialog.Buttons
    local reset = settings and settings.ResetButton
    if not reset or not buttons then
        return
    end
    if not libraryResetSize then
        libraryResetSize = { reset:GetWidth(), reset:GetHeight() }
    end
    if not own then
        if actionRow then
            actionRow:Hide()
        end
        reset:SetParent(settings)
        reset:ClearAllPoints()
        reset:SetSize(libraryResetSize[1], libraryResetSize[2])
        reset:Show()
        return
    end
    actionRow = actionRow or CreateFrame("Frame", nil, settings)
    actionRow.layoutIndex = reset.layoutIndex
    actionRow:SetParent(settings)
    actionRow:Show()
    local undo = findButton(buttons, L.UNDO_CHANGES) or findButton(actionRow, L.UNDO_CHANGES)
    if undo then
        undo:SetParent(actionRow)
        undo:ClearAllPoints()
        undo:SetPoint("LEFT", actionRow, "LEFT")
        undo:Show()
    end
    reset:SetParent(actionRow)
    reset:ClearAllPoints()
    reset:SetPoint("RIGHT", actionRow, "RIGHT")
    reset:Show()
    actionRow.undo = undo
end

local function sizeActions(libDialog, width)
    local sample = libDialog.Buttons and libDialog.Buttons.ResetPositionButton
    if not width or width <= 0 or not actionRow or not sample then
        return
    end
    local height = sample:GetHeight()
    actionRow:SetSize(width, height)
    local half = (width - ACTION_GAP) / 2
    for _, button in ipairs({ actionRow.undo, libDialog.Settings.ResetButton }) do
        if button then
            button:SetSize(half, height)
        end
    end
    for _, child in ipairs({ libDialog.Buttons:GetChildren() }) do
        if child.SetText then
            child:SetWidth(width)
        end
    end
end

local function layoutDivider(row, own)
    local line
    for _, region in ipairs({ row:GetRegions() }) do
        if region:IsObjectType("Texture") then
            line = region
            break
        end
    end
    if not line or not row.Label then
        return
    end
    line:ClearAllPoints()
    row.Label:ClearAllPoints()
    if own then
        row:EnableMouse(true)
        row:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(L.EDIT_MODE_PROFILE_SETTINGS, 1, 1, 1)
            GameTooltip:AddLine(L.EDIT_MODE_PROFILE_SETTINGS_TIP:format(ns.profiles.DisplayName(ns.profiles.CurrentName())), nil, nil,
                nil, true)
            GameTooltip:Show()
        end)
        row:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
        row:SetHeight(DIVIDER_ROW_HEIGHT)
        line:SetPoint("TOPLEFT", row, "TOPLEFT")
        line:SetPoint("TOPRIGHT", row, "TOPRIGHT")
        line:SetHeight(DIVIDER_LINE_HEIGHT)
        row.Label:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT")
        row.Label:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT")
        row.Label:SetHeight(DIVIDER_ROW_HEIGHT - DIVIDER_LINE_HEIGHT)
    else
        row:EnableMouse(false)
        row:SetScript("OnEnter", nil)
        row:SetScript("OnLeave", nil)
        row:SetHeight(DIVIDER_LINE_HEIGHT)
        line:SetAllPoints(row)
        row.Label:SetAllPoints(row)
    end
    row.dividerMoved = own
end

local function sizeRows(rows)
    for _, row in ipairs(rows) do
        local aligned = row.setting and ALIGNED_NAMES[row.setting.name]
        if row.setting and row.setting.profileDivider then
            layoutDivider(row, true)
        end
        if row.Slider and row.Label and row.setting then
            row.Label:SetWidth(SLIDER_LABEL_WIDTH)
            row.Label:SetWordWrap(true)
            row.Slider:SetWidth(SLIDER_WIDTH)
            if row.EditBox then
                local typed = TYPED_NAMES[row.setting.name] == true
                row.EditBox:EnableMouse(typed)
                row.EditBox:SetAlpha(typed and 1 or 0)
            end
            if aligned then
                row.Slider.RightText:SetWidth(VALUE_BOX_WIDTH)
                row.Slider.RightText:SetJustifyH(TYPED_NAMES[row.setting.name] and "CENTER" or "LEFT")
            end
        end
        if row.Dropdown and row.Label and aligned then
            row.Label:SetWidth(DROPDOWN_LABEL_WIDTH)
        end
    end
end

local function placeDropdowns(rows)
    local reference
    for _, row in ipairs(rows) do
        if row.Slider and row:IsShown() and row.setting and ALIGNED_NAMES[row.setting.name] then
            reference = row.Slider.RightText
            break
        end
    end
    local width, startX
    for _, row in ipairs(rows) do
        if row.Dropdown and row.setting and ALIGNED_NAMES[row.setting.name] then
            row.Dropdown:ClearAllPoints()
            if reference and reference:GetRight() and row:GetLeft() then
                local x = reference:GetRight() + DROPDOWN_RIGHT_MARGIN - row.Dropdown:GetWidth() - row:GetLeft()
                row.Dropdown:SetPoint("LEFT", row, "LEFT", x, 0)
                startX = x
            else
                row.Dropdown:SetPoint("RIGHT", row, "RIGHT", 0, 0)
            end
            if reference and reference:GetRight() and row:GetLeft() then
                width = reference:GetRight() + DROPDOWN_RIGHT_MARGIN - row:GetLeft()
            end
        end
    end
    return width, startX
end

local function placeSwatches(rows, startX)
    for _, row in ipairs(rows) do
        local swatch = row.Swatch
        if swatch and row.Label and startX then
            swatch:ClearAllPoints()
            swatch:SetPoint("LEFT", row, "LEFT", startX, 0)
            row.swatchMoved = true
            if row.setting and row.setting.hasOpacity and swatch.Color then
                local checker = swatch.checker or ns.appearanceControls.AddChecker(swatch)
                if checker then
                    checker:Show()
                end
                local color = row.setting.get(ns.timeline.ActiveLayoutName())
                swatch.Color:SetAlpha(color and color.a or 1)
            end
        end
    end
end

local function setReasons(rows)
    local layoutName = ns.timeline.ActiveLayoutName()
    for _, row in ipairs(rows) do
        local setting = row.setting
        if setting and setting.disabledReason and setting.disabled then
            setting.desc = setting.disabled(layoutName) and setting.disabledReason(layoutName) or nil
        end
    end
end

local function alignRows(libDialog)
    local rows = rowsOf(libDialog)
    setReasons(rows)
    sizeRows(rows)
    libDialog:Layout()
    local width, startX = placeDropdowns(rows)
    placeSwatches(rows, startX)
    sizeActions(libDialog, width)
    libDialog:Layout()
end

function dialog.Refresh(libDialog, canUndo, canReset)
    if not libDialog or not libDialog.Buttons or not isOwn(libDialog) then
        return
    end
    alignRows(libDialog)
    local undo = findButton(libDialog.Buttons, L.UNDO_CHANGES) or (actionRow and findButton(actionRow, L.UNDO_CHANGES))
    if undo then
        undo:SetEnabled(canUndo)
    end
    libDialog.Settings.ResetButton:SetEnabled(canReset)
end

function dialog.Adapt(libDialog)
    local own = isOwn(libDialog)
    placeActions(libDialog, own)
    if libDialog.Buttons and libDialog.Settings then
        libDialog.Buttons:ClearAllPoints()
        libDialog.Buttons:SetPoint("TOP", libDialog.Settings, "BOTTOM", 0, own and -BUTTONS_GAP or -LIBRARY_BUTTONS_GAP)
    end
    if not own then
        for _, row in ipairs(rowsOf(libDialog)) do
            if row.swatchMoved then
                row.Swatch:ClearAllPoints()
                row.Swatch:SetPoint("LEFT", row.Label, "RIGHT", LIBRARY_SWATCH_GAP, 0)
                if row.Swatch.checker then
                    row.Swatch.checker:Hide()
                end
                if row.Swatch.Color then
                    row.Swatch.Color:SetAlpha(1)
                end
                row.swatchMoved = nil
            end
            if row.dividerMoved then
                layoutDivider(row, false)
            end
        end
    end
    if libraryPadding then
        libDialog.widthPadding = own and WIDTH_PADDING or libraryPadding
        libDialog:Layout()
    end
end

function dialog.WidenMargins(libDialog)
    libraryPadding = libDialog.widthPadding
    dialog.Adapt(libDialog)
end

function dialog.FitToScreen(libDialog)
    local function fit()
        local height = libDialog:GetHeight()
        if height and height > 0 then
            libDialog:SetScale(isOwn(libDialog) and math.min(UIParent:GetHeight() * SCREEN_FIT_SHARE / height, 1) or 1)
        end
    end
    libDialog:HookScript("OnSizeChanged", fit)
    libDialog:HookScript("OnShow", fit)
end

function dialog.InstallSelectionTooltip(selection, text)
    if not selection then
        return
    end
    if selection.Label and selection.UpdateLabelVisibility then
        selection.Label:SetFontObject(SELECTION_MARK_FONT)
        selection.Label:SetText(SELECTION_MARK)
        hooksecurefunc(selection, "UpdateLabelVisibility", function(self)
            self.Label:SetText(SELECTION_MARK)
        end)
    end
    selection:HookScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
        GameTooltip:SetText(text)
        GameTooltip:Show()
    end)
    selection:HookScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end
