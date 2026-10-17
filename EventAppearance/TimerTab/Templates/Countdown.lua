local addonName, ns = ...

local GetTime = GetTime
local floor = math.floor
local max = math.max
local pairs = pairs
local ipairs = ipairs
local timerStyle = ns.timerStyle
local previewEvent = ns.timerTab.event
local templates = ns.timerTab.templates
local state = templates.state

local COUNT_CYCLE = timerStyle.SECONDS
local COUNT_OFFSET = 1

function templates.Tick()
    local now = GetTime()
    for index, templateID in ipairs(timerStyle.Order()) do
        local event = state.widgets[templateID]
        local template = timerStyle.Template(templateID)
        if event and template then
            local phase = (now + (index - 1) * COUNT_OFFSET) % COUNT_CYCLE
            local second = timerStyle.SECONDS - floor(phase)
            event.texts.cooldown:SetText(previewEvent.SampleText(template,
                template.tenths and max(0, timerStyle.SECONDS - phase) or second))
        end
    end
end

function templates.FlashAll()
    for templateID, event in pairs(state.widgets) do
        local template = timerStyle.Template(templateID)
        if event:IsShown() and template and template.flash then
            ns.eventEffects.PlayFlash(event)
        end
    end
end

function templates.FlashOne(templateID)
    local event = state.widgets[templateID]
    if event and event:IsShown() then
        ns.eventEffects.HoldForPreview(event, true)
        ns.eventEffects.PlayFlash(event)
    end
end

function templates.EndFlashPreview()
    for _, event in pairs(state.widgets) do
        ns.eventEffects.HoldForPreview(event, false)
    end
end

function templates.StopAll()
    for _, event in pairs(state.widgets) do
        ns.timerPaint.Stop(event)
    end
end
