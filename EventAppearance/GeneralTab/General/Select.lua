local addonName, ns = ...

local pairs = pairs

local L = ns.L
local controls = ns.appearanceControls
local general = ns.appearanceGeneral
local state = general.state
local ELEMENT_GAP = general.ELEMENT_GAP
local TEXT_INDENT = general.TEXT_INDENT

local function update()
    local selected = state.selected
    local active
    if selected then
        state.nameLabel:SetText(L[general.OWN_TITLES[selected] or ("EVENT_APPEARANCE_ELEMENT_" .. selected:upper())])
        active = state.nameLabel
    else
        active = state.hintLabel
    end
    state.hintLabel:SetShown(selected == nil)
    state.noteLabel:SetShown(selected == nil)
    state.nameLabel:SetShown(false)
    state.resetButton:SetShown(selected ~= nil)
    general.UpdateOrientationNote()
    general.UpdateUndoButton()
    general.MarkSubtab()
    for key, panel in pairs(state.panels) do
        panel:SetShown(key == selected)
        panel:ClearAllPoints()
        if selected then
            panel:SetPoint("TOPLEFT", state.child, "TOPLEFT", 0, -(ELEMENT_GAP + (state.firstRowShift[key] or 0)))
        else
            panel:SetPoint("TOPLEFT", active, "BOTTOMLEFT", -TEXT_INDENT, -ELEMENT_GAP)
        end
    end
    state.noteLabel:ClearAllPoints()
    state.noteLabel:SetPoint("TOP", state.hintLabel, "BOTTOM", 0, -ELEMENT_GAP)
    if selected then
        general.AlignFirstRow(selected, state.panels[selected])
    end
    general.Resize()
    general.MeasureSoon()
end

function general.Select(key)
    state.selected = key == "border" and "icon" or key
    update()
end

function general.Refresh()
    if not state.child then
        return
    end
    for key, panel in pairs(state.panels) do
        controls.ResyncAll(panel)
        if state.refreshers[key] then
            state.refreshers[key]()
        end
    end
end
