local addonName, ns = ...

local pairs = pairs
local math = math
local next = next
local L = ns.L
local timerStyle = ns.timerStyle
local previewEvent = ns.timerTab.event
local line = ns.timerTab.line
local pins = ns.timerTab.pins
local state = pins.state

local HINT_FONT = "GameFontNormal"
local DROP_FONT = "GameFontNormalLarge"
local HINT_GAP_LABELS = 1
local HINT_MIN_LABELS = 3
local hint

local function hintLastLabel(made)
    local first = made.count + 1
    for index, pin in pairs(state.placed) do
        if pin ~= state.dragging then
            first = math.min(first, index)
        end
    end
    local last = first - 1 - HINT_GAP_LABELS
    if first > made.count then
        return made.count
    end
    return last >= HINT_MIN_LABELS and last or nil
end

function pins.paintHint()
    local context = state.context
    local made = context and context.line
    local lastLabel = made and hintLastLabel(made)
    local untouched = AbilityFlowDB.lineHintDone ~= true
    local wanted = made and made.centerY and made.backingTop and lastLabel and not state.snapped
        and (untouched or next(state.placed) == nil)
    if not wanted then
        if hint then
            hint:Hide()
        end
        return
    end
    if not hint then
        hint = context.frame:CreateFontString(nil, "OVERLAY", HINT_FONT)
        hint:SetJustifyH("CENTER")
    end
    if state.dragging then
        hint:SetFontObject(DROP_FONT)
        hint:SetText(L.TIMER_PINS_DROP)
    else
        hint:SetFontObject(HINT_FONT)
        if next(state.placed) ~= nil then
            hint:SetText(L.TIMER_PINS_HINT_SHORT)
        else
            hint:SetText(#timerStyle.Order() == 0 and L.TIMER_PINS_HINT_CREATE or L.TIMER_PINS_HINT)
        end
    end
    local middle = (made.backingTop + made.centerY - line.THICKNESS / 2) / 2
    hint:ClearAllPoints()
    hint:SetPoint("LEFT", context.frame, "TOPLEFT", line.LabelX(made, 1), -middle)
    hint:SetPoint("RIGHT", context.frame, "TOPLEFT", line.LabelX(made, lastLabel), -middle)
    hint:Show()
end

function pins.Refresh()
    if not state.context.frame:IsVisible() then
        return
    end
    local look = previewEvent.CurrentLook()
    pins.paintStart(look)
    for index, pin in pairs(state.placed) do
        pins.paint(pin, look)
        pins.placeAbove(pin, index)
        pin.event:Show()
    end
    pins.paintSpans()
    pins.paintHint()
end

function pins.Sync()
    if not state.context.frame:IsVisible() then
        return
    end
    local made = state.context.line
    for index = 1, made.count do
        local wanted = timerStyle.TemplateAt(pins.secondAt(index))
        if wanted and not timerStyle.Template(wanted) then
            wanted = nil
        end
        local current = state.placed[index]
        if current and current.templateID ~= wanted then
            pins.retire(current, true)
            current = nil
        end
        if wanted and not current then
            local pin = pins.acquire(wanted)
            pin.index = index
            state.placed[index] = pin
            pins.setLevel(pin, pin.baseLevel)
            pin.event:Show()
        end
        pins.paintLabel(index)
    end
    pins.Refresh()
end

function pins.FlashTemplate(templateID)
    for _, pin in pairs(state.placed) do
        if pin.templateID == templateID and pin.event:IsShown() then
            ns.eventEffects.HoldForPreview(pin.event, true)
            ns.eventEffects.PlayFlash(pin.event)
        end
    end
end

function pins.EndFlashPreview()
    for _, pin in pairs(state.placed) do
        ns.eventEffects.HoldForPreview(pin.event, false)
    end
end

function pins.HideAll()
    pins.CancelDrag()
    pins.hideStart()
    if hint then
        hint:Hide()
    end
    for _, pin in pairs(state.placed) do
        pin.event:Hide()
        ns.timerPaint.Stop(pin.event)
    end
end

function pins.FlashPlaced()
    for index, pin in pairs(state.placed) do
        if pin.event:IsShown() and timerStyle.FlashesAt(pins.secondAt(index), true) then
            ns.eventEffects.PlayFlash(pin.event)
        end
    end
end
