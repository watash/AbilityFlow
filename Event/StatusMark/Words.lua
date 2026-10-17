local addonName, ns = ...

local ipairs = ipairs

local statusMark = ns.statusMark
local MODE_PAUSED, MODE_QUEUED = statusMark.MODE_PAUSED, statusMark.MODE_QUEUED
local TEXT_BLOCKED = statusMark.TEXT_BLOCKED

local GAME_TEXTS = {
    [MODE_PAUSED] = COMBAT_WARNINGS_EVENT_STATUS_PAUSED or "(Paused)",
    [MODE_QUEUED] = COMBAT_WARNINGS_EVENT_STATUS_QUEUED or "(Queued)",
    [TEXT_BLOCKED] = COMBAT_WARNINGS_EVENT_STATUS_BLOCKED or "(Unavailable)",
}
local FALLBACK_COLOR = NORMAL_FONT_COLOR or { r = 1, g = 0.82, b = 0 }
local COLOR_CODE = "|c%x%x(%x%x)(%x%x)(%x%x)"
local COLOR_NAME_CODE = "|cn([%w_]+):"
local COLOR_CODE_STRIP = "|c%x%x%x%x%x%x%x%x"
local COLOR_NAME_STRIP = "|cn[%w_]+:"
local COLOR_END = "|r"
local HEX_BASE = 16
local CHANNEL_MAX = 255

local function plain(text)
    text = text:gsub(COLOR_CODE_STRIP, ""):gsub(COLOR_NAME_STRIP, ""):gsub(COLOR_END, "")
    return text
end

local function namedColor(name)
    local color = _G[name]
    if type(color) == "table" and type(color.r) == "number" then
        return color
    end
    if C_UIColor and C_UIColor.GetColors then
        for _, entry in ipairs(C_UIColor.GetColors()) do
            if entry.baseTag == name and type(entry.color) == "table" then
                return entry.color
            end
        end
    end
    return nil
end

local BRACKET_OPEN = "^[%(%[]"
local BRACKET_CLOSE = "[%)%]]$"
local COLORED_OPEN = "^(|c%x%x%x%x%x%x%x%x)[%(%[]"
local COLORED_CLOSE = "[%)%]](|r)$"

local function unbracketed(text)
    text = text:gsub(COLORED_OPEN, "%1"):gsub(COLORED_CLOSE, "%1")
    text = text:gsub(BRACKET_OPEN, ""):gsub(BRACKET_CLOSE, "")
    return text
end
statusMark.Unbracketed = unbracketed

local STATUS_TEXTS = {}
local STATUS_TEXTS_BARE = {}
for key, text in pairs(GAME_TEXTS) do
    STATUS_TEXTS[key] = plain(text)
    STATUS_TEXTS_BARE[key] = unbracketed(STATUS_TEXTS[key])
end

statusMark.TEXTS, statusMark.TEXTS_BARE = STATUS_TEXTS, STATUS_TEXTS_BARE

function statusMark.GameColor(key)
    local text = GAME_TEXTS[key] or ""
    local name = text:match(COLOR_NAME_CODE)
    local named = name and namedColor(name)
    if named then
        return { r = named.r, g = named.g, b = named.b, a = 1 }
    end
    local red, green, blue = text:match(COLOR_CODE)
    if red then
        return {
            r = tonumber(red, HEX_BASE) / CHANNEL_MAX,
            g = tonumber(green, HEX_BASE) / CHANNEL_MAX,
            b = tonumber(blue, HEX_BASE) / CHANNEL_MAX,
            a = 1,
        }
    end
    return { r = FALLBACK_COLOR.r, g = FALLBACK_COLOR.g, b = FALLBACK_COLOR.b, a = 1 }
end
