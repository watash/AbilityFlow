local addonName, ns = ...

local CreateFrame = CreateFrame
local UIParent = UIParent
local C_Texture = C_Texture
local C_Timer = C_Timer
local InCombatLockdown = InCombatLockdown
local IsEncounterInProgress = IsEncounterInProgress
local tinsert = tinsert
local ipairs = ipairs
local math = math

local L = ns.L
local presets = ns.presets

local firstRun = {}
ns.firstRun = firstRun

local FRAME_NAME = "AbilityFlowStyleFrame"
local TEXTURE_PATH = "Interface\\AddOns\\AbilityFlow\\Media\\Textures\\"
local BACKDROP_TEXTURE = TEXTURE_PATH .. "first-run\\backdrop.png"
local BORDER_TEXTURE = TEXTURE_PATH .. "first-run\\border.png"
local DIVIDER_TEXTURE = TEXTURE_PATH .. "first-run\\divider.png"
local SHADOW_TEXTURE = TEXTURE_PATH .. "first-run\\shadow.png"
local START_DELAY_SECONDS = 6

local FRAME_WIDTH = 720
local FRAME_HEIGHT = 620
local SIDE_MARGIN = 30
local BRAND_TOP = 16
local TITLE_TOP = 100
local HALVES_TOP = 160
local HALVES_BOTTOM = 70
local SHADOW_MARGIN = 60
local SAMPLE_TOP_GAP = 14
local SAMPLE_GAP = 12
local HEADING_GAP = 8
local DESCRIPTION_WIDTH = 290
local DESCRIPTION_HEIGHT = 54
local HEADING_SCALE = 1.15
local DESCRIPTION_SCALE = 1.15
local FOOTER_SCALE = 1.1
local FOOTER_BOTTOM = 34
local CLOSE_SIZE = 30
local CLOSE_CENTER = 20
local CLOSE_OFFSET = CLOSE_CENTER - CLOSE_SIZE / 2
local ADDON_TITLE_COLOR = { 0.3, 0.06, 0.04 }
local BANNER_ATLAS = "charactercreate-banner-bottom"
local BANNER_HEIGHT = 60
local BANNER_MIN_WIDTH = 200
local BANNER_SIDE_ROOM = 90
local BANNER_TOP = 0
local BANNER_RISE = 5
local BORDER_LEVEL = 2
local BANNER_TINT = { 1, 0.8, 0.38 }
local BANNER_ADDED = { { 1, 0.8, 0.38 }, { 0.4, 0.36, 0.17 } }
local PLATE_ATLAS = "evergreen-scenario-titlebg"
local PLATE_HEIGHT = 165
local PLATE_MIN_WIDTH = 350
local PLATE_SIDE_ROOM = 120
local PLATE_SHIFT = 3
local PLATE_STRENGTH = 0.7
local DIVIDER_WIDTH = 16
local DIVIDER_TOP = 154
local DIVIDER_BOTTOM = 80
local ARROW_ATLAS = "Azerite-PointingArrow"
local ARROW_WIDTH = 40
local ARROW_HEIGHT = 28
local ARROW_EDGE = 0
local ARROW_LEVEL = 3
local QUARTER_TURN = math.pi / 2
local LIFT_PIXELS = 8
local HOVER_IN_SPEED = 8
local HOVER_OUT_SPEED = 18
local PARCHMENT_ATLAS = "warboard-parchment"
local PARCHMENT_INSET = 4
local PARCHMENT_GROW = 6
local SAMPLE_PLATE = TEXTURE_PATH .. "first-run\\sample-plate.png"
local HEADING_COLOR = { 0.3, 0.1, 0.03 }
local NOTE_COLOR = { 0.2, 0.12, 0.07 }
local FOOTER_COLOR = { 0.8, 0.8, 0.8 }
local FADE_IN_SECONDS = 0.35

local CARDS = {
    { preset = presets.BLIZZARD, plain = false, name = "STYLE_BLIZZARD", description = "STYLE_BLIZZARD_DESC" },
    { preset = presets.PLAIN, plain = true, name = "STYLE_PLAIN", description = "STYLE_PLAIN_DESC" },
}

