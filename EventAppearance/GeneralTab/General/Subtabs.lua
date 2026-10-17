local addonName, ns = ...

local CreateFrame = CreateFrame
local ipairs = ipairs
local pairs = pairs

local L = ns.L
local general = ns.appearanceGeneral
local state = general.state
local SUBTAB_SPACING = general.SUBTAB_SPACING
local SUBTAB_TEXT_PADDING = general.SUBTAB_TEXT_PADDING
local SUBTAB_MIN_WIDTH = general.SUBTAB_MIN_WIDTH
local SUBTAB_LEFT = general.SUBTAB_LEFT

function general.BuildSubtabs(content)
    local previous
    for _, key in ipairs(general.ELEMENTS) do
        local button = CreateFrame("Button", nil, content, "PanelTopTabButtonTemplate")
        button:SetText(L["EVENT_APPEARANCE_SUBTAB_" .. key:upper()])
        PanelTemplates_TabResize(button, SUBTAB_TEXT_PADDING, nil, SUBTAB_MIN_WIDTH)
        if previous then
            button:SetPoint("LEFT", previous, "RIGHT", SUBTAB_SPACING, 0)
        else
            button:SetPoint("TOPLEFT", content, "TOPLEFT", SUBTAB_LEFT, 0)
        end
        button:SetScript("OnClick", function()
            ns.appearancePreview.SetSelected(key)
            general.Select(key)
        end)
        state.subtabs[key] = button
        previous = button
    end
end

function general.MarkSubtab()
    for key, button in pairs(state.subtabs) do
        if key == state.selected then
            PanelTemplates_SelectTab(button)
        else
            PanelTemplates_DeselectTab(button)
        end
    end
end
