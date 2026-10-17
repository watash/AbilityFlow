local addonName, ns = ...

local ipairs = ipairs
local max = math.max
local timerStyle = ns.timerStyle
local line = ns.timerTab.line
local pins = ns.timerTab.pins
local state = pins.state

local SPAN_COLORS = {
    { 1, 0.35, 0.35 }, { 0.35, 0.65, 1 }, { 0.45, 0.9, 0.45 }, { 1, 0.8, 0.25 }, { 0.8, 0.5, 1 }, { 0.3, 0.9, 0.85 },
    { 0.75, 0.55, 0.35 },
}
local SPAN_DEFAULT_COLOR = { 1, 1, 1 }
local SPAN_FADE = 0.25
pins.SPAN_FADE = SPAN_FADE

function pins.ColorOf(templateID)
    local number = timerStyle.DisplayNumber(templateID)
    return SPAN_COLORS[number] or SPAN_COLORS[1]
end

function pins.paintLabel(index)
    local lit, enlarged = false, false
    if index == state.snapped then
        lit, enlarged = true, true
    elseif index == state.liftedFrom then
        if state.swapPreview then
            lit, enlarged = true, true
        end
    elseif state.placed[index] then
        lit = true
    end
    line.PaintLabel(state.context.line, index, lit, enlarged)
end

local function templateOn(index)
    if state.dragging and not state.releasing then
        if index == state.snapped then
            return state.dragging.templateID
        elseif index == state.liftedFrom then
            return state.swapPreview and state.swapPreview.templateID or nil
        end
    end
    local pin = state.placed[index]
    return pin and pin.templateID
end

function pins.paintSpans()
    local context = state.context
    local spans = {}
    local made = context.line
    local from, color, current = made.lineStart, SPAN_DEFAULT_COLOR, nil
    local selected = context.selected
    local function fadeOf(templateID)
        return (selected == nil or templateID == nil or templateID == selected) and 1 or SPAN_FADE
    end
    for index = 1, made.count do
        local templateID = templateOn(index)
        if templateID and templateID ~= current then
            if from then
                spans[#spans + 1] = { from = from, to = line.LabelX(made, index), color = color, fade = fadeOf(current),
                    templateID = current, selected = current ~= nil and current == selected }
            end
            from, color, current = line.LabelX(made, index), pins.ColorOf(templateID), templateID
        end
    end
    if from then
        spans[#spans + 1] = { from = from, to = made.lineEnd, color = color, fade = fadeOf(current),
            templateID = current, selected = current ~= nil and current == selected }
    end
    if current == nil then
        spans = {}
    end
    if state.dragging and not state.releasing and state.snapped then
        for _, changed in ipairs({ state.snapped, state.swapPreview and state.liftedFrom or nil }) do
            local x = line.LabelX(made, changed)
            for index, span in ipairs(spans) do
                if span.from <= x and x < span.to then
                    for near = max(1, index - 1), index do
                        spans[near].fade = 1
                    end
                    break
                end
            end
        end
    end
    line.PaintSpans(made, context.frame, spans, function(templateID)
        ns.timerTab.templates.Select(templateID)
    end)
end

function pins.paintLabels()
    for index = 1, state.context.line.count do
        pins.paintLabel(index)
    end
    pins.paintSpans()
end
