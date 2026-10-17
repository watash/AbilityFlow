local addonName, ns = ...

local ipairs = ipairs
local math = math
local pairs = pairs
local type = type
local CopyTable = CopyTable

local options = {}
ns.options = options

local TIME_LIMIT_MIN = 15
local TIME_LIMIT_UNLIMITED = 185
options.TIME_LIMIT_MIN = TIME_LIMIT_MIN
options.TIME_LIMIT_UNLIMITED = TIME_LIMIT_UNLIMITED

local DEFAULT_CAPTION_COLOR = { r = 1, g = 0.82, b = 0 }
local COLOR_FIELDS = { "r", "g", "b" }
local DEFAULT_NSRT_NOTES_COLOR = { r = 0, g = 1, b = 1 }
local DEFAULT_NSRT_ALERTS_COLOR = { r = 1, g = 0.5, b = 0 }
local COLOR_KEYS = { "captionColor", "nsrtNotesColor", "nsrtAlertsColor" }
local IS_COLOR_KEY = {}
for _, key in ipairs(COLOR_KEYS) do
    IS_COLOR_KEY[key] = true
end

local DEFAULTS = {
    timeLimit = TIME_LIMIT_UNLIMITED,
    showReadyCheck = true,
    showPullTimer = true,
    showInitiator = true,
    useClassColors = true,
    captionColor = DEFAULT_CAPTION_COLOR,
    showKeyReroll = true,
    showBreak = true,
    hideGameEvents = false,
    hideBlizzardTimeline = true,
    showNsrtNotes = true,
    showNsrtAlerts = true,
    hideNsrtWindows = true,
    colorNsrt = true,
    nsrtNotesColor = DEFAULT_NSRT_NOTES_COLOR,
    nsrtAlertsColor = DEFAULT_NSRT_ALERTS_COLOR,
    showBossModNames = true,
    showBossModTimers = true,
    showBossModColors = true,
    hideBossModBars = true,
}

options.ADDON_KEYS = { "showNsrtNotes", "showNsrtAlerts", "hideNsrtWindows", "colorNsrt", "nsrtNotesColor", "nsrtAlertsColor",
    "showBossModNames", "showBossModTimers", "showBossModColors",
    "hideBossModBars", "hideGameEvents" }

function options.ExtrasKeys()
    local reminder = {}
    for _, key in ipairs(options.ADDON_KEYS) do
        reminder[key] = true
    end
    local keys = {}
    for key in pairs(DEFAULTS) do
        if not reminder[key] then
            keys[#keys + 1] = key
        end
    end
    return keys
end

ns.profiles.OnComplete(function(data)
    data.options = data.options or {}
    ns.profiles.FillMissing(data.options, DEFAULTS)
end)

local listeners = {}

local HIDE_KEY = "hideBlizzardTimeline"
local wasHidden

function options.Get(key)
    local saved = AbilityFlowDB and ns.profiles.Current().options
    local value = saved and saved[key]
    if value == nil then
        value = DEFAULTS[key]
    end
    if key == HIDE_KEY and wasHidden == nil then
        wasHidden = value
    end
    return value
end

function options.Set(key, value)
    local profile = ns.profiles.Current()
    profile.options = profile.options or {}
    profile.options[key] = value
    if key == HIDE_KEY then
        wasHidden = value
    end
    for _, listener in ipairs(listeners) do
        listener(key, value)
    end
end

function options.Sanitize(data)
    local clean = {}
    for key, default in pairs(DEFAULTS) do
        if type(data[key]) == type(default) then
            clean[key] = data[key]
        end
    end
    for _, key in ipairs(COLOR_KEYS) do
        if clean[key] then
            for _, field in ipairs(COLOR_FIELDS) do
                local channel = clean[key][field]
                if type(channel) ~= "number" or channel < 0 or channel > 1 then
                    clean[key] = nil
                    break
                end
            end
        end
    end
    if clean.timeLimit then
        clean.timeLimit = math.min(math.max(clean.timeLimit, TIME_LIMIT_MIN), TIME_LIMIT_UNLIMITED)
    end
    return clean
end

function options.OnChanged(listener)
    listeners[#listeners + 1] = listener
end

local function notifyAll()
    local hidden = options.Get(HIDE_KEY)
    if wasHidden == true and hidden == false and ns.reloadPrompt then
        ns.reloadPrompt.Show()
    end
    wasHidden = hidden
    for key in pairs(DEFAULTS) do
        local value = options.Get(key)
        for _, listener in ipairs(listeners) do
            listener(key, value)
        end
    end
end

ns.profiles.OnChanged(notifyAll)

local function allKeys()
    local keys = {}
    for key in pairs(DEFAULTS) do
        keys[#keys + 1] = key
    end
    return keys
end

local COLOR_TOLERANCE = 1e-6

function options.IsDefault(keys)
    for _, key in ipairs(keys or allKeys()) do
        local default = DEFAULTS[key]
        local value = options.Get(key)
        if IS_COLOR_KEY[key] then
            for _, field in ipairs(COLOR_FIELDS) do
                if math.abs(value[field] - default[field]) > COLOR_TOLERANCE then
                    return false
                end
            end
        elseif value ~= default then
            return false
        end
    end
    return true
end

function options.Reset(keys)
    local profile = ns.profiles.Current()
    profile.options = profile.options or {}
    for _, key in ipairs(keys or allKeys()) do
        local default = DEFAULTS[key]
        profile.options[key] = type(default) == "table" and CopyTable(default) or default
    end
    notifyAll()
end
