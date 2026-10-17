local addonName, ns = ...

local CreateFrame = CreateFrame
local PixelUtil = PixelUtil
local L = ns.L
local appearance = ns.appearance

local selectors = {}
ns.appearanceSelectors = selectors

local HOVER_LIGHT = { 1, 1, 1, 0.3 }
local HOVER_DARK = { 0, 0, 0, 0.3 }
local HOVER_COLORED_ALPHA = 0.5
local PANEL_DARK_LEVEL = 0.1
local LUMA_RED, LUMA_GREEN, LUMA_BLUE = 0.2126, 0.7152, 0.0722
local LUMA_THRESHOLD = 0.5
local SELECTED_COLOR = { 0, 0.9, 1, 1 }
local SELECTED_COLOR_ON_WHITE = { 0.85, 0.4, 0, 1 }
local OUTLINE_THICKNESS = 1
local OUTLINE_MIN_PIXELS = 2
local OUTLINE_GAP = 4
local OUTLINE_GAP_SHARE = 0.25
local LEVEL_UNDER_BADGES = 2
local LEVEL_DETAIL = 13
local LEVEL_BACKGROUND = LEVEL_DETAIL - 1
local MIN_BORDER_BUTTON = 3
local FRAME_BAND_RATIO = 0.85
local FRAME_BAND_INSET_RATIO = 0.5
local MIN_FRAME_BUTTON = 1.5
local FRAME_BAND_TRIM = 1

local ELEMENTS = {
    { key = "icon", level = LEVEL_UNDER_BADGES, outline = true, regions = function(event) return { event.texture } end },
    { key = "cooldown", level = LEVEL_DETAIL, outline = true, regions = function(event) return { event.texts.cooldown } end },
    { key = "debuff", level = LEVEL_DETAIL, outline = true, regions = function(event) return { event.debuffIndicator } end },
    { key = "danger", level = LEVEL_DETAIL, outline = true, regions = function(event) return { event.dangerIndicator } end },
    { key = "name", level = LEVEL_DETAIL, outline = true, regions = function(event) return { event.texts.name } end },
    {
        key = "nameBackground", level = LEVEL_BACKGROUND, outline = true,
        regions = function(event) return { event.textBackgrounds.name } end,
        colorOf = function()
            return appearance.BackgroundPath("name") and appearance.Get("nameBackground", "color") or nil
        end,
    },
    { key = "roles", level = LEVEL_DETAIL, outline = true, regions = function(event) return event.roleIndicators end },
}

local panel
local event
local onSelect
local whiteBacking = false
local entries = {}
local borderEdges
local outerFrame
local iconButton
local backgroundButton
local selectedKey

local function createHighlight(parent, asButton)
    local frame = CreateFrame(asButton and "Button" or "Frame", nil, parent)
    if not asButton then
        frame:EnableMouse(false)
    end

    local tint = frame:CreateTexture(nil, "OVERLAY")
    tint:SetAllPoints()
    tint:SetColorTexture(1, 1, 1, 0)

    local function strip()
        local texture = frame:CreateTexture(nil, "OVERLAY")
        texture:SetColorTexture(0, 0, 0, 0)
        return texture
    end
    local top, bottom, left, right = strip(), strip(), strip(), strip()
    local strips = { top, bottom, left, right }

    function frame:SetOutlineThickness(t)
        top:ClearAllPoints()
        top:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", -t, 0)
        top:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", t, 0)
        top:SetHeight(t)
        bottom:ClearAllPoints()
        bottom:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", -t, 0)
        bottom:SetPoint("TOPRIGHT", frame, "BOTTOMRIGHT", t, 0)
        bottom:SetHeight(t)
        left:ClearAllPoints()
        left:SetPoint("TOPRIGHT", frame, "TOPLEFT", 0, 0)
        left:SetPoint("BOTTOMRIGHT", frame, "BOTTOMLEFT", 0, 0)
        left:SetWidth(t)
        right:ClearAllPoints()
        right:SetPoint("TOPLEFT", frame, "TOPRIGHT", 0, 0)
        right:SetPoint("BOTTOMLEFT", frame, "BOTTOMRIGHT", 0, 0)
        right:SetWidth(t)
    end
    frame:SetOutlineThickness(OUTLINE_THICKNESS)

    function frame:SetTint(red, green, blue, alpha)
        tint:SetColorTexture(red, green, blue, alpha)
    end

    function frame:SetOutline(red, green, blue, alpha)
        for _, texture in ipairs(strips) do
            texture:SetColorTexture(red, green, blue, alpha)
        end
    end

    return frame
end

local function tintAgainst(color)
    local alpha = color.a or 1
    local ground = whiteBacking and 1 or PANEL_DARK_LEVEL
    local brightness = (color.r * LUMA_RED + color.g * LUMA_GREEN + color.b * LUMA_BLUE) * alpha + ground * (1 - alpha)
    local base = brightness > LUMA_THRESHOLD and HOVER_DARK or HOVER_LIGHT
    return { base[1], base[2], base[3], HOVER_COLORED_ALPHA }
