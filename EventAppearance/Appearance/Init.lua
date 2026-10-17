local addonName, ns = ...

local timeline = ns.timeline
local media = ns.media

local appearance = {}
ns.appearance = appearance

appearance.TEXT_ELEMENTS = { "name", "cooldown" }
appearance.ICON_SIZE_MIN = 16
appearance.ICON_SIZE_MAX = 64
appearance.SMALL_ICON_SIZE_MIN = 8
appearance.ROLE_SIZE_MAX = appearance.ICON_SIZE_MAX / 2
appearance.SIZE_LIMITS = {
    icon = { appearance.ICON_SIZE_MIN, appearance.ICON_SIZE_MAX },
    debuff = { appearance.SMALL_ICON_SIZE_MIN, appearance.ICON_SIZE_MAX },
    danger = { appearance.SMALL_ICON_SIZE_MIN, appearance.ICON_SIZE_MAX },
    roles = { appearance.SMALL_ICON_SIZE_MIN, appearance.ROLE_SIZE_MAX },
}

appearance.BACKGROUND_OF = { name = "nameBackground" }

local COOLDOWN_DEFAULT_SIZE = 26
local NAME_DEFAULT_SIZE = 20
local NAME_DEFAULT_SHIFT_X = 8

local function textDefaults(size)
    return {
        font = media.DEFAULT_FONT,
        size = size,
        outline = "OUTLINE",
        monochrome = false,
        slug = false,
        hidden = false,
        shadow = false,
        useEventColor = false,
        color = { r = 1, g = 1, b = 1, a = 1 },
        mirrored = false,
        shiftX = 0,
        shiftY = 0,
        anchor = "CENTER",
    }
end

local nameDefaults = textDefaults(NAME_DEFAULT_SIZE)
nameDefaults.shiftX = NAME_DEFAULT_SHIFT_X

appearance.DEFAULTS = {
    icon = {
        size = timeline.DEFAULT_ICON_SIZE,
        zoom = timeline.DEFAULT_ICON_ZOOM,
    },
    border = {
        style = "BLIZZARD",
        thickness = 1,
        color = { r = 1, g = 1, b = 1, a = 1 },
        useEventColor = true,
    },
    name = nameDefaults,
    nameBackground = {
        enabled = false,
        texture = media.DEFAULT_TEXT_BACKGROUND,
        color = { r = 1, g = 1, b = 1, a = 0.3 },
        offsetX = 10,
        offsetY = 10,
        raise = 0,
        onTop = false,
        borderTexture = media.NONE,
        borderColor = { r = 1, g = 1, b = 1, a = 1 },
        borderOffset = 0,
        borderThickness = 1,
    },
    cooldown = textDefaults(COOLDOWN_DEFAULT_SIZE),
    debuff = { enabled = true, size = 18, anchor = "BOTTOMRIGHT", offsetX = -2, offsetY = 2 },
    danger = { enabled = true, size = 24, anchor = "TOP", offsetX = 0, offsetY = 0 },
    dangerGlow = { enabled = true, color = { r = 1, g = 196 / 255, b = 68 / 255, a = 1 } },
    states = {
        marks = true,
        signs = true,
        tintedFrame = false,
        captions = true,
        brackets = true,
        pausedColor = ns.statusMark.GameColor(ns.statusMark.MODE_PAUSED),
        queuedColor = ns.statusMark.GameColor(ns.statusMark.MODE_QUEUED),
        blockedColor = ns.statusMark.GameColor(ns.statusMark.TEXT_BLOCKED),
    },
    trail = { enabled = true },
    animations = { intro = true, arrival = true, fade = true, outro = true, shift = true, speed = 100 },
    roles = {
        enabled = true,
        size = 18,
        anchor = "RIGHT",
        offsetX = 14,
        offsetY = 0,
        gap = ns.eventIndicators.ROLE_GAP,
        vertical = true,
    },
}

appearance.OVERLAY_FIELDS = {
    debuff = { "enabled", "size", "anchor", "offsetX", "offsetY" },
    danger = { "enabled", "size", "anchor", "offsetX", "offsetY" },
    roles = { "enabled", "size", "anchor", "offsetX", "offsetY", "gap", "vertical" },
}
