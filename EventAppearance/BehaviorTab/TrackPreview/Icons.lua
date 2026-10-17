local addonName, ns = ...

local C_Spell = C_Spell
local ipairs = ipairs
local math = math

local L = ns.L
local timeline = ns.timeline
local trackPreview = ns.appearanceTrackPreview
local state = trackPreview.state

local ICON_SIZE = trackPreview.ICON_SIZE
local TEXT_SHARE = 0.75

function trackPreview.ShowBorderType(event)
    local typed = event.debuffBorderShown == true
    for index, entry in ipairs(ns.debuff.TYPES) do
        for _, fill in ipairs(event.debuffBorders[index]) do
            fill:SetShown(typed and entry.key == event.sampleType)
        end
    end
end

function trackPreview.ShowCountdown(event, remaining)
    local seconds = (remaining > 0 and not ns.statusMark.HasSign(event)) and math.ceil(remaining) or 0
    if event.countdownSeconds ~= seconds then
        event.countdownSeconds = seconds
        event.texts.cooldown:SetText(seconds > 0 and ns.countdownFormat.Of(seconds) or "")
    end
end

function trackPreview.KeepBorderType(event)
    if not ns.statusMark.IsFramed(event) then
        trackPreview.ShowBorderType(event)
    end
end

function trackPreview.BuildSampleIcon(parent, level, spellIndex, typeKey, size)
    local event = ns.eventFrame.Create(parent, level)
    ns.eventStyle.Decorate(event)
    local spells = ns.timerStyle.ICON_SPELLS
    event.texture:SetTexture(C_Spell.GetSpellTexture(spells[spellIndex]) or timeline.PLACEHOLDER_ICON_FILE_ID)
    event.texts.cooldown:SetText("")
    event.debuffIndicator:Hide()
    event.dangerIndicator:Hide()
    for _, role in ipairs(event.roleIndicators) do
        role:Hide()
    end
    event:SetSize(size, size)
    event.sampleType = typeKey
    ns.eventStyle.Apply(event)
    trackPreview.ShowBorderType(event)
    return event
end

function trackPreview.BuildIcon(spellIndex, level, typeKey)
    local box = state.box
    local event = trackPreview.BuildSampleIcon(box, box:GetFrameLevel() + level, spellIndex, typeKey, ICON_SIZE)
    trackPreview.BuildTrail(event)
    return event
end

function trackPreview.StyleIcons()
    local icons = state.icons
    trackPreview.PlanStory()
    state.previewRatio = ICON_SIZE / math.max(timeline.currentIconSize(), 1)
    for _, event in ipairs(icons) do
        ns.eventStyle.Apply(event)
        event.grown = nil
        event.countdownSeconds = nil
        trackPreview.ShowBorderType(event)
        event.nameFlipped = ns.eventStyle.NameSide() == "LEFT"
        ns.eventStyle.PlaceName(event)
        trackPreview.LayoutTrail(event)
    end
    for index, event in ipairs(icons) do
        local name = event.texts.name
        name:SetText(L.STATES_SAMPLE_NAME:format(index))
        local path, size, flags = name:GetFont()
        if path then
            name:SetFont(path, size * TEXT_SHARE, flags)
        end
        ns.statusMark.Layout(event)
        ns.eventStyle.PlaceName(event)
    end
    trackPreview.LayoutTrack()
end

function trackPreview.SetGrowth(event, growth)
    if event.grown == growth then
        return
    end
    event.grown = growth
    local reach = ns.eventStyle.BorderThickness(event:GetWidth()) + (growth - 1) * event:GetWidth() / 2
    event.container:ClearAllPoints()
    event.container:SetPoint("TOPLEFT", event, "TOPLEFT", -reach, reach)
    event.container:SetPoint("BOTTOMRIGHT", event, "BOTTOMRIGHT", reach, -reach)
end

function trackPreview.PutIcon(event, x, y)
    event:ClearAllPoints()
    event:SetPoint("CENTER", state.box, "TOPLEFT", x, -y)
end
