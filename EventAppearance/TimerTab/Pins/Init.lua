local addonName, ns = ...

local max = math.max
local timerStyle = ns.timerStyle
local previewEvent = ns.timerTab.event
local line = ns.timerTab.line

local pins = {}
ns.timerTab.pins = pins

pins.SCALE_RATIO = 0.8
pins.SNAP_ABOVE = 85
pins.SNAP_BELOW = 40
local REST_REACH = 70
local REST_SHARE = 0.4
local ICON_LIFT = 32
pins.NAME_LINE_MARGIN = 2
pins.NAME_BORDER_GAP = 2
pins.STRATA = "FULLSCREEN"
pins.SAMPLE_LEVEL_OVER = 6

pins.state = {
    placed = {},
    pool = {},
    releasing = false,
}
local state = pins.state

function pins.Setup(tab)
    state.context = tab
end

function pins.secondAt(index)
    return line.SecondAt(state.context.line, index)
end

function pins.saveLabel(index)
    AbilityFlowDB.lineHintDone = true
    local pin = state.placed[index]
    timerStyle.SetTemplateAt(pins.secondAt(index), pin and pin.templateID or nil)
end

function pins.restHeight()
    return REST_REACH * REST_SHARE + ICON_LIFT
end

function pins.iconHeightOverLine()
    return pins.restHeight() - line.THICKNESS - line.LABEL_GAP
end

function pins.NameRoom()
    local context = state.context
    local iconScale = context.scale * pins.SCALE_RATIO
    local reach = previewEvent.BorderMargin(previewEvent.CurrentLook()) * iconScale
    return pins.iconHeightOverLine() - reach - pins.NAME_BORDER_GAP - pins.NAME_LINE_MARGIN
end

function pins.Reach()
    local context = state.context
    local labelsBelowMiddle = line.THICKNESS / 2 + line.LABEL_GAP
    local iconSize = context.footprint * context.scale * pins.SCALE_RATIO
    local glowReach = iconSize * (timerStyle.GLOW_SCALE_MAX / ns.glow.FULL_SHARE - 1) / 2
    return max(REST_REACH, pins.restHeight() + iconSize + glowReach - labelsBelowMiddle)
end

function pins.placeFrom(event, x)
    local made = state.context.line
    local scale = event:GetScale()
    local rest = line.LabelTop(made) - pins.restHeight()
    local margin = previewEvent.BorderMargin(previewEvent.CurrentLook())
    event:ClearAllPoints()
    event:SetPoint("BOTTOMLEFT", state.context.frame, "TOPLEFT", x / scale + margin, -rest / scale)
end

function pins.placeAbove(pin, index)
    pins.placeFrom(pin.event, line.LabelX(state.context.line, index))
end
