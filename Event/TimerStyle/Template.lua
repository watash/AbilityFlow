local addonName, ns = ...

local same = ns.tables.Same
local timerStyle = ns.timerStyle

function timerStyle.newTemplate()
    return {
        color = nil,
        textScale = 100,
        nameScale = timerStyle.NAME_SCALE_MIN,
        nameBackgroundUseColor = false,
        tenths = false,
        useGlow = false,
        glowType = ns.glow.TIMER_TYPE,
        glowScale = 100,
        glowSpeeds = {},
        glowReversed = {},
        glowLines = ns.glow.DEFAULT_LINES,
        glowParticles = ns.glow.DEFAULT_SPARKS,
        glowLength = ns.glow.DEFAULT_LENGTH,
        glowThickness = ns.glow.DEFAULT_THICKNESS,
        glowSparkSize = ns.glow.FULL_SHARE,
        glowShapes = {},
        glowBacking = ns.glow.BACKING_AUTO,
        glowOwn = {},
        glowUseCustomColor = false,
        glowColor = { r = 1, g = 1, b = 1, a = 1 },
        pulse = false,
        pulseStrength = timerStyle.PULSE_STRENGTH_DEFAULT,
        pulseScaleText = false,
        pulseIndicators = true,
        pulseRoles = false,
        flash = false,
    }
end

function timerStyle.Sanitize(data)
    local clean = { enabled = data.enabled ~= false, seconds = {}, templates = {}, order = {}, nextID = 1 }
    local templates = type(data.templates) == "table" and data.templates or {}
    for _, templateID in ipairs(type(data.order) == "table" and data.order or {}) do
        local template = templates[templateID]
        if type(templateID) == "number" and type(template) == "table" and not clean.templates[templateID]
            and #clean.order < timerStyle.MAX_TEMPLATES then
            local made = timerStyle.newTemplate()
            for key, default in pairs(made) do
                if ns.profiles.Matches(template[key], default) then
                    made[key] = template[key]
                end
            end
            if ns.profiles.Matches(template.color, { r = 0, g = 0, b = 0 }) then
                made.color = template.color
            end
            if type(template.colorOverride) == "boolean" then
                made.colorOverride = template.colorOverride
            end
            if template.timerMode == timerStyle.TIMER_SHOW or template.timerMode == timerStyle.TIMER_HIDE then
                made.timerMode = template.timerMode
            elseif template.showTimer == false then
                made.timerMode = timerStyle.TIMER_HIDE
            end
            made.glowBacking = ns.glow.BackingMode(made)
            if type(template.iconSpell) == "number" then
                made.iconSpell = template.iconSpell
            end
            clean.templates[templateID] = made
            table.insert(clean.order, templateID)
            clean.nextID = math.max(clean.nextID, templateID + 1)
        end
    end
    if type(data.nextID) == "number" then
        clean.nextID = math.max(clean.nextID, data.nextID)
    end
    local seconds = type(data.seconds) == "table" and data.seconds or {}
    for second = 1, timerStyle.SECONDS do
        if clean.templates[seconds[second]] then
            clean.seconds[second] = seconds[second]
        end
    end
    return clean
end

function timerStyle.NameScaleOf(template)
    local scale = template and template.nameScale or timerStyle.NAME_SCALE_MIN
    return math.min(math.max(scale, timerStyle.NAME_SCALE_MIN), timerStyle.NAME_SCALE_MAX)
end

function timerStyle.TimerModeOf(template)
    if not template then
        return timerStyle.TIMER_DEFAULT
    end
    if template.timerMode then
        return template.timerMode
    end
    return template.showTimer == false and timerStyle.TIMER_HIDE or timerStyle.TIMER_DEFAULT
end

function timerStyle.CountdownColor(template)
    if template and template.color and template.colorOverride ~= false then
        return template.color
    end
    return nil
end

local PAGE_FIELDS = {
    TIMER = { "color", "colorOverride", "timerMode", "showTimer", "textScale", "tenths" },
    NAME = { "nameScale", "nameBackground", "nameBackgroundColor", "nameBackgroundUseColor" },
    EFFECTS = { "pulse", "pulseStrength", "pulseScaleText", "pulseIndicators", "pulseRoles", "flash" },
}

local GLOW_COMMON_FIELDS = { "glowUseCustomColor", "glowColor", "glowBacking" }

function timerStyle.PageCanReset(page)
    return PAGE_FIELDS[page] ~= nil or page == "GLOW"
end

local function shownGlow(template)
    if ns.glow.ShownType and ns.appearance then
        return ns.glow.ShownType(template.glowType, ns.appearance.Get("border", "style") == "SOLID")
    end
    return template.glowType or ns.glow.TIMER_TYPE
end

local function resetGlow(template)
    local fresh = timerStyle.newTemplate()
    for _, key in ipairs(GLOW_COMMON_FIELDS) do
        template[key] = fresh[key]
    end
    local kind = shownGlow(template)
    local own = {}
    for key, field in pairs(ns.glow.OWN_FIELDS) do
        own[key] = fresh[field]
    end
    template.glowOwn = template.glowOwn or {}
    template.glowOwn[kind] = own
    for _, field in ipairs({ "glowSpeeds", "glowReversed", "glowShapes" }) do
        template[field] = template[field] or {}
        template[field][kind] = nil
    end
end

function timerStyle.PageIsDefault(templateID, page)
    local template = timerStyle.Saved().templates[templateID]
    if not template or not timerStyle.PageCanReset(page) then
        return true
    end
    local fresh = timerStyle.newTemplate()
    if page ~= "GLOW" then
        for _, key in ipairs(PAGE_FIELDS[page]) do
            if not same(template[key], fresh[key]) then
                return false
            end
        end
        return true
    end
    for _, key in ipairs(GLOW_COMMON_FIELDS) do
        if not same(template[key], fresh[key]) then
            return false
        end
    end
    local kind = shownGlow(template)
    local own = template.glowOwn and template.glowOwn[kind] or {}
    for key, field in pairs(ns.glow.OWN_FIELDS) do
        local value = own[key]
        if value == nil then
            value = template[field]
        end
        if not same(value, fresh[field]) then
            return false
        end
    end
    local speed = template.glowSpeeds and template.glowSpeeds[kind]
    local reversed = template.glowReversed and template.glowReversed[kind]
    local shape = template.glowShapes and template.glowShapes[kind]
    return (speed == nil or speed == ns.glow.SPEED_DEFAULT) and not reversed and (shape == nil or shape == "square")
end

function timerStyle.ResetPage(templateID, page)
    local template, fields = timerStyle.Saved().templates[templateID], PAGE_FIELDS[page]
    if template and page == "GLOW" then
        resetGlow(template)
        return
    end
    if not template or not fields then
        return
    end
    local fresh = timerStyle.newTemplate()
    for _, key in ipairs(fields) do
        template[key] = fresh[key]
    end
end
