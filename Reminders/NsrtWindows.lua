local addonName, ns = ...

local CreateFrame = CreateFrame
local C_Timer = C_Timer
local IsEncounterInProgress = IsEncounterInProgress
local ipairs = ipairs

local nsrtWindows = {}
ns.nsrtWindows = nsrtWindows

local SETTING_KEY = "hideNsrtWindows"
local HIDDEN_ALPHA = 0
local WINDOW_FIELDS = { "ReminderFrame", "PersonalReminderFrame" }
local MOVER_SUFFIX = "Mover"

local savedAlpha = {}
local tookMouse = {}
local hidden = false
local fighting = false
local REAPPLY_DELAYS = { 0, 1 }

local function api()
    local addon = _G.NorthernSkyRaidTools
    return type(addon) == "table" and addon or nil
end

local function frames()
    local list = {}
    local addon = api()
    if not addon then
        return list
    end
    for _, field in ipairs(WINDOW_FIELDS) do
        for _, name in ipairs({ field, field .. MOVER_SUFFIX }) do
            local frame = addon[name]
            if type(frame) == "table" and frame.SetAlpha and not frame:IsForbidden() then
                list[#list + 1] = frame
            end
        end
    end
    return list
end

local function apply(hide)
    for _, frame in ipairs(frames()) do
        if hide then
            if savedAlpha[frame] == nil then
                savedAlpha[frame] = frame:GetAlpha()
            end
            frame:SetAlpha(HIDDEN_ALPHA)
            if frame:IsMouseEnabled() then
                tookMouse[frame] = true
                frame:EnableMouse(false)
            end
        else
            if savedAlpha[frame] ~= nil then
                frame:SetAlpha(savedAlpha[frame])
                savedAlpha[frame] = nil
            end
            if tookMouse[frame] then
                tookMouse[frame] = nil
                frame:EnableMouse(true)
            end
        end
    end
    hidden = hide
end

local function refresh()
    apply(ns.options.Get(SETTING_KEY) and fighting)
end

function nsrtWindows.Enable()
    if not ns.NSRT.IsAvailable() then
        return
    end
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("ENCOUNTER_START")
    frame:RegisterEvent("ENCOUNTER_END")
    fighting = IsEncounterInProgress()
    frame:SetScript("OnEvent", function(_, event)
        fighting = event == "ENCOUNTER_START"
        refresh()
        if fighting then
            for _, delay in ipairs(REAPPLY_DELAYS) do
                C_Timer.After(delay, refresh)
            end
        end
    end)
    ns.options.OnChanged(function(key)
        if key == SETTING_KEY then
            refresh()
        end
    end)
    refresh()
end

function nsrtWindows.IsHidden()
    return hidden
end
