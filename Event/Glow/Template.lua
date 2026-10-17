local addonName, ns = ...

local glow = ns.glow

local FULL_SIZE = glow.FULL_SHARE

local PIXEL_LINE_LEAST = 1

local FLAT_GROWTH = { [glow.CLASSIC] = 1.3, Thin = 1.1, Medium = 1.2 }
local CLASSIC_BORDER_GROWTH = 1.4
local CLASSIC_BORDER_CLEARANCE = 1.2
local PIXEL_FRAME_GROWTH = 1.05
local FRAME_GROWTH = { [glow.CLASSIC] = FLAT_GROWTH[glow.CLASSIC], [glow.PIXEL] = PIXEL_FRAME_GROWTH }

local RING_EASING = 0.2

local function easedRingSize(size)
    local over = size - FULL_SIZE
    if over <= 0 then
        return size
    end
    local limit = ns.timerStyle.GLOW_SCALE_MAX - FULL_SIZE
    return FULL_SIZE + over * (1 - RING_EASING * over / limit)
end

glow.SPEED_DEFAULT = 5
local SPEED_STEPS_PER_DOUBLING = 2
local CLASSIC_FREQUENCY = 0.25
local PIXEL_FREQUENCY = 0.25
local AUTOCAST_FREQUENCY = 0.125
local FLIPBOOK_CYCLE = 1

local OWN_FIELDS = {
    scale = "glowScale", lines = "glowLines", length = "glowLength", thickness = "glowThickness",
    particles = "glowParticles", sparkSize = "glowSparkSize",
}

glow.OWN_FIELDS = OWN_FIELDS

function glow.Own(template, glowType, key)
    local own = template.glowOwn and template.glowOwn[glowType]
    if own and own[key] ~= nil then
        return own[key]
    end
    return template[OWN_FIELDS[key]]
end

function glow.SetOwn(template, glowType, key, value)
    template.glowOwn = template.glowOwn or {}
    template.glowOwn[glowType] = template.glowOwn[glowType] or {}
    template.glowOwn[glowType][key] = value
end

function glow.FlatGrowth(glowType, holderSide)
    local growth = FLAT_GROWTH[glowType]
    if growth and glowType == glow.CLASSIC and holderSide and holderSide > 0 then
        growth = CLASSIC_BORDER_GROWTH + 2 * CLASSIC_BORDER_CLEARANCE / holderSide
    end
    return growth
end

local BACKING_NEAR = 0.6
local BACKING_BACKGROUND = { r = 0.1, g = 0.1, b = 0.1 }
local LIGHT_RED, LIGHT_GREEN, LIGHT_BLUE = 0.299, 0.587, 0.114
local LIGHT_LINES = 0.5

function glow.BackingMode(template)
    local mode = template.glowBacking
    if mode == glow.BACKING_ALWAYS or mode == glow.BACKING_NEVER then
        return mode
    end
    return glow.BACKING_AUTO
end

function glow.BackingFor(mode, lines, ground)
    if mode == glow.BACKING_NEVER then
        return nil
    end
    local lightness = LIGHT_RED * lines.r + LIGHT_GREEN * lines.g + LIGHT_BLUE * lines.b
    local shade = lightness > LIGHT_LINES and "dark" or "light"
    if mode == glow.BACKING_ALWAYS then
        return shade
    end
    ground = ground or BACKING_BACKGROUND
    local red, green, blue = lines.r - ground.r, lines.g - ground.g, lines.b - ground.b
    if math.sqrt(red * red + green * green + blue * blue) < BACKING_NEAR then
        return shade
    end
    return nil
end

function glow.ApplyBacking(options, glowType, template, color, borderColor, onFrame)
    if glowType == glow.PIXEL and not onFrame then
        options.shadow = glow.BackingFor(glow.BackingMode(template), color, borderColor)
    end
end

function glow.TimerGlow(template, flatBorder, noFrame, holderSide)
    local glowType = glow.ShownType(template.glowType, flatBorder)
    local size = math.min(math.max(glow.Own(template, glowType, "scale") or FULL_SIZE, ns.timerStyle.GLOW_SCALE_MIN),
        ns.timerStyle.GLOW_SCALE_MAX)
    if glow.RING_GLOWS[glowType] then
        size = easedRingSize(size)
    end
    local growth
    if noFrame then
        growth = glow.FlatGrowth(glowType, holderSide)
    else
        growth = FRAME_GROWTH[glowType]
    end
    if growth then
        size = size * growth
    end
    local options = { size = size }
    local steps = math.max(template.glowSpeeds and template.glowSpeeds[glowType] or glow.SPEED_DEFAULT,
        ns.timerStyle.GLOW_SPEED_MIN)
    local direction = template.glowReversed and template.glowReversed[glowType] and -1 or 1
    local speed = 2 ^ ((steps - glow.SPEED_DEFAULT) / SPEED_STEPS_PER_DOUBLING)
    if glowType == glow.CLASSIC then
        options.frequency = CLASSIC_FREQUENCY * speed
        options.speed = FLIPBOOK_CYCLE / speed
    elseif glowType == glow.PIXEL then
        options.frequency = PIXEL_FREQUENCY * speed * direction
        options.lines = math.min(glow.Own(template, glowType, "lines") or glow.DEFAULT_LINES, ns.timerStyle.GLOW_LINES_MAX)
        options.lengthShare = (glow.Own(template, glowType, "length") or glow.DEFAULT_LENGTH) / glow.FULL_SHARE
        options.thickness = math.max(glow.Own(template, glowType, "thickness") or glow.DEFAULT_THICKNESS, PIXEL_LINE_LEAST)
    elseif glowType == glow.AUTOCAST then
        options.particles = math.min(glow.Own(template, glowType, "particles") or glow.DEFAULT_SPARKS,
            ns.timerStyle.GLOW_SPARKS_MAX)
        options.scale = math.min(glow.Own(template, glowType, "sparkSize") or glow.FULL_SHARE, ns.timerStyle.GLOW_SPARK_SIZE_MAX)
            / glow.FULL_SHARE
        options.frequency = AUTOCAST_FREQUENCY * speed * direction
    elseif glowType == "Thin" or glowType == "Medium" then
        options.desaturated = true
        options.speed = FLIPBOOK_CYCLE / speed
    elseif glow.IsPack(glowType) then
        options.loopDuration = FLIPBOOK_CYCLE / speed
        options.shape = template.glowShapes and template.glowShapes[glowType]
    end
    return glowType, options
end

function glow.ScaleToEvents(glowType, options, scale)
    if glowType == glow.PIXEL then
        options.thickness = math.max(math.floor(options.thickness * scale + 0.5), PIXEL_LINE_LEAST)
    elseif glowType == glow.AUTOCAST then
        options.scale = options.scale * scale
    end
end
