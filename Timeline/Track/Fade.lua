local addonName, ns = ...

local CreateFrame = CreateFrame
local C_Timer = C_Timer
local IsEncounterInProgress = IsEncounterInProgress
local math = math

local timeline = ns.timeline
local frame = timeline.frame

local FADE_SECONDS = 0.2
local MODE_IN = "in"
local MODE_OUT = "out"

local mode, elapsed
local DISAPPEAR_DELAY = 0.15
local pendingHide
local PERCENT = 100
local overall = 1

local function setFrameAlpha(fade)
    frame:SetAlpha(fade * overall)
end

local driver = CreateFrame("Frame")
driver:Hide()

local function fadeSeconds()
    return FADE_SECONDS / timeline.AnimationSpeed()
end

timeline.FadeSeconds = fadeSeconds

local function opacity()
    local share = math.min(elapsed / fadeSeconds(), 1)
    if mode == MODE_IN then
        return share * share
    end
    return (1 - share) * (1 - share)
end

local function finish()
    driver:Hide()
    if mode == MODE_OUT then
        frame:Hide()
    end
    setFrameAlpha(1)
    mode, elapsed = nil, nil
end

driver:SetScript("OnUpdate", function(_, step)
    elapsed = elapsed + step
    if elapsed >= fadeSeconds() then
        finish()
        return
    end
    setFrameAlpha(opacity())
end)

local function start(newMode)
    local alpha = frame:IsShown() and overall > 0 and frame:GetAlpha() / overall or 0
    mode = newMode
    local share = math.sqrt(alpha)
    elapsed = (newMode == MODE_IN and share or 1 - share) * fadeSeconds()
    setFrameAlpha(opacity())
    frame:Show()
    driver:Show()
end

local function cancelPendingHide()
    if pendingHide then
        pendingHide:Cancel()
        pendingHide = nil
    end
end

function timeline.appear()
    cancelPendingHide()
    if mode == MODE_IN or (mode == nil and frame:IsShown()) then
        return
    end
    if not timeline.IsFadeAnimated() then
        timeline.setShownNow(true)
        return
    end
    start(MODE_IN)
end

local held = false

function timeline.setHeld(value)
    held = value
end

local fighting = false
local function keptShown()
    return held or fighting
end

function timeline.disappear()
    if keptShown() or mode == MODE_OUT or not frame:IsShown() then
        return
    end
    if not timeline.IsFadeAnimated() then
        if not pendingHide then
            pendingHide = C_Timer.NewTimer(DISAPPEAR_DELAY, function()
                pendingHide = nil
                if not keptShown() and not timeline.HasEvents() then
                    timeline.setShownNow(false)
                end
            end)
        end
        return
    end
    start(MODE_OUT)
end

function timeline.setShownNow(shown)
    cancelPendingHide()
    driver:Hide()
    mode, elapsed = nil, nil
    setFrameAlpha(1)
    frame:SetShown(shown)
end

function timeline.SetOverallTransparency(percent)
    overall = 1 - percent / PERCENT
    if mode == nil then
        setFrameAlpha(1)
    else
        setFrameAlpha(opacity())
    end
end

local fightWatcher = CreateFrame("Frame")
fightWatcher:RegisterEvent("ENCOUNTER_START")
fightWatcher:RegisterEvent("ENCOUNTER_END")
fightWatcher:RegisterEvent("PLAYER_ENTERING_WORLD")
fightWatcher:SetScript("OnEvent", function(_, event)
    fighting = event == "ENCOUNTER_START" or (event == "PLAYER_ENTERING_WORLD" and IsEncounterInProgress())
    if not fighting and not timeline.HasEvents() then
        timeline.disappear()
    end
end)
