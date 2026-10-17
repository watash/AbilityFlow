local addonName, ns = ...

local GetLocale = GetLocale

local L = ns.L

local media = {}
ns.media = media

media.NONE = "NONE"
media.DEFAULT_BACKGROUND = "CHAT"
media.DEFAULT_TEXT_BACKGROUND = "SOLID"
media.DEFAULT_BORDER = "SOLID_BORDER"
media.DEFAULT_FONT = "FRIZQT"

media.MENU_MAX_HEIGHT = 400

local SHARED_MEDIA_PREFIX = "LSM:"
local SHARED_MEDIA_TEXT_COLOR = "ff7fb2ff"
local PREVIEW_HEIGHT = 16
local PREVIEW_WIDTH = 64

local sharedMedia = LibStub("LibSharedMedia-3.0", true)
local BACKGROUND_TYPE = sharedMedia and sharedMedia.MediaType.BACKGROUND
local BORDER_TYPE = sharedMedia and sharedMedia.MediaType.BORDER
local FONT_TYPE = sharedMedia and sharedMedia.MediaType.FONT

local BACKGROUND_TEXTURES = {
    { key = "SOLID", name = "WHITE8X8", path = "Interface\\Buttons\\WHITE8X8" },
    { key = "DIALOG", name = "UI-DialogBox-Background", path = "Interface\\DialogFrame\\UI-DialogBox-Background" },
    { key = "TOOLTIP", name = "UI-Tooltip-Background", path = "Interface\\Tooltips\\UI-Tooltip-Background" },
    { key = "CHAT", name = "ChatFrameBackground", path = "Interface\\ChatFrame\\ChatFrameBackground" },
}
local BORDER_TEXTURES = {
    { key = "SOLID_BORDER", name = "WHITE8X8", path = "Interface\\Buttons\\WHITE8X8" },
    { key = "TOOLTIP_BORDER", name = "UI-Tooltip-Border", path = "Interface\\Tooltips\\UI-Tooltip-Border" },
    { key = "DIALOG_BORDER", name = "UI-DialogBox-Border", path = "Interface\\DialogFrame\\UI-DialogBox-Border" },
}
local FONTS = {
    { key = "FRIZQT", name = "Friz Quadrata TT", path = "Fonts\\FRIZQT__.TTF", ruPath = "Fonts\\FRIZQT___CYR.TTF" },
    { key = "ARIALN", name = "Arial Narrow", path = "Fonts\\ARIALN.TTF" },
    { key = "MORPHEUS", name = "Morpheus", path = "Fonts\\MORPHEUS_CYR.TTF" },
    { key = "SKURRI", name = "Skurri", path = "Fonts\\SKURRI_CYR.TTF" },
}
if GetLocale() == "ruRU" then
    for _, font in ipairs(FONTS) do
        font.path = font.ruPath or font.path
    end
end

local function isEmptyPath(path)
    return path == nil or path == ""
end

local function pathOf(key, builtins, mediaType)
    if key == media.NONE then
        return nil
    end
    for _, entry in ipairs(builtins) do
        if entry.key == key then
            return entry.path
        end
    end
    local name = sharedMedia and mediaType and key:match("^" .. SHARED_MEDIA_PREFIX .. "(.+)$")
    if name then
        local path = sharedMedia:HashTable(mediaType)[name]
        if not isEmptyPath(path) then
            return path
        end
    end
    return nil
end

local function optionsOf(builtins, mediaType, withNone, withPreview, skipBuiltinFiles)
    local options = {}
    if withNone then
        table.insert(options, { text = L.NONE, value = media.NONE })
    end
    local function builtinText(path, name)
        if withPreview then
            return ("|T%s:%d:%d|t %s"):format(path, PREVIEW_HEIGHT, PREVIEW_WIDTH, name)
        end
        return name
    end
    local function sharedText(path, name)
        local coloured = ns.text.Colored(name, SHARED_MEDIA_TEXT_COLOR)
        if withPreview then
            return ("|T%s:%d:%d|t %s"):format(path, PREVIEW_HEIGHT, PREVIEW_WIDTH, coloured)
        end
        return coloured
    end
    local builtinPaths = {}
    for _, entry in ipairs(builtins) do
        builtinPaths[entry.path:lower()] = true
        table.insert(options, { text = builtinText(entry.path, entry.name), value = entry.key, path = entry.path })
    end
    if sharedMedia and mediaType then
        local paths = sharedMedia:HashTable(mediaType)
        for _, name in ipairs(sharedMedia:List(mediaType)) do
            if not isEmptyPath(paths[name]) and not (skipBuiltinFiles and builtinPaths[paths[name]:lower()]) then
                table.insert(options, { text = sharedText(paths[name], name), value = SHARED_MEDIA_PREFIX .. name,
                    path = paths[name] })
            end
        end
    end
    return options
end

function media.BackgroundPath(key)
    return pathOf(key, BACKGROUND_TEXTURES, BACKGROUND_TYPE)
end

function media.BorderPath(key)
    return pathOf(key, BORDER_TEXTURES, BORDER_TYPE)
end

function media.FontPath(key)
    return pathOf(key, FONTS, FONT_TYPE)
end

function media.BackgroundOptions()
    return optionsOf(BACKGROUND_TEXTURES, BACKGROUND_TYPE, true, true)
end

function media.TextBackgroundOptions()
    return optionsOf(BACKGROUND_TEXTURES, BACKGROUND_TYPE, false, true)
end

function media.BorderOptions()
    return optionsOf(BORDER_TEXTURES, BORDER_TYPE, true, true)
end

function media.FontOptions()
    local options = optionsOf(FONTS, FONT_TYPE, false, false, true)
    for _, option in ipairs(options) do
        option.fontPath = option.path
    end
    return options
end