local frame
local halves = {}
local arrowPictures = {}
local shownSeconds = 0

local function markChosen()
    AbilityFlowDB.styleChosen = true
end

local function onHide()
    if AbilityFlowDB.styleChosen == false then
        presets.Apply(presets.BLIZZARD)
    end
    markChosen()
end

local function follow(step)
    shownSeconds = shownSeconds + step
    frame:SetAlpha(math.min(shownSeconds / FADE_IN_SECONDS, 1))
    for index, half in ipairs(halves) do
        if half.button:IsMouseOver() then
            half.hover = math.min(half.hover + HOVER_IN_SPEED * step, 1)
        else
            half.hover = math.max(half.hover - HOVER_OUT_SPEED * step, 0)
        end
        local hover = half.hover
        local inset = PARCHMENT_INSET - math.floor(PARCHMENT_GROW * hover + 0.5)
        if inset ~= half.parchmentInset then
            half.parchmentInset = inset
            half.parchment:ClearAllPoints()
            half.parchment:SetPoint("TOPLEFT", half.button, "TOPLEFT", inset, -inset)
            half.parchment:SetPoint("BOTTOMRIGHT", half.button, "BOTTOMRIGHT", -inset, inset)
        end
        arrowPictures[index]:SetAlpha(hover)
        half.content:ClearAllPoints()
        half.content:SetPoint("CENTER", half.button, "CENTER", 0, math.floor(LIFT_PIXELS * hover + 0.5))
    end
end

local function buildHalf(card, index)
    local width = (FRAME_WIDTH - 2 * SIDE_MARGIN) / 2
    local half = { hover = 0 }
    halves[index] = half
    half.button = CreateFrame("Button", nil, frame)
    half.button:SetSize(width, FRAME_HEIGHT - HALVES_TOP - HALVES_BOTTOM)
    half.button:SetPoint("TOPLEFT", frame, "TOPLEFT", SIDE_MARGIN + (index - 1) * width, -HALVES_TOP)
    half.button:SetScript("OnClick", function()
        presets.Apply(card.preset)
        markChosen()
        frame:Hide()
    end)

    half.parchment = half.button:CreateTexture(nil, "BACKGROUND")
    half.parchment:SetAtlas(PARCHMENT_ATLAS)
    if index == 2 then
        local upperLeftX, upperLeftY, lowerLeftX, lowerLeftY, upperRightX, upperRightY, lowerRightX, lowerRightY = half.parchment:GetTexCoord()
        half.parchment:SetTexCoord(upperRightX, upperRightY, lowerRightX, lowerRightY, upperLeftX, upperLeftY, lowerLeftX, lowerLeftY)
    end
    half.parchment:SetPoint("TOPLEFT", half.button, "TOPLEFT", PARCHMENT_INSET, -PARCHMENT_INSET)
    half.parchment:SetPoint("BOTTOMRIGHT", half.button, "BOTTOMRIGHT", -PARCHMENT_INSET, PARCHMENT_INSET)

    half.content = CreateFrame("Frame", nil, half.button)
    half.content:SetSize(width, FRAME_HEIGHT - HALVES_TOP - HALVES_BOTTOM)
    half.content:SetPoint("CENTER", half.button, "CENTER")
    local sample = ns.firstRunSample.Create(half.content, card.plain, false, SAMPLE_PLATE)
    sample:SetPoint("TOP", half.content, "TOP", 0, -SAMPLE_TOP_GAP)

    local heading = half.content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    heading:SetPoint("TOP", sample, "BOTTOM", 0, -SAMPLE_GAP)
    heading:SetText(L[card.name])
    local headingFont, headingSize, headingFlags = heading:GetFont()
    if headingFont then
        heading:SetFont(headingFont, headingSize * HEADING_SCALE, headingFlags)
    end
    heading:SetTextColor(HEADING_COLOR[1], HEADING_COLOR[2], HEADING_COLOR[3])
    heading:SetShadowOffset(0, 0)

    local description = half.content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    description:SetPoint("TOP", heading, "BOTTOM", 0, -HEADING_GAP)
    description:SetSize(DESCRIPTION_WIDTH, DESCRIPTION_HEIGHT)
    description:SetJustifyH("CENTER")
    description:SetJustifyV("TOP")
    description:SetTextColor(NOTE_COLOR[1], NOTE_COLOR[2], NOTE_COLOR[3])
    description:SetShadowOffset(0, 0)
    description:SetText(L[card.description])
    local descriptionFont, descriptionSize, descriptionFlags = description:GetFont()
    if descriptionFont then
        description:SetFont(descriptionFont, descriptionSize * DESCRIPTION_SCALE, descriptionFlags)
    end
