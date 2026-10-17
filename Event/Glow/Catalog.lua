local addonName, ns = ...

local orbitGlow = LibStub("LibOrbitGlow-1.0")

local glow = ns.glow

local FRAME_ONLY = { Thin = true, Medium = true }

function glow.EffectiveType(glowType, flatBorder)
    if flatBorder and FRAME_ONLY[glowType] then
        return glow.PIXEL
    end
    return glowType
end

function glow.ShownType(glowType, flatBorder)
    if not glowType or not glow.IsKnown(glowType) then
        glowType = glow.TIMER_TYPE
    end
    return glow.EffectiveType(glowType, flatBorder)
end

function glow.FrameOnly(glowType)
    return FRAME_ONLY[glowType] == true
end

function glow.IsKnown(name)
    for _, known in ipairs(glow.TYPES) do
        if known == name then
            return true
        end
    end
    return orbitGlow:IsGlowRegistered(name)
end

function glow.PackNames()
    local names = {}
    for _, name in ipairs(orbitGlow:GetGlowList()) do
        local info = orbitGlow:GetGlowInfo(name)
        if info and info.source ~= "LibOrbitGlow" then
            table.insert(names, name)
        end
    end
    return names
end

function glow.IsPack(name)
    local info = orbitGlow:GetGlowInfo(name)
    return info ~= nil and info.source ~= "LibOrbitGlow"
end

function glow.IsRegistered(name)
    return orbitGlow:IsGlowRegistered(name)
end

local SHAPE_ORDER = {
    "square", "chamfer", "blade", "notch", "soft-small", "soft", "soft-large", "softer", "softer-large", "round",
    "round-full", "round-large",
}
local shapeRank = {}
for rank, shape in ipairs(SHAPE_ORDER) do
    shapeRank[shape] = rank
end

function glow.ShapesOf(name)
    local info = orbitGlow:GetGlowInfo(name)
    local shapes = {}
    for shape in pairs(info and info.shapes or {}) do
        table.insert(shapes, shape)
    end
    table.sort(shapes, function(a, b)
        local rankA, rankB = shapeRank[a] or #SHAPE_ORDER + 1, shapeRank[b] or #SHAPE_ORDER + 1
        if rankA ~= rankB then
            return rankA < rankB
        end
        return a < b
    end)
    return shapes
end
