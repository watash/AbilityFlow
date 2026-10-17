local addonName, ns = ...

local CreateFrame = CreateFrame
local PixelUtil = PixelUtil
local ipairs = ipairs
local math = math

local glow = ns.glow

local WHITE_TEXTURE = "Interface\\BUTTONS\\WHITE8X8"
local SPARK_TEXTURE = "Interface\\Artifacts\\Artifacts"
local SPARK_LEFT, SPARK_RIGHT, SPARK_TOP, SPARK_BOTTOM = 0.8115234375, 0.9169921875, 0.8798828125, 0.9853515625
local SPARK_SIZES = { 7, 6, 5, 4 }
local LINE_PERIOD = 4
local SPARK_PERIOD = 8
local PIECES_PER_LINE = 2
local SHADOW_COLORS = { dark = { 0.1, 0.1, 0.1, 0.5 }, light = { 0.9, 0.9, 0.9, 0.5 } }

local rings = setmetatable({}, { __mode = "k" })
local smoothFrames = setmetatable({}, { __mode = "k" })

local function pixelUnit(frame)
    return PixelUtil.GetPixelToUIUnitFactor() / glow.surroundingScale(frame)
end

local function setVisible(texture, shown)
    if texture.visible ~= shown then
        texture.visible = shown
        texture:SetShown(shown)
    end
end

local function ensureTextures(ring, count)
    local textures = ring.textures
    for index = #textures + 1, count do
        local texture = ring.holder:CreateTexture(nil, "ARTWORK")
        textures[index] = texture
    end
    for index = 1, #textures do
        setVisible(textures[index], index <= count)
    end
end

local function breathe(ring, frame)
    local factor = ring.getFactor and ring.getFactor() or 1
    if ring.factor ~= factor then
        ring.factor = factor
        ring.holder:SetScale(ring.restScale * factor)
    end
    local alpha = ring.held and 0 or frame:GetAlpha()
    if ring.alpha ~= alpha then
        ring.alpha = alpha
        ring.holder:SetAlpha(alpha)
    end
end

local function placeHolder(ring, frame)
    local width, height = glow.FrameSize(frame)
    width, height = width * ring.share - 2 * ring.inset, height * ring.share - 2 * ring.inset
    local scale = frame:GetScale()
    if ring.width ~= width or ring.height ~= height or ring.restScale ~= scale then
        ring.width, ring.height, ring.restScale = width, height, scale
        ring.holder:SetSize(math.max(width, 0), math.max(height, 0))
        ring.holder:ClearAllPoints()
        ring.holder:SetPoint("CENTER", frame, "CENTER", 0, 0)
        ring.factor = nil
    end
    breathe(ring, frame)
end

local function placePiece(texture, holder, edge, from, to, thick, unit)
    if texture.edge ~= edge then
        texture:ClearAllPoints()
        texture.edge = edge
    end
    if edge == 1 then
        texture:SetPoint("TOPLEFT", holder, "TOPLEFT", from * unit, 0)
        texture:SetPoint("BOTTOMRIGHT", holder, "TOPLEFT", to * unit, -thick)
    elseif edge == 2 then
        texture:SetPoint("TOPRIGHT", holder, "TOPRIGHT", 0, -from * unit)
        texture:SetPoint("BOTTOMLEFT", holder, "TOPRIGHT", -thick, -to * unit)
    elseif edge == 3 then
        texture:SetPoint("BOTTOMRIGHT", holder, "BOTTOMRIGHT", -from * unit, 0)
        texture:SetPoint("TOPLEFT", holder, "BOTTOMRIGHT", -to * unit, thick)
    else
        texture:SetPoint("BOTTOMLEFT", holder, "BOTTOMLEFT", 0, from * unit)
        texture:SetPoint("TOPRIGHT", holder, "BOTTOMLEFT", thick, to * unit)
    end
end

local edgeStart, edgeLength = {}, {}

local function measureEdges(width, height)
    edgeStart[1], edgeLength[1] = 0, width
    edgeStart[2], edgeLength[2] = width, height
    edgeStart[3], edgeLength[3] = width + height, width
    edgeStart[4], edgeLength[4] = 2 * width + height, height
end

