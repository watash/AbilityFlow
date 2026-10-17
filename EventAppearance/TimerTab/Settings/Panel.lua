local addonName, ns = ...

local C_Timer = C_Timer
local CreateFrame = CreateFrame
local ipairs = ipairs
local pairs = pairs
local PanelTemplates_SelectTab = PanelTemplates_SelectTab
local PanelTemplates_DeselectTab = PanelTemplates_DeselectTab
local PanelTemplates_TabResize = PanelTemplates_TabResize
local L = ns.L
local controls = ns.appearanceControls
local timerStyle = ns.timerStyle
local settings = ns.timerTab.settings

local PAGES = {
    { key = "GLOW", labelKey = "TIMER_STYLE_TAB_GLOW" },
    { key = "EFFECTS", labelKey = "TIMER_STYLE_TAB_EFFECTS" },
    { key = "TIMER", labelKey = "TIMER_STYLE_TAB_TIMER" },
    { key = "NAME", labelKey = "TIMER_STYLE_TAB_NAME" },
}

local TAB_TEXT_PADDING = controls.SUBTAB_TEXT_PADDING
local TAB_MIN_WIDTH = controls.SUBTAB_MIN_WIDTH
local TAB_SPACING = controls.SUBTAB_SPACING
local RESET_LEVEL = 10
local TABS_SHIFT = 12
local PAGE_GAP = 0
local PAGE_PADDING = 10
local EMPTY_FONT = "GameFontNormalLarge"
local BOX_TEXTURE = "Interface\\Buttons\\WHITE8X8"
local BOX_EDGE_SIZE = 1
settings.BOX_EDGE_DEPTH = 2 * BOX_EDGE_SIZE
local BOX_FILL = { 0, 0, 0, 0.4 }
local BOX_EDGE = { 0, 0, 0, 1 }
local BOX_INNER_EDGE = { 0.45, 0.45, 0.45, 0.9 }

local area
local emptyText
local pageBox
local tabStrip
local tabButtons = {}
local resetButton
local updateReset
local changed
local panel
local shownID
local currentPage = PAGES[1].key

local function alignPage()
    if not panel or not shownID then
        return
    end
    local top = panel.frame:GetTop()
    local page = panel.pages[currentPage]
    local center = top and page and controls.FirstRowCenter(page, top)
    if center then
        local general = ns.appearanceGeneral
        local line = general.ELEMENT_GAP + general.SUBTAB_CONTENT_GAP + general.FIRST_ROW_CENTER
        panel.frame:SetPoint("TOPLEFT", pageBox, "TOPLEFT", 0, -(line - center))
    end
end

local function showPage()
    updateReset()
    if panel then
        for key, page in pairs(panel.pages) do
            page:SetShown(key == currentPage)
        end
    end
    alignPage()
    C_Timer.After(0, alignPage)
    for key, button in pairs(tabButtons) do
        if key == currentPage then
            PanelTemplates_SelectTab(button)
        else
            PanelTemplates_DeselectTab(button)
        end
    end
end

updateReset = function()
    if not resetButton then
        return
    end
    local has = shownID ~= nil and timerStyle.PageCanReset(currentPage)
    resetButton:SetShown(has)
    resetButton:SetEnabled(has and not timerStyle.PageIsDefault(shownID, currentPage))
end

local function shownTemplate()
    return shownID and timerStyle.Template(shownID) or nil
end

function settings.ShownID()
    return shownID
end

local function buildPanel()
    local frame = CreateFrame("Frame", nil, pageBox)
    frame:SetPoint("TOPLEFT", pageBox, "TOPLEFT", 0, -PAGE_PADDING)
    frame:SetPoint("BOTTOMRIGHT", pageBox, "BOTTOMRIGHT", -PAGE_PADDING, PAGE_PADDING)
    local entry = { frame = frame, pages = {}, controls = {} }
    for _, page in ipairs(PAGES) do
        local pageFrame = CreateFrame("Frame", nil, frame)
        pageFrame:SetAllPoints()
        entry.pages[page.key] = pageFrame
        entry.controls[page.key] = settings.builders[page.key](pageFrame, shownTemplate, function()
            changed()
            updateReset()
        end)
    end
    return entry
end

local function refreshControls()
    if not panel or not shownID then
        return
    end
    controls.ResyncAll(panel.frame)
    for _, pageControls in pairs(panel.controls) do
        pageControls.refresh()
    end
end

