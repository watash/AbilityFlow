local addonName, ns = ...

local L = ns.L
local preview = ns.appearancePreview
local controls = ns.appearanceControls
local general = ns.appearanceGeneral
local CreateFrame = CreateFrame
local UIParent = UIParent
local tinsert = tinsert

local eventAppearance = {}
ns.eventAppearance = eventAppearance

local WINDOW_WIDTH = 1000
local WINDOW_HEIGHT = 790
local PADDING = 15
local TAB_BAR_TOP = 32
local TAB_SPACING = 5
local TAB_TEXT_PADDING = 15
local TAB_MIN_WIDTH = 70
local TITLE_GAP = 8
local SCALE_ROW_HEIGHT = 20
local TITLE_ROW_GAP = 20
local SCALE_LABEL_WIDTH = 230
local PREVIEW_HEIGHT = 340
local SECTION_GAP = 12
local FRAME_NAME = "AbilityFlowEventAppearanceFrame"
local PREVIEW_SCALE_MIN = 100
local PREVIEW_SCALE_MAX = 300
local PREVIEW_SCALE_DEFAULT = 100

local TABS = {
    { key = "General", labelKey = "EVENT_APPEARANCE_TAB_GENERAL" },
    { key = "TimerAppearance", labelKey = "EVENT_APPEARANCE_TAB_TIMER_APPEARANCE" },
    { key = "Behavior", labelKey = "EVENT_APPEARANCE_TAB_BEHAVIOR" },
    { key = "Addons", labelKey = "EVENT_APPEARANCE_TAB_ADDONS" },
    { key = "Options", labelKey = "EVENT_APPEARANCE_TAB_OPTIONS" },
    { key = "Profiles", labelKey = "EVENT_APPEARANCE_TAB_PROFILES" },
}

local frame
local tabButtons = {}
local tabContents = {}
local previewAnchor
local previewScale
local previewPanel
local currentTab
local FIRST_TAB = TABS[1].key
local PROFILES_TAB = "Profiles"
local TABS_WITHOUT_PREVIEW = { TimerAppearance = true, Profiles = true, Options = true, Behavior = true, Addons = true }

function eventAppearance.SelectTab(key)
    currentTab = key
    local showPreview = not TABS_WITHOUT_PREVIEW[key]
    previewScale:SetShown(showPreview)
    previewScale.rowLabel:SetShown(showPreview)
    previewPanel:SetShown(showPreview)
    for _, tab in ipairs(TABS) do
        local isSelected = tab.key == key
        tabContents[tab.key]:SetShown(isSelected)
        if isSelected then
            PanelTemplates_SelectTab(tabButtons[tab.key])
        else
            PanelTemplates_DeselectTab(tabButtons[tab.key])
        end
    end
end

local function applyPreviewScale(percent)
    local shift = math.max(0, (percent - PREVIEW_SCALE_DEFAULT) / (PREVIEW_SCALE_MAX - PREVIEW_SCALE_DEFAULT))
    preview.SetScale(previewPanel, percent, shift)
end

