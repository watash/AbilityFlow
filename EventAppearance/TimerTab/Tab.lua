local addonName, ns = ...

local CreateFrame = CreateFrame
local GameTooltip = GameTooltip
local max = math.max
local C_Timer = C_Timer
local L = ns.L
local controls = ns.appearanceControls
local appearance = ns.appearance
local timerStyle = ns.timerStyle
local previewEvent = ns.timerTab.event
local line = ns.timerTab.line
local pins = ns.timerTab.pins
local templates = ns.timerTab.templates
local settings = ns.timerTab.settings

local timerAppearance = {}
ns.appearanceTimer = timerAppearance

local SIDE_MARGIN = 20
local CONTROLS_LEFT = SIDE_MARGIN - controls.ROW_INDENT - controls.CHECKBOX_PICTURE_PADDING
local SWITCH_RIGHT_NUDGE = 2
local SWITCH_LEFT = -controls.ROW_INDENT - controls.CHECKBOX_PICTURE_PADDING + SWITCH_RIGHT_NUDGE
local SWITCH_RAISE = 7
local SWITCH_LABEL_HIT_EXTRA = 12
local ICON_SHRINK = 0.9
local ROW_INSET = 16
local ROW_EDGE_GAP = 8
local TEMPLATE_GAP = 8
local SWITCH_ROW_HEIGHT = 26
local SWITCH_GAP = 2
local ROW_BOX_BOTTOM_PADDING = 6
local LIMIT_TEXT_GAP = 12
local NOTE_HEIGHT = 14
local NOTE_COLOR = { 0.8, 0.8, 0.8 }
local NOTE_BOTTOM_GAP = 4
local SETTINGS_TOP_GAP = 6
local LINE_SETTINGS_GAP = 12
local TEMPLATE_ROW_PADDING = 38
local LINE_END_CELLS = 0.5
local SETTINGS_HEIGHT = 300
local FLASH_INTERVAL = 3
local COUNT_INTERVAL = 0.1

