local addonName, ns = ...

local C_CVar = C_CVar
local CreateFrame = CreateFrame
local _G = _G

local L = ns.L
local controls = ns.appearanceControls
local options = ns.options
local settings = ns.timerTab.settings

local optionsTab = {}
ns.appearanceOptionsTab = optionsTab

local HIDE_OTHER_ROLES_CVAR = "encounterTimelineHideForOtherRoles"
local HIDE_QUEUED_COUNTDOWNS_CVAR = "encounterTimelineHideQueuedCountdowns"

local BOX_PADDING = 14
local TOP_OFFSET = 8
local CHECKBOX_HEIGHT = 32
local CHECKBOX_INSET = 4
local BOX_GAP = 10
local SLIDER_LABEL_WIDTH = 300
local SLIDER_VALUE_WIDTH = 120
local SLIDER_EXTRA_WIDTH = 120
local TIME_LIMIT_STEP = 5
local COLUMN_OFFSET = 480
local COLOR_LABEL_WIDTH = 110
local SAME_LINE_GAP = 40
local NOTE_GAP = 24
local NOTE_WIDTH = 600
local function boxHeight(rowCount, headingHeight)
    return 2 * BOX_PADDING + headingHeight + rowCount * (controls.LABEL_GAP + CHECKBOX_HEIGHT) - CHECKBOX_INSET
end

