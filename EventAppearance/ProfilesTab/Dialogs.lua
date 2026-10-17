local addonName, ns = ...

local CreateFrame = CreateFrame
local PlaySound = PlaySound
local SOUNDKIT = SOUNDKIT
local UIParent = UIParent
local tinsert = tinsert
local CANCEL = CANCEL
local OKAY = OKAY
local L = ns.L

local dialogs = {}
ns.appearanceDialogs = dialogs

local DIALOG_WIDTH = 480
local DIALOG_PADDING = 24
local DIALOG_OFFSET_Y = 120
local ELEMENT_GAP = 14
local EDIT_HEIGHT = 30
local CHECK_HEIGHT = 26
local CHECK_LABEL_GAP = 4
local BUTTON_WIDTH = 140
local BUTTON_HEIGHT = 24
local BUTTON_GAP = 10
local PASTE_MAX_BYTES = 65536
local FRAME_NAME = "AbilityFlowDialog"
local GROUND_COLOR = 0.08
local GROUND_INSET = 11
local BACKDROP = {
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true,
    tileSize = 32,
    edgeSize = 32,
    insets = { left = 11, right = 11, top = 12, bottom = 11 },
}

local dialog

local function show(options)
    dialog:Hide()
    dialog.text:SetText(options.text)
    local hasEdit = options.edit ~= nil
    dialog.edit:SetShown(hasEdit)
    dialog.copyText = nil
    dialog.check:SetShown(options.check ~= nil)
    dialog.checkLabel:SetShown(options.check ~= nil)
    dialog.checkChanged = options.check and options.check.onChanged
    if options.check then
        dialog.check:SetChecked(options.check.checked)
        dialog.checkLabel:SetText(options.check.text)
    end
    if hasEdit then
        dialog.edit:SetMaxBytes(options.edit == "type" and ns.profiles.MAX_NAME_LENGTH * 4 or PASTE_MAX_BYTES)
        dialog.edit:SetMaxLetters(options.edit == "type" and ns.profiles.MAX_NAME_LENGTH or 0)
        dialog.edit:SetText(options.value or "")
        if options.edit == "copy" then
            dialog.copyText = options.value
        end
    end
    dialog.onAccept = options.onAccept
    dialog.accept:SetText(options.accept or OKAY)
    dialog.cancel:SetText(CANCEL)
    dialog.cancel:SetShown(options.cancel ~= false)
    dialog.other:SetShown(options.other ~= nil)
    dialog.otherAction = options.onOther
    dialog.accept:ClearAllPoints()
    dialog.cancel:ClearAllPoints()
    dialog.other:ClearAllPoints()
    if options.other then
        dialog.other:SetText(options.other)
        dialog.other:SetPoint("BOTTOM", dialog, "BOTTOM", 0, DIALOG_PADDING)
        dialog.accept:SetPoint("RIGHT", dialog.other, "LEFT", -BUTTON_GAP, 0)
        dialog.cancel:SetPoint("LEFT", dialog.other, "RIGHT", BUTTON_GAP, 0)
    elseif options.cancel == false then
        dialog.accept:SetPoint("BOTTOM", dialog, "BOTTOM", 0, DIALOG_PADDING)
    else
        dialog.accept:SetPoint("BOTTOMRIGHT", dialog, "BOTTOM", -BUTTON_GAP / 2, DIALOG_PADDING)
        dialog.cancel:SetPoint("BOTTOMLEFT", dialog, "BOTTOM", BUTTON_GAP / 2, DIALOG_PADDING)
    end
    local height = 2 * DIALOG_PADDING + dialog.text:GetStringHeight() + ELEMENT_GAP + BUTTON_HEIGHT
    if hasEdit then
        height = height + ELEMENT_GAP + EDIT_HEIGHT
    end
    if options.check then
        height = height + ELEMENT_GAP + CHECK_HEIGHT
    end
    dialog:SetHeight(height)
    dialog:Show()
    if hasEdit then
        dialog.edit:SetFocus()
        dialog.edit:HighlightText()
    end
end

local function accept()
    local callback, typed = dialog.onAccept, dialog.edit:IsShown() and dialog.edit:GetText() or nil
    dialog:Hide()
    if callback then
        callback(typed)
    end
end

