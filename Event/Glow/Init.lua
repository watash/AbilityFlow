local addonName, ns = ...

local glow = {}
ns.glow = glow

glow.PIXEL = "Pixel"
glow.AUTOCAST = "Autocast"
glow.CLASSIC = "Classic"
glow.TYPES = { "Thin", "Medium", glow.PIXEL, glow.AUTOCAST }
glow.TIMER_TYPE = "Medium"
local GLOW_FRAME_LEVEL = 1
glow.FRAME_LEVEL = GLOW_FRAME_LEVEL
glow.DEFAULT_LINES = 8
glow.DEFAULT_LENGTH = 15
glow.DEFAULT_SPARKS = 4
glow.DEFAULT_THICKNESS = 1
glow.BACKING_AUTO, glow.BACKING_ALWAYS, glow.BACKING_NEVER = "AUTO", "ALWAYS", "NEVER"
glow.FULL_SHARE = 100
glow.RING_GLOWS = { [glow.PIXEL] = true, [glow.AUTOCAST] = true }
