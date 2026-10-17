local addonName, ns = ...

local CreateFrame = CreateFrame
local C_Spell = C_Spell
local GetTime = GetTime
local L = ns.L
local appearance = ns.appearance
local selectors = ns.appearanceSelectors

local preview = {}
ns.appearancePreview = preview

local SAMPLE_ICON_FILE_ID = ns.timeline.PLACEHOLDER_ICON_FILE_ID
local SAMPLE_DEBUFF_ATLAS = "icons_16x16_magic"
local SAMPLE_DANGER_ATLAS = "icons_16x16_deadly"
local SAMPLE_ROLE_ATLASES = { "icons_16x16_heal", "icons_16x16_tank" }
local DISABLED_INDICATOR_ALPHA = 0.45
local DISABLED_NAME_GRAY = 0.6
local COUNTDOWN_PLATE_ALPHA = 0.6
local COUNTDOWN_PLATE_PADDING = 2
local COUNTDOWN_SECONDS = 15
local EDGE_MARGIN = 45
local MIN_FITTED_PERCENT = 10
local FIT_MARGIN = 8
local HELD_BACK_TOLERANCE = 0.5
local UNIT_SCALE = 1
local OPPOSITE_SIDE = { LEFT = "RIGHT", RIGHT = "LEFT" }
local INWARD = { LEFT = 1, RIGHT = -1 }
local OVERHANG = {
    LEFT = function(event, region) return event:GetLeft() - region:GetLeft() end,
    RIGHT = function(event, region) return region:GetRight() - event:GetRight() end,
}
local GROUND_INSET = ns.appearanceControls.GROUND_INSET

local function runCountdown(event)
    local startTime = GetTime()
    event:SetScript("OnUpdate", function(self)
        local now = GetTime()
        if startTime + COUNTDOWN_SECONDS < now then
            startTime = now
        end
        local seconds = math.ceil(startTime + COUNTDOWN_SECONDS - now)
        if self.shownSeconds ~= seconds then
            self.shownSeconds = seconds
            self.texts.cooldown:SetText(tostring(seconds))
        end
    end)
end

local function createWhiteToggle(panel)
    panel.whiteToggle = ns.appearanceControls.CreateGroundToggle(panel, function()
        preview.SetWhite(panel, not panel.whiteFill:IsShown())
    end)
end

