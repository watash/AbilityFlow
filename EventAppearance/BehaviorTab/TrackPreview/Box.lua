local addonName, ns = ...

local CreateFrame = CreateFrame
local GameTooltip = GameTooltip
local NORMAL_FONT_COLOR = NORMAL_FONT_COLOR
local C_Texture = C_Texture
local ipairs = ipairs

local L = ns.L
local timeline = ns.timeline
local trackPreview = ns.appearanceTrackPreview
local state = trackPreview.state

local ACTOR_COUNT = trackPreview.ACTOR_COUNT
local controls = ns.appearanceControls
local ZONE_LABEL_WIDTH = 70
local ZONE_HIT_LEVEL = 1
local ZONE_TIPS = {
    { name = "PREVIEW_ZONE_WAITING", tip = "PREVIEW_ZONE_WAITING_TIP" },
    { name = "PREVIEW_ZONE_TRACK", tip = "PREVIEW_ZONE_TRACK_TIP" },
    { name = "PREVIEW_ZONE_QUEUE", tip = "PREVIEW_ZONE_QUEUE_TIP" },
}
local LINE_ZERO_ATLAS = "combattimeline-line-right"
local LINE_FAR_ATLAS = "combattimeline-line-left"
local LINE_ZERO_SHARE = 0.25
local LINE_FAR_SHARE = 0.75
local ICON_LEVEL = 4
local ICONS_PER_ACTOR = 2

function trackPreview.Create(parent)
    if state.box then
        return state.box
    end
    local box = CreateFrame("Frame", nil, parent, "InsetFrameTemplate")
    state.box = box
    box:SetClipsChildren(true)

    local halves, dividers, icons = state.halves, state.dividers, state.icons
    for _, spec in ipairs({ { LINE_ZERO_ATLAS, LINE_ZERO_SHARE }, { LINE_FAR_ATLAS, LINE_FAR_SHARE } }) do
        halves[#halves + 1] = { texture = box:CreateTexture(nil, "ARTWORK", nil, 1), atlas = spec[1], share = spec[2] }
    end
    if C_Texture.GetAtlasInfo(timeline.DIVIDER_ATLAS) then
        dividers[1], dividers[2] = trackPreview.BuildDivider(box), trackPreview.BuildDivider(box)
    end

    local spells = #ns.timerStyle.ICON_SPELLS
    for index = 1, ACTOR_COUNT do
        local firstIcon = (index - 1) * ICONS_PER_ACTOR
        local level = ICON_LEVEL + firstIcon * timeline.EVENT_LEVEL_BLOCK
        local actor = {
            main = trackPreview.BuildIcon(firstIcon % spells + 1, level, "MAGIC"),
            passing = trackPreview.BuildIcon((firstIcon + 1) % spells + 1, level + timeline.EVENT_LEVEL_BLOCK, "BLEED"),
        }
        state.actors[index] = actor
        icons[#icons + 1] = actor.main
        icons[#icons + 1] = actor.passing
    end
    ns.appearance.OnChanged(function()
        if icons[1] then
            trackPreview.StyleIcons()
        end
    end)
    box:SetScript("OnSizeChanged", function()
        if icons[1] then
            trackPreview.LayoutTrack()
        end
    end)
    for index, zone in ipairs(ZONE_TIPS) do
        local label = box:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
        label:SetWidth(ZONE_LABEL_WIDTH)
        label:SetJustifyH("RIGHT")
        label:SetText(L[zone.name])
        state.zoneLabels[index] = label
        local hit = CreateFrame("Frame", nil, box)
        hit:SetAllPoints(label)
        hit:SetFrameLevel(box:GetFrameLevel() + ZONE_HIT_LEVEL)
        hit:EnableMouse(true)
        hit:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(L[zone.name]:match("^[^\n]+"), 1, 1, 1)
            local red, green, blue = NORMAL_FONT_COLOR:GetRGB()
            GameTooltip:AddLine(L[zone.tip], red, green, blue, true)
            GameTooltip:Show()
        end)
        hit:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
    end
    state.whiteFill = box:CreateTexture(nil, "ARTWORK", nil, -1)
    state.whiteFill:SetPoint("TOPLEFT", box, "TOPLEFT", controls.GROUND_INSET, -controls.GROUND_INSET)
    state.whiteFill:SetPoint("BOTTOMRIGHT", box, "BOTTOMRIGHT", -controls.GROUND_INSET, controls.GROUND_INSET)
    state.whiteFill:SetColorTexture(1, 1, 1, 1)
    state.whiteFill:Hide()
    state.whiteToggle = controls.CreateGroundToggle(box, function()
        trackPreview.SetWhite(not state.whiteFill:IsShown())
    end)
    state.plainBackground = box:CreateTexture(nil, "ARTWORK", nil, 0)
    state.plainBorder = CreateFrame("Frame", nil, box, "BackdropTemplate")
    state.plainBorder:SetFrameLevel(box:GetFrameLevel() + 1)
    local previousColorChanged = timeline.onBackgroundColorChanged
    timeline.onBackgroundColorChanged = function()
        if previousColorChanged then
            previousColorChanged()
        end
        if icons[1] and not state.laidOutBlizzlike then
            trackPreview.LayoutPlain()
        end
    end
    local previousGeometry = timeline.onGeometryChanged
    timeline.onGeometryChanged = function()
        if previousGeometry then
            previousGeometry()
        end
        if icons[1] then
            trackPreview.LayoutTrack()
        end
    end
    box:SetScript("OnShow", trackPreview.Restart)
    box:EnableMouse(true)
    box:SetScript("OnMouseUp", function(_, button)
        if button == "RightButton" then
            trackPreview.Restart()
        elseif button == "LeftButton" then
            state.paused = not state.paused
        end
    end)
    box:SetScript("OnUpdate", function(_, step)
        trackPreview.Play(state.paused and 0 or step)
    end)
    return box
end

function trackPreview.SetWhite(white)
    if not state.whiteFill then
        return
    end
    state.whiteFill:SetShown(white)
    state.whiteToggle.Refresh(white)
end

function trackPreview.Ratio()
    return state.previewRatio
end

function trackPreview.Halves()
    return state.halves
end

function trackPreview.Icons()
    return state.icons
end

function trackPreview.Refresh()
    if state.icons[1] then
        trackPreview.StyleIcons()
    end
end