local function placeShadowStrips(shadow, holder, thick)
    local top, right, bottom, left = shadow[1], shadow[2], shadow[3], shadow[4]
    top:ClearAllPoints()
    top:SetPoint("TOPLEFT", holder, "TOPLEFT", 0, 0)
    top:SetPoint("TOPRIGHT", holder, "TOPRIGHT", 0, 0)
    top:SetHeight(thick)
    bottom:ClearAllPoints()
    bottom:SetPoint("BOTTOMLEFT", holder, "BOTTOMLEFT", 0, 0)
    bottom:SetPoint("BOTTOMRIGHT", holder, "BOTTOMRIGHT", 0, 0)
    bottom:SetHeight(thick)
    right:ClearAllPoints()
    right:SetPoint("TOPRIGHT", holder, "TOPRIGHT", 0, -thick)
    right:SetPoint("BOTTOMRIGHT", holder, "BOTTOMRIGHT", 0, thick)
    right:SetWidth(thick)
    left:ClearAllPoints()
    left:SetPoint("TOPLEFT", holder, "TOPLEFT", 0, -thick)
    left:SetPoint("BOTTOMLEFT", holder, "BOTTOMLEFT", 0, thick)
    left:SetWidth(thick)
end

local function placeShadow(ring, thick)
    local shadow, holder = ring.shadow, ring.holder
    if not ring.shadowOn then
        for _, texture in ipairs(shadow) do
            setVisible(texture, false)
        end
        return
    end
    thick = math.min(thick, holder:GetWidth() / 2, holder:GetHeight() / 2)
    if ring.shadowThick ~= thick then
        ring.shadowThick = thick
        placeShadowStrips(shadow, holder, thick)
    end
    for _, texture in ipairs(shadow) do
        setVisible(texture, true)
    end
end

local function updateLines(ring, frame, elapsed)
    placeHolder(ring, frame)
    local unit = pixelUnit(frame)
    local width, height = ring.holder:GetWidth() / unit, ring.holder:GetHeight() / unit
    if not (width > 0 and height > 0) then
        return
    end
    ring.timer = (ring.timer + elapsed / ring.period) % 1
    local around = 2 * (width + height)
    local count = ring.count
    local side = math.min(width, height)
    local length = math.min(math.max(math.floor(side * ring.lengthShare + 0.5), 1), side)
    local thickPixels = math.min(ring.thickness, width / 2, height / 2)
    local thick = thickPixels * unit
    measureEdges(width, height)
    placeShadow(ring, thick)
    local textures = ring.textures
    for line = 1, count do
        local from = ((ring.timer + (line - 1) / count) % 1) * around
        local used = 0
        for edge = 1, 4 do
            local start, size = edgeStart[edge], edgeLength[edge]
            for pass = 1, 2 do
                local shift = pass == 1 and 0 or -around
                local first = math.max(from + shift, start) - start
                local last = math.min(from + shift + length, start + size) - start
                if edge == 2 or edge == 4 then
                    first, last = math.max(first, thickPixels), math.min(last, size - thickPixels)
                end
                if last > first and used < PIECES_PER_LINE then
                    used = used + 1
                    local texture = textures[(line - 1) * PIECES_PER_LINE + used]
                    placePiece(texture, ring.holder, edge, first, last, thick, unit)
                    setVisible(texture, true)
                end
            end
        end
        for piece = used + 1, PIECES_PER_LINE do
            setVisible(textures[(line - 1) * PIECES_PER_LINE + piece], false)
        end
    end
end

local function updateSparks(ring, frame, elapsed)
    placeHolder(ring, frame)
    local unit = pixelUnit(frame)
    local width, height = ring.holder:GetWidth() / unit, ring.holder:GetHeight() / unit
    if not (width > 0 and height > 0) then
        return
    end
    local around = 2 * (width + height)
    local count = ring.count
    local space = around / count
    local holder = ring.holder
    for band, size in ipairs(SPARK_SIZES) do
        ring.timers[band] = (ring.timers[band] + elapsed / (ring.period * band)) % 1
        local side = size * ring.sparkScale * unit
        for spark = 1, count do
            local texture = ring.textures[(band - 1) * count + spark]
            local at = (space * spark + around * ring.timers[band]) % around
            if texture.side ~= side then
                texture.side = side
                texture:SetSize(side, side)
            end
            if at < width then
                texture:SetPoint("CENTER", holder, "TOPLEFT", at * unit, 0)
            elseif at < width + height then
                texture:SetPoint("CENTER", holder, "TOPRIGHT", 0, -(at - width) * unit)
            elseif at < 2 * width + height then
                texture:SetPoint("CENTER", holder, "BOTTOMRIGHT", -(at - width - height) * unit, 0)
            else
                texture:SetPoint("CENTER", holder, "BOTTOMLEFT", 0, (at - 2 * width - height) * unit)
            end
        end
    end
end

local function periodOf(frequency, default)
    if frequency and frequency ~= 0 then
        return 1 / frequency
    end
    return default
end