local function createWindow()
    frame = CreateFrame("Frame", FRAME_NAME, UIParent, "ButtonFrameTemplate")
    ButtonFrameTemplate_HidePortrait(frame)
    ButtonFrameTemplate_HideButtonBar(frame)
    frame.Inset:Hide()
    frame:SetSize(WINDOW_WIDTH, WINDOW_HEIGHT)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetToplevel(true)
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetTitle(L.EVENT_APPEARANCE_WINDOW_TITLE:format(addonName))
    frame:Hide()
    tinsert(UISpecialFrames, FRAME_NAME)
    controls.CloseOnEscape(frame)

    frame.CloseButton:SetScript("OnClick", function()
        frame:Hide()
    end)

    local previousButton
    for _, tab in ipairs(TABS) do
        local button = CreateFrame("Button", nil, frame, "PanelTopTabButtonTemplate")
        button:SetText(L[tab.labelKey])
        PanelTemplates_TabResize(button, TAB_TEXT_PADDING, nil, TAB_MIN_WIDTH)
        if previousButton then
            button:SetPoint("LEFT", previousButton, "RIGHT", TAB_SPACING, 0)
        else
            button:SetPoint("TOPLEFT", frame, "TOPLEFT", PADDING, -TAB_BAR_TOP)
        end
        button:SetScript("OnClick", function()
            eventAppearance.SelectTab(tab.key)
        end)
        tabButtons[tab.key] = button
        previousButton = button
    end

    previewAnchor = CreateFrame("Frame", nil, frame)
    previewAnchor:SetSize(1, SCALE_ROW_HEIGHT)
    previewAnchor:SetPoint("TOPLEFT", tabButtons[TABS[1].key], "BOTTOMLEFT", 0, -TITLE_GAP)

    previewPanel = preview.Create(frame, function(key)
        general.Select(key)
    end)
    local scaleLabel
    local showingHeldBack = false
    scaleLabel, previewScale = controls.InlineSlider(frame, L.EVENT_APPEARANCE_PREVIEW_SCALE, "%d%%", PREVIEW_SCALE_MIN,
        PREVIEW_SCALE_MAX, 1, PREVIEW_SCALE_DEFAULT, function(value)
            if not showingHeldBack then
                applyPreviewScale(value)
            end
        end)
    previewPanel.onHeldBack = function(percent)
        showingHeldBack = true
        previewScale:SetValue(math.floor(percent))
        showingHeldBack = false
        previewPanel.percent = math.floor(percent)
    end
    previewScale:SetPoint("RIGHT", previewPanel, "TOPRIGHT", 0, SCALE_ROW_HEIGHT / 2 + TITLE_GAP)
    scaleLabel:SetPoint("RIGHT", previewScale, "LEFT", -TITLE_ROW_GAP, 0)
    scaleLabel:SetWidth(SCALE_LABEL_WIDTH)
    scaleLabel:SetJustifyH("RIGHT")
    previewPanel:SetPoint("TOPLEFT", previewAnchor, "BOTTOMLEFT", 0, -TITLE_GAP)
    previewPanel:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -PADDING, 0)
    previewPanel:SetHeight(PREVIEW_HEIGHT)
    preview.Refresh(previewPanel)
    frame:HookScript("OnHide", function()
        preview.SetWhite(previewPanel, false)
        ns.appearanceTrackPreview.SetWhite(false)
        ns.appearanceDialogs.Close()
    end)
    ns.profiles.OnChanged(function()
        general.Refresh()
        ns.appearanceTimer.Refresh()
        preview.Refresh(previewPanel)
        ns.appearanceProfilesTab.Update()
    end)
    frame:HookScript("OnShow", function()
        preview.ChangePicture(previewPanel)
        previewScale:SetValue(PREVIEW_SCALE_DEFAULT)
        applyPreviewScale(PREVIEW_SCALE_DEFAULT)
    end)

    ns.appearanceTimer.OnLineBottom = function(lineBottom)
        previewPanel:SetHeight(math.max(PREVIEW_HEIGHT, lineBottom - SCALE_ROW_HEIGHT - TITLE_GAP))
    end

    for _, tab in ipairs(TABS) do
        local content = CreateFrame("Frame", nil, frame)
        if TABS_WITHOUT_PREVIEW[tab.key] then
            content:SetPoint("TOPLEFT", previewAnchor, "TOPLEFT", 0, 0)
        else
            content:SetPoint("TOPLEFT", previewPanel, "BOTTOMLEFT", 0, -SECTION_GAP)
        end
        content:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -PADDING, PADDING)
        content:Hide()
        tabContents[tab.key] = content

        if tab.key == "General" then
            general.Build(content, function()
                preview.Refresh(previewPanel)
            end)
        elseif tab.key == "TimerAppearance" then
            ns.appearanceTimer.Build(content)
        elseif tab.key == "Profiles" then
            ns.appearanceProfilesTab.Build(content)
        elseif tab.key == "Behavior" then
            ns.appearanceBehaviorTab.Build(content)
        elseif tab.key == "Options" then
            ns.appearanceOptionsTab.Build(content)
        elseif tab.key == "Addons" then
            ns.appearanceAddonsTab.Build(content)
        end
    end

    eventAppearance.SelectTab(FIRST_TAB)
end

function eventAppearance.Toggle(key)
    if not frame then
        createWindow()
    end
    if not key then
        if frame:IsShown() then
            frame:Hide()
            return
        end
        key = currentTab ~= PROFILES_TAB and currentTab or FIRST_TAB
    end
    if frame:IsShown() and currentTab == key then
        frame:Hide()
        return
    end
    eventAppearance.SelectTab(key)
    frame:Show()
end

function eventAppearance.IsShown()
    return frame ~= nil and frame:IsShown()
end
