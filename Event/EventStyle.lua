local addonName, ns = ...

local CreateFrame = CreateFrame
local UIParent = UIParent
local ipairs = ipairs
local pairs = pairs
local issecretvalue = issecretvalue

local eventStyle = {}
ns.eventStyle = eventStyle

eventStyle.TEXT_KEYS = { "name", "cooldown" }

local defaultFontPath, defaultFontSize, defaultFontFlags
do
    local probe = CreateFrame("Frame", nil, UIParent):CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    defaultFontPath, defaultFontSize, defaultFontFlags = probe:GetFont()
    probe:Hide()
end
eventStyle.DEFAULT_TEXT_FONT_SIZE = defaultFontSize

local function newTextStyle()
    return {
        path = defaultFontPath,
        size = defaultFontSize,
        outline = defaultFontFlags or "",
        shadow = false,
        color = { r = 1, g = 1, b = 1, a = 1 },
        enabled = true,
        useEventColor = false,
        backgroundPath = nil,
        backgroundColor = { r = 1, g = 1, b = 1, a = 1 },
        backgroundOffsetX = 0,
        backgroundOffsetY = 0,
        backgroundRaise = 0,
        backgroundOnTop = false,
        backgroundBorderPath = nil,
        backgroundAnyPath = nil,
        backgroundAnyBorderPath = nil,
        backgroundBorderColor = { r = 1, g = 1, b = 1, a = 1 },
        backgroundBorderOffset = 0,
        backgroundBorderThickness = 1,
        mirrored = false,
        shiftX = 0,
        shiftY = 0,
        anchor = "CENTER",
    }
end

local state = {
    scale = 1,
    border = { style = "NONE", thickness = 1, color = { r = 1, g = 1, b = 1, a = 1 } },
    texts = {},
    overlays = {
        debuff = { enabled = false, size = 1, anchor = "BOTTOMRIGHT", offsetX = 0, offsetY = 0 },
        danger = { enabled = false, size = 1, anchor = "TOP", offsetX = 0, offsetY = 0 },
        roles = { enabled = false, size = 1, anchor = "RIGHT", offsetX = 0, offsetY = 0, gap = 0, vertical = false },
    },
    defaultFontPath = defaultFontPath,
}
for _, key in ipairs(eventStyle.TEXT_KEYS) do
    state.texts[key] = newTextStyle()
end
eventStyle.state = state

function eventStyle.Scale()
    return state.scale
end

function eventStyle.SetScale(fraction)
    state.scale = fraction
end

function eventStyle.ShowName(event, shown)
    event.nameHolder:SetShown(shown)
    event.nameBackdrop:SetShown(shown)
end

function eventStyle.SetBorder(style, thickness, color, typeFrames)
    local border = state.border
    border.style = style
    border.thickness = thickness
    border.typeFrames = typeFrames ~= false
    border.color.r, border.color.g, border.color.b, border.color.a = color.r, color.g, color.b, color.a
end

function eventStyle.SetText(key, style)
    local current = state.texts[key]
    for field, value in pairs(style) do
        current[field] = value
    end
    current.backgroundPath = style.backgroundPath
    current.backgroundBorderPath = style.backgroundBorderPath
    current.backgroundAnyPath = style.backgroundAnyPath
    current.backgroundAnyBorderPath = style.backgroundAnyBorderPath
    if key == "name" and ns.timeline and ns.timeline.PlaceTicks then
        ns.timeline.PlaceTicks()
    end
end

function eventStyle.SetOverlay(kind, settings)
    local current = state.overlays[kind]
    for field, value in pairs(settings) do
        current[field] = value
    end
end

function eventStyle.DecorateName(event)
    event.nameAnchor = CreateFrame("Frame", nil, event)
    event.nameAnchor:SetAllPoints()
    event.nameAnchor:EnableMouse(false)
    event.texts.name = event.nameHolder:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    event.nameBackdrop = CreateFrame("Frame", nil, event)
    event.nameBackdrop:EnableMouse(false)
    ns.eventFrame.PlaceBackdrop(event)
    event.textBackgrounds = event.textBackgrounds or {}
    event.textBackgrounds.name = event.nameBackdrop:CreateTexture(nil, "BACKGROUND")
end

function eventStyle.Decorate(event)
    event.debuffBorders = {}
    for index in ipairs(ns.debuff.TYPES) do
        event.debuffBorders[index] = ns.eventFrame.NewRing(event.container, 1)
    end

    eventStyle.DecorateName(event)

    event.textBackgrounds.cooldown = event.cooldownHolder:CreateTexture(nil, "BACKGROUND")

    event.dangerIndicator = event.dangerHolder:CreateTexture(nil, "OVERLAY")
    ns.eventIndicators.Smooth(event.dangerIndicator)
    event.roleIndicators = {}
    for slot = 1, ns.eventIndicators.ROLE_SLOTS do
        event.roleIndicators[slot] = event.rolesHolder:CreateTexture(nil, "OVERLAY")
        ns.eventIndicators.Smooth(event.roleIndicators[slot])
    end
end

function eventStyle.Apply(event)
    eventStyle.ApplyBorder(event)
    for _, key in ipairs(eventStyle.TEXT_KEYS) do
        eventStyle.ApplyText(event, key)
    end
    eventStyle.PlaceOverlays(event)
end

function eventStyle.Assign(event, eventInfo)
    event.eventID = eventInfo.id
    local mask = eventInfo.icons
    event.debuffEntry = nil
    event.debuffSecret = issecretvalue(mask)
    if not event.debuffSecret and mask and mask ~= 0 then
        event.debuffEntry = ns.debuff.FindType(mask)
    end
    for _, key in ipairs(eventStyle.TEXT_KEYS) do
        eventStyle.ApplyTextColour(event, key)
    end
    eventStyle.AssignBorderArt(event)
    event.debuffBorderShown = true
    eventStyle.ApplyBorder(event)
    eventStyle.AssignOverlayArt(event)
    eventStyle.PlaceOverlays(event)
end

function eventStyle.RefreshOverlays(event)
    eventStyle.AssignOverlayArt(event)
    eventStyle.PlaceOverlays(event)
end
