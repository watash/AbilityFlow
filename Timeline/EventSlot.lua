local addonName, ns = ...

local C_EncounterTimeline = C_EncounterTimeline
local Enum = Enum

local timeline = ns.timeline

local SEVERITY = Enum.EncounterEventSeverity.Medium

local eventSlot = {}
ns.eventSlot = eventSlot

function eventSlot.New(defaultName, place)
    local slot = {}
    local eventID

    local function cancel()
        if eventID and C_EncounterTimeline.GetEventInfo(eventID) then
            C_EncounterTimeline.CancelScriptEvent(eventID)
        end
        eventID = nil
    end

    function slot.Start(seconds, text, icon, caption, icons)
        cancel()
        if type(seconds) ~= "number" or seconds <= 0 then
            return
        end
        eventID = C_EncounterTimeline.AddScriptEvent({
            duration = seconds,
            maxQueueDuration = 0,
            overrideName = type(text) == "string" and text ~= "" and text or defaultName,
            spellID = 0,
            iconFileID = type(icon) == "number" and icon or timeline.PLACEHOLDER_ICON_FILE_ID,
            icons = icons,
            severity = SEVERITY,
            paused = false,
        })
        if not eventID then
            return
        end
        local hasCaption = type(caption) == "function" or (type(caption) == "string" and caption ~= "")
        timeline.MarkLongEvent(eventID, place, hasCaption and caption or nil)
    end

    function slot.Stop()
        cancel()
    end

    return slot
end
