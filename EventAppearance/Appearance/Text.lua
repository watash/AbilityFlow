local addonName, ns = ...

local table = table
local UIParent = UIParent

local media = ns.media
local appearance = ns.appearance
local BACKGROUND_OF = appearance.BACKGROUND_OF

function appearance.HasBackground(element)
    return BACKGROUND_OF[element] ~= nil
end

function appearance.BackgroundPath(element)
    local group = BACKGROUND_OF[element]
    if not group or not appearance.Get(group, "enabled") then
        return nil
    end
    return appearance.BackgroundTexturePath(element)
end

function appearance.BackgroundTexturePath(element)
    local group = BACKGROUND_OF[element]
    if not group then
        return nil
    end
    return media.BackgroundPath(appearance.Get(group, "texture"))
        or media.BackgroundPath(media.DEFAULT_TEXT_BACKGROUND)
end

function appearance.BackgroundBorderPath(element)
    local group = BACKGROUND_OF[element]
    if not group or not appearance.Get(group, "enabled") then
        return nil
    end
    return appearance.BackgroundBorderTexturePath(element)
end

function appearance.BackgroundBorderTexturePath(element)
    local group = BACKGROUND_OF[element]
    return group and media.BorderPath(appearance.Get(group, "borderTexture")) or nil
end

function appearance.FontPath(element)
    return media.FontPath(appearance.Get(element, "font")) or media.FontPath(media.DEFAULT_FONT)
end

local SLUG_SUPPORTED = UIParent:CreateFontString().SetSmoothScaling ~= nil
appearance.SLUG_SUPPORTED = SLUG_SUPPORTED

function appearance.FontFlags(element)
    local flags = {}
    local outline = appearance.Get(element, "outline")
    if outline ~= "NONE" then
        table.insert(flags, outline)
    end
    if appearance.Get(element, "monochrome") then
        table.insert(flags, "MONOCHROME")
    end
    if SLUG_SUPPORTED and appearance.Get(element, "slug") then
        table.insert(flags, "SLUG")
    end
    return table.concat(flags, ",")
end
