local addonName, ns = ...

local CreateFrame = CreateFrame
local GameTooltip = GameTooltip
local math = math
local pairs = pairs
local ipairs = ipairs
local timerStyle = ns.timerStyle
local previewEvent = ns.timerTab.event
local pins = ns.timerTab.pins
local templates = ns.timerTab.templates
local state = templates.state

local BAR_ALPHA = 0.9
local BAR_THICKNESS = 5
local BAR_SELECTED_THICKNESS = 7
templates.BAR_ROOM = BAR_SELECTED_THICKNESS
local BAR_HIT_SIDE = 3
local BAR_HIT_HEIGHT = 5
local BAR_EASE_RATE = 18
local BAR_EASE_LEAST = 0.2
local PLATE_COLOR = { 1, 1, 1, 0.12 }
local HOVER_PLATE_COLOR = { 1, 0.82, 0, 0.1 }
local PLATE_PADDING = 3
local PLATE_SIDE_GAP = 1

local function placePlate(texture, centerX)
    local context = state.context
    local top = context.barTop
    texture:ClearAllPoints()
    texture:SetPoint("TOPLEFT", context.frame, "TOPLEFT", centerX - context.pitch / 2 + PLATE_SIDE_GAP, -top)
    texture:SetPoint("BOTTOMRIGHT", context.frame, "TOPLEFT", centerX + context.pitch / 2 - PLATE_SIDE_GAP,
        -(context.top + context.nameRow + PLATE_PADDING))
    texture:Show()
end

local function showHover(templateID)
    local context = state.context
    if templateID == context.selected or pins.IsDragging() then
        return
    end
    local number = timerStyle.DisplayNumber(templateID)
    if number then
        placePlate(state.hoverPlate,
            context.leftInset + (number - 1) * context.pitch + context.footprint * context.scale / 2)
    end
end

function templates.BuildRow()
    local box = state.context.rowBox
    state.plate = box:CreateTexture(nil, "ARTWORK")
    state.plate:SetColorTexture(PLATE_COLOR[1], PLATE_COLOR[2], PLATE_COLOR[3], PLATE_COLOR[4])
    state.plate:Hide()
    state.hoverPlate = box:CreateTexture(nil, "ARTWORK")
    state.hoverPlate:SetColorTexture(HOVER_PLATE_COLOR[1], HOVER_PLATE_COLOR[2], HOVER_PLATE_COLOR[3],
        HOVER_PLATE_COLOR[4])
    state.hoverPlate:Hide()
end

function templates.Repaint()
    local context = state.context
    local look = previewEvent.CurrentLook()
    for _, templateID in ipairs(timerStyle.Order()) do
        local event = state.widgets[templateID]
        if event then
            local template = timerStyle.Template(templateID)
            local fit = previewEvent.FitScale(look, context.footprint, context.scale)
            previewEvent.Apply(event, fit, false, look)
            state.nameSamples[templateID]:SetScale(previewEvent.TextScale())
            previewEvent.Paint(event, template, look)
            previewEvent.SetIcon(event, templateID)
            previewEvent.PaintName(state.nameSamples[templateID], template)
        end
    end
    templates.Tick()
end

local function barTarget(bar)
    if bar.selected or bar.hovered then
        return bar.expandedWidth, BAR_SELECTED_THICKNESS
    end
    return bar.restWidth, BAR_THICKNESS
end

local function easeBar(bar, elapsed)
    local targetWidth, targetThickness = barTarget(bar)
    local width, thickness = bar:GetSize()
    local share = math.min(1, BAR_EASE_RATE * elapsed)
    width = width + (targetWidth - width) * share
    thickness = thickness + (targetThickness - thickness) * share
    if math.abs(targetWidth - width) < BAR_EASE_LEAST and math.abs(targetThickness - thickness) < BAR_EASE_LEAST then
        width, thickness = targetWidth, targetThickness
        bar:SetScript("OnUpdate", nil)
    end
    bar:SetSize(width, thickness)
end

local function startEase(bar)
    if bar:IsShown() then
        bar:SetScript("OnUpdate", easeBar)
    end
end

local function setBarHovered(templateID, hovered)
    local bar = templateID and state.colorBars[templateID]
    if bar and bar.hovered ~= hovered then
        bar.hovered = hovered
        startEase(bar)
    end
end

local function createBar()
    local bar = CreateFrame("Button", nil, state.context.frame)
    bar.fill = bar:CreateTexture(nil, "ARTWORK")
    bar.fill:SetAllPoints()
    bar:RegisterForClicks("LeftButtonUp")
    bar:SetHitRectInsets(-BAR_HIT_SIDE, -BAR_HIT_SIDE, -BAR_HIT_HEIGHT, -BAR_HIT_HEIGHT)
    bar:SetScript("OnClick", function(self)
        templates.Select(self.templateID)
    end)
    bar:SetScript("OnEnter", function(self)
        if not pins.IsDragging() then
            setBarHovered(self.templateID, true)
        end
    end)
    bar:SetScript("OnLeave", function(self)
        setBarHovered(self.templateID, false)
    end)
    return bar
