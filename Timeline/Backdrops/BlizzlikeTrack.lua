local addonName, ns = ...

local timeline = ns.timeline

local track = timeline.CreateBlizzlikeBackdrop(timeline.frame)
timeline.onBackgroundColorChanged = track.Tint

function timeline.IsBlizzlikeBackdrop()
    return track.IsEnabled()
end

function timeline.RefreshBackdropReach()
    if timeline.onBackdropReachChanged then
        local path, offset, thickness = timeline.GetBorder()
        local border = (path and thickness > 0) and math.max(offset, 0) or 0
        local along = math.max(timeline.DIVIDER_GAP, timeline.GetPlainEndReach()) + border
        if timeline.GetOrientation() == timeline.ORIENTATION_HORIZONTAL then
            timeline.onBackdropReachChanged(along, border)
        else
            timeline.onBackdropReachChanged(border, along)
        end
    end
end

local function layout()
    track.Layout()
    timeline.RefreshBackdropReach()
end

function timeline.SetBlizzlikeBackdrop(value)
    track.SetEnabled(value)
    timeline.SetBorderSuppressed(value)
    layout()
    timeline.PlaceTicks()
end

local previousGeometry = timeline.onGeometryChanged
timeline.onGeometryChanged = function()
    if previousGeometry then
        previousGeometry()
    end
    layout()
end
layout()
