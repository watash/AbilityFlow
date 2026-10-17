local addonName, ns = ...

local C_AddOns = C_AddOns
local CreateFrame = CreateFrame
local HideUIPanel = HideUIPanel
local Settings = Settings

local L = ns.L





local LEFT = 16
local TOP = 16
local LINE_GAP = 10
local BUTTON_GAP = 16
local DIVIDER_HEIGHT = 16

local DIVIDER_TEXTURE = [[Interface\FriendsFrame\UI-FriendsFrame-OnlineDivider]]

local BUTTON_PADDING = 40

local function build()
    local page = CreateFrame("Frame")
    local title = page:CreateFontString(nil, "ARTWORK", "GameFontHighlightHuge")
    title:SetPoint("TOPLEFT", page, "TOPLEFT", LEFT, -TOP)
    title:SetText(addonName)

    local version = page:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    version:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -LINE_GAP)
    version:SetText(L.GAME_SETTINGS_VERSION:format(C_AddOns.GetAddOnMetadata(addonName, "Version") or ""))

    local divider = page:CreateTexture(nil, "ARTWORK")
    divider:SetTexture(DIVIDER_TEXTURE)
    divider:SetHeight(DIVIDER_HEIGHT)
    divider:SetPoint("TOPLEFT", version, "BOTTOMLEFT", 0, -LINE_GAP)
    divider:SetPoint("RIGHT", page, "RIGHT", -LEFT, 0)

    local hint = page:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    hint:SetPoint("TOPLEFT", divider, "BOTTOMLEFT", 0, -LINE_GAP)
    hint:SetPoint("RIGHT", page, "RIGHT", -LEFT, 0)
    hint:SetJustifyH("LEFT")
    hint:SetWordWrap(true)

    local text = ns.text
    hint:SetText(text.Quoted(L.GAME_SETTINGS_HINT, text.WHITE, text.GOLD))


    local commands = page:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    commands:SetPoint("TOPLEFT", hint, "BOTTOMLEFT", 0, -LINE_GAP)
    commands:SetJustifyH("LEFT")
    commands:SetText(L.GAME_SETTINGS_COMMANDS:format(text.Gold(_G.SLASH_ABILITYFLOW2), text.Gold(_G.SLASH_ABILITYFLOW1)))

    local button = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
    button:SetText(L.GAME_SETTINGS_OPEN)
    button:SetWidth(button:GetFontString():GetStringWidth() + BUTTON_PADDING)
    button:SetPoint("TOPLEFT", commands, "BOTTOMLEFT", 0, -BUTTON_GAP)
    button:SetScript("OnClick", function()

        if SettingsPanel and SettingsPanel:IsShown() then
            HideUIPanel(SettingsPanel)
        end
        if not ns.eventAppearance.IsShown() then
            ns.eventAppearance.Toggle()
        end
    end)

    local category = Settings.RegisterCanvasLayoutCategory(page, addonName)
    Settings.RegisterAddOnCategory(category)
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", function(self)
    self:UnregisterAllEvents()
    build()
end)