function glow.ShowRing(frame, glowType, color, options, share, level)
    local ring = rings[frame]
    if not ring then
        local holder = CreateFrame("Frame", nil, frame:GetParent() or frame)
        ring = { holder = holder, textures = {}, timers = { 0, 0, 0, 0 }, timer = 0, shadow = {} }
        for edge = 1, 4 do
            local texture = holder:CreateTexture(nil, "BORDER")
            texture:SetColorTexture(1, 1, 1, 1)
            ring.shadow[edge] = texture
        end
        rings[frame] = ring
        holder:SetScript("OnUpdate", function(_, elapsed)
            ring.update(ring, frame, elapsed)
        end)
    end
    if ring.glowType ~= glowType then
        ring.timer, ring.timers = 0, { 0, 0, 0, 0 }
        ring.glowType = glowType
    end
    ring.share = share
    ring.inset = options.inset or 0
    ring.width = nil
    ring.holder:SetFrameLevel(frame:GetFrameLevel() + level)
    local textureCount
    if glowType == glow.PIXEL then
        ring.update = updateLines
        ring.count = math.max(options.lines or glow.DEFAULT_LINES, 1)
        ring.period = periodOf(options.frequency, LINE_PERIOD)
        ring.lengthShare = options.lengthShare or glow.DEFAULT_LENGTH / glow.FULL_SHARE
        ring.thickness = options.thickness or glow.DEFAULT_THICKNESS
        ring.shadowOn = SHADOW_COLORS[options.shadow] ~= nil
        local shade = SHADOW_COLORS[options.shadow]
        if shade then
            for _, texture in ipairs(ring.shadow) do
                texture:SetColorTexture(shade[1], shade[2], shade[3], shade[4])
            end
        end
        ring.shadowThick = nil
        textureCount = ring.count * PIECES_PER_LINE
    else
        ring.update = updateSparks
        ring.count = math.max(options.particles or glow.DEFAULT_SPARKS, 1)
        ring.period = periodOf(options.frequency, SPARK_PERIOD)
        ring.sparkScale = options.scale or 1
        ring.shadowOn = false
        for _, texture in ipairs(ring.shadow) do
            setVisible(texture, false)
        end
        textureCount = ring.count * #SPARK_SIZES
    end
    ensureTextures(ring, textureCount)
    for _, texture in ipairs(ring.shadow) do
        texture:SetSnapToPixelGrid(not smoothFrames[frame])
        texture:SetTexelSnappingBias(0)
    end
    for index = 1, textureCount do
        local texture = ring.textures[index]
        texture:ClearAllPoints()
        texture.edge, texture.side = nil, nil
        if glowType == glow.PIXEL then
            texture:SetTexture(WHITE_TEXTURE)
            texture:SetTexCoord(0, 1, 0, 1)
            texture:SetDesaturated(false)
            texture:SetSnapToPixelGrid(not smoothFrames[frame])
            texture:SetTexelSnappingBias(0)
        else
            texture:SetTexture(SPARK_TEXTURE)
            texture:SetTexCoord(SPARK_LEFT, SPARK_RIGHT, SPARK_TOP, SPARK_BOTTOM)
            texture:SetDesaturated(true)
        end
        texture:SetVertexColor(color[1], color[2], color[3], color[4])
    end
    ring.holder:Show()
    ring.update(ring, frame, 0)
end

function glow.SetRingBreath(frame, getFactor, steps)
    local ring = rings[frame]
    if not ring then
        return
    end
    for _, step in ipairs(ring.breathSteps or {}) do
        step:SetScript("OnUpdate", nil)
    end
    ring.getFactor, ring.breathSteps = getFactor, steps
    local function follow()
        breathe(ring, frame)
    end
    for _, step in ipairs(steps or {}) do
        step:SetScript("OnUpdate", follow)
    end
    if ring.restScale then
        breathe(ring, frame)
    end
end

function glow.HoldRing(frame, held)
    local ring = rings[frame]
    if ring then
        ring.held = held
        ring.alpha = nil
        ring.holder:SetAlpha(held and 0 or frame:GetAlpha())
    end
end

function glow.StopRing(frame)
    local ring = rings[frame]
    if ring then
        glow.SetRingBreath(frame, nil)
        ring.holder:Hide()
        ring.glowType = nil
        ring.held = false
        ring.alpha = nil
    end
end

function glow.SetRingSmooth(frame, smooth)
    smoothFrames[frame] = smooth or nil
    local ring = rings[frame]
    if ring and ring.glowType == glow.PIXEL then
        for _, texture in ipairs(ring.textures) do
            texture:SetSnapToPixelGrid(not smooth)
            texture:SetTexelSnappingBias(0)
        end
        for _, texture in ipairs(ring.shadow) do
            texture:SetSnapToPixelGrid(not smooth)
            texture:SetTexelSnappingBias(0)
        end
    end
end
