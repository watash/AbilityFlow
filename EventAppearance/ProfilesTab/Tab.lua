local addonName, ns = ...

local CreateFrame = CreateFrame
local C_Timer = C_Timer
local MenuTemplates = MenuTemplates
local MenuUtil = MenuUtil
local ipairs = ipairs
local L = ns.L
local profiles = ns.profiles
local actions = ns.profileActions
local settings = ns.timerTab.settings
local controls = ns.appearanceControls
local specSwitch = ns.specSwitch

local profilesTab = {}
ns.appearanceProfilesTab = profilesTab

local BOX_PADDING = 14
local BOX_GAP = 12
local TOP_OFFSET = 8
local CONTROL_GAP = 10
local DROPDOWN_WIDTH = 300
local BUTTON_GAP = 8
local BUTTON_WIDTH = (DROPDOWN_WIDTH - BUTTON_GAP) / 2
local BUTTON_HEIGHT = 24
local NOTE_GAP = 16
local BOX_HEIGHT_FIRST = 100
local REMOVE_ICON_ATLAS = "transmog-icon-remove"
local RENAME_ICON_ATLAS = "Pencil-Icon"
local REMOVE_ICON_SIZE = 18
local RENAME_ICON_SIZE = 22
local ROW_ICON_GAP = 4
local SPEC_LIST_GAP = 2
local SPEC_CHECKBOX_RAISE = 8
local SPEC_ROW_GAP = 10
local SPEC_ICON_SIZE = 24
local SPEC_ICON_GAP = 8
local SPEC_NAME_WIDTH = 150
local SPEC_ICON_INDENT = 4
local NOTE_COLOR = { 0.8, 0.8, 0.8 }

local dropdown
local notes = {}
local specCheckbox
local specDropdowns = {}

local function createSection(content, previous, headingText, height)
    local box = settings.CreateBox(content)
    box:SetHeight(height)
    if previous then
        box:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, -BOX_GAP)
        box:SetPoint("TOPRIGHT", previous, "BOTTOMRIGHT", 0, -BOX_GAP)
    else
        box:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -TOP_OFFSET)
        box:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, -TOP_OFFSET)
    end
    local heading = box:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    heading:SetPoint("TOPLEFT", box, "TOPLEFT", BOX_PADDING, -BOX_PADDING)
    heading:SetText(headingText)
    return box, heading
end

