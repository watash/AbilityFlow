local addonName, ns = ...

local CreateFrame = CreateFrame
local max = math.max
local L = ns.L
local timerStyle = ns.timerStyle
local templates = ns.timerTab.templates
local state = templates.state

local ADD_PLUS_SHARE = 0.5
local ADD_HIGHLIGHT_TEXTURE = "Interface\\Buttons\\ButtonHilight-Square"
local ADD_TEXT_GAP = 12
local ADD_TEXT_RIGHT_MARGIN = 24
local ADD_TEXT_FONT = "GameFontHighlight"
local ADD_SLOT_ATLAS = "ui-hud-actionbar-iconframe-slot"
local ADD_PLUS_ATLAS = "bags-icon-addslots"

function templates.BuildAddButton()
    local context = state.context
    local button = CreateFrame("Button", nil, context.frame)
    button:EnableMouse(true)
    button:RegisterForClicks("LeftButtonUp")
    button.slot = button:CreateTexture(nil, "BACKGROUND")
    button.slot:SetPoint("CENTER")
    button.slot:SetAtlas(ADD_SLOT_ATLAS)
    button.plus = button:CreateTexture(nil, "ARTWORK")
    button.plus:SetPoint("CENTER")
    button.plus:SetAtlas(ADD_PLUS_ATLAS)
    button:SetHighlightTexture(ADD_HIGHLIGHT_TEXTURE, "ADD")
    button:SetScript("OnClick", function()
        templates.Add(nil)
    end)
    state.addButton = button
    state.addText = context.frame:CreateFontString(nil, "OVERLAY", ADD_TEXT_FONT)
    state.addText:SetJustifyH("LEFT")
    state.addText:SetText(L.TIMER_ADD_EMPTY:format(timerStyle.MAX_TEMPLATES))
end

function templates.LayoutAddButton(count)
    local context = state.context
    local button = state.addButton
    local cell = context.footprint * context.scale
    local canAdd = timerStyle.CanAdd()
    button:SetShown(canAdd)
    button:SetSize(cell, cell)
    button.slot:SetSize(cell, cell)
    button.plus:SetSize(cell * ADD_PLUS_SHARE, cell * ADD_PLUS_SHARE)
    local centerX = context.leftInset + count * context.pitch + cell / 2
    button:ClearAllPoints()
    button:SetPoint("CENTER", context.frame, "TOPLEFT", centerX, -(context.top + cell / 2))
    local textLeft = centerX + cell / 2 + ADD_TEXT_GAP
    state.addText:SetWidth(max(1, context.frame:GetWidth() - textLeft - ADD_TEXT_RIGHT_MARGIN))
    state.addText:ClearAllPoints()
    state.addText:SetPoint("LEFT", context.frame, "TOPLEFT", textLeft, -(context.top + cell / 2))
    state.addText:SetShown(count == 0)
    context.countText:SetText(L.TIMER_ADD_COUNT:format(count, timerStyle.MAX_TEMPLATES))
    context.countText:SetShown(canAdd)
    context.limitText:SetShown(not canAdd)
end
