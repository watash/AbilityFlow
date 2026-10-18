local addonName, ns = ...

local _G = _G
local type = type
local pairs = pairs

local L = ns.L

local gameWords = {
    NONE = "NONE",
    EVENT_APPEARANCE_RESET = "SETTINGS_DEFAULTS",
    EVENT_APPEARANCE_RESET_ALL_ACCEPT = "RESET",
    PROFILE_DEFAULT = "DEFAULT",
    PROFILE_DELETE = "DELETE",
    RELOAD_LATER = "LATER",
    STATES_COLORS = "COLORS",
    STATES_BLOCKED = "UNAVAILABLE",
    OPTIONS_CLASS_COLORS = "CLASS_COLORS",
    TIMER_STYLE_GLOW_BACKING_ALWAYS = "ALWAYS",
    TIMER_STYLE_GLOW_BACKING_NEVER = "NEVER",
    MARK_ALL = "ALL",
    PROFILE_DONE = "DONE",
    PROFILE_IMPORT_WITH_TRACK = "APPLY",
    EVENT_APPEARANCE_BORDER_COLOR = "COLOR",
}

for key, name in pairs(gameWords) do
    local word = _G[name]
    if type(word) == "string" then
        L[key] = word
    end
end
