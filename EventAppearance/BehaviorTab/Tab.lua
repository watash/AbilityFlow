local addonName, ns = ...

local CreateFrame = CreateFrame
local unpack = unpack
local math = math

local L = ns.L
local controls = ns.appearanceControls
local appearance = ns.appearance
local statusMark = ns.statusMark
local settings = ns.timerTab.settings

local behaviorTab = {}
ns.appearanceBehaviorTab = behaviorTab

local STATES_RESET_KEY = "states"
local ANIMATIONS_RESET_KEY = "motion"

local BOX_WIDTH = 640
local BOX_PADDING = 14
local TOP_OFFSET = 8
local PREVIEW_GAP = 24
local COLOR_LABEL_WIDTH = 100
local COLOR_ROWS = {
    { key = statusMark.MODE_PAUSED, labelKey = "EVENT_APPEARANCE_PREVIEW_PAUSED" },
    { key = statusMark.MODE_QUEUED, labelKey = "EVENT_APPEARANCE_PREVIEW_QUEUED" },
    { key = statusMark.TEXT_BLOCKED, labelKey = "STATES_BLOCKED" },
}
local COLOR_FIELD_SUFFIX = "Color"
local ANIMATIONS = {
    { element = "animations", field = "intro", labelKey = "ANIMATIONS_INTRO", tipKey = "ANIMATIONS_INTRO_TIP" },
    { element = "animations", field = "outro", labelKey = "ANIMATIONS_OUTRO", tipKey = "ANIMATIONS_OUTRO_TIP" },
    { element = "animations", field = "arrival", labelKey = "ANIMATIONS_ARRIVAL", tipKey = "ANIMATIONS_ARRIVAL_TIP", column = 2 },
    { element = "animations", field = "shift", labelKey = "ANIMATIONS_SHIFT", tipKey = "ANIMATIONS_SHIFT_TIP", column = 2 },
    { element = "trail", field = "enabled", labelKey = "TRAIL", tipKey = "TRAIL_DESC", column = 3 },
    { element = "animations", field = "fade", labelKey = "ANIMATIONS_FADE", tipKey = "ANIMATIONS_FADE_TIP", column = 3 },
}
local SPEED_MIN = 50
local SPEED_MAX = 200
local SPEED_STEP = 10
local SPEED_ROW_HEIGHT = 20
local SPEED_VALUE_WIDTH = 40
local SPEED_LABEL_WIDTH = 200
local BOX_GAP = 10
local HEADING_HEIGHT = 22
local CHECKBOX_HEIGHT = 26
local COLOR_COLUMN_OFFSET = 340
local ANIMATION_COLUMNS = 3
local COLOR_ROW_HEIGHT = 20
local BUTTON_HEIGHT = controls.RESET_BUTTON_HEIGHT
local CHECKBOX_COUNT = 4
local BOTTOM_ROOM = 12