local function showRandomPicture(event)
    local pool = ns.timerStyle.ICON_SPELLS
    local spellID
    repeat
        spellID = pool[math.random(#pool)]
    until spellID ~= event.sampleSpell
    event.sampleSpell = spellID
    event.texture:SetTexture(C_Spell.GetSpellTexture(spellID) or SAMPLE_ICON_FILE_ID)
end

local RESET_BUTTON_LEVEL = 10

local function placeResetButton(panel)
    local corner = ns.eventStyle.NameSide() == "LEFT" and "BOTTOMLEFT" or "BOTTOMRIGHT"
    local sideMargin = ns.appearanceControls.RESET_BUTTON_RIGHT_MARGIN
    panel.resetButton:ClearAllPoints()
    panel.resetButton:SetPoint(corner, panel, corner, corner == "BOTTOMLEFT" and sideMargin or -sideMargin,
        ns.appearanceControls.RESET_BUTTON_BOTTOM_MARGIN)
end

local function createResetButton(panel)
    local button = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    button:SetText(L.EVENT_APPEARANCE_RESET)
    ns.appearanceControls.SizeResetButton(button)
    button:SetFrameLevel(panel:GetFrameLevel() + RESET_BUTTON_LEVEL)
    button:SetScript("OnClick", function()
        local warning = L.EVENT_APPEARANCE_RESET_ALL_WARNING:format(ns.text.Red(L.EVENT_APPEARANCE_RESET_ALL_IRREVERSIBLE))
        ns.appearanceDialogs.Confirm(warning, L.EVENT_APPEARANCE_RESET_ALL_ACCEPT, function()
            appearance.ResetAll()
            ns.appearanceGeneral.Refresh()
            preview.Refresh(panel)
        end)
    end)
    panel.resetButton = button
    placeResetButton(panel)
    local function updateEnabled()
        button:SetEnabled(not appearance.AllDefault())
    end
    appearance.OnChanged(updateEnabled)
    updateEnabled()
end

local function setSampleName(panel)
    local horizontal = ns.timeline.GetOrientation() == ns.timeline.ORIENTATION_HORIZONTAL
    panel.sample.texts.name:SetText(horizontal and L.EVENT_APPEARANCE_SAMPLE_NAME_HORIZONTAL or L.EVENT_APPEARANCE_SAMPLE_NAME)
end

function preview.Create(parent, onSelect)
    local panel = CreateFrame("Frame", nil, parent, "InsetFrameTemplate")

    panel.whiteFill = panel:CreateTexture(nil, "ARTWORK")
    panel.whiteFill:SetPoint("TOPLEFT", panel, "TOPLEFT", GROUND_INSET, -GROUND_INSET)
    panel.whiteFill:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -GROUND_INSET, GROUND_INSET)
    panel.whiteFill:SetColorTexture(1, 1, 1, 1)
    panel.whiteFill:Hide()

    local event = ns.eventFrame.Create(panel, panel:GetFrameLevel() + 2)
    ns.eventStyle.Decorate(event)
    showRandomPicture(event)
    event.debuffEntry = ns.debuff.FindType(ns.debuff.MAGIC_MASK)
    event.debuffIndicator:SetAtlas(SAMPLE_DEBUFF_ATLAS)
    event.dangerIndicator:SetAtlas(SAMPLE_DANGER_ATLAS)
    for index, atlas in ipairs(SAMPLE_ROLE_ATLASES) do
        event.roleIndicators[index]:SetAtlas(atlas)
    end
    panel.sample = event
    preview.panel = panel
    setSampleName(panel)
    local previousGeometry = ns.timeline.onGeometryChanged
    ns.timeline.onGeometryChanged = function()
        if previousGeometry then
            previousGeometry()
        end
        setSampleName(panel)
        preview.Refresh(panel)
    end
    panel.percent, panel.shift = 100, 0
    runCountdown(event)

    createWhiteToggle(panel)
    createResetButton(panel)
    selectors.Build(panel, onSelect)
    return panel
end

local function measureContent(panel)
    local event = panel.sample
    local scale = ns.eventStyle.Scale()
    local name = event.texts.name
    local textAlong, textAcross = name:GetStringWidth(), name:GetStringHeight()
    local backgroundAlong = appearance.Get("nameBackground", "offsetX")
    local backgroundAcross = appearance.Get("nameBackground", "offsetY")
    local shiftAlong = appearance.Get("name", "shiftX") * scale
    local shiftAcross = appearance.Get("name", "shiftY") * scale
    if not appearance.BackgroundPath("name") then
        backgroundAlong, backgroundAcross = 0, 0
    elseif appearance.Get("nameBackground", "borderTexture") ~= ns.media.NONE then
        local reach = math.max(appearance.Get("nameBackground", "borderOffset"), 0) + appearance.Get("nameBackground", "borderThickness")
        backgroundAlong, backgroundAcross = backgroundAlong + reach, backgroundAcross + reach
    end
    local size = event:GetWidth()
    local outward = math.max(0, ns.eventStyle.NAME_GAP + (event.flatReach or 0) + shiftAlong + textAlong + backgroundAlong)
    local halfAcross = math.max(size / 2, math.abs(shiftAcross) + textAcross / 2 + backgroundAcross)
    return size + outward, halfAcross
end

local function overhang(event, side)
    if not event:GetLeft() then
        return 0
    end
    local measure = OVERHANG[side]
    local most = 0
    local debuff, danger = event.debuffIndicator, event.dangerIndicator
    if debuff:IsShown() and debuff:GetLeft() then
        most = math.max(most, measure(event, debuff))
    end
    if danger:IsShown() and danger:GetLeft() then
        most = math.max(most, measure(event, danger))
    end
    for _, role in ipairs(event.roleIndicators) do
        if role:IsShown() and role:GetLeft() then
            most = math.max(most, measure(event, role))
        end
    end
    return most
end

local function edgeMargin(reach, percent)
    return math.max(EDGE_MARGIN, reach * percent / 100 + FIT_MARGIN)
end

local function placeEvent(panel)
    local event = panel.sample
    local size = event:GetWidth()
    local farSide = OPPOSITE_SIDE[ns.eventStyle.NameSide()]
    local panelAlong, panelAcross = panel:GetWidth(), panel:GetHeight()

    local along, halfAcross = measureContent(panel)
    local reach = overhang(event, farSide)
    local fit = math.min((panelAlong - edgeMargin(reach, panel.percent) - FIT_MARGIN) / along,
        (panelAcross - 2 * FIT_MARGIN) / (2 * halfAcross))
    local percent = panelAlong > EDGE_MARGIN + FIT_MARGIN and math.min(panel.percent, fit * 100) or panel.percent
    percent = math.max(percent, MIN_FITTED_PERCENT)
    local heldBack = percent < panel.percent - HELD_BACK_TOLERANCE
    local largest = math.max(appearance.Get("name", "size"), appearance.Get("cooldown", "size"))
    if largest > 0 then
        percent = math.max(math.floor(largest * percent / 100 + 0.5), 1) / largest * 100
    end
    event:SetScale(percent / 100)
    if heldBack and panel.onHeldBack then
        panel.onHeldBack(percent)
    end

    local margin = edgeMargin(reach, percent)
    local centred = (panelAlong - size * percent / 100) / 2
    local distance = math.max(margin, math.min(centred, panelAlong - FIT_MARGIN - along * percent / 100))
    local factor = distance * 100 / percent
    event:ClearAllPoints()
    event:SetPoint(farSide, panel, farSide, INWARD[farSide] * factor, 0)
    selectors.UpdateOutlineThickness()
end

local function showIndicator(texture, enabled)
    texture:Show()
    texture:SetDesaturated(not enabled)
    texture:SetAlpha(enabled and 1 or DISABLED_INDICATOR_ALPHA)
end

local function atUnitScale(fn, ...)
    local style = ns.eventStyle.state
    local saved = style.scale
    style.scale = UNIT_SCALE
    local ok, message = pcall(fn, ...)
    style.scale = saved
    if not ok then
        error(message, 0)
    end
end

local function refreshPanel(panel)
    local event = panel.sample
    local scale = ns.eventStyle.Scale()
    local size = appearance.Get("icon", "size") * scale
    event:SetSize(size, size)
    local crop = appearance.Get("icon", "zoom") / 100
    event.texture:SetTexCoord(crop, 1 - crop, crop, 1 - crop)

    setSampleName(panel)
    ns.eventStyle.Apply(event)
    if panel.resetButton then
        placeResetButton(panel)
    end
    local nameShown = not appearance.Get("name", "hidden")
    event.nameBackdrop:SetAlpha(nameShown and 1 or DISABLED_INDICATOR_ALPHA)
    if not nameShown then
        event.texts.name:SetTextColor(DISABLED_NAME_GRAY, DISABLED_NAME_GRAY, DISABLED_NAME_GRAY, DISABLED_INDICATOR_ALPHA)
    end
    local countdownHidden = appearance.Get("cooldown", "hidden") == true
    if not event.countdownPlate then
        event.countdownPlate = event.cooldownHolder:CreateTexture(nil, "BACKGROUND")
        event.countdownPlate:SetColorTexture(0, 0, 0, COUNTDOWN_PLATE_ALPHA)
    end
    event.countdownPlate:ClearAllPoints()
    event.countdownPlate:SetPoint("TOPLEFT", event.texts.cooldown, "TOPLEFT", -COUNTDOWN_PLATE_PADDING, COUNTDOWN_PLATE_PADDING)
    event.countdownPlate:SetPoint("BOTTOMRIGHT", event.texts.cooldown, "BOTTOMRIGHT", COUNTDOWN_PLATE_PADDING,
        -COUNTDOWN_PLATE_PADDING)
    event.countdownPlate:SetShown(countdownHidden)
    if countdownHidden then
        event.texts.cooldown:SetTextColor(DISABLED_NAME_GRAY, DISABLED_NAME_GRAY, DISABLED_NAME_GRAY, DISABLED_INDICATOR_ALPHA)
    end

    placeEvent(panel)

    local borderStyle = appearance.BorderStyle()
    local debuffBorder = borderStyle == "DEBUFF"
        or (borderStyle == "BLIZZARD" and appearance.Get("border", "useEventColor"))
    for index, fills in ipairs(event.debuffBorders) do
        for _, fill in ipairs(fills) do
            fill:SetShown(debuffBorder and ns.debuff.TYPES[index].mask == ns.debuff.MAGIC_MASK)
        end
    end

    showIndicator(event.debuffIndicator, appearance.Get("debuff", "enabled"))
    showIndicator(event.dangerIndicator, appearance.Get("danger", "enabled"))
    local showRoles = appearance.Get("roles", "enabled")
    for index = 1, #SAMPLE_ROLE_ATLASES do
        showIndicator(event.roleIndicators[index], showRoles)
    end

    ns.deadlyGlow.Preview(event, panel.glowHint == true)

    selectors.PlaceBackgroundButton()
    selectors.PlaceBorderButtons(ns.eventStyle.BorderThickness(size), borderStyle == "BLIZZARD")
end

function preview.Refresh(panel)
    atUnitScale(refreshPanel, panel)
end

function preview.SetGlowHint(shown)
    local panel = preview.panel
    if panel then
        panel.glowHint = shown
        ns.deadlyGlow.Preview(panel.sample, shown)
        selectors.SetOutlineHidden(shown)
    end
end

function preview.ChangePicture(panel)
    showRandomPicture(panel.sample)
    preview.Refresh(panel)
end

function preview.SetScale(panel, percent, shift)
    panel.percent, panel.shift = percent, shift
    atUnitScale(placeEvent, panel)
end

function preview.SetWhite(panel, white)
    panel.whiteFill:SetShown(white)
    panel.whiteToggle.Refresh(white)
    selectors.SetWhiteBacking(white)
end

function preview.SetSelected(key)
    selectors.SetSelected(key)
end
