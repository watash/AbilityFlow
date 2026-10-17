local addonName, ns = ...

local orbitGlow = LibStub("LibOrbitGlow-1.0")

local glow = ns.glow

local FULL_SIZE = glow.FULL_SHARE

local GLOW_KEY = addonName
local GLOW_FRAME_LEVEL = glow.FRAME_LEVEL
local CLASSIC_SHIFT_SHARE = -0.01
local SIZE_TOLERANCE = 1
local SCALE_TOLERANCE = 0.01

local states = setmetatable({}, { __mode = "k" })

local function near(a, b, tolerance)
    return math.abs(a - b) <= tolerance
end

local function sameColor(a, b)
    if a == b then
        return true
    end
    if not a or not b then
        return false
    end
    return a.r == b.r and a.g == b.g and a.b == b.b and a.a == b.a
end

local function sameOptions(a, b, ignored)
    if a == b then
        return true
    end
    if not a or not b then
        return false
    end
    for key, value in pairs(a) do
        if key ~= ignored and b[key] ~= value then
            return false
        end
    end
    for key, value in pairs(b) do
        if key ~= ignored and a[key] ~= value then
            return false
        end
    end
    return true
end

function glow.Show(frame, glowType, color, options)
    local state = states[frame] or {}
    states[frame] = state
    local width, height = glow.FrameSize(frame)
    local scale = glow.surroundingScale(frame)
    local sizeKnown = width > 0 and height > 0
    local sameGlow = state.glowType == glowType and sameOptions(state.options, options, "size")
        and (not sizeKnown or (near(state.width, width, SIZE_TOLERANCE) and near(state.height, height,
            SIZE_TOLERANCE) and near(state.scale, scale, SCALE_TOLERANCE)))
    local sameSize = (state.options and state.options.size) == (options and options.size)
    if sameGlow and sameSize and sameColor(state.color, color) then
        return
    end
    if state.glowType and not sameGlow then
        glow.Stop(frame)
    end

    local given = {}
    for key, value in pairs(options or {}) do
        if key ~= "size" then
            given[key] = value
        end
    end
    local target = frame
    local percent = options and options.size
    local ring = glow.RING_GLOWS[glowType]
    if percent and not ring then
        target = glow.host(frame, percent, glowType == glow.CLASSIC and CLASSIC_SHIFT_SHARE or nil)
        state.host = target
        state.baseScale = target:GetScale()
    end
    local lowestLevel = -target:GetFrameLevel()
    if ring then
        glow.ShowRing(frame, glowType, { color.r, color.g, color.b, color.a or 1 }, given, (percent or FULL_SIZE) / FULL_SIZE,
            math.max(given.frameLevel or GLOW_FRAME_LEVEL, lowestLevel))
    else
        local applied = {
            key = GLOW_KEY,
            frameLevel = GLOW_FRAME_LEVEL,
            color = { color.r, color.g, color.b, color.a or 1 },
        }
        local targetWidth, targetHeight = target:GetWidth(), target:GetHeight()
        if targetWidth > 0 and targetHeight > 0 then
            applied.hostWidth, applied.hostHeight = targetWidth, targetHeight
        end
        for key, value in pairs(given) do
            applied[key] = value
        end
        applied.frameLevel = math.max(applied.frameLevel, lowestLevel + 1)
        orbitGlow.Apply(target, glowType, applied)
    end
    state.glowType, state.color, state.options = glowType, color, options
    state.width, state.height, state.scale = width, height, scale
end

function glow.Breathe(frame, getFactor, pulse)
    local state = states[frame]
    if state and state.glowType and glow.RING_GLOWS[state.glowType] then
        if state.breath ~= getFactor or state.breathPulse ~= pulse then
            state.breath, state.breathPulse = getFactor, pulse
            glow.SetRingBreath(frame, getFactor, pulse)
        end
        return
    end
    local host = state and state.host
    if not host or (state.breath == getFactor and state.breathPulse == pulse) then
        return
    end
    for _, step in ipairs(state.breathPulse or {}) do
        step:SetScript("OnUpdate", nil)
    end
    state.breath, state.breathPulse = getFactor, pulse
    if getFactor then
        local function follow()
            host:SetScale(state.baseScale * getFactor())
        end
        host:SetScript("OnUpdate", follow)
        for _, step in ipairs(pulse or {}) do
            step:SetScript("OnUpdate", follow)
        end
    else
        host:SetScript("OnUpdate", nil)
        host:SetScale(state.baseScale)
    end
end

function glow.Relevel(frame)
    local state = states[frame]
    if not state or not state.glowType then
        return
    end
    local glowType, color, options, breath, pulse = state.glowType, state.color, state.options, state.breath, state.breathPulse
    glow.Stop(frame)
    glow.Show(frame, glowType, color, options)
    if breath then
        glow.Breathe(frame, breath, pulse)
    end
end

function glow.ShownOn(frame)
    local state = states[frame]
    return state and state.glowType or nil
end

function glow.SetHeld(frame, held)
    local state = states[frame]
    if not state or not state.glowType then
        return
    end
    if glow.RING_GLOWS[state.glowType] then
        glow.HoldRing(frame, held)
    elseif state.host then
        state.host:SetAlpha(held and 0 or 1)
    end
end

function glow.Inspect(frame)
    local state = states[frame]
    if not state or not state.glowType then
        return nil
    end
    local host = state.host
    return {
        glowType = state.glowType,
        size = state.options and state.options.size,
        baseScale = state.baseScale,
        breathing = state.breath ~= nil,
        hostScale = host and host:GetScale(),
        hostWidth = host and host:GetWidth(),
        hostHeight = host and host:GetHeight(),
        frameWidth = state.width,
        frameHeight = state.height,
    }
end

function glow.Stop(frame)
    local state = states[frame]
    if state and state.glowType then
        if state.host and state.breath then
            glow.Breathe(frame, nil)
        end
        if glow.RING_GLOWS[state.glowType] then
            glow.StopRing(frame)
            state.breath, state.breathPulse = nil, nil
        else
            orbitGlow.Remove(state.host or frame, state.glowType, GLOW_KEY)
        end
        if state.host then
            state.host:SetScript("OnUpdate", nil)
        end
        state.host = nil
        state.glowType = nil
    end
end
