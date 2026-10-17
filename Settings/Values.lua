local addonName, ns = ...

local same = ns.tables.Same
local type = type
local pairs = pairs
local CopyTable = CopyTable

local timeline = ns.timeline
local media = ns.media
local store = ns.store

local values = {}
ns.values = values

local DEFAULTS = {
    timelinePositions = nil,
    trackLengths = timeline.DEFAULT_TRACK_LENGTH,
    trackWidths = timeline.TRACK_WIDTH,
    trackOrientations = timeline.ORIENTATION_VERTICAL,
    trackDirections = 1,
    iconScales = 100,
    waitingGaps = timeline.DEFAULT_WAITING_GAP,
    waitingTransparencies = timeline.DEFAULT_WAITING_TRANSPARENCY,
    overallTransparencies = timeline.DEFAULT_OVERALL_TRANSPARENCY,
    tooltipAnchors = timeline.TOOLTIP_HIDDEN,
    markStyles = timeline.MARK_ICON_TEXT,
    markScales = 100,
    markSteps = timeline.DEFAULT_MARK_STEP,
    blizzlikeBackdrops = true,
    backgroundTextures = media.DEFAULT_BACKGROUND,
    backgroundColors = { r = 0, g = 0, b = 0, a = 0.7 },
    borderTextures = media.DEFAULT_BORDER,
    borderColors = { r = 1, g = 1, b = 1, a = 1 },
    borderOffsets = 0,
    borderThicknesses = 1,
}

local LOOK_KEYS = {
    iconScales = true,
    waitingGaps = true,
    waitingTransparencies = true,
    overallTransparencies = true,
    tooltipAnchors = true,
    markStyles = true,
    markScales = true,
    markSteps = true,
    blizzlikeBackdrops = true,
    backgroundTextures = true,
    backgroundColors = true,
    borderTextures = true,
    borderColors = true,
    borderOffsets = true,
    borderThicknesses = true,
}
values.LOOK_KEYS = LOOK_KEYS

local RANGES = {
    trackLengths = { 300, 1000 },
    trackWidths = { 1, 200 },
    iconScales = { 50, 200 },
    waitingGaps = { 0, 100 },
    waitingTransparencies = { 0, 100 },
    overallTransparencies = { 0, 100 },
    markScales = { 50, 150 },
    borderOffsets = { -32, 32 },
    borderThicknesses = { 0, 64 },
}
local CHOICES = {
    trackOrientations = { timeline.ORIENTATION_VERTICAL, timeline.ORIENTATION_HORIZONTAL },
    trackDirections = { 1, 2 },
    tooltipAnchors = { timeline.TOOLTIP_HIDDEN, timeline.TOOLTIP_DEFAULT, timeline.TOOLTIP_CURSOR },
    markSteps = timeline.MARK_STEPS,
    markStyles = { timeline.MARK_NONE, timeline.MARK_ICON, timeline.MARK_ICON_TEXT, timeline.MARK_BAR,
        timeline.MARK_BAR_TEXT, timeline.MARK_ICON_BAR, timeline.MARK_ALL },
}
local POSITION_KEY = "timelinePositions"
local POSITION_POINTS = { "TOPLEFT", "TOP", "TOPRIGHT", "LEFT", "CENTER", "RIGHT", "BOTTOMLEFT", "BOTTOM", "BOTTOMRIGHT" }
local POSITION_LIMIT = 4000

values.Keys = {
    "timelinePositions",
    "trackLengths",
    "trackWidths",
    "trackOrientations",
    "trackDirections",
    "iconScales",
    "waitingGaps",
    "waitingTransparencies",
    "overallTransparencies",
    "tooltipAnchors",
    "markStyles",
    "markScales",
    "markSteps",
    "blizzlikeBackdrops",
    "backgroundTextures",
    "backgroundColors",
    "borderTextures",
    "borderColors",
    "borderOffsets",
    "borderThicknesses",
}

function values.RangeMin(key)
    return RANGES[key][1]
end

function values.RangeMax(key)
    return RANGES[key][2]
end

function values.Snapshot(layoutName, withoutLook)
    local snapshot = {}
    for _, key in ipairs(values.Keys) do
        if not (withoutLook and LOOK_KEYS[key]) then
            local value = values.Get(key, layoutName)
            if value == nil then
                value = false
            end
            snapshot[key] = type(value) == "table" and CopyTable(value) or value
        end
    end
    return snapshot
end

local function sanitizePosition(value)
    if value == false then
        return false
    end
    if not ns.profiles.Matches(value, { point = "", x = 0, y = 0 }) then
        return nil
    end
    for _, point in ipairs(POSITION_POINTS) do
        if point == value.point then
            return {
                point = point,
                x = math.min(math.max(value.x, -POSITION_LIMIT), POSITION_LIMIT),
                y = math.min(math.max(value.y, -POSITION_LIMIT), POSITION_LIMIT),
            }
        end
    end
    return nil
end