local function createNote(box, text, above, offsetX, contentsHeight)
    local note = box:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    note:SetTextColor(NOTE_COLOR[1], NOTE_COLOR[2], NOTE_COLOR[3])
    note:SetJustifyH("LEFT")
    note:SetJustifyV("TOP")
    note:SetPoint("TOPLEFT", above, "BOTTOMLEFT", offsetX or 0, -NOTE_GAP)
    note:SetText(text)
    notes[#notes + 1] = { box = box, note = note, contentsHeight = contentsHeight }
end

local function fitNotes()
    for _, entry in ipairs(notes) do
        local width = entry.box:GetWidth()
        if width > 0 then
            entry.note:SetWidth(math.max(width - 2 * BOX_PADDING, 1))
            entry.box:SetHeight(entry.contentsHeight() + NOTE_GAP + entry.note:GetStringHeight() + BOX_PADDING)
        end
    end
end

local function createButtons(box, heading, list)
    local previous
    local first
    for _, entry in ipairs(list) do
        local button = CreateFrame("Button", nil, box, "UIPanelButtonTemplate")
        button:SetSize(BUTTON_WIDTH, BUTTON_HEIGHT)
        button:SetText(entry.text)
        button:SetScript("OnClick", entry.onClick)
        if previous then
            button:SetPoint("LEFT", previous, "RIGHT", BUTTON_GAP, 0)
        else
            button:SetPoint("TOPLEFT", heading, "BOTTOMLEFT", 0, -CONTROL_GAP)
        end
        previous = button
        first = first or button
    end
    return first
end

function profilesTab.Update()
    if dropdown then
        dropdown:GenerateMenu()
    end
    if specCheckbox then
        specCheckbox:SetChecked(profiles.SpecEnabled())
        for _, specDropdown in ipairs(specDropdowns) do
            specDropdown:SetEnabled(profiles.SpecEnabled())
            specDropdown:GenerateMenu()
        end
    end
end

local function attachRowButton(row, menu, tooltip, offset, size, onClick, picture)
    local button = MenuTemplates.AttachAutoHideButton(row, REMOVE_ICON_ATLAS)
    button:SetPoint("RIGHT", -offset, 0)
    button:SetSize(size, size)
    if button.Texture then
        picture(button.Texture)
    end
    button:SetScript("OnClick", function()
        menu:Close()
        onClick()
    end)
    MenuUtil.HookTooltipScripts(button, function(tip)
        tip:SetText(tooltip)
    end)
end

local function createSpecs(content, previous)
    local count = specSwitch.Count()
    local box, heading = createSection(content, previous, L.PROFILE_SPECS_HEADING, BOX_HEIGHT_FIRST)
    specCheckbox = controls.Checkbox(box, heading, L.PROFILE_SPECS_ENABLE, profiles.SpecEnabled, function(checked)
        profiles.SetSpecEnabled(checked)
        profilesTab.Update()
    end, 0, SPEC_CHECKBOX_RAISE)
    local above = specCheckbox
    for spec = 1, count do
        local name, icon = specSwitch.Info(spec)
        local picture = box:CreateTexture(nil, "ARTWORK")
        picture:SetSize(SPEC_ICON_SIZE, SPEC_ICON_SIZE)
        picture:SetTexture(icon)
        picture:SetPoint("TOPLEFT", above, "BOTTOMLEFT", spec == 1 and SPEC_ICON_INDENT or 0,
            spec == 1 and -SPEC_LIST_GAP or -SPEC_ROW_GAP)
        local label = box:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        label:SetWidth(SPEC_NAME_WIDTH)
        label:SetJustifyH("LEFT")
        label:SetPoint("LEFT", picture, "RIGHT", SPEC_ICON_GAP, 0)
        label:SetText(name or "")
        local specDropdown = CreateFrame("DropdownButton", nil, box, "WowStyle1DropdownTemplate")
        specDropdown:SetWidth(DROPDOWN_WIDTH)
        specDropdown:SetPoint("LEFT", label, "RIGHT", SPEC_ICON_GAP, 0)
        specDropdown:SetupMenu(function(_, rootDescription)
            for _, profileName in ipairs(profiles.Names()) do
                rootDescription:CreateRadio(profiles.DisplayName(profileName), function()
                    return profiles.SpecProfile(spec) == profileName
                end, function()
                    profiles.SetSpecProfile(spec, profileName)
                end)
            end
            rootDescription:SetScrollMode(ns.media.MENU_MAX_HEIGHT)
        end)
        specDropdowns[#specDropdowns + 1] = specDropdown
        above = picture
    end
    createNote(box, L.PROFILE_SPECS_NOTE, above, above == specCheckbox and 0 or -SPEC_ICON_INDENT, function()
        local rows = count > 0 and SPEC_LIST_GAP + count * SPEC_ICON_SIZE + (count - 1) * SPEC_ROW_GAP or 0
        return BOX_PADDING + heading:GetStringHeight() + controls.LABEL_GAP - SPEC_CHECKBOX_RAISE + specCheckbox:GetHeight()
            + rows
    end)
    return box
end

function profilesTab.Build(content)
    local current, currentHeading = createSection(content, nil, L.PROFILE_HEADING, BOX_HEIGHT_FIRST)
    dropdown = CreateFrame("DropdownButton", nil, current, "WowStyle1DropdownTemplate")
    dropdown:SetWidth(DROPDOWN_WIDTH)
    dropdown:SetPoint("TOPLEFT", currentHeading, "BOTTOMLEFT", 0, -CONTROL_GAP)
    dropdown:SetupMenu(function(_, rootDescription)
        for _, name in ipairs(profiles.Names()) do
            local entry = rootDescription:CreateRadio(profiles.DisplayName(name), function()
                return profiles.CurrentName() == name
            end, function()
                profiles.Select(name)
            end)
            if not profiles.IsDefault(name) then
                local removable = name ~= profiles.CurrentName()
                entry:AddInitializer(function(row, _, menu)
                    attachRowButton(row, menu, L.PROFILE_RENAME, removable and REMOVE_ICON_SIZE + ROW_ICON_GAP or 0,
                        RENAME_ICON_SIZE, function()
                        actions.Rename(name)
                    end, function(texture)
                        texture:SetAtlas(RENAME_ICON_ATLAS)
                    end)
                    if removable then
                        attachRowButton(row, menu, L.PROFILE_DELETE, 0, REMOVE_ICON_SIZE, function()
                            actions.DeleteProfile(name)
                        end, function(texture)
                            texture:SetAtlas(REMOVE_ICON_ATLAS)
                        end)
                    end
                end)
            end
        end
        rootDescription:CreateDivider()
        rootDescription:CreateButton(ns.text.Gold(L.PROFILE_NEW_COPY), actions.Duplicate)
        rootDescription:CreateButton(ns.text.Gold(L.PROFILE_NEW_BLIZZARD), function()
            actions.CreateWithLook(ns.presets.BLIZZARD)
        end)
        rootDescription:CreateButton(ns.text.Gold(L.PROFILE_NEW_PLAIN), function()
            actions.CreateWithLook(ns.presets.PLAIN)
        end)
        rootDescription:SetScrollMode(ns.media.MENU_MAX_HEIGHT)
    end)
    createNote(current, L.PROFILE_NOTE, dropdown, 0, function()
        return BOX_PADDING + currentHeading:GetStringHeight() + CONTROL_GAP + dropdown:GetHeight()
    end)

    local specs = createSpecs(content, current)

    local exchange, exchangeHeading = createSection(content, specs, L.PROFILE_EXCHANGE, BOX_HEIGHT_FIRST)
    local exchangeButtons = createButtons(exchange, exchangeHeading, {
        { text = L.PROFILE_IMPORT, onClick = actions.Import },
        { text = L.PROFILE_EXPORT, onClick = actions.Export },
    })
    createNote(exchange, L.PROFILE_EXCHANGE_NOTE, exchangeButtons, 0, function()
        return BOX_PADDING + exchangeHeading:GetStringHeight() + CONTROL_GAP + BUTTON_HEIGHT
    end)

    profilesTab.Update()
    content:SetScript("OnShow", function()
        profilesTab.Update()
        fitNotes()
        C_Timer.After(0, fitNotes)
    end)
    profiles.OnChanged(profilesTab.Update)
end
