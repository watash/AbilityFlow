local addonName, ns = ...

local C_Timer = C_Timer
local next = next
local pairs = pairs
local setmetatable = setmetatable

local bigWigsBars = {}
ns.bigWigsBars = bigWigsBars

local MESSAGE_BAR_CREATED = "BigWigs_BarCreated"
local MESSAGE_BAR_EMPHASIZED = "BigWigs_BarEmphasized"
local MESSAGE_START_BAR = "BigWigs_StartBar"
local MESSAGE_STOP_BAR = "BigWigs_StopBar"
local SETTING_KEY = "hideBossModBars"
local HIDDEN_ALPHA = 0
local SHOWN_ALPHA = 1

local known = setmetatable({}, { __mode = "k" })
local receiver = {}

local function isLive(bar)
    return type(bar.data) == "table" and bar.Get ~= nil and bar:Get("bigwigs:anchor") ~= nil
end

local function setAlpha(bar, alpha)
    if bar.IsForbidden and bar:IsForbidden() then
        return
    end
    bar:SetAlpha(alpha)
    local icon = bar.candyBarIconFrame
    if icon and bar:Get("bigwigs:tooltip") then
        icon:EnableMouse(alpha ~= HIDDEN_ALPHA)
    end
end

local function take(bar)
    if type(bar) ~= "table" or not isLive(bar) then
        return
    end
    known[bar] = true
    if ns.options.Get(SETTING_KEY) then
        setAlpha(bar, HIDDEN_ALPHA)
    end
end

local function applyAll()
    local alpha = ns.options.Get(SETTING_KEY) and HIDDEN_ALPHA or SHOWN_ALPHA
    for bar in pairs(known) do
        if isLive(bar) then
            setAlpha(bar, alpha)
        else
            known[bar] = nil
        end
    end
end

function bigWigsBars.Enable()
    local loader = _G.BigWigsLoader
    if not loader or not loader.RegisterMessage then
        return
    end
    loader.RegisterMessage(receiver, MESSAGE_BAR_CREATED, function(_, _, bar)
        take(bar)
    end)
    loader.RegisterMessage(receiver, MESSAGE_BAR_EMPHASIZED, function(_, _, bar)
        take(bar)
    end)
    for _, message in pairs({ MESSAGE_START_BAR, MESSAGE_STOP_BAR }) do
        loader.RegisterMessage(receiver, message, function()
            if ns.options.Get(SETTING_KEY) and next(known) then
                C_Timer.After(0, applyAll)
            end
        end)
    end
    ns.options.OnChanged(function(key)
        if key == SETTING_KEY then
            applyAll()
        end
    end)
end
