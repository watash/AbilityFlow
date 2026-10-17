local addonName, ns = ...

local CreateFrame = CreateFrame
local UIParent = UIParent
local C_EncounterTimeline = C_EncounterTimeline
local C_Timer = C_Timer
local tinsert = tinsert
local L = ns.L

local FRAME_NAME = "AbilityFlowNoticeFrame"
local CHECK_DELAY_SECONDS = 3

local FRAME_WIDTH = 420
local BODY_SIDE_PADDING = 30
local TITLE_TOP_OFFSET = 20
local BODY_TOP_GAP = 12
local BUTTON_WIDTH = 120
local BUTTON_HEIGHT = 24
local BUTTON_BOTTOM_OFFSET = 18
local BUTTON_TOP_GAP = 16
local BACKDROP_TILE_SIZE = 32
local BACKDROP_EDGE_SIZE = 32
local BACKDROP_INSETS = { left = 11, right = 12, top = 12, bottom = 11 }

local frame = CreateFrame("Frame", FRAME_NAME, UIParent, "BackdropTemplate")
frame:SetWidth(FRAME_WIDTH)
frame:SetPoint("CENTER")
frame:SetFrameStrata("DIALOG")
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
title:SetWidth(FRAME_WIDTH - 2 * BODY_SIDE_PADDING)
title:SetJustifyH("CENTER")
title:SetText(L.NOTICE_TITLE:format(addonName))

local body = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
body:SetPoint("TOP", title, "BOTTOM", 0, -BODY_TOP_GAP)
body:SetWidth(FRAME_WIDTH - 2 * BODY_SIDE_PADDING)
body:SetJustifyH("CENTER")
body:SetText(L.NOTICE_BODY:format(addonName, ns.text.Gold(L.NOTICE_PATH)))
frame:SetHeight(TITLE_TOP_OFFSET + title:GetStringHeight() + BODY_TOP_GAP + body:GetStringHeight() + BUTTON_TOP_GAP + BUTTON_HEIGHT
    + BUTTON_BOTTOM_OFFSET)

local okButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
okButton:SetSize(BUTTON_WIDTH, BUTTON_HEIGHT)
okButton:SetPoint("BOTTOM", frame, "BOTTOM", 0, BUTTON_BOTTOM_OFFSET)
okButton:SetText(L.NOTICE_OK)
okButton:SetScript("OnClick", function()
    frame:Hide()
end)

tinsert(UISpecialFrames, FRAME_NAME)

local loginFrame = CreateFrame("Frame")
loginFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
loginFrame:SetScript("OnEvent", function(self)
    self:UnregisterEvent("PLAYER_ENTERING_WORLD")
    C_Timer.After(CHECK_DELAY_SECONDS, function()
        if C_EncounterTimeline.IsFeatureAvailable() and not C_EncounterTimeline.IsFeatureEnabled() then
            frame:Show()
        end
    end)
end)