function settings.CreateBox(parent)
    local box = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    box:SetBackdrop({ bgFile = BOX_TEXTURE, edgeFile = BOX_TEXTURE, edgeSize = BOX_EDGE_SIZE })
    box:SetBackdropColor(BOX_FILL[1], BOX_FILL[2], BOX_FILL[3], BOX_FILL[4])
    box:SetBackdropBorderColor(BOX_EDGE[1], BOX_EDGE[2], BOX_EDGE[3], BOX_EDGE[4])
    local inner = CreateFrame("Frame", nil, box, "BackdropTemplate")
    inner:SetPoint("TOPLEFT", box, "TOPLEFT", BOX_EDGE_SIZE, -BOX_EDGE_SIZE)
    inner:SetPoint("BOTTOMRIGHT", box, "BOTTOMRIGHT", -BOX_EDGE_SIZE, BOX_EDGE_SIZE)
    inner:SetBackdrop({ edgeFile = BOX_TEXTURE, edgeSize = BOX_EDGE_SIZE })
    inner:SetBackdropBorderColor(BOX_INNER_EDGE[1], BOX_INNER_EDGE[2], BOX_INNER_EDGE[3], BOX_INNER_EDGE[4])
    return box
end

function settings.Setup(settingsArea, onChanged)
    area = settingsArea
    changed = onChanged
    tabStrip = CreateFrame("Frame", nil, area)
    tabStrip:SetPoint("TOPLEFT", area, "TOPLEFT", TABS_SHIFT, 0)
    local previous
    for _, page in ipairs(PAGES) do
        local button = CreateFrame("Button", nil, tabStrip, "PanelTopTabButtonTemplate")
        button:SetText(L[page.labelKey])
        PanelTemplates_TabResize(button, TAB_TEXT_PADDING, nil, TAB_MIN_WIDTH)
        if previous then
            button:SetPoint("LEFT", previous, "RIGHT", TAB_SPACING, 0)
        else
            button:SetPoint("TOPLEFT", tabStrip, "TOPLEFT", 0, 0)
        end
        button:SetScript("OnClick", function()
            currentPage = page.key
            showPage()
        end)
        tabButtons[page.key] = button
        previous = button
    end
    tabStrip:SetSize(1, tabButtons[PAGES[1].key]:GetHeight())

    pageBox = settings.CreateBox(area)
    pageBox:SetPoint("TOPLEFT", tabStrip, "BOTTOMLEFT", 0, -PAGE_GAP)
    pageBox:SetPoint("BOTTOMRIGHT", area, "BOTTOMRIGHT", 0, 0)
    resetButton = CreateFrame("Button", nil, pageBox, "UIPanelButtonTemplate")
    resetButton:SetText(L.EVENT_APPEARANCE_RESET)
    controls.SizeResetButton(resetButton)
    resetButton:SetFrameLevel(pageBox:GetFrameLevel() + RESET_LEVEL)
    resetButton:SetPoint("BOTTOMRIGHT", pageBox, "BOTTOMRIGHT", -controls.RESET_BUTTON_RIGHT_MARGIN,
        controls.RESET_BUTTON_BOTTOM_MARGIN)
    resetButton:SetScript("OnClick", function()
        if shownID then
            timerStyle.ResetPage(shownID, currentPage)
            refreshControls()
            changed()
            updateReset()
        end
    end)
    emptyText = pageBox:CreateFontString(nil, "OVERLAY", EMPTY_FONT)
    emptyText:SetPoint("CENTER", pageBox, "CENTER")
    emptyText:SetText(L.TIMER_STYLE_SELECT_TEMPLATE)
end

local boxTabWidth, boxSettingsLeft

local function placeBox()
    if not boxTabWidth then
        return
    end
    local rightEdge = boxSettingsLeft + area:GetWidth()
    local top = tabStrip:IsShown() and (tabStrip:GetHeight() + PAGE_GAP) or 0
    pageBox:ClearAllPoints()
    pageBox:SetPoint("TOPLEFT", area, "TOPLEFT", -boxSettingsLeft, -top)
    pageBox:SetPoint("BOTTOMRIGHT", area, "BOTTOMRIGHT", boxTabWidth - rightEdge, 0)
end

function settings.PlaceBox(tabWidth, settingsLeft)
    boxTabWidth, boxSettingsLeft = tabWidth, settingsLeft
    placeBox()
end

function settings.Show(templateID)
    shownID = templateID
    if templateID and not panel then
        panel = buildPanel()
    end
    if panel then
        panel.frame:SetShown(templateID ~= nil)
    end
    refreshControls()
    tabStrip:SetShown(templateID ~= nil)
    emptyText:SetShown(templateID == nil)
    placeBox()
    showPage()
end
