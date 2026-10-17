local addonName, ns = ...

local abs = math.abs
local timerStyle = ns.timerStyle
local previewEvent = ns.timerTab.event
local line = ns.timerTab.line
local pins = ns.timerTab.pins
local state = pins.state

function pins.setSnapped(index)
    if index == state.snapped then
        return
    end
    state.snapped = index
    local dragging = state.dragging
    if dragging and not state.releasing then
        local template = timerStyle.Template(dragging.templateID)
        dragging.event.texts.cooldown:SetText(previewEvent.SampleText(template,
            index and pins.secondAt(index) or timerStyle.DisplayNumber(dragging.templateID) or dragging.templateID))
    end
    pins.refreshDragName()
    pins.refreshNotes()
    pins.paintLabels()
    pins.paintHint()
    line.ShowSnapMark(state.context.line, index)
end

function pins.updateSnap(x, y)
    local dragging = state.dragging
    if not dragging then
        return
    end
    local frame, made = state.context.frame, state.context.line
    local top, left = frame:GetTop(), frame:GetLeft()
    local function leaveLabels()
        pins.setSnapped(nil)
        pins.setFullColor(dragging, false)
        pins.setReplacePreview(nil)
        pins.setSwapPreview(nil)
    end
    if not top or not left or not made.centerY then
        leaveLabels()
        return
    end
    local delta = y - (top - line.LabelTop(made))
    local reach = delta < 0 and pins.SNAP_BELOW or pins.SNAP_ABOVE
    if abs(delta) > reach then
        leaveLabels()
        return
    end

    local event = dragging.event
    local half = (event:GetWidth() / 2 + previewEvent.BorderMargin(previewEvent.CurrentLook())) * event:GetScale()
    local index = line.IndexAtX(made, x - left - half)
    pins.setSnapped(index)
    pins.setFullColor(dragging, true)
    local occupant = state.placed[index]
    if occupant == dragging then
        occupant = nil
    end
    if dragging.index == nil then
        pins.setReplacePreview(occupant)
        pins.setSwapPreview(nil)
    else
        pins.setReplacePreview(nil)
        pins.setSwapPreview(occupant)
    end
end
