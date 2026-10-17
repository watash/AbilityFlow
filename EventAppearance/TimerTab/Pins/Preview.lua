local addonName, ns = ...

local timerStyle = ns.timerStyle
local previewEvent = ns.timerTab.event
local pins = ns.timerTab.pins
local state = pins.state

function pins.setReplacePreview(occupant)
    if occupant == state.replacePreview then
        return
    end
    if state.replacePreview then
        pins.setFullColor(state.replacePreview, true)
    end
    state.replacePreview = occupant
    if occupant then
        pins.setFullColor(occupant, false)
    end
end

local function showSecond(pin, index)
    pin.event.texts.cooldown:SetText(previewEvent.SampleText(timerStyle.Template(pin.templateID), pins.secondAt(index)))
end

function pins.setSwapPreview(occupant)
    if occupant == state.swapPreview then
        return
    end
    if state.swapPreview and state.swapPreview.index then
        pins.placeAbove(state.swapPreview, state.swapPreview.index)
        showSecond(state.swapPreview, state.swapPreview.index)
    end
    state.swapPreview = occupant
    if occupant and state.liftedFrom then
        pins.placeAbove(occupant, state.liftedFrom)
        showSecond(occupant, state.liftedFrom)
    end
    pins.paintLabels()
end

function pins.refreshDragName()
    local pin = state.dragging
    if not pin or state.releasing then
        return
    end
    local change, kind = pins.sampleText(pin)
    pin.showName = change ~= nil
    if change then
        pins.paintNameFitted(pin.nameSample, pin.event, timerStyle.Template(pin.templateID), change, kind)
        previewEvent.SetNameDesaturated(pin.nameSample, pin.desaturated)
    end
    pin.nameSample:SetShown(pin.event:IsShown() and pin.showName)
end
