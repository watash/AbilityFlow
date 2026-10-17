local addonName, ns = ...

local C_EncounterTimeline = C_EncounterTimeline
local C_Spell = C_Spell
local Enum = Enum
local CreateFrame = CreateFrame
local GetTime = GetTime
local C_Timer = C_Timer
local ipairs = ipairs
local pairs = pairs

local timeline = ns.timeline

local nsrt = {}
ns.NSRT = nsrt

local CALLBACK_PHASE = "NSRT_PHASE"
local NOTES_KEY = "showNsrtNotes"
local ALERTS_KEY = "showNsrtAlerts"
local COLOR_KEY = "colorNsrt"
local NOTES_COLOR_KEY = "nsrtNotesColor"
local ALERTS_COLOR_KEY = "nsrtAlertsColor"
local FULL_OPACITY = 1
local RELEASE_INTERVAL = 0.25
local KEEP_AFTER_SECONDS = 5
local SEVERITY = Enum.EncounterEventSeverity.High

local shown = {}
local pending = {}
local queueOrder = {}
local ticker
local alertOfID = {}
local receiver = {}

local function cancel(alerts)
    local keptOrder = {}
    for _, key in ipairs(queueOrder) do
        if alerts == nil or pending[key].alert == alerts then
            pending[key] = nil
        else
            keptOrder[#keptOrder + 1] = key
        end
    end
    queueOrder = keptOrder
    if ticker and #queueOrder == 0 then
        ticker:Cancel()
        ticker = nil
    end
    local kept = {}
    for _, entry in ipairs(shown) do
        if alerts == nil or entry.alert == alerts then
            if C_EncounterTimeline.GetEventInfo(entry.id) then
                C_EncounterTimeline.CancelScriptEvent(entry.id)
            end
            alertOfID[entry.id] = nil
        else
            kept[#kept + 1] = entry
        end
    end
    shown = kept
end

function nsrt.Entries(kept, encounterID, phase, testRun, kinds)
    local entries = {}
    if not kept then
        return entries
    end
    local function collect(ofEncounter)
        for _, info in ipairs(ofEncounter and ofEncounter[phase] or {}) do
            local text = type(info.text) == "string" and info.text ~= "" and info.text or nil
            local spellID = type(info.spellID) == "number" and info.spellID > 0 and info.spellID or nil
            local alert = (info.IsAlert or info.IsAssignment) and true or false
            local wanted = not info.isAnchorPreview and (alert and kinds.alerts or not alert and kinds.notes)
            if wanted and type(info.time) == "number" and info.time > 0 and (text or spellID) then
                entries[#entries + 1] = { seconds = info.time, text = text, spellID = spellID, alert = alert }
            end
        end
    end
    if testRun then
        for _, ofEncounter in pairs(kept) do
            collect(ofEncounter)
        end
    else
        collect(kept[encounterID])
    end
    table.sort(entries, function(a, b)
        return a.seconds < b.seconds
    end)
    return entries
end

local function isWaiting(key, now)
    for _, entry in ipairs(shown) do
        if entry.key == key and entry.deadline - now > timeline.TRACK_SPAN_SECONDS then
            return true
        end
    end
    return false
end

local function add(item, key, alert, now)
    local remaining = item.deadline - now
    if remaining <= 0 then
        return
    end
    local spellName, iconFile
    if item.spellID then
        local info = C_Spell.GetSpellInfo(item.spellID)
        spellName = info and info.name
        iconFile = C_Spell.GetSpellTexture(item.spellID)
    end
    local id = C_EncounterTimeline.AddScriptEvent({
        duration = remaining,
        maxQueueDuration = 0,
        overrideName = (item.text or spellName or "") .. (item.number and (" (" .. item.number .. ")") or ""),
        spellID = item.spellID or 0,
        iconFileID = iconFile or timeline.PLACEHOLDER_ICON_FILE_ID,
        severity = SEVERITY,
        paused = false,
    })
    if id then
        shown[#shown + 1] = { id = id, alert = alert, key = key, deadline = item.deadline }
        alertOfID[id] = alert
        timeline.RefreshEventName(id)
    end
end

local function release()
    local now = GetTime()
    local kept = {}
    for _, entry in ipairs(shown) do
        if now - entry.deadline <= KEEP_AFTER_SECONDS then
            kept[#kept + 1] = entry
        else
            alertOfID[entry.id] = nil
        end
    end
    shown = kept
    local waitingOrder = {}
    for _, key in ipairs(queueOrder) do
        local queue = pending[key]
        while #queue.items > 0 and not isWaiting(key, now) do
            add(table.remove(queue.items, 1), key, queue.alert, now)
        end
        if #queue.items > 0 then
            waitingOrder[#waitingOrder + 1] = key
        else
            pending[key] = nil
        end
    end
    queueOrder = waitingOrder
    if ticker and #queueOrder == 0 then
        ticker:Cancel()
        ticker = nil
    end
end

function nsrt.Show(entries)
    cancel()
    local now = GetTime()
    local total = {}
    for _, entry in ipairs(entries) do
        local key = (entry.alert and "alert " or "note ") .. (entry.text or ("spell " .. entry.spellID))
        total[key] = (total[key] or 0) + 1
    end
    local seen = {}
    for _, entry in ipairs(entries) do
        local key = (entry.alert and "alert " or "note ") .. (entry.text or ("spell " .. entry.spellID))
        seen[key] = (seen[key] or 0) + 1
        local queue = pending[key]
        if not queue then
            queue = { alert = entry.alert == true, items = {} }
            pending[key] = queue
            queueOrder[#queueOrder + 1] = key
        end
        queue.items[#queue.items + 1] = {
            deadline = now + entry.seconds, text = entry.text, spellID = entry.spellID,
            number = total[key] > 1 and seen[key] or nil,
        }
    end
    release()
    if not ticker and #queueOrder > 0 then
        ticker = C_Timer.NewTicker(RELEASE_INTERVAL, release)
    end
end

function nsrt.ColorOf(eventID, kind)
    local isAlert = alertOfID[eventID]
    if isAlert == nil or (kind ~= "text" and kind ~= "border") or not ns.options.Get(COLOR_KEY) then
        return nil
    end
    local color = ns.options.Get(isAlert and ALERTS_COLOR_KEY or NOTES_COLOR_KEY)
    return { r = color.r, g = color.g, b = color.b, a = FULL_OPACITY }
end

function nsrt.Enable()
    local api = _G.NorthernSkyRaidTools
    if not api or not api.RegisterCallback then
        return
    end
    api.RegisterCallback(receiver, CALLBACK_PHASE, function(_, phase, encounterID, testRun)
        local kinds = { notes = ns.options.Get(NOTES_KEY), alerts = ns.options.Get(ALERTS_KEY) }
        nsrt.Show(nsrt.Entries(api.ProcessedReminder, encounterID, phase, testRun, kinds))
    end)
    ns.eventStyle.AddColorSource(nsrt.ColorOf)
    ns.options.OnChanged(function(key, value)
        if key == COLOR_KEY or key == NOTES_COLOR_KEY or key == ALERTS_COLOR_KEY then
            for _, entry in ipairs(shown) do
                timeline.RefreshEventName(entry.id)
            end
        end
        if key == NOTES_KEY and not value then
            cancel(false)
        elseif key == ALERTS_KEY and not value then
            cancel(true)
        end
    end)
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("ENCOUNTER_END")
    frame:SetScript("OnEvent", function()
        cancel()
    end)
end

function nsrt.IsAvailable()
    local api = _G.NorthernSkyRaidTools
    return api ~= nil and api.RegisterCallback ~= nil
end