function values.Sanitize(track)
    local clean = {}
    for _, key in ipairs(values.Keys) do
        local value = track[key]
        if key == POSITION_KEY then
            clean[key] = sanitizePosition(value)
        elseif ns.profiles.Matches(value, DEFAULTS[key]) then
            local range, choices = RANGES[key], CHOICES[key]
            if range then
                clean[key] = math.min(math.max(value, range[1]), range[2])
            elseif choices then
                for _, choice in ipairs(choices) do
                    if choice == value then
                        clean[key] = value
                    end
                end
            else
                clean[key] = type(value) == "table" and CopyTable(value) or value
            end
        end
    end
    return clean
end

function values.SanitizeLook(look)
    local clean = {}
    for key, value in pairs(values.Sanitize(look)) do
        if LOOK_KEYS[key] then
            clean[key] = value
        end
    end
    return clean
end

function values.Import(layoutName, track)
    for key, value in pairs(values.Sanitize(track)) do
        values.Set(key, layoutName, value or nil)
    end
end

function values.IsDefault(layoutName)
    for _, key in ipairs(values.Keys) do
        if key ~= POSITION_KEY and not same(values.Get(key, layoutName), DEFAULTS[key]) then
            return false
        end
    end
    return true
end

function values.Default(key)
    return DEFAULTS[key]
end

function values.Get(key, layoutName)
    if LOOK_KEYS[key] then
        local look = ns.profiles.Current().look
        local value = look and look[key]
        if value == nil then
            return DEFAULTS[key]
        end
        return value
    end
    return store.Get(key, layoutName, DEFAULTS[key])
end

function values.Raw(key, layoutName)
    if LOOK_KEYS[key] then
        local look = ns.profiles.Current().look
        return look and look[key]
    end
    return store.Raw(key, layoutName)
end

function values.Set(key, layoutName, value)
    if LOOK_KEYS[key] then
        local profile = ns.profiles.Current()
        profile.look = profile.look or {}
        if value == nil then
            value = DEFAULTS[key]
        end
        profile.look[key] = type(value) == "table" and CopyTable(value) or value
        return
    end
    store.Set(key, layoutName, value)
end

ns.profiles.OnComplete(function(data)
    data.look = data.look or {}
    for key in pairs(LOOK_KEYS) do
        if data.look[key] == nil then
            local default = DEFAULTS[key]
            data.look[key] = type(default) == "table" and CopyTable(default) or default
        end
    end
end)

local DIRECTIONS = {
    [timeline.ORIENTATION_VERTICAL] = { timeline.DIRECTION_TOP, timeline.DIRECTION_BOTTOM },
    [timeline.ORIENTATION_HORIZONTAL] = { timeline.DIRECTION_LEFT, timeline.DIRECTION_RIGHT },
}

function values.Direction(layoutName)
    local orientation = values.Get("trackOrientations", layoutName)
    return DIRECTIONS[orientation][values.Get("trackDirections", layoutName)]
end

function values.BackgroundPath(layoutName)
    local key = values.Get("backgroundTextures", layoutName)
    local path = media.BackgroundPath(key)
    if path == nil and key ~= media.NONE then
        path = timeline.BACKGROUND_TEXTURE_DEFAULT_PATH
    end
    return path
end

function values.ApplyBackground(layoutName)
    local color = values.Get("backgroundColors", layoutName)
    timeline.SetBackgroundTexture(values.BackgroundPath(layoutName))
    timeline.SetBackgroundColor(color.r, color.g, color.b, color.a)
    values.ApplyBorder(layoutName)
end

function values.ApplyBorder(layoutName)
    local color = values.Get("borderColors", layoutName)
    timeline.SetBorder(media.BorderPath(values.Get("borderTextures", layoutName)),
        values.Get("borderOffsets", layoutName), values.Get("borderThicknesses", layoutName),
        color.r, color.g, color.b, color.a)
end

function values.Apply(layoutName)
    timeline.SetOrientation(values.Get("trackOrientations", layoutName))
    timeline.SetDirection(values.Direction(layoutName))
    timeline.SetTrackLength(values.Get("trackLengths", layoutName))
    timeline.SetTrackWidth(values.Get("trackWidths", layoutName))
    values.ApplyLook(layoutName)
end

function values.ApplyLook(layoutName)
    timeline.SetEventScale(values.Get("iconScales", layoutName))
    timeline.SetWaitingGap(values.Get("waitingGaps", layoutName))
    timeline.SetWaitingTransparency(values.Get("waitingTransparencies", layoutName))
    timeline.SetOverallTransparency(values.Get("overallTransparencies", layoutName))
    timeline.SetTooltipAnchor(values.Get("tooltipAnchors", layoutName))
    timeline.SetBlizzlikeBackdrop(values.Get("blizzlikeBackdrops", layoutName))
    timeline.SetMarkStyle(values.Get("markStyles", layoutName))
    timeline.SetMarkScale(values.Get("markScales", layoutName))
    timeline.SetMarkStep(values.Get("markSteps", layoutName))
    values.ApplyBackground(layoutName)
end

ns.profiles.OnChanged(function()
    local layoutName = timeline.ActiveLayoutName()
    if layoutName then
        values.ApplyLook(layoutName)
    end
end)
