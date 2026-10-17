local addonName, ns = ...

local C_Timer = C_Timer
local CreateFrame = CreateFrame
local pairs = pairs

local dbmBars = {}
ns.dbmBars = dbmBars

local SETTING_KEY = "hideBossModBars"
local BAR_NAME = "DBT_Bar_%d"
local HIDDEN_ALPHA = 0
local SHOWN_ALPHA = 1

local holders = {}
local tookMouse = {}

local function apply()
    local hidden = ns.options.Get(SETTING_KEY)
    local index = 1
    local bar = _G[BAR_NAME:format(index)]
    while bar do
        if not bar:IsForbidden() then
            local holder = bar:GetParent()
            if holder then
                holders[holder] = true
            end
            if hidden and bar:IsMouseEnabled() then
                tookMouse[bar] = true
                bar:EnableMouse(false)
            elseif not hidden and tookMouse[bar] then
                tookMouse[bar] = nil
                bar:EnableMouse(true)
            end
        end
        index = index + 1
        bar = _G[BAR_NAME:format(index)]
    end
    local alpha = hidden and HIDDEN_ALPHA or SHOWN_ALPHA
    for holder in pairs(holders) do
        if not holder:IsForbidden() then
            holder:SetAlpha(alpha)
        end
    end
end

local function applySoon()
    C_Timer.After(0, apply)
end

function dbmBars.Enable()
    if ns.bossMods.Active() ~= ns.bossMods.DBM then
        return
    end
    _G.DBM:RegisterCallback("DBM_TimerBegin", applySoon)
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("ENCOUNTER_TIMELINE_EVENT_ADDED")
    frame:SetScript("OnEvent", applySoon)
    ns.options.OnChanged(function(key)
        if key == SETTING_KEY then
            apply()
        end
    end)
    apply()
end
