local addonName, ns = ...

local CreateFrame = CreateFrame
local GameTooltip = GameTooltip
local GetCursorPosition = GetCursorPosition
local L = ns.L
local controls = ns.appearanceControls

local TOGGLE_TEXTURE = "Interface\\AddOns\\AbilityFlow\\Media\\Icons\\corner-triangle.png"
local TOGGLE_SIZE = 24
local TOGGLE_LEVEL_ABOVE_PANEL = 3
local TOGGLE_ALPHA = 1
local TOGGLE_HOVER_ALPHA = 0.6
local TOGGLE_TO_WHITE = { 1, 1, 1 }
local TOGGLE_TO_DARK = { 0, 0, 0 }
controls.GROUND_INSET = 4
local GROUND_INSET = controls.GROUND_INSET

function controls.CreateGroundToggle(panel, onToggle)
    local button = CreateFrame("Button", nil, panel)
    button:SetSize(TOGGLE_SIZE, TOGGLE_SIZE)
    button:SetPoint("TOPLEFT", panel, "TOPLEFT", GROUND_INSET, -GROUND_INSET)
    button:SetFrameLevel(panel:GetFrameLevel() + TOGGLE_LEVEL_ABOVE_PANEL)
    button:SetAlpha(TOGGLE_ALPHA)

    local triangle = button:CreateTexture(nil, "OVERLAY")
    triangle:SetAllPoints()
    triangle:SetTexture(TOGGLE_TEXTURE)

    function button.Refresh(white)
        local color = white and TOGGLE_TO_DARK or TOGGLE_TO_WHITE
        triangle:SetVertexColor(color[1], color[2], color[3])
    end
    button.Refresh(false)

    local function overTriangle()
        local scale = button:GetEffectiveScale()
        local mouseX, mouseY = GetCursorPosition()
        local across = mouseX / scale - button:GetLeft()
        local down = button:GetTop() - mouseY / scale
        return across >= 0 and down >= 0 and across + down <= TOGGLE_SIZE
    end

    local tipShown = false
    local function setTip(shown)
        if shown == tipShown then
            return
        end
        tipShown = shown
        if shown then
            GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
            GameTooltip:SetText(L.EVENT_APPEARANCE_TIP_WHITE_GROUND, 1, 1, 1, 1, true)
            GameTooltip:Show()
        else
            GameTooltip:Hide()
        end
    end
    button:SetScript("OnEnter", function(self)
        self:SetScript("OnUpdate", function()
            local over = overTriangle()
            self:SetAlpha(over and TOGGLE_HOVER_ALPHA or TOGGLE_ALPHA)
            setTip(over)
        end)
    end)
    button:SetScript("OnLeave", function(self)
        self:SetScript("OnUpdate", nil)
        self:SetAlpha(TOGGLE_ALPHA)
        setTip(false)
    end)
    button:SetScript("OnClick", function()
        if overTriangle() then
            onToggle()
        end
    end)
    return button
end
