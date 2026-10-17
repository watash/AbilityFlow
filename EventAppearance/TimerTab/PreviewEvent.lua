local addonName, ns = ...

local ipairs = ipairs
local C_Texture = C_Texture
local appearance = ns.appearance
local overlays = ns.eventIndicators
local media = ns.media

ns.timerTab = ns.timerTab or {}

local previewEvent = {}
ns.timerTab.event = previewEvent

previewEvent.TEMPLATE_FILE_ID = 463284
local DEBUFF_ATLAS = "icons_16x16_magic"
local DANGER_ATLAS = "icons_16x16_deadly"
local ROLE_ATLASES = { "icons_16x16_heal", "icons_16x16_tank" }
local paintBase = {}

local paintLook

local function flatReach(look)
    if look.borderStyle == "SOLID" or look.borderStyle == "DEBUFF" then
        return look.borderThickness
    end
    return 0
end

local function badgeCenter(kind)
    return overlays.BadgeCenter(paintLook[kind .. "Anchor"], paintLook.size / 2, paintLook[kind .. "OffsetX"],
        paintLook[kind .. "OffsetY"], flatReach(paintLook))
end

function previewEvent.CurrentLook()
    return {
        size = appearance.Get("icon", "size"),
        zoom = appearance.Get("icon", "zoom"),
        borderStyle = appearance.BorderStyle(),
        borderTypeFrames = appearance.Get("border", "useEventColor"),
        borderThickness = appearance.Get("border", "thickness"),
        borderColor = CopyTable(appearance.Get("border", "color")),
        font = appearance.Get("cooldown", "font"),
        fontSize = appearance.Get("cooldown", "size"),
        outline = appearance.FontFlags("cooldown"),
        color = CopyTable(appearance.Get("cooldown", "color")),
        debuffSize = appearance.Get("debuff", "size"),
        debuffAnchor = appearance.Get("debuff", "anchor"),
        debuffOffsetX = appearance.Get("debuff", "offsetX"),
        debuffOffsetY = appearance.Get("debuff", "offsetY"),
        dangerSize = appearance.Get("danger", "size"),
        dangerAnchor = appearance.Get("danger", "anchor"),
        dangerOffsetX = appearance.Get("danger", "offsetX"),
        dangerOffsetY = appearance.Get("danger", "offsetY"),
        rolesSize = appearance.Get("roles", "size"),
        rolesAnchor = appearance.Get("roles", "anchor"),
        rolesOffsetX = appearance.Get("roles", "offsetX"),
        rolesOffsetY = appearance.Get("roles", "offsetY"),
        rolesGap = appearance.Get("roles", "gap"),
        rolesVertical = appearance.Get("roles", "vertical"),
    }
end

function previewEvent.BorderMargin(look)
    if look.borderStyle == "NONE" then
        return 0
    end
    if look.borderStyle == "BLIZZARD" then
        return ns.eventStyle.FrameOutset(look.size)
    end
    return look.borderThickness
end

function previewEvent.FitScale(look, cellFootprint, cellScale)
    return cellScale * cellFootprint / (look.size + 2 * previewEvent.BorderMargin(look))
end

function previewEvent.Create(parent, fileID)
    local event = ns.eventFrame.Create(parent)
    event.texture:SetTexture(fileID)
    event.debuffIndicator:SetAtlas(DEBUFF_ATLAS)
    event.debuffIndicator:Hide()
    event.dangerIndicator = event.dangerHolder:CreateTexture(nil, "OVERLAY")
    overlays.Smooth(event.dangerIndicator)
    event.dangerIndicator:SetAtlas(DANGER_ATLAS)
    event.dangerIndicator:Hide()
    event.roleIndicators = {}
    for index, atlas in ipairs(ROLE_ATLASES) do
        event.roleIndicators[index] = event.rolesHolder:CreateTexture(nil, "OVERLAY")
        overlays.Smooth(event.roleIndicators[index])
        event.roleIndicators[index]:SetAtlas(atlas)
        event.roleIndicators[index]:Hide()
    end
    return event
end

local GREY_RED, GREY_GREEN, GREY_BLUE = 0.299, 0.587, 0.114

local function paintBorder(event)
    if event.borderIsFrame then
        event.borderFill:SetDesaturated(event.desaturated == true)
        return
    end
    local color = event.borderColor
    if not color then
        return
    end
    if event.desaturated then
        local grey = color.r * GREY_RED + color.g * GREY_GREEN + color.b * GREY_BLUE
        event.borderFill:SetColorTexture(grey, grey, grey, color.a)
    else
        event.borderFill:SetColorTexture(color.r, color.g, color.b, color.a)
    end
end

