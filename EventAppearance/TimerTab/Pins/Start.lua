local addonName, ns = ...

local UIParent = UIParent
local GameTooltip = GameTooltip
local L = ns.L
local timerStyle = ns.timerStyle
local previewEvent = ns.timerTab.event
local pins = ns.timerTab.pins
local state = pins.state

local START_TAB = "General"
local START_ALPHA = 0.6

local function explainStart(event)
    event:EnableMouse(true)
    event:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(L.TIMER_START_HINT_TITLE)
        GameTooltip:AddLine(L.TIMER_START_NAME, 1, 1, 1, true)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(L.TIMER_START_HINT, 1, 1, 1, true)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(pins.ActionLine(L.TIMER_ACTION_CLICK, L.TIMER_START_DO_OPEN), 1, 1, 1, true)
        GameTooltip:Show()
    end)
    event:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    event:SetScript("OnMouseUp", function(_, button)
        if button == "LeftButton" then
            ns.eventAppearance.SelectTab(START_TAB)
        end
    end)
end

function pins.paintStart(look)
    local context = state.context
    if not state.startIcon then
        local event = previewEvent.Create(UIParent, previewEvent.TEMPLATE_FILE_ID)
        previewEvent.SetStrata(event, pins.STRATA)
        explainStart(event)
        local sample = previewEvent.CreateNameSample(UIParent, pins.STRATA)
        state.startIcon = { event = event, nameSample = sample }
        previewEvent.SetNameLevel(sample, event:GetFrameLevel() + pins.SAMPLE_LEVEL_OVER)
    end
    local event, sample = state.startIcon.event, state.startIcon.nameSample
    previewEvent.Apply(event, previewEvent.FitScale(look, context.footprint, context.scale) * pins.SCALE_RATIO, false, look)
    previewEvent.Paint(event, nil, look)
    event.texts.cooldown:SetText(">" .. timerStyle.SECONDS)
    pins.placeFrom(event, context.line.lineStart)
    event:Show()
    pins.placeName(sample, event)
    pins.paintNameFitted(sample, event, nil, pins.NAME_SIZE_FORMAT:format(timerStyle.NameScaleOf(nil)))
    event:SetAlpha(START_ALPHA)
    sample:SetAlpha(START_ALPHA)
    sample:Show()
end

function pins.hideStart()
    if state.startIcon then
        GameTooltip:Hide()
        state.startIcon.event:Hide()
        state.startIcon.nameSample:Hide()
    end
end
