local addonName, ns = ...

local CreateFrame = CreateFrame
local UIParent = UIParent
local ReloadUI = ReloadUI
local tinsert = tinsert
local L = ns.L

local reloadPrompt = {}
ns.reloadPrompt = reloadPrompt

local FRAME_NAME = "AbilityFlowReloadPrompt"

local FRAME_WIDTH = 420
local BODY_SIDE_PADDING = 30
local TITLE_TOP_OFFSET = 20
local BODY_TOP_GAP = 12
local BUTTON_WIDTH = 140
local BUTTON_HEIGHT = 24
local BUTTON_BOTTOM_OFFSET = 18
local BUTTON_TOP_GAP = 16
local BUTTON_GAP = 12
local BACKDROP_TILE_SIZE = 32
local BACKDROP_EDGE_SIZE = 32
local BACKDROP_INSETS = { left = 11, right = 12, top = 12, bottom = 11 }

local frame

local function build()
    frame = CreateFrame("Frame", FRAME_NAME, UIParent, "BackdropTemplate")
    frame:SetWidth(FRAME_WIDTH)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = BACKDROP_TILE_SIZE,
        edgeSize = BACKDROP_EDGE_SIZE,
        insets = BACKDROP_INSETS,
    })
    frame:Hide()

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", frame, "TOP", 0, -TITLE_TOP_OFFSET)
    title:SetText(L.RELOAD_PROMPT_TITLE)

    local body = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    body:SetPoint("TOP", title, "BOTTOM", 0, -BODY_TOP_GAP)
    body:SetWidth(FRAME_WIDTH - 2 * BODY_SIDE_PADDING)
    body:SetJustifyH("CENTER")
    body:SetText(L.RELOAD_PROMPT_BODY)
    frame:SetHeight(TITLE_TOP_OFFSET + title:GetStringHeight() + BODY_TOP_GAP + body:GetStringHeight() + BUTTON_TOP_GAP
        + BUTTON_HEIGHT + BUTTON_BOTTOM_OFFSET)

    local reloadButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    reloadButton:SetSize(BUTTON_WIDTH, BUTTON_HEIGHT)
    reloadButton:SetPoint("BOTTOMRIGHT", frame, "BOTTOM", -BUTTON_GAP / 2, BUTTON_BOTTOM_OFFSET)
    reloadButton:SetText(L.RELOAD_NOW)
    reloadButton:SetScript("OnClick", function()
        ReloadUI()
    end)

    local laterButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    laterButton:SetSize(BUTTON_WIDTH, BUTTON_HEIGHT)
    laterButton:SetPoint("BOTTOMLEFT", frame, "BOTTOM", BUTTON_GAP / 2, BUTTON_BOTTOM_OFFSET)
    laterButton:SetText(L.RELOAD_LATER)
    laterButton:SetScript("OnClick", function()
        frame:Hide()
    end)

    tinsert(UISpecialFrames, FRAME_NAME)
end

function reloadPrompt.Show()
    if not frame then
        build()
    end
    frame:Show()
end
