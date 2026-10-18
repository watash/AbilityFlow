local addonName, ns = ...

local CreateFrame = CreateFrame
local ipairs = ipairs
local L = ns.L
local controls = ns.appearanceControls
local timerStyle = ns.timerStyle
local appearance = ns.appearance
local settings = ns.timerTab.settings
local ROW_GAP = settings.ROW_GAP
local SWATCH_BESIDE_GAP = settings.SWATCH_BESIDE_GAP
local SLIDER_EXTRA = settings.SLIDER_EXTRA
local DISABLED_ALPHA = settings.DISABLED_ALPHA
local FULL_ALPHA = settings.FULL_ALPHA
local ownColor = settings.ownColor

local SECOND_COLUMN_LEFT = settings.SECOND_COLUMN_LEFT
local SECOND_COLUMN_ROWS_SHIFT = 4

function settings.builders.GLOW(page, templateOf, changedCallback)
    local controlsOf = {}
    local function isColoredFlat()
        return appearance.Get("border", "style") == "SOLID"
    end
    local function isGameFrame()
        return appearance.Get("border", "style") == "BLIZZARD"
    end
    local function kindOf(template)
        return ns.glow.ShownType(template.glowType, isColoredFlat())
    end
    local function ownOf(key, default)
        local template = templateOf()
        local value = ns.glow.Own(template, kindOf(template), key)
        if value == nil then
            return default
        end
        return value
    end
    local function setOwn(key, value)
        local template = templateOf()
        ns.glow.SetOwn(template, kindOf(template), key, value)
    end
    local left = CreateFrame("Frame", nil, page)
    left:SetSize(1, 1)
    left:SetPoint("TOPLEFT", page, "TOPLEFT", 0, 0)
    local right = CreateFrame("Frame", nil, page)
    right:SetSize(1, 1)
    right:SetPoint("TOPLEFT", page, "TOPLEFT", SECOND_COLUMN_LEFT, 0)
    local FIRST_BOX_X = controls.LABEL_GAP
    local FIRST_ROW_X = controls.LABEL_GAP + controls.CHECKBOX_PICTURE_PADDING
    local SECOND_BOX_X = SECOND_COLUMN_LEFT + controls.LABEL_GAP - controls.CHECKBOX_PICTURE_PADDING
    local SECOND_ROW_X = SECOND_COLUMN_LEFT + controls.LABEL_GAP + SECOND_COLUMN_ROWS_SHIFT
    local function levelWith(row, rowX, lane, laneX)
        row:ClearAllPoints()
        row:SetPoint("LEFT", lane, "LEFT", rowX - laneX, 0)
    end

    local glow = controls.Checkbox(left, left, L.TIMER_STYLE_GLOW, function()
        return templateOf().useGlow == true
    end, function(checked)
        templateOf().useGlow = checked
        changedCallback()
        controlsOf.refreshStates()
    end)
    local typeItems = {}
    local listedForFlat
    local listedForFrame
    local function fillTypeItems()
        local flat = isColoredFlat()
        listedForFlat = flat
        listedForFrame = isGameFrame()
        for index in ipairs(typeItems) do
            typeItems[index] = nil
        end
        for _, item in ipairs(settings.glowChoices.TypeItems(flat)) do
            table.insert(typeItems, item)
        end
    end
    fillTypeItems()
    local glowType = controls.InlineDropdown(left, glow, L.TIMER_STYLE_GLOW_TYPE, typeItems,
        function()
            return ns.glow.ShownType(templateOf().glowType, isColoredFlat())
        end, function(value)
            templateOf().glowType = value
            changedCallback()
            controlsOf.refreshStates()
        end, SLIDER_EXTRA)

    local glowScale = controls.EditableSlider(left, glowType, L.TIMER_STYLE_GLOW_SCALE, timerStyle.GLOW_SCALE_MIN,
        timerStyle.GLOW_SCALE_MAX, 1, function()
            return ownOf("scale", ns.glow.FULL_SHARE)
        end, function(value)
            setOwn("scale", value)
            changedCallback()
        end, SLIDER_EXTRA, "%d%%", controls.VALUE_WIDTH)

    local function speedsOf(source)
        source.glowSpeeds = source.glowSpeeds or {}
        return source.glowSpeeds
    end
    local function speedOf(source)
        return speedsOf(source)[kindOf(source)] or ns.glow.SPEED_DEFAULT
    end
    local loadingSpeed = false
    local speedShift = timerStyle.GLOW_SPEED_MIN - 1
    local function shownSpeed(source)
        return math.max(speedOf(source), timerStyle.GLOW_SPEED_MIN) - speedShift
    end
    local glowSpeed = controls.EditableSlider(left, glowScale, L.TIMER_STYLE_GLOW_SPEED,
        timerStyle.GLOW_SPEED_MIN - speedShift, timerStyle.GLOW_SPEED_MAX - speedShift, 1, function()
            return shownSpeed(templateOf())
        end, function(value)
            if not loadingSpeed then
                local template = templateOf()
                speedsOf(template)[kindOf(template)] = value + speedShift
                changedCallback()
            end
        end, SLIDER_EXTRA, "%d", controls.VALUE_WIDTH)

    local glowLines = controls.EditableSlider(right, right, L.TIMER_STYLE_GLOW_LINES, timerStyle.GLOW_LINES_MIN,
        timerStyle.GLOW_LINES_MAX, 1, function()
            return ownOf("lines", ns.glow.DEFAULT_LINES)
        end, function(value)
            setOwn("lines", value)
            changedCallback()
        end, SLIDER_EXTRA, "%d", controls.VALUE_WIDTH)
    local glowLength = controls.EditableSlider(right, glowLines, L.TIMER_STYLE_GLOW_LENGTH, timerStyle.GLOW_LENGTH_MIN,
        timerStyle.GLOW_LENGTH_MAX, 1, function()
            return ownOf("length", ns.glow.DEFAULT_LENGTH)
        end, function(value)
            setOwn("length", value)
            changedCallback()
        end, SLIDER_EXTRA, "%d%%", controls.VALUE_WIDTH)
    local glowThickness = controls.EditableSlider(right, glowLength, L.EVENT_APPEARANCE_BORDER_THICKNESS,
        timerStyle.GLOW_THICKNESS_MIN, timerStyle.GLOW_THICKNESS_MAX, 1, function()
            return ownOf("thickness", ns.glow.DEFAULT_THICKNESS)
        end,
        function(value)
            setOwn("thickness", value)
            changedCallback()
        end, SLIDER_EXTRA, "%d", controls.VALUE_WIDTH)
    local glowSparks = controls.EditableSlider(right, right, L.TIMER_STYLE_GLOW_SPARKS, timerStyle.GLOW_SPARKS_MIN,
        timerStyle.GLOW_SPARKS_MAX, 1, function()
            return ownOf("particles", ns.glow.DEFAULT_SPARKS)
        end, function(value)
            setOwn("particles", value)
            changedCallback()
        end, SLIDER_EXTRA, "%d", controls.VALUE_WIDTH)
    local glowSparkSize = controls.EditableSlider(right, glowSparks, L.EVENT_APPEARANCE_SIZE,
        timerStyle.GLOW_SPARK_SIZE_MIN, timerStyle.GLOW_SPARK_SIZE_MAX, 1, function()
            return ownOf("sparkSize", ns.glow.FULL_SHARE)
        end,
        function(value)
            setOwn("sparkSize", value)
            changedCallback()
        end, SLIDER_EXTRA, "%d%%", controls.VALUE_WIDTH)

    local SQUARE_SHAPE = "square"
    local shapeItems = {}
    local function shapesOf(source)
        source.glowShapes = source.glowShapes or {}
        return source.glowShapes
    end
    local function shapeOf(source)
        local kind = kindOf(source)
        local chosen = shapesOf(source)[kind]
        for _, item in ipairs(shapeItems) do
            if item.value == chosen then
                return chosen
            end
        end
        return SQUARE_SHAPE
    end
    local glowShape = controls.InlineDropdown(right, right, L.TIMER_STYLE_GLOW_SHAPE, shapeItems, function()
        return shapeOf(templateOf())
    end, function(value)
        local template = templateOf()
        shapesOf(template)[kindOf(template)] = value
        changedCallback()
    end, SLIDER_EXTRA)

    local function glowColor()
        local template = templateOf()
        return template.glowColor or ownColor(template)
    end
    local function reversedOf(source)
        source.glowReversed = source.glowReversed or {}
        return source.glowReversed
    end
    local reverse = controls.Checkbox(right, glowThickness, L.TIMER_STYLE_GLOW_REVERSE, function()
        local template = templateOf()
        return reversedOf(template)[kindOf(template)] == true
    end, function(checked)
        local template = templateOf()
        reversedOf(template)[kindOf(template)] = checked
        changedCallback()
    end)
    local backing = controls.InlineDropdown(right, reverse, L.TIMER_STYLE_GLOW_BACKING, {
        { text = L.TIMER_STYLE_GLOW_BACKING_AUTO, value = ns.glow.BACKING_AUTO },
        { text = L.TIMER_STYLE_GLOW_BACKING_ALWAYS, value = ns.glow.BACKING_ALWAYS },
        { text = L.TIMER_STYLE_GLOW_BACKING_NEVER, value = ns.glow.BACKING_NEVER },
    }, function()
        return ns.glow.BackingMode(templateOf())
    end, function(value)
        templateOf().glowBacking = value
        changedCallback()
    end, SLIDER_EXTRA)
    controls.SetTooltip(backing, L.TIMER_STYLE_GLOW_BACKING_TOOLTIP, backing.dropdown)
    local custom = controls.Checkbox(left, glow, L.TIMER_STYLE_GLOW_CUSTOM_COLOR, function()
        return templateOf().glowUseCustomColor == true
    end, function(checked)
        templateOf().glowUseCustomColor = checked
        changedCallback()
        controlsOf.refreshStates()
    end)
    glowType:ClearAllPoints()
    glowType:SetPoint("TOPLEFT", custom, "BOTTOMLEFT", controls.CHECKBOX_PICTURE_PADDING, -ROW_GAP)
    controls.SetTooltip(custom, L.TIMER_STYLE_GLOW_CUSTOM_COLOR_TIP)
    levelWith(glowLines, SECOND_ROW_X, glow, FIRST_BOX_X)
    levelWith(glowLength, SECOND_ROW_X, custom, FIRST_BOX_X)
    levelWith(glowThickness, SECOND_ROW_X, glowType, FIRST_ROW_X)
    levelWith(glowSparks, SECOND_ROW_X, glow, FIRST_BOX_X)
    levelWith(glowSparkSize, SECOND_ROW_X, custom, FIRST_BOX_X)
    levelWith(glowShape, SECOND_ROW_X, glow, FIRST_BOX_X)
    levelWith(backing, SECOND_ROW_X, glowSpeed, FIRST_ROW_X)
    local swatch = controls.Swatch(left)
    swatch:SetPoint("LEFT", custom.label, "RIGHT", SWATCH_BESIDE_GAP, 0)
    swatch:SetScript("OnClick", function()
        local template = templateOf()
        controls.PickColor(glowColor(), true, function(red, green, blue, alpha)
            template.glowColor = { r = red, g = green, b = blue, a = alpha }
            template.glowUseCustomColor = true
            swatch:SetColor(red, green, blue, alpha)
            changedCallback()
            controlsOf.refreshStates()
        end, swatch)
    end)

    controls.AlignWhenShown(page, function()
        controls.StretchListToBox(glowType, glowScale)
        controls.StretchListToBox(glowShape, glowLines)
    end)

    function controlsOf.refreshStates()
        fillTypeItems()
        local template = templateOf()
        local glowOn = template.useGlow == true
        local kind = kindOf(template)
        controls.SetRowEnabled(glowType, glowOn)
        controls.SetRowEnabled(glowScale, glowOn)
        controls.SetRowEnabled(glowSpeed, glowOn)
        loadingSpeed = true
        glowSpeed.slider:SetValue(shownSpeed(template))
        loadingSpeed = false
        local isPixel, isAutocast = kind == ns.glow.PIXEL, kind == ns.glow.AUTOCAST
        for _, item in ipairs({ glowLines, glowLength, glowThickness }) do
            item:SetShown(isPixel)
            controls.SetRowEnabled(item, glowOn)
        end
        for _, item in ipairs({ glowSparks, glowSparkSize }) do
            item:SetShown(isAutocast)
            controls.SetRowEnabled(item, glowOn)
        end
        local isRegistered = ns.glow.IsPack(kind)
        for index in ipairs(shapeItems) do
            shapeItems[index] = nil
        end
        if isRegistered then
            for _, item in ipairs(settings.glowChoices.ShapeItems(kind)) do
                table.insert(shapeItems, item)
            end
        end
        controls.ResyncAll(page)
        glowShape:SetShown(isRegistered and #shapeItems > 1)
        if glowShape.Resync then
            glowShape.Resync()
        end
        controls.SetRowEnabled(glowShape, glowOn)
        levelWith(reverse, SECOND_BOX_X, isAutocast and glowType or glowScale, FIRST_ROW_X)
        reverse:SetShown(isPixel or isAutocast)
        reverse.label:SetShown(isPixel or isAutocast)
        reverse:SetChecked(reversedOf(template)[kind] == true)
        controls.SetCheckboxEnabled(reverse, glowOn)
        backing:SetShown(isPixel and not isGameFrame())
        controls.SetRowEnabled(backing, glowOn)
        custom:SetChecked(template.glowUseCustomColor == true)
        controls.SetCheckboxEnabled(custom, glowOn)
        swatch:SetEnabled(glowOn)
        swatch:SetAlpha((glowOn and template.glowUseCustomColor) and FULL_ALPHA or DISABLED_ALPHA)
    end

    appearance.OnChanged(function()
        if (isColoredFlat() ~= listedForFlat or isGameFrame() ~= listedForFrame) and templateOf() then
            controlsOf.refreshStates()
        end
    end)

    function controlsOf.refresh()
        local color = glowColor()
        swatch:SetColor(color.r, color.g, color.b, color.a)
        controlsOf.refreshStates()
    end
    return controlsOf
end