end

local function createWidget()
    local event = previewEvent.Create(state.context.frame, previewEvent.TEMPLATE_FILE_ID)
    event:EnableMouse(true)
    event:RegisterForDrag("LeftButton")
    event:SetScript("OnEnter", function(self)
        if pins.IsDragging() then
            return
        end
        showHover(self.templateID)
        setBarHovered(self.templateID, true)
        templates.ShowHint(self)
    end)
    event:SetScript("OnLeave", function(self)
        state.hoverPlate:Hide()
        setBarHovered(self.templateID, false)
        GameTooltip:Hide()
    end)
    event:SetScript("OnDragStart", function()
        state.hoverPlate:Hide()
        setBarHovered(event.templateID, false)
        GameTooltip:Hide()
        pins.BeginDrag(event.templateID, event)
    end)
    event:SetScript("OnDragStop", pins.EndDrag)
    event:SetScript("OnMouseUp", function(_, button)
        if button == "LeftButton" then
            templates.Select(event.templateID)
        elseif button == "RightButton" then
            state.hoverPlate:Hide()
            setBarHovered(event.templateID, false)
            GameTooltip:Hide()
            templates.OpenMenu(event, event.templateID)
        end
    end)
    return event
end

local function acquire(templateID)
    local made = table.remove(state.free)
    if not made then
        made = {
            event = createWidget(),
            sample = previewEvent.CreateNameSample(state.context.frame),
            bar = createBar(),
        }
    end
    made.event.templateID = templateID
    made.bar.templateID = templateID
    state.widgets[templateID] = made.event
    state.nameSamples[templateID] = made.sample
    state.colorBars[templateID] = made.bar
end

function templates.Sync()
    local alive = {}
    for _, templateID in ipairs(timerStyle.Order()) do
        alive[templateID] = true
        if not state.widgets[templateID] then
            acquire(templateID)
        end
    end
    for templateID in pairs(state.widgets) do
        if not alive[templateID] then
            templates.Forget(templateID)
        end
    end
    templates.Layout()
end

function templates.Forget(templateID)
    local event = state.widgets[templateID]
    if not event then
        return
    end
    local sample, bar = state.nameSamples[templateID], state.colorBars[templateID]
    event:Hide()
    ns.timerPaint.Stop(event)
    sample:Hide()
    bar:Hide()
    bar:SetScript("OnUpdate", nil)
    bar.hovered, bar.selected, bar.sized = false, false, false
    event.templateID, bar.templateID = nil, nil
    state.widgets[templateID], state.nameSamples[templateID], state.colorBars[templateID] = nil, nil, nil
    state.free[#state.free + 1] = { event = event, sample = sample, bar = bar }
end

function templates.Layout()
    local context = state.context
    if not context.scale then
        return
    end
    local scale = context.scale
    local order = timerStyle.Order()
    templates.Repaint()
    state.plate:Hide()
    state.hoverPlate:Hide()
    for index, templateID in ipairs(order) do
        local event = state.widgets[templateID]
        local iconScale = event:GetScale()
        event:ClearAllPoints()
        local half = context.footprint * scale / 2
        local centerX = context.leftInset + (index - 1) * context.pitch + half
        event:SetPoint("CENTER", context.frame, "TOPLEFT", centerX / iconScale, -(context.top + half) / iconScale)
        event:Show()
        local bar = state.colorBars[templateID]
        local color = pins.ColorOf(templateID)
        local selected = templateID == context.selected
        bar.fill:SetColorTexture(color[1], color[2], color[3], BAR_ALPHA)
        bar.restWidth = context.footprint * scale
        bar.expandedWidth = context.pitch - 2 * PLATE_SIDE_GAP
        bar.selected = selected
        bar:ClearAllPoints()
        bar:SetPoint("TOP", context.frame, "TOPLEFT", centerX, -context.barTop)
        if bar.sized then
            startEase(bar)
        else
            bar:SetSize(barTarget(bar))
            bar.sized = true
            bar:Show()
        end
        if selected then
            placePlate(state.plate, centerX)
        end
        local sample = state.nameSamples[templateID]
        sample:ClearAllPoints()
        local sampleScale = sample:GetScale()
        sample:SetPoint("TOP", context.frame, "TOPLEFT", centerX / sampleScale,
            -(context.top + 2 * half) / sampleScale - previewEvent.NAME_SAMPLE_GAP)
        sample:Show()
    end
    templates.LayoutAddButton(#order)
    pins.Refresh()
end