function behaviorTab.Build(content)
    local preview = ns.appearanceTrackPreview.Create(content)
    preview:SetPoint("TOPLEFT", content, "TOPLEFT", BOX_WIDTH + PREVIEW_GAP, -TOP_OFFSET)
    preview:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", 0, 0)

    local box = settings.CreateBox(content)
    box:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -TOP_OFFSET)
    local heading = box:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    heading:SetPoint("TOPLEFT", box, "TOPLEFT", BOX_PADDING, -BOX_PADDING)
    heading:SetText(L.STATES_HEADING)

    local colorRows = {}
    local bracketsBox, colorHeading, tintedBox
    local function refreshColorRows()
        local colorsUsed = appearance.Get("states", "captions")
            or (appearance.Get("states", "marks") and appearance.Get("states", "tintedFrame"))
        for _, row in ipairs(colorRows) do
            controls.SetRowEnabled(row, colorsUsed)
        end
        if tintedBox then
            controls.SetCheckboxEnabled(tintedBox, appearance.Get("states", "marks"))
        end
        if colorHeading then
            controls.SetTextEnabled(colorHeading, colorsUsed)
        end
        if bracketsBox then
            controls.SetCheckboxEnabled(bracketsBox, appearance.Get("states", "captions"))
        end
    end

    local marks = controls.Checkbox(box, heading, L.STATES_MARKS, function()
        return appearance.Get("states", "marks")
    end, function(checked)
        appearance.Set("states", "marks", checked)
        refreshColorRows()
        ns.appearanceTrackPreview.Refresh()
    end)
    controls.SetTooltip(marks, L.STATES_MARKS_TIP)
    local signs = controls.Checkbox(box, marks, L.STATES_SIGNS, function()
        return appearance.Get("states", "signs")
    end, function(checked)
        appearance.Set("states", "signs", checked)
        ns.appearanceTrackPreview.Refresh()
    end)
    controls.SetTooltip(signs, L.STATES_SIGNS_TIP)
    local captions = controls.Checkbox(box, signs, L.STATES_CAPTIONS, function()
        return appearance.Get("states", "captions")
    end, function(checked)
        appearance.Set("states", "captions", checked)
        refreshColorRows()
        ns.appearanceTrackPreview.Refresh()
    end)
    controls.SetTooltip(captions, L.STATES_CAPTIONS_TIP)

    bracketsBox = controls.Checkbox(box, captions, L.STATES_BRACKETS, function()
        return appearance.Get("states", "brackets") ~= false
    end, function(checked)
        appearance.Set("states", "brackets", checked)
        ns.appearanceTrackPreview.Refresh()
    end)

    colorHeading = box:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    colorHeading:SetPoint("TOPLEFT", heading, "TOPLEFT", COLOR_COLUMN_OFFSET, 0)
    colorHeading:SetText(L.STATES_COLORS)
    local above = colorHeading
    for _, spec in ipairs(COLOR_ROWS) do
        local field = spec.key .. COLOR_FIELD_SUFFIX
        local row = controls.InlineColor(box, above, L[spec.labelKey], appearance.Reader("states", field),
            function(red, green, blue)
                appearance.Set("states", field, { r = red, g = green, b = blue, a = 1 })
                ns.appearanceTrackPreview.Refresh()
            end, false, COLOR_LABEL_WIDTH)
        colorRows[#colorRows + 1] = row
        above = row
    end

    tintedBox = controls.Checkbox(box, above, L.STATES_TINTED_FRAME, function()
        return appearance.Get("states", "tintedFrame")
    end, function(checked)
        appearance.Set("states", "tintedFrame", checked)
        refreshColorRows()
        ns.appearanceTrackPreview.Refresh()
    end, -controls.CHECKBOX_PICTURE_PADDING)
    controls.SetTooltip(tintedBox, L.STATES_TINTED_FRAME_TIP)

    local checkboxesHeight = CHECKBOX_COUNT * (controls.LABEL_GAP + CHECKBOX_HEIGHT)
    local colorsHeight = colorHeading:GetStringHeight() - HEADING_HEIGHT + #COLOR_ROWS * (controls.LABEL_GAP + COLOR_ROW_HEIGHT)
        + controls.LABEL_GAP + CHECKBOX_HEIGHT
    box:SetSize(BOX_WIDTH, 2 * BOX_PADDING + HEADING_HEIGHT + math.max(checkboxesHeight, colorsHeight) + BOTTOM_ROOM)
    refreshColorRows()

    local animationsBox = settings.CreateBox(content)
    animationsBox:SetPoint("TOPLEFT", box, "BOTTOMLEFT", 0, -(BUTTON_HEIGHT + 2 * BOX_GAP))
    local animationsHeading = animationsBox:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    animationsHeading:SetPoint("TOPLEFT", animationsBox, "TOPLEFT", BOX_PADDING, -BOX_PADDING)
    animationsHeading:SetText(L.ANIMATIONS_HEADING)
    local columnWidth = (BOX_WIDTH - 2 * BOX_PADDING) / ANIMATION_COLUMNS
    local columnAbove = {}
    local columnCount = {}
    local trailBox
    for column = 1, ANIMATION_COLUMNS do
        columnAbove[column] = animationsHeading
        columnCount[column] = 0
    end
    for _, spec in ipairs(ANIMATIONS) do
        local column = spec.column or 1
        local checkbox = controls.Checkbox(animationsBox, columnAbove[column], L[spec.labelKey], function()
            return appearance.Get(spec.element, spec.field)
        end, function(checked)
            appearance.Set(spec.element, spec.field, checked)
            appearance.Apply()
        end, columnAbove[column] == animationsHeading and (column - 1) * columnWidth or 0)
        controls.SetTooltip(checkbox, L[spec.tipKey])
        if spec.element == "trail" then
            trailBox = checkbox
        end
        columnAbove[column] = checkbox
        columnCount[column] = columnCount[column] + 1
    end
    local rows = math.max(unpack(columnCount))
    local lowest = animationsHeading
    for column = 1, ANIMATION_COLUMNS do
        if columnCount[column] == rows then
            lowest = columnAbove[column]
            break
        end
    end
    controls.EditableSlider(animationsBox, lowest, L.ANIMATIONS_SPEED, SPEED_MIN, SPEED_MAX, SPEED_STEP,
        appearance.Reader("animations", "speed"), function(value)
            appearance.Set("animations", "speed", value)
            appearance.Apply()
        end, controls.WIDE_SLIDER_EXTRA, "%d%%", SPEED_VALUE_WIDTH, nil, SPEED_LABEL_WIDTH)
    animationsBox:SetSize(BOX_WIDTH, 2 * BOX_PADDING + HEADING_HEIGHT
        + rows * (controls.LABEL_GAP + CHECKBOX_HEIGHT) + controls.LABEL_GAP
        + SPEED_ROW_HEIGHT + BOTTOM_ROOM)

    local function refreshTrailBox()
        controls.SetCheckboxEnabled(trailBox, ns.timeline.IsBlizzlikeBackdrop())
    end
    refreshTrailBox()
    content:HookScript("OnShow", refreshTrailBox)
    ns.appearanceTrackPreview.onLookChanged = refreshTrailBox

    local function resync()
        controls.ResyncAll(box)
        controls.ResyncAll(animationsBox)
        refreshColorRows()
        ns.appearanceTrackPreview.Refresh()
    end

    local updateButtons = {}
    local lastReset
    for _, spec in ipairs({ { box, STATES_RESET_KEY }, { animationsBox, ANIMATIONS_RESET_KEY } }) do
        local owner, resetKey = spec[1], spec[2]
        local reset = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
        reset:SetText(L.EVENT_APPEARANCE_RESET)
        controls.SizeResetButton(reset)
        reset:SetPoint("TOPRIGHT", owner, "BOTTOMRIGHT", 0, -BOX_GAP)
        reset:SetScript("OnClick", function()
            appearance.Reset(resetKey)
            resync()
        end)
        updateButtons[#updateButtons + 1] = function()
            reset:SetEnabled(not appearance.IsDefault(resetKey))
        end
        lastReset = reset
    end
    local function updateButton()
        for _, update in ipairs(updateButtons) do
            update()
        end
    end
    appearance.OnChanged(updateButton)
    updateButton()

    local hint = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    hint:SetPoint("LEFT", animationsBox, "BOTTOMLEFT", 0, -BOX_GAP - BUTTON_HEIGHT / 2)
    hint:SetPoint("RIGHT", lastReset, "LEFT", -BOX_GAP, 0)
    hint:SetJustifyH("CENTER")
    hint:SetText(L.PREVIEW_HINT)

    ns.profiles.OnChanged(function()
        resync()
        updateButton()
    end)
end
