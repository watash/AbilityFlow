local addonName, ns = ...

local CreateFrame = CreateFrame
local ipairs = ipairs
local pairs = pairs

local L = ns.L
local general = ns.appearanceGeneral
local state = general.state
local TEXT_INDENT = general.TEXT_INDENT
local SCROLLBAR_WIDTH = general.SCROLLBAR_WIDTH
local FALLBACK_PANEL_HEIGHT = general.FALLBACK_PANEL_HEIGHT
local SUBTAB_ROW_HEIGHT = general.SUBTAB_ROW_HEIGHT
local SUBTAB_CONTENT_GAP = general.SUBTAB_CONTENT_GAP
local HINT_FONT = general.HINT_FONT
local NOTE_FONT = general.NOTE_FONT
local HINT_SIDE_MARGIN = general.HINT_SIDE_MARGIN

local function buildPanels()
    for _, key in ipairs(general.ELEMENTS) do
        local panel = CreateFrame("Frame", nil, state.child)
        panel:SetSize(state.child:GetWidth(), FALLBACK_PANEL_HEIGHT)
        panel:Hide()
        state.panels[key] = panel
        state.refreshers[key] = ns.appearanceElements[key].Build(panel, state.onChanged)
    end
end

local function buildLabels()
    local child = state.child
    state.hintLabel = child:CreateFontString(nil, "OVERLAY", HINT_FONT)
    state.hintLabel:SetPoint("TOP", state.box, "CENTER", 0, 0)
    state.hintLabel:SetJustifyH("CENTER")
    state.hintLabel:SetText(L.EVENT_APPEARANCE_HINT)
    state.nameLabel = child:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    state.nameLabel:SetPoint("TOPLEFT", child, "TOPLEFT", TEXT_INDENT, 0)
    state.nameLabel:SetJustifyH("LEFT")
    state.noteLabel = child:CreateFontString(nil, "OVERLAY", NOTE_FONT)
    state.noteLabel:SetJustifyH("CENTER")
    local before, after = L.EVENT_APPEARANCE_DEFAULTS_NOTE_LATER:match("^(.*)%%s(.*)$")
    state.noteLabel:SetText(ns.text.White(L.EVENT_APPEARANCE_DEFAULTS_NOTE) .. "\n" .. ns.text.White(before)
        .. ns.text.Gold(L.EVENT_APPEARANCE_TAB_TIMER_APPEARANCE) .. ns.text.White(after))
end

function general.Build(content, changed)
    state.onChanged = changed
    state.box = ns.timerTab.settings.CreateBox(content)
    state.box:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -SUBTAB_ROW_HEIGHT)
    state.box:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", 0, 0)
    state.box:SetFrameLevel(content:GetFrameLevel())

    state.scroll = CreateFrame("ScrollFrame", nil, content, "UIPanelScrollFrameTemplate")
    state.scroll:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -(SUBTAB_ROW_HEIGHT + SUBTAB_CONTENT_GAP))
    state.scroll:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -SCROLLBAR_WIDTH, 0)
    state.scroll.scrollBarHideable = true
    state.scroll.ScrollBar:Hide()

    general.BuildSubtabs(content)

    state.child = CreateFrame("Frame", nil, state.scroll)
    state.child:SetSize(1, 1)
    state.scroll:SetScrollChild(state.child)

    buildLabels()
    general.BuildButtons(content)
    buildPanels()

    state.scroll:SetScript("OnSizeChanged", function(_, width)
        state.child:SetWidth(width)
        state.hintLabel:SetWidth(width - 2 * HINT_SIDE_MARGIN)
        state.nameLabel:SetWidth(width - TEXT_INDENT)
        state.noteLabel:SetWidth(width - 2 * HINT_SIDE_MARGIN)
        for _, panel in pairs(state.panels) do
            panel:SetWidth(width)
        end
        general.Resize()
    end)

    general.Select(nil)
end