local function build()
    dialog = CreateFrame("Frame", FRAME_NAME, UIParent, "BackdropTemplate")
    dialog:SetBackdrop(BACKDROP)
    local ground = dialog:CreateTexture(nil, "BACKGROUND", nil, 1)
    ground:SetPoint("TOPLEFT", dialog, "TOPLEFT", GROUND_INSET, -GROUND_INSET)
    ground:SetPoint("BOTTOMRIGHT", dialog, "BOTTOMRIGHT", -GROUND_INSET, GROUND_INSET)
    ground:SetColorTexture(GROUND_COLOR, GROUND_COLOR, GROUND_COLOR, 1)
    dialog:SetSize(DIALOG_WIDTH, 1)
    dialog:SetPoint("CENTER", UIParent, "CENTER", 0, DIALOG_OFFSET_Y)
    dialog:SetFrameStrata("FULLSCREEN_DIALOG")
    dialog:SetToplevel(true)
    dialog:EnableMouse(true)
    dialog:Hide()
    dialog:SetScript("OnShow", function()
        PlaySound(SOUNDKIT.IG_MAINMENU_OPEN)
    end)
    dialog:SetScript("OnHide", function()
        PlaySound(SOUNDKIT.IG_MAINMENU_CLOSE)
    end)
    tinsert(UISpecialFrames, FRAME_NAME)
    ns.appearanceControls.CloseOnEscape(dialog)

    dialog.text = dialog:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    dialog.text:SetPoint("TOP", dialog, "TOP", 0, -DIALOG_PADDING)
    dialog.text:SetWidth(DIALOG_WIDTH - 2 * DIALOG_PADDING)
    dialog.text:SetJustifyH("CENTER")

    dialog.edit = CreateFrame("EditBox", nil, dialog, "InputBoxTemplate")
    dialog.edit:SetAutoFocus(false)
    dialog.edit:SetSize(DIALOG_WIDTH - 2 * DIALOG_PADDING - BUTTON_GAP, EDIT_HEIGHT)
    dialog.edit:SetPoint("BOTTOM", dialog, "BOTTOM", 0, DIALOG_PADDING + BUTTON_HEIGHT + ELEMENT_GAP)
    dialog.edit:SetScript("OnEnterPressed", function()
        accept()
    end)
    dialog.edit:SetScript("OnEscapePressed", function()
        dialog:Hide()
    end)
    dialog.edit:SetScript("OnTextChanged", function(self)
        if dialog.copyText and self:GetText() ~= dialog.copyText then
            self:SetText(dialog.copyText)
            self:HighlightText()
        end
    end)

    dialog.check = CreateFrame("CheckButton", nil, dialog, "UICheckButtonTemplate")
    dialog.check:SetPoint("BOTTOMLEFT", dialog, "BOTTOMLEFT", DIALOG_PADDING,
        DIALOG_PADDING + BUTTON_HEIGHT + ELEMENT_GAP + EDIT_HEIGHT + ELEMENT_GAP)
    dialog.checkLabel = dialog:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    dialog.checkLabel:SetPoint("LEFT", dialog.check, "RIGHT", CHECK_LABEL_GAP, 0)
    dialog.check:SetScript("OnClick", function(self)
        if dialog.checkChanged then
            local value = dialog.checkChanged(not not self:GetChecked())
            dialog.copyText = value
            dialog.edit:SetText(value)
            dialog.edit:SetFocus()
            dialog.edit:HighlightText()
        end
    end)

    dialog.accept = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
    dialog.accept:SetSize(BUTTON_WIDTH, BUTTON_HEIGHT)
    dialog.accept:SetScript("OnClick", accept)
    dialog.other = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
    dialog.other:SetSize(BUTTON_WIDTH, BUTTON_HEIGHT)
    dialog.other:SetScript("OnClick", function()
        local callback = dialog.otherAction
        dialog:Hide()
        if callback then
            callback()
        end
    end)
    dialog.cancel = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
    dialog.cancel:SetSize(BUTTON_WIDTH, BUTTON_HEIGHT)
    dialog.cancel:SetScript("OnClick", function()
        dialog:Hide()
    end)
end

function dialogs.Message(text)
    if not dialog then
        build()
    end
    show({ text = text, cancel = false })
end

function dialogs.Confirm(text, acceptText, onAccept)
    if not dialog then
        build()
    end
    show({ text = text, accept = acceptText, onAccept = onAccept })
end

function dialogs.Choose(text, acceptText, otherText, onAccept, onOther)
    if not dialog then
        build()
    end
    show({ text = text, accept = acceptText, other = otherText, onAccept = onAccept, onOther = onOther })
end

function dialogs.Prompt(text, acceptText, value, onAccept)
    if not dialog then
        build()
    end
    show({ text = text, accept = acceptText, edit = "type", value = value, onAccept = onAccept })
end

function dialogs.Paste(text, acceptText, onAccept)
    if not dialog then
        build()
    end
    show({ text = text, accept = acceptText, edit = "paste", onAccept = onAccept })
end

function dialogs.Copy(text, value, check)
    if not dialog then
        build()
    end
    show({ text = text, accept = L.PROFILE_DONE, edit = "copy", value = value, cancel = false, check = check })
end

function dialogs.Close()
    if dialog then
        dialog:Hide()
    end
end
