local addonName, ns = ...

local GameTooltip = GameTooltip
local issecretvalue = issecretvalue
local GameTooltip_SetDefaultAnchor = GameTooltip_SetDefaultAnchor

local timeline = ns.timeline
local state = timeline.state

local ANCHOR_CURSOR = "ANCHOR_CURSOR_RIGHT"

local function hide(event)
    if GameTooltip:IsOwned(event) then
        GameTooltip:Hide()
    end
end

local function show(event)
    hide(event)
    local anchor = state.tooltipAnchor
    if anchor == timeline.TOOLTIP_HIDDEN then
        return
    end
    local spellID = event.spellID
    if not issecretvalue(spellID) and (spellID == nil or spellID == 0) then
        return
    end
    if anchor == timeline.TOOLTIP_CURSOR then
        GameTooltip:SetOwner(event, ANCHOR_CURSOR)
    else
        GameTooltip_SetDefaultAnchor(GameTooltip, event)
    end
    GameTooltip:SetSpellByID(spellID)
    GameTooltip:Show()
end

local takesMouse = true

function timeline.setupTooltip(event)
    event:EnableMouse(takesMouse)
    event:SetScript("OnEnter", show)
    event:SetScript("OnLeave", hide)
    event:SetScript("OnHide", hide)
end

function timeline.clearTooltip(event)
    hide(event)
end

function timeline.SetTooltipAnchor(value)
    state.tooltipAnchor = value
end

function timeline.SetIconsTakeMouse(enabled)
    takesMouse = enabled
    for _, event in pairs(state.activeEvents) do
        event:EnableMouse(enabled)
        hide(event)
    end
    for _, event in ipairs(state.eventPool) do
        event:EnableMouse(enabled)
    end
end
