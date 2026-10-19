local addonName, ns = ...

local C_Texture = C_Texture

local timeline = ns.timeline
local state = timeline.state
local frame = timeline.frame

local MIN_FRAME_WIDTH = 24
local ORIENTATION_HORIZONTAL = timeline.ORIENTATION_HORIZONTAL
local DIRECTION_TOP = timeline.DIRECTION_TOP
local DIRECTION_BOTTOM = timeline.DIRECTION_BOTTOM
local DIRECTION_LEFT = timeline.DIRECTION_LEFT
local DIRECTION_RIGHT = timeline.DIRECTION_RIGHT

local function applyFrameSize()
    local frameWidth = math.max(state.trackWidth, MIN_FRAME_WIDTH)
    if state.orientation == ORIENTATION_HORIZONTAL then
        frame:SetSize(state.trackLength, frameWidth)
    else
        frame:SetSize(frameWidth, state.trackLength)
    end
end
applyFrameSize()

local function notifyGeometryChanged()
    if timeline.onGeometryChanged then
        timeline.onGeometryChanged()
    end
end

function timeline.currentIconSize()
    return state.iconBaseSize * ns.eventStyle.Scale()
end

function timeline.currentCrop()
    return state.iconZoom / 100
end

function timeline.TrackLength()
    return state.trackLength
end

function timeline.TrackWidth()
    return state.trackWidth
end

function timeline.Orientation()
    return state.orientation
end

function timeline.SetTrackLength(length)
    state.trackLength = length
    applyFrameSize()
    notifyGeometryChanged()
end

local function keepFrameCentre(oldWidth, oldHeight)
    local point, relativeTo, relativePoint, x, y = frame:GetPoint(1)
    if not point then
        return false
    end
    local halfGrowthX = (frame:GetWidth() - oldWidth) / 2
    local halfGrowthY = (frame:GetHeight() - oldHeight) / 2
    if halfGrowthX == 0 and halfGrowthY == 0 then
        return false
    end
    if point:find("LEFT") then
        x = x - halfGrowthX
    elseif point:find("RIGHT") then
        x = x + halfGrowthX
    end
    if point:find("TOP") then
        y = y + halfGrowthY
    elseif point:find("BOTTOM") then
        y = y - halfGrowthY
    end
    frame:ClearAllPoints()
    frame:SetPoint(point, relativeTo, relativePoint, x, y)
    return true
end

function timeline.SetTrackWidth(width)
    local oldWidth, oldHeight = frame:GetSize()
    state.trackWidth = width
    applyFrameSize()
    if keepFrameCentre(oldWidth, oldHeight) and timeline.onFrameMoved then
        timeline.onFrameMoved()
    end
    notifyGeometryChanged()
end

function timeline.SetWaitingGap(percent)
    state.waitingGap = percent
    notifyGeometryChanged()
end

function timeline.SetWaitingTransparency(percent)
    state.waitingTransparency = percent
    for _, event in pairs(state.activeEvents) do
        event.flow.dimmed = nil
    end
end

function timeline.WaitingTransparency()
    return state.waitingTransparency
end

function timeline.SetTimeLimit(seconds)
    state.timeLimit = seconds
end

function timeline.SetOrientation(value)
    state.orientation = value
    timeline.applyToAllEvents()
    local direction = state.direction
    local secondOption = direction == DIRECTION_BOTTOM or direction == DIRECTION_RIGHT
    if value == ORIENTATION_HORIZONTAL then
        state.direction = secondOption and DIRECTION_RIGHT or DIRECTION_LEFT
    else
        state.direction = secondOption and DIRECTION_BOTTOM or DIRECTION_TOP
    end
    applyFrameSize()
    notifyGeometryChanged()
end

function timeline.SetDirection(value)
    local turned = state.direction ~= value
    state.direction = value
    if turned then
        timeline.restartWaitingEvents()
    end
    notifyGeometryChanged()
end

function timeline.EntersFromStart()
    return state.direction == DIRECTION_TOP or state.direction == DIRECTION_RIGHT
end

function timeline.IconSize()
    return state.iconBaseSize
end

function timeline.EndReach()
    local info = C_Texture.GetAtlasInfo(timeline.DIVIDER_ATLAS)
    return ns.endReach.Of(timeline.currentIconSize(), info and info.width, info and info.height)
end

function timeline.SetEventAppearance(sizePixels, zoomPercent)
    state.iconBaseSize = sizePixels
    state.iconZoom = zoomPercent
    timeline.applyToAllEvents()
    for _, event in pairs(state.activeEvents) do
        ns.eventStyle.RefreshOverlays(event)
    end
    notifyGeometryChanged()
end

function timeline.SetEventScale(percent)
    ns.eventStyle.SetScale(percent / 100)
    timeline.applyToAllEvents()
    notifyGeometryChanged()
end