end

local function build()
    frame = CreateFrame("Frame", FRAME_NAME, UIParent)
    frame:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
    frame:SetPoint("CENTER", UIParent, "CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetToplevel(true)
    frame:EnableMouse(true)
    frame:Hide()
    tinsert(UISpecialFrames, FRAME_NAME)
    frame:SetScript("OnHide", onHide)
    frame:SetScript("OnShow", function()
        shownSeconds = 0
        frame:SetAlpha(0)
    end)
    frame:SetScript("OnUpdate", function(_, step)
        follow(step)
    end)

    local shadow = frame:CreateTexture(nil, "BACKGROUND", nil, -8)
    shadow:SetTexture(SHADOW_TEXTURE)
    shadow:SetPoint("CENTER", frame, "CENTER")
    shadow:SetSize(FRAME_WIDTH + 2 * SHADOW_MARGIN, FRAME_HEIGHT + 2 * SHADOW_MARGIN)
    local backdrop = frame:CreateTexture(nil, "BACKGROUND")
    backdrop:SetTexture(BACKDROP_TEXTURE)
    backdrop:SetAllPoints()

    local border = CreateFrame("Frame", nil, frame)
    border:SetAllPoints()
    border:SetFrameLevel(frame:GetFrameLevel() + BORDER_LEVEL)
    local edge = border:CreateTexture(nil, "OVERLAY")
    edge:SetTexture(BORDER_TEXTURE)
    edge:SetAllPoints()

    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetFrameLevel(frame:GetFrameLevel() + BORDER_LEVEL + 1)
    close:SetSize(CLOSE_SIZE, CLOSE_SIZE)
    close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -CLOSE_OFFSET, -CLOSE_OFFSET)

    local banner = CreateFrame("Frame", nil, frame)
    banner:SetSize(BANNER_MIN_WIDTH, BANNER_HEIGHT)
    banner:SetPoint("TOP", frame, "TOP", 0, -BANNER_TOP)
    banner:SetFrameLevel(frame:GetFrameLevel() + 1)
    local brand = banner:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    brand:SetPoint("TOP", frame, "TOP", 0, -BRAND_TOP)
    brand:SetText(addonName)
    brand:SetTextColor(ADDON_TITLE_COLOR[1], ADDON_TITLE_COLOR[2], ADDON_TITLE_COLOR[3])
    brand:SetShadowOffset(0, 0)
    if C_Texture.GetAtlasInfo(BANNER_ATLAS) then
        banner:SetWidth(math.max(BANNER_MIN_WIDTH, brand:GetStringWidth() + BANNER_SIDE_ROOM))
        banner:SetClipsChildren(true)
        local base = banner:CreateTexture(nil, "ARTWORK")
        base:SetAtlas(BANNER_ATLAS)
        base:SetPoint("TOPLEFT", banner, "TOPLEFT", 0, BANNER_RISE)
        base:SetPoint("BOTTOMRIGHT", banner, "BOTTOMRIGHT")
        base:SetVertexColor(BANNER_TINT[1], BANNER_TINT[2], BANNER_TINT[3])
        for layer, color in ipairs(BANNER_ADDED) do
            local added = banner:CreateTexture(nil, "ARTWORK", nil, layer)
            added:SetAtlas(BANNER_ATLAS)
            added:SetBlendMode("ADD")
            added:SetPoint("TOPLEFT", banner, "TOPLEFT", 0, BANNER_RISE)
            added:SetPoint("BOTTOMRIGHT", banner, "BOTTOMRIGHT")
            added:SetVertexColor(color[1], color[2], color[3])
        end
    end
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    title:SetPoint("TOP", frame, "TOP", 0, -TITLE_TOP)
    title:SetText(L.FIRST_RUN_TITLE)
    if C_Texture.GetAtlasInfo(PLATE_ATLAS) then
        local plate = frame:CreateTexture(nil, "ARTWORK")
        plate:SetAtlas(PLATE_ATLAS)
        plate:SetSize(math.max(PLATE_MIN_WIDTH, title:GetStringWidth() + PLATE_SIDE_ROOM), PLATE_HEIGHT)
        plate:SetPoint("CENTER", title, "CENTER", 0, PLATE_SHIFT)
        plate:SetAlpha(PLATE_STRENGTH)
    end

    local divider = frame:CreateTexture(nil, "ARTWORK")
    divider:SetTexture(DIVIDER_TEXTURE)
    divider:SetWidth(DIVIDER_WIDTH)
    divider:SetPoint("TOP", frame, "TOP", 0, -DIVIDER_TOP)
    divider:SetPoint("BOTTOM", frame, "BOTTOM", 0, DIVIDER_BOTTOM)

    for index, card in ipairs(CARDS) do
        buildHalf(card, index)
    end

    local arrows = CreateFrame("Frame", nil, frame)
    arrows:SetAllPoints()
    arrows:SetFrameLevel(frame:GetFrameLevel() + ARROW_LEVEL)
    arrows:EnableMouse(false)
    for side, turn in ipairs({ QUARTER_TURN, -QUARTER_TURN }) do
        local arrow = arrows:CreateTexture(nil, "OVERLAY")
        arrow:SetAtlas(ARROW_ATLAS)
        arrow:SetSize(ARROW_HEIGHT, ARROW_WIDTH)
        arrow:SetRotation(turn)
        arrow:SetPoint("CENTER", halves[side].button, side == 1 and "LEFT" or "RIGHT", side == 1 and ARROW_EDGE or -ARROW_EDGE, 0)
        arrow:SetAlpha(0)
        arrowPictures[side] = arrow
    end

    local footer = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    footer:SetPoint("BOTTOM", frame, "BOTTOM", 0, FOOTER_BOTTOM)
    footer:SetTextColor(FOOTER_COLOR[1], FOOTER_COLOR[2], FOOTER_COLOR[3])
    footer:SetText(L.FIRST_RUN_FOOTER:format(ns.text.Gold(_G.SLASH_ABILITYFLOW2)))
    local footerFont, footerSize, footerFlags = footer:GetFont()
    if footerFont then
        footer:SetFont(footerFont, footerSize * FOOTER_SCALE, footerFlags)
    end
end

function firstRun.Show()
    if not frame then
        build()
    end
    frame:Show()
end

function firstRun.Prepare(isNew)
    if isNew then
        AbilityFlowDB.styleChosen = false
    elseif AbilityFlowDB.styleChosen == nil then
        AbilityFlowDB.styleChosen = true
    end
end

local waiter

local function showWhenFree()
    if InCombatLockdown() or IsEncounterInProgress() then
        waiter = waiter or CreateFrame("Frame")
        waiter:RegisterEvent("PLAYER_REGEN_ENABLED")
        waiter:SetScript("OnEvent", function(self)
            self:UnregisterAllEvents()
            C_Timer.After(START_DELAY_SECONDS, showWhenFree)
        end)
        return
    end
    firstRun.Show()
end

function firstRun.Start()
    if AbilityFlowDB.styleChosen == false then
        C_Timer.After(START_DELAY_SECONDS, showWhenFree)
    end
end