end

local function setHovered(entry, hovered)
    local group = entry.group
    local color = entry.colorOf and entry.colorOf()
    local tint = color and tintAgainst(color) or (whiteBacking and HOVER_DARK or HOVER_LIGHT)
    for _, highlight in ipairs(group) do
        if hovered then
            highlight:SetTint(tint[1], tint[2], tint[3], tint[4])
        else
            highlight:SetTint(0, 0, 0, 0)
        end
    end
end

function selectors.UpdateOutlineThickness()
    if not event then
        return
    end
    local thickness = PixelUtil.GetNearestPixelSize(OUTLINE_THICKNESS, event:GetEffectiveScale(), OUTLINE_MIN_PIXELS)
    for _, entry in ipairs(entries) do
        for _, highlight in ipairs(entry.outlines or entry.group) do
            if highlight.SetOutlineThickness then
                highlight:SetOutlineThickness(thickness)
            end
        end
    end
end

local outlineHidden = false

function selectors.SetSelected(key)
    selectedKey = key
    for _, entry in ipairs(entries) do
        local color = { 0, 0, 0, 0 }
        if entry.key == key and entry.outline and not outlineHidden then
            color = whiteBacking and SELECTED_COLOR_ON_WHITE or SELECTED_COLOR
        end
        for _, highlight in ipairs(entry.outlines or entry.group) do
            if highlight.SetOutline then
                highlight:SetOutline(color[1], color[2], color[3], color[4])
            end
        end
    end
end

function selectors.SetOutlineHidden(hidden)
    outlineHidden = hidden
    selectors.SetSelected(selectedKey)
end

local function choose(key)
    selectors.SetSelected(key)
    onSelect(key)
end

local function clicked(entry)
    local matches = {}
    for _, other in ipairs(entries) do
        for _, frame in ipairs(other.frames) do
            if frame:IsMouseOver() then
                table.insert(matches, other)
                break
            end
        end
    end
    if #matches <= 1 then
        choose(entry.key)
        return
    end
    MenuUtil.CreateContextMenu(panel, function(_, rootDescription)
        rootDescription:CreateTitle(L.EVENT_APPEARANCE_PICKER_TITLE)
        for _, match in ipairs(matches) do
            rootDescription:CreateButton(L["EVENT_APPEARANCE_ELEMENT_" .. match.key:upper()], function()
                choose(match.key)
            end)
        end
    end)
end

local function createElementButton(spec)
    local regions = spec.regions(event)
    local highlight = createHighlight(event, true)
    if spec.key == "icon" then
        iconButton = highlight
    elseif spec.key == "nameBackground" then
        backgroundButton = highlight
    end
    if #regions == 1 then
        highlight:SetAllPoints(regions[1])
    else
        highlight:SetScript("OnUpdate", function(self)
            local left, right, top, bottom
            for _, region in ipairs(regions) do
                local regionLeft, regionRight = region:GetLeft(), region:GetRight()
                local regionTop, regionBottom = region:GetTop(), region:GetBottom()
                if regionLeft and region:IsShown() then
                    if not left or regionLeft < left.value then left = { region = region, value = regionLeft } end
                    if not right or regionRight > right.value then right = { region = region, value = regionRight } end
                    if not top or regionTop > top.value then top = { region = region, value = regionTop } end
                    if not bottom or regionBottom < bottom.value then
                        bottom = { region = region, value = regionBottom }
                    end
                end
            end
            if left then
                self:ClearAllPoints()
                self:SetPoint("LEFT", left.region, "LEFT")
                self:SetPoint("RIGHT", right.region, "RIGHT")
                self:SetPoint("TOP", top.region, "TOP")
                self:SetPoint("BOTTOM", bottom.region, "BOTTOM")
            end
        end)
    end
    highlight:SetFrameLevel(event:GetFrameLevel() + spec.level)
    local entry = {
        key = spec.key, outline = spec.outline, frames = { highlight }, group = { highlight }, colorOf = spec.colorOf,
    }
    table.insert(entries, entry)
    highlight:SetScript("OnEnter", function() setHovered(entry, true) end)
    highlight:SetScript("OnLeave", function() setHovered(entry, false) end)
    highlight:SetScript("OnClick", function() clicked(entry) end)
end

