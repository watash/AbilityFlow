local addonName, ns = ...

local CreateFrame = CreateFrame

local timeline = {}
ns.timeline = timeline

local DEFAULT_TRACK_LENGTH = 550
local TRACK_WIDTH = 58
local DEFAULT_ICON_SIZE = 50
local DEFAULT_ICON_ZOOM = 8
local TRACK_SPAN_SECONDS = 12
local DEFAULT_WAITING_GAP = 15
local DEFAULT_WAITING_TRANSPARENCY = 40
local DEFAULT_OVERALL_TRANSPARENCY = 0
local TIME_LIMIT_UNLIMITED = ns.options.TIME_LIMIT_UNLIMITED
local TOOLTIP_HIDDEN = "hidden"
local TOOLTIP_DEFAULT = "default"
local TOOLTIP_CURSOR = "cursor"
local ORIENTATION_VERTICAL = "VERTICAL"
local ORIENTATION_HORIZONTAL = "HORIZONTAL"
local DIRECTION_TOP = "TOP"
local DIRECTION_BOTTOM = "BOTTOM"
local DIRECTION_LEFT = "LEFT"
local DIRECTION_RIGHT = "RIGHT"
timeline.PHASE_LIVE = "live"
timeline.PHASE_FINISHING = "finishing"
timeline.PHASE_CANCELING = "canceling"
timeline.ZONE_TRACK = "track"
timeline.LANE_TRAIL_TOLERANCE = 1
local PLACE_ENTRY = "entry"
local PLACE_EXIT = "exit"
local INITIAL_OFFSET_X = 410
local INITIAL_OFFSET_Y = 110

timeline.DIVIDER_ATLAS = "combattimeline-cooldown-divider"
timeline.PLACE_ENTRY = PLACE_ENTRY
timeline.PLACE_EXIT = PLACE_EXIT
timeline.DEFAULT_WAITING_GAP = DEFAULT_WAITING_GAP
timeline.DEFAULT_WAITING_TRANSPARENCY = DEFAULT_WAITING_TRANSPARENCY
timeline.DEFAULT_OVERALL_TRANSPARENCY = DEFAULT_OVERALL_TRANSPARENCY
timeline.TIME_LIMIT_UNLIMITED = TIME_LIMIT_UNLIMITED
timeline.TOOLTIP_HIDDEN = TOOLTIP_HIDDEN
timeline.TOOLTIP_DEFAULT = TOOLTIP_DEFAULT
timeline.TOOLTIP_CURSOR = TOOLTIP_CURSOR
timeline.DEFAULT_TRACK_LENGTH = DEFAULT_TRACK_LENGTH
timeline.TRACK_WIDTH = TRACK_WIDTH
timeline.DEFAULT_ICON_SIZE = DEFAULT_ICON_SIZE
timeline.DEFAULT_ICON_ZOOM = DEFAULT_ICON_ZOOM
timeline.TRACK_SPAN_SECONDS = TRACK_SPAN_SECONDS
timeline.ORIENTATION_VERTICAL = ORIENTATION_VERTICAL
timeline.ORIENTATION_HORIZONTAL = ORIENTATION_HORIZONTAL
timeline.DIRECTION_TOP = DIRECTION_TOP
timeline.DIRECTION_BOTTOM = DIRECTION_BOTTOM
timeline.DIRECTION_LEFT = DIRECTION_LEFT
timeline.DIRECTION_RIGHT = DIRECTION_RIGHT
timeline.DEFAULT_TEXT_FONT_SIZE = ns.eventStyle.DEFAULT_TEXT_FONT_SIZE

local state = {
    trackLength = DEFAULT_TRACK_LENGTH,
    trackWidth = TRACK_WIDTH,
    waitingGap = DEFAULT_WAITING_GAP,
    waitingTransparency = DEFAULT_WAITING_TRANSPARENCY,
    tooltipAnchor = TOOLTIP_HIDDEN,
    timeLimit = TIME_LIMIT_UNLIMITED,
    orientation = ORIENTATION_VERTICAL,
    direction = DIRECTION_TOP,
    iconBaseSize = DEFAULT_ICON_SIZE,
    iconZoom = DEFAULT_ICON_ZOOM,
    activeEvents = {},
    activeCount = 0,
    longEvents = {},
    longOrder = {},
    captions = {},
    limitedEvents = {},
    eventPool = {},
}
timeline.state = state

local frame = CreateFrame("Frame", nil, UIParent)
frame:SetPoint("CENTER", UIParent, "CENTER", INITIAL_OFFSET_X, INITIAL_OFFSET_Y)
frame:Hide()
timeline.frame = frame