function timerAppearance.Build(content)
    local body = CreateFrame("Frame", nil, content)
    body:SetAllPoints()
    local tab = { frame = body }
    ns.timerTab.tab = tab

    function tab.changed()
        ns.timeline.RefreshTimerStyle()
        templates.Repaint()
        pins.Refresh()
    end
    function tab.onSelect(templateID)
        settings.Show(templateID)
    end

    local switch = controls.Checkbox(content, content, L.TIMER_STYLE_ENABLE, timerStyle.IsEnabled(), function(checked)
        timerStyle.SetEnabled(checked)
        ns.timeline.RefreshTimerStyle()
    end, SWITCH_LEFT, SWITCH_RAISE)
    switch:SetHitRectInsets(0, -(switch.label:GetStringWidth() + SWITCH_LABEL_HIT_EXTRA), 0, 0)
    switch:HookScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(L.TIMER_STYLE_ENABLE_HINT, 1, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    switch:HookScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    local rowBox = settings.CreateBox(body)
    rowBox:SetFrameLevel(body:GetFrameLevel())
    tab.rowBox = rowBox
    local note = rowBox:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    note:SetTextColor(NOTE_COLOR[1], NOTE_COLOR[2], NOTE_COLOR[3])
    note:SetText(L.TIMER_TEMPLATES_NOTE)
    note:SetPoint("BOTTOM", rowBox, "BOTTOM", 0, NOTE_BOTTOM_GAP)
    local heading = body:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    heading:SetText(L.TIMER_TEMPLATES_HEADING)
    heading:SetPoint("CENTER", body, "TOP", 0, -SWITCH_ROW_HEIGHT / 2)
    tab.countText = body:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    tab.countText:SetPoint("LEFT", heading, "RIGHT", LIMIT_TEXT_GAP, 0)
    tab.limitText = body:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    tab.limitText:SetTextColor(RED_FONT_COLOR:GetRGB())
    tab.limitText:SetText(L.TIMER_LIMIT_REACHED)
    tab.limitText:SetPoint("LEFT", heading, "RIGHT", LIMIT_TEXT_GAP, 0)
    tab.limitText:Hide()

    local settingsArea = CreateFrame("Frame", nil, body)
    settingsArea:SetHeight(SETTINGS_HEIGHT)

    tab.line = line.Create(body, timerStyle.SECONDS)
    pins.Setup(tab)
    templates.Setup(tab)
    templates.Build()
    settings.Setup(settingsArea, tab.changed)

    local function layout()
        local width = content:GetWidth()
        if not width or width <= 0 then
            return
        end
        local available = width - 2 * SIDE_MARGIN
        local size = appearance.Get("icon", "size")
        local footprint = size + 2 * previewEvent.BorderMargin(previewEvent.CurrentLook())
        local count = timerStyle.SECONDS
        tab.footprint = footprint
        tab.scale = ICON_SHRINK * (available - (count - 1) * TEMPLATE_GAP) / (count * footprint)
        local iconSize = footprint * tab.scale
        local gaps = timerStyle.MAX_TEMPLATES - 1
        local nameReach = ((width - iconSize) / (2 * gaps) + ROW_EDGE_GAP - previewEvent.NAME_MIN_GAP / 2 - iconSize / 2)
            / (1 + 1 / gaps)
        tab.leftInset = max(SIDE_MARGIN + ROW_INSET, nameReach)
        tab.pitch = (width - 2 * tab.leftInset - iconSize) / gaps
        previewEvent.SetTextScale(tab.pitch)
        tab.barTop = SWITCH_ROW_HEIGHT + SWITCH_GAP + settings.BOX_EDGE_DEPTH
        tab.top = tab.barTop + templates.BAR_ROOM + TEMPLATE_ROW_PADDING

        local nameRow = tab.footprint * tab.scale + previewEvent.NameHeight()
        tab.nameRow = nameRow
        local rowBottom = tab.top + nameRow + ROW_BOX_BOTTOM_PADDING + NOTE_HEIGHT
        rowBox:ClearAllPoints()
        rowBox:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -(SWITCH_ROW_HEIGHT + SWITCH_GAP))
        rowBox:SetPoint("BOTTOMRIGHT", content, "TOPRIGHT", 0, -rowBottom)
        local reach = pins.Reach()
        local lineCenter = rowBottom + SETTINGS_TOP_GAP + reach + line.BACKING_TOP_PADDING
        local cell = available / (timerStyle.SECONDS + 1 + LINE_END_CELLS)
        previewEvent.SetPinTextScale(cell, pins.NameRoom(), tab.footprint * tab.scale * pins.SCALE_RATIO)
        line.Layout(tab.line, body, lineCenter, SIDE_MARGIN + cell, cell * timerStyle.SECONDS, SIDE_MARGIN,
            SIDE_MARGIN + available)
        local lineBottom = line.LayoutBacking(tab.line, body, reach)

        if timerAppearance.OnLineBottom then
            timerAppearance.OnLineBottom(lineBottom)
        end
        local settingsTop = lineBottom + LINE_SETTINGS_GAP
        settingsArea:ClearAllPoints()
        settingsArea:SetPoint("TOPLEFT", content, "TOPLEFT", CONTROLS_LEFT, -settingsTop)
        settingsArea:SetWidth(available)
        settingsArea:SetHeight(content:GetHeight() - settingsTop)
        settings.PlaceBox(width, CONTROLS_LEFT)

        templates.Sync()
        pins.Sync()
    end

    layout()

    templates.Select(nil)
    content:GetParent():HookScript("OnHide", function()
        templates.Select(nil)
    end)

    local flashTicker, countTicker
    local function startTickers()
        if not flashTicker then
            flashTicker = C_Timer.NewTicker(FLASH_INTERVAL, function()
                if content:IsVisible() then
                    templates.FlashAll()
                    pins.FlashPlaced()
                end
            end)
        end
        if not countTicker then
            countTicker = C_Timer.NewTicker(COUNT_INTERVAL, function()
                if content:IsVisible() then
                    templates.Tick()
                end
            end)
        end
    end
    local function stopTickers()
        if flashTicker then
            flashTicker:Cancel()
            flashTicker = nil
        end
        if countTicker then
            countTicker:Cancel()
            countTicker = nil
        end
    end

    content:SetScript("OnShow", function()
        startTickers()
        layout()
        C_Timer.After(0, function()
            if content:IsVisible() then
                layout()
            end
        end)
    end)
    content:SetScript("OnHide", function()
        stopTickers()
        pins.HideAll()
        templates.StopAll()
    end)

    function timerAppearance.Refresh()
        templates.Sync()
        templates.Select(nil)
        switch:SetChecked(timerStyle.IsEnabled())
        if content:IsVisible() then
            layout()
        end
    end
end