local function createBox(content, anchorTo, headingText, columnHeading, rows)
    local box = settings.CreateBox(content)
    local columnLength = { 0, columnHeading and 1 or 0 }
    local longest = 0
    for _, row in ipairs(rows) do
        if not row.sameLine then
            local column = row.column or 1
            columnLength[column] = (columnLength[column] or 0) + 1
            longest = math.max(longest, columnLength[column])
        end
    end
    if anchorTo then
        box:SetPoint("TOPLEFT", anchorTo, "BOTTOMLEFT", 0, -BOX_GAP)
        box:SetPoint("TOPRIGHT", anchorTo, "BOTTOMRIGHT", 0, -BOX_GAP)
    else
        box:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -TOP_OFFSET)
        box:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, -TOP_OFFSET)
    end
    local heading = box:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    heading:SetPoint("TOPLEFT", box, "TOPLEFT", BOX_PADDING, -BOX_PADDING)
    heading:SetText(headingText)
    box.heading = heading
    box:SetHeight(boxHeight(longest, heading:GetStringHeight()))
    local aboveInColumn = { heading, heading }
    if columnHeading then
        local line = CreateFrame("Frame", nil, box)
        line:SetSize(1, CHECKBOX_HEIGHT)
        line:SetPoint("TOPLEFT", heading, "BOTTOMLEFT", COLUMN_OFFSET, -controls.LABEL_GAP)
        local small = line:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        small:SetPoint("LEFT", line, "LEFT", CHECKBOX_INSET, 0)
        small:SetText(columnHeading)
        aboveInColumn[2] = line
    end
    local gameKept = {}
    local dependents = {}
    local availability = {}
    local function refreshAvailability()
        for _, entry in ipairs(availability) do
            controls.SetCheckboxEnabled(entry.checkbox, entry.available())
            if entry.note then
                local text = entry.noteText()
                entry.note:SetText(text and ns.text.Quoted(text, ns.text.RED, ns.text.GOLD) or "")
            end
        end
    end
    box.RefreshAvailability = refreshAvailability

    local function addSlider(row, column)
        return controls.EditableSlider(box, aboveInColumn[column], row.label, row.slider.min, row.slider.max, row.slider.step,
            function()
                return options.Get(row.key)
            end, function(value)
                options.Set(row.key, value)
            end, SLIDER_EXTRA_WIDTH, row.slider.format, SLIDER_VALUE_WIDTH, nil, SLIDER_LABEL_WIDTH)
    end

    local function addColor(row, column)
        return controls.InlineColor(box, aboveInColumn[column], row.label, function()
            return options.Get(row.key)
        end, function(red, green, blue)
            options.Set(row.key, { r = red, g = green, b = blue })
        end, false, COLOR_LABEL_WIDTH)
    end

    local function addCheckbox(row, column)
        local store = row.store
        local checkbox = controls.Checkbox(box, aboveInColumn[column], (store and store.label) or row.label, function()
            if store then
                return store.get()
            end
            return options.Get(row.key)
        end, function(checked)
            if store then
                store.set(checked)
            else
                options.Set(row.key, checked)
            end
            if row.onChanged then
                row.onChanged(checked)
            end
            for _, dependent in ipairs(dependents[row.key] or {}) do
                controls.SetCheckboxEnabled(dependent, checked)
            end
        end, aboveInColumn[column] == heading and (column - 1) * COLUMN_OFFSET or 0)
        if row.key then
            box.checkboxes = box.checkboxes or {}
            box.checkboxes[row.key] = checkbox
        end
        if row.dependsOn then
            dependents[row.dependsOn] = dependents[row.dependsOn] or {}
            table.insert(dependents[row.dependsOn], checkbox)
            controls.SetCheckboxEnabled(checkbox, options.Get(row.dependsOn))
        end
        if row.available then
            local entry = { checkbox = checkbox, available = row.available, noteText = row.note }
            if row.note then
                entry.note = box:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                entry.note:SetWidth(NOTE_WIDTH)
                entry.note:SetJustifyH("LEFT")
                entry.note:SetWordWrap(true)
            end
            availability[#availability + 1] = entry
        end
        if store then
            controls.SetTooltip(checkbox, store.tooltip)
            gameKept[store.cvar] = true
        elseif row.tooltip then
            controls.SetTooltip(checkbox, row.tooltip)
        end
        return checkbox
    end

    local conditional = {}
    local function refreshConditional()
        for _, entry in ipairs(conditional) do
            controls.SetRowEnabled(entry.row, entry.enabledWhen())
        end
    end
    for _, row in ipairs(rows) do
        local column = row.column or 1
        if row.color then
            local colorRow = addColor(row, column)
            conditional[#conditional + 1] = { row = colorRow, enabledWhen = row.enabledWhen }
            if row.sameLine then
                local before = aboveInColumn[column]
                colorRow:ClearAllPoints()
                colorRow:SetPoint("TOPLEFT", before, "TOPLEFT", before:GetWidth() + SAME_LINE_GAP, 0)
            else
                aboveInColumn[column] = colorRow
            end
        else
            aboveInColumn[column] = row.slider and addSlider(row, column) or addCheckbox(row, column)
        end
    end
    local longestLabel = 0
    for _, checkbox in pairs(box.checkboxes or {}) do
        longestLabel = math.max(longestLabel, checkbox.label:GetStringWidth())
    end
    box.noteOffset = controls.CHECKBOX_LABEL_GAP + longestLabel + NOTE_GAP
    for _, entry in ipairs(availability) do
        if entry.note then
            entry.note:SetPoint("LEFT", entry.checkbox, "RIGHT", box.noteOffset, 0)
        end
    end
    refreshConditional()
    refreshAvailability()
    options.OnChanged(refreshConditional)
    function box.Refresh()
        controls.ResyncAll(box)
        refreshConditional()
        for key, list in pairs(dependents) do
            for _, dependent in ipairs(list) do
                controls.SetCheckboxEnabled(dependent, options.Get(key))
            end
        end
        refreshAvailability()
    end
    ns.profiles.OnChanged(box.Refresh)
    if next(gameKept) then
        local function resync()
            controls.ResyncAll(box)
        end
        box:HookScript("OnShow", resync)
        box:RegisterEvent("CVAR_UPDATE")
        box:HookScript("OnEvent", function(_, _, name)
            if gameKept[name] then
                resync()
            end
        end)
    end
    return box
end

optionsTab.CreateBox = createBox

function optionsTab.AddReset(content, lastBox, boxes, keys, tooltip)
    local reset = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    reset:SetText(L.EVENT_APPEARANCE_RESET)
    controls.SizeResetButton(reset)
    reset:SetPoint("TOPRIGHT", lastBox, "BOTTOMRIGHT", 0, -BOX_GAP)
    if tooltip then
        controls.SetTooltip(reset, tooltip)
    end
    local function updateReset()
        reset:SetEnabled(not options.IsDefault(keys))
    end
    reset:SetScript("OnClick", function()
        options.Reset(keys)
        for _, box in ipairs(boxes) do
            box.Refresh()
        end
        updateReset()
    end)
    updateReset()
    options.OnChanged(updateReset)
    ns.profiles.OnChanged(updateReset)
    content:HookScript("OnShow", updateReset)
end

local function gameSetting(cvar, labelName, tooltipName)
    return {
        cvar = cvar,
        label = _G[labelName],
        tooltip = _G[tooltipName],
        get = function()
            return C_CVar.GetCVar(cvar) == "1"
        end,
        set = function(checked)
            C_CVar.SetCVar(cvar, checked and "1" or "0")
        end,
    }
end

function optionsTab.Build(content)
    local eventsBox = createBox(content, nil, L.OPTIONS_EVENTS_HEADING, L.OPTIONS_CAPTION_HEADING, {
        { label = L.OPTIONS_READY_CHECK, key = "showReadyCheck" },
        { label = L.OPTIONS_PULL_TIMER, key = "showPullTimer" },
        { label = L.OPTIONS_BREAK, key = "showBreak" },
        { label = L.OPTIONS_KEY_REROLL, key = "showKeyReroll", tooltip = L.OPTIONS_KEY_REROLL_TOOLTIP },
        { label = L.OPTIONS_INITIATOR, key = "showInitiator", tooltip = L.OPTIONS_INITIATOR_TOOLTIP, column = 2 },
        { label = L.OPTIONS_CAPTION_COLOR, key = "captionColor", color = true, column = 2, enabledWhen = function()
            return options.Get("showInitiator") and not options.Get("useClassColors")
        end },
        { label = L.OPTIONS_CLASS_COLORS, key = "useClassColors", dependsOn = "showInitiator", column = 2 },
    })
    local gameBox = createBox(content, eventsBox, L.OPTIONS_DISPLAY_HEADING, nil, {
        { store = gameSetting(HIDE_OTHER_ROLES_CVAR, "COMBAT_WARNINGS_HIDE_FOR_OTHER_ROLES_LABEL",
            "COMBAT_WARNINGS_HIDE_FOR_OTHER_ROLES_TOOLTIP") },
        { store = gameSetting(HIDE_QUEUED_COUNTDOWNS_CVAR, "COMBAT_WARNINGS_HIDE_QUEUED_COUNTDOWNS_LABEL",
            "COMBAT_WARNINGS_HIDE_QUEUED_COUNTDOWNS_TOOLTIP") },
        { label = L.TIME_LIMIT, key = "timeLimit", slider = { min = options.TIME_LIMIT_MIN, max = options.TIME_LIMIT_UNLIMITED,
            step = TIME_LIMIT_STEP, format = function(value)
                if value >= options.TIME_LIMIT_UNLIMITED then
                    return L.TIME_LIMIT_NONE
                end
                return L.TIME_LIMIT_SECONDS:format(value)
            end } },
    })
    local barBox = createBox(content, gameBox, L.OPTIONS_DEFAULT_BAR_HEADING, nil, {
        { label = L.OPTIONS_HIDE_DEFAULT_BAR, key = "hideBlizzardTimeline", tooltip = L.OPTIONS_HIDE_DEFAULT_BAR_TOOLTIP,
            onChanged = function(checked)
                if not checked then
                    ns.reloadPrompt.Show()
                end
            end },
    })

    optionsTab.AddReset(content, barBox, { eventsBox, gameBox, barBox }, options.ExtrasKeys(), L.OPTIONS_RESET_TIP)
end
