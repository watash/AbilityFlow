local addonName, ns = ...

local overlays = {}
ns.eventIndicators = overlays

overlays.MASK_DANGER = 0x1
overlays.MASK_DEBUFF = 0x7E
overlays.MASK_ROLES = 0x380
overlays.ROLE_SLOTS = 3
overlays.ROLES_USUAL = 2
overlays.BLANK_ATLAS = "icons_16x16_none"
overlays.ROLE_GAP = 2

overlays.ANCHOR_POINTS = {
    "TOPLEFT", "TOP", "TOPRIGHT",
    "LEFT", "CENTER", "RIGHT",
    "BOTTOMLEFT", "BOTTOM", "BOTTOMRIGHT",
}

local POINT_DIRECTION = {
    TOPLEFT = { -1, 1 }, TOP = { 0, 1 }, TOPRIGHT = { 1, 1 },
    LEFT = { -1, 0 }, CENTER = { 0, 0 }, RIGHT = { 1, 0 },
    BOTTOMLEFT = { -1, -1 }, BOTTOM = { 0, -1 }, BOTTOMRIGHT = { 1, -1 },
}

function overlays.Smooth(texture)
    texture:SetSnapToPixelGrid(false)
    texture:SetTexelSnappingBias(0)
end

function overlays.BadgeCenter(point, halfSize, offsetX, offsetY, reach)
    local x = point:find("LEFT") and -1 or (point:find("RIGHT") and 1 or 0)
    local y = point:find("BOTTOM") and -1 or (point:find("TOP") and 1 or 0)
    reach = reach or 0
    return x * (halfSize + reach) + offsetX, y * (halfSize + reach) + offsetY
end

function overlays.PlaceOnPoint(texture, event, point, offsetX, offsetY, reach)
    local direction = POINT_DIRECTION[point] or POINT_DIRECTION.RIGHT
    reach = reach or 0
    texture:ClearAllPoints()
    texture:SetPoint("CENTER", event, point, offsetX + direction[1] * reach, offsetY + direction[2] * reach)
end

function overlays.PlaceInRow(texture, event, point, index, count, spacing, vertical, offsetX, offsetY, reach)
    local direction = POINT_DIRECTION[point] or POINT_DIRECTION.RIGHT
    reach = reach or 0
    offsetX = (offsetX or 0) + direction[1] * reach
    offsetY = (offsetY or 0) + direction[2] * reach
    local step = vertical and direction[2] or direction[1]
    local offset
    if step == 0 then
        offset = spacing * ((count - 1) / 2 - (index - 1))
    else
        offset = spacing * (index - 1) * step
    end
    texture:ClearAllPoints()
    if vertical then
        texture:SetPoint("CENTER", event, point, offsetX, offset + offsetY)
    else
        texture:SetPoint("CENTER", event, point, offset + offsetX, offsetY)
    end
end

function overlays.FilledRoleSlots(textures)
    local filled = {}
    local unknown = false
    for _, texture in ipairs(textures) do
        local atlas = texture:GetAtlas()
        if issecretvalue(atlas) then
            unknown = true
            table.insert(filled, texture)
        elseif atlas ~= overlays.BLANK_ATLAS and (atlas or texture:GetTexture()) then
            table.insert(filled, texture)
        end
    end
    return filled, unknown
end
