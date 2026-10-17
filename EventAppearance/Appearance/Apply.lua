local addonName, ns = ...

local pairs = pairs
local ipairs = ipairs

local timeline = ns.timeline
local appearance = ns.appearance
local BACKGROUND_OF = appearance.BACKGROUND_OF

local function applyText(element)
    local group = BACKGROUND_OF[element]
    local function background(field, fallback)
        if group then
            return appearance.Get(group, field)
        end
        return fallback
    end
    ns.eventStyle.SetText(element, {
        path = appearance.FontPath(element),
        size = appearance.Get(element, "size"),
        outline = appearance.FontFlags(element),
        shadow = appearance.Get(element, "shadow"),
        color = appearance.Get(element, "color"),
        useEventColor = appearance.Get(element, "useEventColor"),
        enabled = not appearance.Get(element, "hidden"),
        backgroundPath = appearance.BackgroundPath(element),
        backgroundColor = background("color", { r = 1, g = 1, b = 1, a = 1 }),
        backgroundOffsetX = background("offsetX", 0),
        backgroundOffsetY = background("offsetY", 0),
        backgroundRaise = background("raise", 0),
        backgroundOnTop = background("onTop", false),
        backgroundBorderPath = appearance.BackgroundBorderPath(element),
        backgroundAnyPath = appearance.BackgroundTexturePath(element),
        backgroundAnyBorderPath = appearance.BackgroundBorderTexturePath(element),
        backgroundBorderColor = background("borderColor", { r = 1, g = 1, b = 1, a = 1 }),
        backgroundBorderOffset = background("borderOffset", 0),
        backgroundBorderThickness = background("borderThickness", 1),
        mirrored = appearance.Get(element, "mirrored"),
        shiftX = appearance.Get(element, "shiftX"),
        shiftY = appearance.Get(element, "shiftY"),
        anchor = appearance.Get(element, "anchor"),
    })
end

function appearance.BorderStyle()
    local style = appearance.Get("border", "style")
    if style == "SOLID" and appearance.Get("border", "useEventColor") then
        return "DEBUFF"
    end
    return style
end

function appearance.Apply()
    ns.eventStyle.SetBorder(appearance.BorderStyle(), appearance.Get("border", "thickness"),
        appearance.Get("border", "color"), appearance.Get("border", "useEventColor"))
    local useEventColor = false
    for _, element in ipairs(appearance.TEXT_ELEMENTS) do
        applyText(element)
        useEventColor = useEventColor or appearance.Get(element, "useEventColor")
    end
    ns.eventColors.SetEnabled(useEventColor, appearance.Get("name", "color"))
    for kind, fields in pairs(appearance.OVERLAY_FIELDS) do
        local settings = {}
        for _, field in ipairs(fields) do
            settings[field] = appearance.Get(kind, field)
        end
        ns.eventStyle.SetOverlay(kind, settings)
    end
    timeline.SetEventAppearance(appearance.Get("icon", "size"), appearance.Get("icon", "zoom"))
    timeline.RefreshDeadlyGlow()
    timeline.SetTrail(appearance.Get("trail", "enabled"))
    timeline.SetAnimations(appearance.Get("animations", "intro"), appearance.Get("animations", "outro"),
        appearance.Get("animations", "shift"), appearance.Get("animations", "arrival"), appearance.Get("animations", "fade"),
        appearance.Get("animations", "speed"))
end

ns.profiles.OnChanged(function()
    appearance.ClearUndo()
    appearance.Notify()
    appearance.Apply()
    timeline.RefreshTimerStyle()
end)
