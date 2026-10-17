local addonName, ns = ...

local pairs = pairs
local pcall = pcall

local bigWigsColors = {}
ns.bigWigsColors = bigWigsColors

local SETTING_KEY = "showBossModColors"
local COLORS_PLUGIN = "Colors"
local HINT_OF_KIND = { text = "barText", border = "barColor" }
local COLOR_PARTS = 4
local FULL_OPACITY = 1

local sources = {}

function bigWigsColors.Remember(eventID, module, key, ofGame)
    if type(module) ~= "table" or key == nil then
        sources[eventID] = nil
        return
    end
    sources[eventID] = { module = module, key = key, ofGame = ofGame }
end

function bigWigsColors.Forget(eventID)
    sources[eventID] = nil
end

function bigWigsColors.ForgetGameEvents()
    for eventID, source in pairs(sources) do
        if source.ofGame then
            sources[eventID] = nil
        end
    end
end

local function colorsPlugin()
    local core = _G.BigWigs
    if type(core) ~= "table" or not core.GetPlugin then
        return nil
    end
    local ok, plugin = pcall(core.GetPlugin, core, COLORS_PLUGIN, true)
    if ok and type(plugin) == "table" and plugin.GetColorTable then
        return plugin
    end
    return nil
end

local function sameColor(a, b)
    for part = 1, COLOR_PARTS do
        if a[part] ~= b[part] then
            return false
        end
    end
    return true
end

function bigWigsColors.ColorOf(eventID, kind)
    local source = sources[eventID]
    local hint = HINT_OF_KIND[kind]
    if not source or not hint or not ns.options.Get(SETTING_KEY) then
        return nil
    end
    local plugin = colorsPlugin()
    if not plugin then
        return nil
    end
    local ok, own = pcall(plugin.GetColorTable, plugin, hint, source.module, source.key)
    local okGeneral, general = pcall(plugin.GetColorTable, plugin, hint)
    if ok and okGeneral and type(own) == "table" and type(general) == "table" and not sameColor(own, general) then
        return { r = own[1], g = own[2], b = own[3], a = own[4] or FULL_OPACITY }
    end
    return nil
end

function bigWigsColors.Enable()
    ns.eventStyle.AddColorSource(bigWigsColors.ColorOf)
    ns.options.OnChanged(function(key)
        if key == SETTING_KEY then
            for eventID in pairs(sources) do
                ns.timeline.RefreshEventName(eventID)
            end
        end
    end)
end
