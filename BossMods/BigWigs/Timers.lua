local addonName, ns = ...

local C_EncounterTimeline = C_EncounterTimeline
local Enum = Enum
local GetFileIDFromPath = GetFileIDFromPath
local issecretvalue = issecretvalue
local pairs = pairs
local pcall = pcall
local UnitGUID = UnitGUID

local timeline = ns.timeline

local bigWigsTimers = {}
ns.bigWigsTimers = bigWigsTimers

local MESSAGE_PAUSE_BAR = "BigWigs_PauseBar"
local MESSAGE_RESUME_BAR = "BigWigs_ResumeBar"
local MESSAGE_STOP_BAR = "BigWigs_StopBar"
local MESSAGE_STOP_BARS = "BigWigs_StopBars"
local MESSAGE_BOSS_DISABLE = "BigWigs_OnBossDisable"
local MESSAGE_PLUGIN_DISABLE = "BigWigs_OnPluginDisable"
local SETTING_KEY = "showBossModTimers"
local SEVERITY = Enum.EncounterEventSeverity.High
local SKIPPED_PLUGINS = { Pull = true, Break = true }
local BARS_PLUGIN = "Bars"
local CUSTOM_KEY_PREFIX = "bwcb"
local CUSTOM_TEXT_SEPARATOR = ": "
local BIGWIGS_LOCALE = "BigWigs"
local LOCAL_WORD_KEY = "localTimer"

local shown = {}
local receiver = {}

local function cancelEntry(entry)
    if C_EncounterTimeline.GetEventInfo(entry.id) then
        C_EncounterTimeline.CancelScriptEvent(entry.id)
    end
end

function bigWigsTimers.Stop(text)
    local entry = shown[text]
    if entry then
        cancelEntry(entry)
        shown[text] = nil
        ns.bigWigsColors.Forget(entry.id)
        if AbilityFlowDB.bigWigsTimerIDs then
            AbilityFlowDB.bigWigsTimerIDs[entry.id] = nil
        end
    end
end

local function stopAll(sender)
    for text, entry in pairs(shown) do
        if sender == nil or entry.sender == sender then
            bigWigsTimers.Stop(text)
        end
    end
end

function bigWigsTimers.IsSkipped(sender)
    return type(sender) == "table" and SKIPPED_PLUGINS[sender.moduleName] == true
end

local function iconFile(icon)
    if type(icon) == "number" and not issecretvalue(icon) then
        return icon
    end
    if type(icon) == "string" and not issecretvalue(icon) and GetFileIDFromPath then
        local file = GetFileIDFromPath(icon)
        if type(file) == "number" then
            return file
        end
    end
    return timeline.PLACEHOLDER_ICON_FILE_ID
end

local function localWord()
    local api = _G.BigWigsAPI
    if type(api) ~= "table" or not api.GetLocale then
        return nil
    end
    local ok, locale = pcall(api.GetLocale, api, BIGWIGS_LOCALE)
    return ok and type(locale) == "table" and locale[LOCAL_WORD_KEY] or nil
end

function bigWigsTimers.SplitCustomBar(sender, key, text)
    if type(sender) ~= "table" or sender.moduleName ~= BARS_PLUGIN or type(key) ~= "string"
        or key:sub(1, #CUSTOM_KEY_PREFIX) ~= CUSTOM_KEY_PREFIX then
        return nil, nil
    end
    local separator = text:find(CUSTOM_TEXT_SEPARATOR, 1, true)
    if not separator then
        return nil, nil
    end
    local words = text:sub(separator + #CUSTOM_TEXT_SEPARATOR)
    if words == "" or key:sub(-#words) ~= words then
        return nil, nil
    end
    local starter = key:sub(#CUSTOM_KEY_PREFIX + 1, #key - #words)
    if starter == "" or starter == localWord() then
        return words, nil
    end
    return words, starter
end

function bigWigsTimers.Start(sender, text, seconds, icon, key)
    bigWigsTimers.Stop(text)
    if not ns.options.Get(SETTING_KEY) or bigWigsTimers.IsSkipped(sender) or type(seconds) ~= "number" or seconds <= 0 then
        return
    end
    local name, caption = text, nil
    local words, starter = bigWigsTimers.SplitCustomBar(sender, key, text)
    if words then
        name = words
        local guid = starter and UnitGUID(starter)
        if guid and issecretvalue(guid) then
            guid = nil
        end
        caption = ns.playerName.Caption(starter, guid)
    end
    local id = C_EncounterTimeline.AddScriptEvent({
        duration = seconds,
        maxQueueDuration = 0,
        overrideName = name,
        spellID = 0,
        iconFileID = iconFile(icon),
        severity = SEVERITY,
        paused = false,
    })
    if not id then
        return
    end
    ns.bigWigsColors.Remember(id, sender, key)
    timeline.MarkLongEvent(id, nil, caption)
    timeline.RefreshEventName(id)
    shown[text] = { id = id, sender = sender }
    AbilityFlowDB.bigWigsTimerIDs = AbilityFlowDB.bigWigsTimerIDs or {}
    AbilityFlowDB.bigWigsTimerIDs[id] = true
end

local function setPaused(text, pause)
    local entry = type(text) == "string" and shown[text]
    if entry then
        pcall(pause and C_EncounterTimeline.PauseScriptEvent or C_EncounterTimeline.ResumeScriptEvent, entry.id)
    end
end

function bigWigsTimers.Enable()
    for id in pairs(AbilityFlowDB.bigWigsTimerIDs or {}) do
        pcall(C_EncounterTimeline.CancelScriptEvent, id)
    end
    AbilityFlowDB.bigWigsTimerIDs = nil
    local loader = _G.BigWigsLoader
    if not loader or not loader.RegisterMessage then
        return
    end
    loader.RegisterMessage(receiver, MESSAGE_PAUSE_BAR, function(_, _, text)
        setPaused(text, true)
    end)
    loader.RegisterMessage(receiver, MESSAGE_RESUME_BAR, function(_, _, text)
        setPaused(text, false)
    end)
    loader.RegisterMessage(receiver, MESSAGE_STOP_BAR, function(_, _, text)
        if type(text) == "string" then
            bigWigsTimers.Stop(text)
        end
    end)
    for _, message in pairs({ MESSAGE_STOP_BARS, MESSAGE_BOSS_DISABLE, MESSAGE_PLUGIN_DISABLE }) do
        loader.RegisterMessage(receiver, message, function(_, sender)
            if sender ~= nil then
                stopAll(sender)
            end
        end)
    end
    ns.options.OnChanged(function(key, value)
        if key == SETTING_KEY and not value then
            stopAll()
        end
    end)
end