local function placeBand(edges, thickness, inset)
    local top, bottom, left, right = edges[1], edges[2], edges[3], edges[4]
    top:ClearAllPoints()
    top:SetPoint("BOTTOMLEFT", event, "TOPLEFT", -thickness, -inset)
    top:SetPoint("BOTTOMRIGHT", event, "TOPRIGHT", thickness, -inset)
    top:SetHeight(thickness + inset)
    bottom:ClearAllPoints()
    bottom:SetPoint("TOPLEFT", event, "BOTTOMLEFT", -thickness, inset)
    bottom:SetPoint("TOPRIGHT", event, "BOTTOMRIGHT", thickness, inset)
    bottom:SetHeight(thickness + inset)
    left:ClearAllPoints()
    left:SetPoint("TOPRIGHT", event, "TOPLEFT", inset, -inset)
    left:SetPoint("BOTTOMRIGHT", event, "BOTTOMLEFT", inset, inset)
    left:SetWidth(thickness + inset)
    right:ClearAllPoints()
    right:SetPoint("TOPLEFT", event, "TOPRIGHT", -inset, -inset)
    right:SetPoint("BOTTOMLEFT", event, "BOTTOMRIGHT", -inset, inset)
    right:SetWidth(thickness + inset)
end

function selectors.PlaceBackgroundButton()
    if not backgroundButton or not event then
        return
    end
    local outset = 0
    if appearance.BackgroundBorderPath("name") then
        outset = math.max(0, appearance.Get("nameBackground", "borderOffset"))
    end
    local region = event.textBackgrounds.name
    backgroundButton:ClearAllPoints()
    backgroundButton:SetPoint("TOPLEFT", region, "TOPLEFT", -outset, outset)
    backgroundButton:SetPoint("BOTTOMRIGHT", region, "BOTTOMRIGHT", outset, -outset)
end

local function placeIconButton(inset)
    if not iconButton then
        return
    end
    iconButton:ClearAllPoints()
    iconButton:SetPoint("TOPLEFT", event.texture, "TOPLEFT", inset, -inset)
    iconButton:SetPoint("BOTTOMRIGHT", event.texture, "BOTTOMRIGHT", -inset, inset)
end

local function createBorderButtons(iconEntry)
    local edges, tints = {}, {}
    for index = 1, 4 do
        local edge = CreateFrame("Button", nil, event)
        edge:SetFrameLevel(event:GetFrameLevel() + LEVEL_UNDER_BADGES)
        local tint = edge:CreateTexture(nil, "OVERLAY")
        tint:SetAllPoints()
        tint:SetColorTexture(0, 0, 0, 0)
        edges[index], tints[index] = edge, tint
    end
    borderEdges = edges

    local visual = {}
    function visual:SetTint(red, green, blue, alpha)
        for _, tint in ipairs(tints) do
            tint:SetColorTexture(red, green, blue, alpha)
        end
    end
    table.insert(iconEntry.group, visual)
    outerFrame = createHighlight(event, false)
    outerFrame:SetFrameLevel(event:GetFrameLevel() + LEVEL_DETAIL)
    iconEntry.outlines = { outerFrame }
    for _, edge in ipairs(edges) do
        table.insert(iconEntry.frames, edge)
        edge:SetScript("OnEnter", function() setHovered(iconEntry, true) end)
        edge:SetScript("OnLeave", function() setHovered(iconEntry, false) end)
        edge:SetScript("OnClick", function() clicked(iconEntry) end)
    end
end

function selectors.PlaceBorderButtons(borderThickness, isFrame)
    if not borderEdges then
        return
    end
    local pixel = 1 / event:GetScale()
    local minimum = MIN_BORDER_BUTTON
    local inset = 0
    local band = 0
    if borderThickness > 0 then
        if isFrame then
            inset = math.max(0, borderThickness * FRAME_BAND_INSET_RATIO - FRAME_BAND_TRIM * pixel)
            borderThickness = borderThickness * FRAME_BAND_RATIO - FRAME_BAND_TRIM * pixel
            minimum = MIN_FRAME_BUTTON - FRAME_BAND_TRIM
        end
        band = math.max(borderThickness, minimum * pixel)
        placeBand(borderEdges, band, inset)
    end
    for _, edge in ipairs(borderEdges) do
        edge:SetShown(band > 0)
    end
    placeIconButton(inset)
    local reach = band + OUTLINE_GAP * pixel + band * OUTLINE_GAP_SHARE
    outerFrame:ClearAllPoints()
    outerFrame:SetPoint("TOPLEFT", event, "TOPLEFT", -reach, reach)
    outerFrame:SetPoint("BOTTOMRIGHT", event, "BOTTOMRIGHT", reach, -reach)
end

function selectors.SetWhiteBacking(white)
    whiteBacking = white
    selectors.SetSelected(selectedKey)
end

function selectors.Build(previewPanel, selected)
    panel, event, onSelect = previewPanel, previewPanel.sample, selected
    for _, spec in ipairs(ELEMENTS) do
        createElementButton(spec)
    end
    for _, entry in ipairs(entries) do
        if entry.key == "icon" then
            createBorderButtons(entry)
        end
    end

    local catcher = CreateFrame("Button", nil, panel)
    catcher:SetAllPoints()
    catcher:SetFrameLevel(panel:GetFrameLevel() + 1)
    catcher:SetScript("OnClick", function()
        if selectedKey then
            choose(nil)
        end
    end)
end
