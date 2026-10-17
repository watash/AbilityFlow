local addonName, ns = ...

local UIParent = UIParent
local GetCursorPosition = GetCursorPosition
local timerStyle = ns.timerStyle
local previewEvent = ns.timerTab.event
local pins = ns.timerTab.pins
local state = pins.state

local DRAG_LEVEL = 500

local function followCursor()
    local scale = UIParent:GetEffectiveScale()
    local x, y = GetCursorPosition()
    x, y = x / scale, y / scale
    local dragging = state.dragging
    if dragging then
        local event = dragging.event
        local own = event:GetScale()
        event:ClearAllPoints()
        event:SetPoint("CENTER", UIParent, "BOTTOMLEFT", (x + dragging.grabX) / own, (y + dragging.grabY) / own)
    end
    pins.updateSnap(x, y)
end

local function stick(pin, index)
    local placed = state.placed
    if pin.index ~= index then
        local occupant = placed[index]
        if occupant and occupant ~= pin then
            local previous = pin.index
            if previous then
                placed[previous] = nil
                pin.index = nil
                stick(occupant, previous)
            else
                pins.retire(occupant)
            end
        end
    end

    pins.placeAbove(pin, index)
    if pin.index ~= index then
        local previous = pin.index
        if previous then
            placed[previous] = nil
            pins.paintLabel(previous)
        end
        placed[index] = pin
        pin.index = index
        pins.paintLabel(index)
        if previous then
            pins.saveLabel(previous)
        end
        pins.saveLabel(index)
    end
    pins.paint(pin)
end

local function beginDrag(pin, grabX, grabY)
    pin.grabX, pin.grabY = grabX, grabY
    state.dragging = pin
    pins.refreshDragName()
    pins.refreshNotes()
    pins.paintSpans()
    pins.paintHint()
    pin.retired = false
    pins.setLevel(pin, DRAG_LEVEL)
    pin.event:Show()
    previewEvent.Paint(pin.event, timerStyle.Template(pin.templateID), previewEvent.CurrentLook())
    pins.dim(pin, not pin.desaturated)
    followCursor()
    pin.event:SetScript("OnUpdate", followCursor)
end

function pins.onDragStart(pin)
    pin.wasDragged = true
    pins.setFullColor(pin, false)
    state.liftedFrom = pin.index
    if state.liftedFrom then
        pins.paintLabel(state.liftedFrom)
    end
    local event = pin.event
    local centerX, centerY = event:GetCenter()
    local grabX, grabY = 0, 0
    if centerX then
        local scale = UIParent:GetEffectiveScale()
        local cursorX, cursorY = GetCursorPosition()
        local toScreen = event:GetEffectiveScale() / scale
        grabX, grabY = centerX * toScreen - cursorX / scale, centerY * toScreen - cursorY / scale
    end
    beginDrag(pin, grabX, grabY)
end

function pins.IsDragging()
    return state.dragging ~= nil
end

function pins.BeginDrag(templateID)
    local pin = pins.acquire(templateID)
    pin.desaturated = true
    pins.paint(pin)
    beginDrag(pin, 0, 0)
end

function pins.EndDrag()
    local pin = state.dragging
    if not pin then
        return
    end
    state.releasing = true
    local madeNow = pin.index == nil and state.snapped ~= nil
    pin.event:SetScript("OnUpdate", nil)
    pins.setLevel(pin, pin.baseLevel)

    local lifted = state.liftedFrom
    state.liftedFrom = nil
    if lifted then
        pins.paintLabel(lifted)
    end
    pins.setReplacePreview(nil)
    pins.setSwapPreview(nil)
    if state.snapped then
        stick(pin, state.snapped)
        pins.setSnapped(nil)
    else
        pins.retire(pin)
        pins.setSnapped(nil)
    end
    state.dragging = nil
    state.releasing = false
    pins.refreshNotes()
    state.context.changed()
    if madeNow and state.context.frame:IsVisible() and state.context.selected ~= pin.templateID then
        ns.timerTab.templates.Select(pin.templateID)
    end
end

function pins.CancelDrag()
    if state.dragging then
        pins.EndDrag()
    end
end
