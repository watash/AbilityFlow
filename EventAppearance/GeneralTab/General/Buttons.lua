local addonName, ns = ...

local CreateFrame = CreateFrame

local L = ns.L
local appearance = ns.appearance
local general = ns.appearanceGeneral
local state = general.state
local RESET_BUTTON_HEIGHT = general.RESET_BUTTON_HEIGHT
local RESET_BUTTON_RIGHT_MARGIN = general.RESET_BUTTON_RIGHT_MARGIN
local RESET_BUTTON_BOTTOM_MARGIN = general.RESET_BUTTON_BOTTOM_MARGIN
local ORIENTATION_NOTE_WIDTH = general.ORIENTATION_NOTE_WIDTH
local ORIENTATION_NOTE_GAP = general.ORIENTATION_NOTE_GAP

function general.UpdateOrientationNote()
    if state.orientationNote then
        local selected = state.selected
        local onNameTab = selected == "name" or selected == "nameBackground"
        state.orientationNote:SetShown(onNameTab and ns.timeline.GetOrientation() == ns.timeline.ORIENTATION_HORIZONTAL)
    end
end

function general.UpdateUndoButton()
    if state.undoButton then
        local selected = state.selected
        local undoable = selected ~= nil and appearance.UndoElement() == selected
        state.undoButton:SetShown(undoable)
        state.resetButton:SetShown(selected ~= nil and not undoable)
        if selected then
            state.resetButton:SetEnabled(not appearance.IsDefault(selected))
        end
    end
end

function general.BuildButtons(content)
    state.resetButton = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    state.resetButton:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -RESET_BUTTON_RIGHT_MARGIN, RESET_BUTTON_BOTTOM_MARGIN)
    state.resetButton:SetText(L.EVENT_APPEARANCE_RESET)
    ns.appearanceControls.SizeResetButton(state.resetButton)

    state.orientationNote = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    state.orientationNote:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -RESET_BUTTON_RIGHT_MARGIN,
        RESET_BUTTON_BOTTOM_MARGIN + RESET_BUTTON_HEIGHT + ORIENTATION_NOTE_GAP)
    state.orientationNote:SetWidth(ORIENTATION_NOTE_WIDTH)
    state.orientationNote:SetJustifyH("RIGHT")
    state.orientationNote:SetText(ns.text.Red(L.EVENT_APPEARANCE_NAME_ORIENTATION_NOTE))
    local previousGeometry = ns.timeline.onGeometryChanged
    ns.timeline.onGeometryChanged = function()
        if previousGeometry then
            previousGeometry()
        end
        general.UpdateOrientationNote()
    end
    content:HookScript("OnShow", general.UpdateOrientationNote)

    state.undoButton = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    state.undoButton:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -RESET_BUTTON_RIGHT_MARGIN, RESET_BUTTON_BOTTOM_MARGIN)
    state.undoButton:SetText(L.EVENT_APPEARANCE_UNDO)
    ns.appearanceControls.SizeResetButton(state.undoButton)
    state.undoButton:Hide()
    state.undoButton:SetScript("OnClick", function()
        appearance.UndoReset()
        general.Refresh()
        state.onChanged()
    end)
    appearance.OnChanged(general.UpdateUndoButton)
    state.resetButton:SetScript("OnClick", function()
        if state.selected then
            appearance.Reset(state.selected)
            general.Refresh()
            state.onChanged()
        end
    end)
end
