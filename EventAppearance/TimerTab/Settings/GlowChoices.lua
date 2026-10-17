local addonName, ns = ...

local ipairs = ipairs
local table = table
local L = ns.L
local settings = ns.timerTab.settings

local choices = {}
settings.glowChoices = choices

local PACK_NAME_COLOR = "ff7fb2ff"

function choices.GlowName(glowType)
    return L["GLOW_NAME_" .. glowType:upper()] or glowType
end

function choices.TypeItems(flatBorder)
    local items = {}
    for _, name in ipairs(ns.glow.TYPES) do
        if not (flatBorder and ns.glow.FrameOnly(name)) then
            table.insert(items, { text = choices.GlowName(name), value = name })
        end
    end
    for _, name in ipairs(ns.glow.PackNames()) do
        table.insert(items, { text = ns.text.Colored(name, PACK_NAME_COLOR), value = name })
    end
    return items
end

function choices.ShapeName(shape)
    return L["GLOW_SHAPE_" .. shape:upper()] or shape
end

function choices.ShapeItems(glowType)
    local items = {}
    for _, shape in ipairs(ns.glow.ShapesOf(glowType)) do
        table.insert(items, { text = choices.ShapeName(shape), value = shape })
    end
    return items
end
