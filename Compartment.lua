local addonName, ns = ...

local L = ns.L
local GameTooltip = GameTooltip

function AbilityFlow_OnCompartmentClick()
    ns.eventAppearance.Toggle()
end

function AbilityFlow_OnCompartmentEnter(_, button)
    GameTooltip:SetOwner(button, "ANCHOR_LEFT")
    GameTooltip:SetText(addonName)
    GameTooltip:AddLine(L.COMPARTMENT_HINT, 1, 1, 1)
    GameTooltip:Show()
end

function AbilityFlow_OnCompartmentLeave()
    GameTooltip:Hide()
end
