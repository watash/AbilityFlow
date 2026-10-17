local addonName, ns = ...

local GameTooltip = GameTooltip
local StaticPopupDialogs = StaticPopupDialogs
local StaticPopup_Show = StaticPopup_Show
local CANCEL = CANCEL
local L = ns.L
local timerStyle = ns.timerStyle
local pins = ns.timerTab.pins
local templates = ns.timerTab.templates
local state = templates.state

local REMOVE_COLOR = RED_FONT_COLOR
local DUPLICATE_COLOR = GREEN_FONT_COLOR
local ACTION_COLOR = NORMAL_FONT_COLOR

function templates.Add(copyFrom)
    local templateID = timerStyle.Add(copyFrom)
    if not templateID then
        return
    end
    templates.Sync()
    templates.Select(templateID)
    state.context.changed()
end

local function removeTemplate(templateID)
    local context = state.context
    timerStyle.Remove(templateID)
    templates.Forget(templateID)
    pins.Sync()
    if context.selected == templateID then
        templates.Select(nil)
    end
    templates.Sync()
    context.changed()
end

local REMOVE_USED_POPUP = "ABILITYFLOW_REMOVE_USED_TEMPLATE"
StaticPopupDialogs[REMOVE_USED_POPUP] = {
    text = L.TIMER_STYLE_REMOVE_USED,
    button1 = L.TIMER_STYLE_REMOVE,
    button2 = CANCEL,
    OnAccept = function(_, templateID)
        removeTemplate(templateID)
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
}

local function askRemoveTemplate(templateID)
    if timerStyle.IsUsed(templateID) then
        local popup = StaticPopup_Show(REMOVE_USED_POPUP, nil, nil, templateID)
        if popup and state.context.rowBox then
            popup:ClearAllPoints()
            popup:SetPoint("CENTER", state.context.rowBox, "CENTER")
        end
    else
        removeTemplate(templateID)
    end
end

function templates.OpenMenu(event, templateID)
    MenuUtil.CreateContextMenu(event, function(_, rootDescription)
        local duplicate = rootDescription:CreateButton(L.PROFILE_DUPLICATE, function()
            templates.Add(templateID)
        end)
        if not timerStyle.CanAdd() then
            duplicate:SetEnabled(false)
            duplicate:SetTooltip(function(tooltip)
                tooltip:SetText(L.TIMER_LIMIT_REACHED)
            end)
        end
        rootDescription:CreateButton(REMOVE_COLOR:WrapTextInColorCode(L.TIMER_STYLE_REMOVE), function()
            askRemoveTemplate(templateID)
        end)
    end)
end

function templates.ShowHint(icon)
    GameTooltip:SetOwner(icon, "ANCHOR_RIGHT")
    GameTooltip:AddLine(L.TIMER_TEMPLATE_HINT_SELECT:format(
        ACTION_COLOR:WrapTextInColorCode(L.TIMER_TEMPLATE_ACTION_CLICK)), 1, 1, 1, true)
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(L.TIMER_TEMPLATE_HINT_DRAG:format(
        ACTION_COLOR:WrapTextInColorCode(L.TIMER_TEMPLATE_ACTION_DRAG)), 1, 1, 1, true)
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(L.TIMER_TEMPLATE_HINT_MENU:format(
        ACTION_COLOR:WrapTextInColorCode(L.TIMER_TEMPLATE_ACTION_MENU),
        DUPLICATE_COLOR:WrapTextInColorCode(L.TIMER_TEMPLATE_WORD_DUPLICATE),
        REMOVE_COLOR:WrapTextInColorCode(L.TIMER_TEMPLATE_WORD_REMOVE)), 1, 1, 1, true)
    GameTooltip:Show()
end
