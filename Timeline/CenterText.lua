local addonName, ns = ...

local centerText = {}
ns.centerText = centerText

local ENABLED = false
local TRIGGER_SECONDS = 5
local LINE_WIDTH = 450
local LINE_HEIGHT = 40
local LINE_MARGIN = 5
local STATE_ACTIVE = Enum.EncounterTimelineEventState.Active

local container = CreateFrame("Frame", nil, UIParent)
container:SetSize(LINE_WIDTH, LINE_HEIGHT)
container:SetPoint("CENTER", UIParent, "CENTER")
container:SetFrameStrata("FULLSCREEN")
container:Hide()

local driver = CreateFrame("Frame")

local entries = {}
local entryCount = 0
local shownLines = {}
local linePool = {}

local function createLine()
    local line = CreateFrame("Frame", nil, container)
    line:SetSize(LINE_WIDTH, LINE_HEIGHT)
    line.text = line:CreateFontString(nil, "OVERLAY", "SystemFont_Shadow_Med3")
    line.text:SetPoint("CENTER", line, "CENTER")
    line.text:SetWordWrap(false)
    return line
end

local function byRemaining(a, b)
    if a.remaining ~= b.remaining then
        return a.remaining < b.remaining
    end
    return a.eventID < b.eventID
end

local suppressed = false

local function layoutLines()
    table.sort(shownLines, byRemaining)
    local previous
    for i = 1, #shownLines do
        local line = shownLines[i]
        line:ClearAllPoints()
        if previous then
            line:SetPoint("BOTTOM", previous, "TOP", 0, LINE_MARGIN)
        else
            line:SetPoint("BOTTOM", container, "BOTTOM", 0, 0)
        end
        previous = line
    end
    container:SetShown(not suppressed and #shownLines > 0)
end

function centerText.SetSuppressed(value)
    suppressed = value
    layoutLines()
end

local function attachLine(entry, eventID)
    local line = table.remove(linePool) or createLine()
    line.eventID = eventID
    line.remaining = 0
    line.shownSeconds = nil
    entry.line = line
    table.insert(shownLines, line)
    line:Show()
end

local function detachLine(entry)
    local line = entry.line
    for i = #shownLines, 1, -1 do
        if shownLines[i] == line then
            table.remove(shownLines, i)
            break
        end
    end
    line:Hide()
    line.eventID = nil
    table.insert(linePool, line)
    entry.line = nil
end

local function updateLines()
    for eventID, entry in pairs(entries) do
        local remaining = C_EncounterTimeline.GetEventTimeRemaining(eventID)
        local isActive = C_EncounterTimeline.GetEventState(eventID) == STATE_ACTIVE
        if not remaining or remaining <= 0 or not isActive then
            if entry.line then
                detachLine(entry)
            end
        elseif remaining <= TRIGGER_SECONDS then
            if not entry.line then
                attachLine(entry, eventID)
            end
            local line = entry.line
            line.remaining = remaining
            local seconds = math.ceil(remaining)
            if line.shownSeconds ~= seconds then
                line.shownSeconds = seconds
                line.text:SetText(string.format("%s in %d", entry.name, seconds))
            end
        end
    end
    layoutLines()
end

function centerText.Start(eventInfo)
    if not ENABLED or entries[eventInfo.id] then
        return
    end
    entries[eventInfo.id] = { name = eventInfo.spellName }
    entryCount = entryCount + 1
    if entryCount == 1 then
        driver:SetScript("OnUpdate", updateLines)
    end
end

function centerText.Stop(eventID)
    local entry = entries[eventID]
    if not entry then
        return
    end
    if entry.line then
        detachLine(entry)
    end
    entries[eventID] = nil
    entryCount = entryCount - 1
    if entryCount == 0 then
        driver:SetScript("OnUpdate", nil)
    end
    layoutLines()
end