function previewEvent.Apply(event, scale, showBadges, look)
    event:SetSize(look.size, look.size)
    event:SetScale(scale)
    event.crop = look.zoom / 100
    event.texture:SetTexCoord(event.crop, 1 - event.crop, event.crop, 1 - event.crop)

    event.flatBorder = look.borderStyle ~= "BLIZZARD"
    event.borderIsFrame = false
    ns.eventFrame.SetRounded(event, look.borderStyle == "BLIZZARD" and
        ns.eventStyle.MaskReach(ns.eventStyle.FrameOutset(look.size)) or nil)
    event.borderFill:SetDesaturated(false)
    event.borderFill:SetDrawLayer("BACKGROUND")
    if look.borderStyle == "NONE" then
        event.borderColor = nil
        ns.eventFrame.SetBorder(event, 0, nil)
    elseif look.borderStyle == "BLIZZARD" then
        local frameAtlas = ns.debuff.FrameAtlasOf("MAGIC")
        if not look.borderTypeFrames then
            event.borderColor = nil
            ns.eventFrame.SetBorder(event, ns.eventStyle.FrameOutset(look.size), nil)
            event.borderFill:Hide()
        elseif frameAtlas and C_Texture.GetAtlasInfo(frameAtlas) then
            event.borderIsFrame = true
            event.borderColor = nil
            ns.eventFrame.SetBorder(event, ns.eventStyle.FrameOutset(look.size), nil)
            event.borderFill:SetAtlas(frameAtlas)
            event.borderFill:SetDrawLayer("OVERLAY")
            event.borderFill:Show()
            paintBorder(event)
        else
            event.borderColor = ns.debuff.ColorOf("MAGIC")
            ns.eventFrame.SetBorder(event, ns.eventStyle.FrameOutset(look.size), event.borderColor)
            paintBorder(event)
        end
    else
        event.borderColor = look.borderStyle == "DEBUFF" and ns.debuff.ColorOf("MAGIC") or look.borderColor
        ns.eventFrame.SetBorder(event, look.borderThickness, event.borderColor)
        paintBorder(event)
    end

    local reach = flatReach(look)
    event.flatReach = reach
    event.debuffIndicator:SetSize(look.debuffSize, look.debuffSize)
    overlays.PlaceOnPoint(event.debuffIndicator, event, look.debuffAnchor, look.debuffOffsetX, look.debuffOffsetY, reach)
    event.debuffIndicator:SetShown(showBadges == true)

    event.dangerIndicator:SetSize(look.dangerSize, look.dangerSize)
    overlays.PlaceOnPoint(event.dangerIndicator, event, look.dangerAnchor, look.dangerOffsetX, look.dangerOffsetY, reach)
    event.dangerIndicator:SetShown(showBadges == true)

    local roleCount = #event.roleIndicators
    for index, texture in ipairs(event.roleIndicators) do
        texture:SetSize(look.rolesSize, look.rolesSize)
        overlays.PlaceInRow(texture, event, look.rolesAnchor, index, roleCount, look.rolesSize + look.rolesGap,
            look.rolesVertical, look.rolesOffsetX, look.rolesOffsetY, reach)
        texture:SetShown(showBadges == true)
    end
end

function previewEvent.SetIcon(event, templateID)
    local spellID = ns.timerStyle.IconSpell(templateID)
    event.texture:SetTexture(spellID and C_Spell.GetSpellTexture(spellID) or previewEvent.TEMPLATE_FILE_ID)
    local crop = event.crop or 0
    event.texture:SetTexCoord(crop, 1 - crop, crop, 1 - crop)
end

function previewEvent.SetDesaturated(event, desaturated)
    event.desaturated = desaturated
    event.texture:SetDesaturated(desaturated)
    paintBorder(event)
    event.debuffIndicator:SetDesaturated(desaturated)
    event.dangerIndicator:SetDesaturated(desaturated)
    for _, texture in ipairs(event.roleIndicators) do
        texture:SetDesaturated(desaturated)
    end
end

previewEvent.SetStrata = ns.eventFrame.SetStrata
previewEvent.SetLevel = ns.eventFrame.SetLevel

function previewEvent.SampleText(template, second)
    if not second then
        return ""
    end
    if template and template.tenths then
        return ("%.1f"):format(second)
    end
    return tostring(second)
end

function previewEvent.greyText(text)
    local red, green, blue, alpha = text:GetTextColor()
    local grey = red * GREY_RED + green * GREY_GREEN + blue * GREY_BLUE
    text:SetTextColor(grey, grey, grey, alpha)
end

function previewEvent.GreyCountdown(event)
    previewEvent.greyText(event.texts.cooldown)
end

function previewEvent.GreyGlow(event, template)
    if not template or not template.useGlow then
        return
    end
    local color = template.glowUseCustomColor and template.glowColor or ns.timerStyle.CountdownColor(template) or paintBase.color
    local grey = color.r * GREY_RED + color.g * GREY_GREEN + color.b * GREY_BLUE
    local reach = event.flatReach or 0
    local glowType, options = ns.glow.TimerGlow(template, reach > 0, reach > 0 or event.flatBorder == true,
        reach > 0 and event:GetWidth() + 2 * reach or nil)
    local greyed = { r = grey, g = grey, b = grey, a = color.a or 1 }
    ns.glow.ApplyBacking(options, glowType, template, greyed, event.wantedColor, event.flatBorder == false)
    ns.glow.Show(event.container, glowType, greyed, options)
end

function previewEvent.Paint(event, template, look)
    local defaultFont = media.FontPath(media.DEFAULT_FONT)
    paintLook = look
    paintBase.fontPath = media.FontPath(look.font) or defaultFont
    paintBase.fallbackFontPath = defaultFont
    paintBase.fontSize = look.fontSize
    paintBase.outline = look.outline
    paintBase.color = look.color
    paintBase.restoreColor = nil
    paintBase.badgeCenter = badgeCenter
    ns.timerPaint.Apply(event, template, paintBase)
end
