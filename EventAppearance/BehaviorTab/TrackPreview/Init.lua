local addonName, ns = ...

local trackPreview = {}
ns.appearanceTrackPreview = trackPreview

trackPreview.ICON_SIZE = 56
local TRACK_EDGE_MARGIN = 24
trackPreview.TRACK_CENTER_X = trackPreview.ICON_SIZE / 2 + TRACK_EDGE_MARGIN
trackPreview.MIN_TRACK_LENGTH = 100
trackPreview.LINE_REFERENCE_SIZE = 45
trackPreview.DIVIDER_ALPHA = 0.9

trackPreview.ACTOR_COUNT = 2
trackPreview.RATE = 1.6
trackPreview.TWIN_DELAY_SECONDS = 1
trackPreview.TWIN_ENTER_SECONDS = 0.4

trackPreview.state = {
    box = nil,
    actors = {},
    icons = {},
    halves = {},
    dividers = {},
    zoneLabels = {},
    whiteFill = nil,
    whiteToggle = nil,
    plainBackground = nil,
    plainBorder = nil,
    laidOutBlizzlike = nil,
    paused = false,
    sceneTime = 0,
    direction = 1,
    previewRatio = 1,
    trackLength = trackPreview.MIN_TRACK_LENGTH,
    trackTop = 0,
    starts = {},
    remainingAtStart = {},
    totalSeconds = 0,
    lagSeconds = 0,
    roundSeconds = 0,
    lineFade = 0,
}
