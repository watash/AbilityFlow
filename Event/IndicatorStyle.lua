local addonName, ns = ...

local ipairs = ipairs
local pcall = pcall
local C_EncounterTimeline = C_EncounterTimeline

local eventStyle = ns.eventStyle
local state = eventStyle.state

function eventStyle.AssignOverlayArt(event)
    local overlays = ns.eventIndicators
    local settings = state.overlays
    local kinds = {
        { settings = settings.debuff, mask = overlays.MASK_DEBUFF, textures = { event.debuffIndicator } },
        { settings = settings.danger, mask = overlays.MASK_DANGER, textures = { event.dangerIndicator } },
        { settings = settings.roles, mask = overlays.MASK_ROLES, textures = event.roleIndicators },
    }
    for _, kind in ipairs(kinds) do
        for _, texture in ipairs(kind.textures) do
            texture:SetShown(kind.settings.enabled and event.eventID ~= nil)
        end
        if kind.settings.enabled and event.eventID then
            pcall(C_EncounterTimeline.SetEventIconTextures, event.eventID, kind.mask, kind.textures)
        end
    end
end

function eventStyle.PlaceOverlays(event)
    local overlays = ns.eventIndicators
    local scale = state.scale
    local reach = event.flatReach or 0

    local debuff = state.overlays.debuff
    local debuffSize = debuff.size * scale
    event.debuffIndicator:SetSize(debuffSize, debuffSize)
    overlays.PlaceOnPoint(event.debuffIndicator, event, debuff.anchor, debuff.offsetX * scale, debuff.offsetY * scale, reach)

    local danger = state.overlays.danger
    local dangerSize = danger.size * scale
    event.dangerIndicator:SetSize(dangerSize, dangerSize)
    overlays.PlaceOnPoint(event.dangerIndicator, event, danger.anchor, danger.offsetX * scale, danger.offsetY * scale, reach)

    local roles = state.overlays.roles
    local roleSize = roles.size * scale
    local filled, unknown = overlays.FilledRoleSlots(event.roleIndicators)
    local rowCount = unknown and overlays.ROLES_USUAL or #filled
    local isFilled = {}
    for index, texture in ipairs(filled) do
        isFilled[texture] = true
        texture:SetSize(roleSize, roleSize)
        overlays.PlaceInRow(texture, event, roles.anchor, index, rowCount, roleSize + roles.gap * scale, roles.vertical,
            roles.offsetX * scale, roles.offsetY * scale, reach)
    end
    for _, texture in ipairs(event.roleIndicators) do
        if not isFilled[texture] then
            texture:SetSize(roleSize, roleSize)
            overlays.PlaceInRow(texture, event, roles.anchor, 1, 1, 0, roles.vertical, roles.offsetX * scale,
                roles.offsetY * scale, reach)
            texture:Hide()
        end
    end
end

function eventStyle.BadgeCenter(kind, iconSize, reach)
    local settings = state.overlays[kind]
    return ns.eventIndicators.BadgeCenter(settings.anchor, iconSize / 2, settings.offsetX * state.scale,
        settings.offsetY * state.scale, reach)
end
