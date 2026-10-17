local addonName, ns = ...

local C_Timer = C_Timer

local L = ns.L
local options = ns.options
local optionsTab = ns.appearanceOptionsTab

local addonsTab = {}
ns.appearanceAddonsTab = addonsTab

local NOTE_GAP = 10

local REFRESH_INTERVAL = 1

local BOSS_MOD_COLORS = { BigWigs = "ffff8c1a", DBM = "ffc77dff" }

local BASIC_TIMERS_NOTE_WIDTH = 600

local function noteWhenMissing(box, available)
    if not available() then
        local note = box:CreateFontString(nil, "OVERLAY", "GameFontDisable")
        note:SetPoint("LEFT", box.heading, "RIGHT", NOTE_GAP, 0)
        note:SetText(L.ADDONS_NOT_INSTALLED)
    end
end

function addonsTab.Build(content)
    local nsrtBox = optionsTab.CreateBox(content, nil, "Northern Sky Raid Tools", nil, {
        { label = L.ADDONS_NSRT_NOTES, key = "showNsrtNotes", tooltip = L.ADDONS_NSRT_NOTES_TOOLTIP,
            available = ns.NSRT.IsAvailable },
        { label = L.ADDONS_NSRT_ALERTS, key = "showNsrtAlerts", tooltip = L.ADDONS_NSRT_ALERTS_TOOLTIP,
            available = ns.NSRT.IsAvailable },
        { label = L.ADDONS_NSRT_COLORS, key = "colorNsrt", tooltip = L.ADDONS_NSRT_COLORS_TOOLTIP,
            available = ns.NSRT.IsAvailable },
        { label = L.ADDONS_NSRT_NOTES_COLOR, key = "nsrtNotesColor", color = true, enabledWhen = function()
            return options.Get("colorNsrt")
        end },
        { label = L.ADDONS_NSRT_ALERTS_COLOR, key = "nsrtAlertsColor", color = true, sameLine = true, enabledWhen = function()
            return options.Get("colorNsrt")
        end },
        { label = L.ADDONS_NSRT_HIDE_WINDOWS, key = "hideNsrtWindows", tooltip = L.ADDONS_NSRT_HIDE_WINDOWS_TOOLTIP,
            available = ns.NSRT.IsAvailable, column = 2 },
    })
    noteWhenMissing(nsrtBox, ns.NSRT.IsAvailable)

    local bossMods = ns.bossMods
    local bigWigs = ns.bigWigsNames
    local dbm = ns.dbmNames
    local function isActive()
        return bossMods.Active() ~= nil
    end
    local function usesOwnTimers()
        local active = bossMods.Active()
        if not isActive() then
            return false
        end
        if active == bossMods.BIGWIGS then
            return bigWigs.UsesOwnTimers()
        end
        return not dbm.BarsHiddenInDbm()
    end
    local bossBox = optionsTab.CreateBox(content, nsrtBox, L.ADDONS_BOSSMODS_HEADING, nil, {
        { label = L.ADDONS_BOSSMODS_NAMES, key = "showBossModNames", tooltip = L.ADDONS_BOSSMODS_NAMES_TOOLTIP,
            available = usesOwnTimers },
        { label = L.ADDONS_BOSSMODS_COLORS, key = "showBossModColors", tooltip = L.ADDONS_BOSSMODS_COLORS_TOOLTIP,
            available = usesOwnTimers },
        { label = L.ADDONS_BOSSMODS_TIMERS, key = "showBossModTimers", tooltip = L.ADDONS_BOSSMODS_TIMERS_TOOLTIP,
            available = isActive },
        { label = L.ADDONS_BOSSMODS_HIDE_BARS, key = "hideBossModBars", tooltip = L.ADDONS_BOSSMODS_HIDE_BARS_TOOLTIP:format(addonName),
            available = isActive },
        { label = L.OPTIONS_HIDE_GAME_EVENTS, key = "hideGameEvents", tooltip = L.OPTIONS_HIDE_GAME_EVENTS_TOOLTIP },
    })
    local used = bossBox:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    used:SetPoint("LEFT", bossBox.heading, "RIGHT", NOTE_GAP, 0)
    local function refreshUsed()
        local active = bossMods.Active()
        if not active then
            used:SetText(L.ADDONS_BOSSMODS_NONE)
            return
        end
        local name = ns.text.Colored(active, BOSS_MOD_COLORS[active])
        used:SetText(bossMods.DbmLeftOut() and L.ADDONS_BOSSMODS_DBM_UNUSED:format(name) or name)
    end
    local namesCheckbox = bossBox.checkboxes.showBossModNames
    local basicTimersNote = bossBox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    basicTimersNote:SetPoint("LEFT", namesCheckbox, "RIGHT", bossBox.noteOffset,
        -(namesCheckbox:GetHeight() + ns.appearanceControls.LABEL_GAP) / 2)
    basicTimersNote:SetWidth(BASIC_TIMERS_NOTE_WIDTH)
    basicTimersNote:SetJustifyH("LEFT")
    basicTimersNote:SetWordWrap(true)
    local function refreshBasicTimersNote()
        local active = bossMods.Active()
        if not active or usesOwnTimers() then
            basicTimersNote:SetText("")
            return
        end
        local text = active == bossMods.BIGWIGS and L.ADDONS_BIGWIGS_BASIC_TIMERS or L.ADDONS_DBM_BARS_OFF
        basicTimersNote:SetText(ns.text.Quoted(text, ns.text.RED, ns.text.GOLD))
    end
    local function refresh()
        refreshUsed()
        bossBox.RefreshAvailability()
        refreshBasicTimersNote()
    end
    refresh()
    local ticker
    content:HookScript("OnShow", function()
        refresh()
        ticker = ticker or C_Timer.NewTicker(REFRESH_INTERVAL, refresh)
    end)
    content:HookScript("OnHide", function()
        if ticker then
            ticker:Cancel()
            ticker = nil
        end
    end)

    optionsTab.AddReset(content, bossBox, { nsrtBox, bossBox }, options.ADDON_KEYS)
end
