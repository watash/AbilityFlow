local addonName, ns = ...

local CreateFrame = CreateFrame
local CreateFont = CreateFont
local pcall = pcall
local ipairs = ipairs
local table = table

local L = ns.L
local controls = ns.appearanceControls
local LABEL_GAP = controls.LABEL_GAP
local FIRST_ROW_OFFSET = controls.FIRST_ROW_OFFSET
local INLINE_LABEL_WIDTH = controls.INLINE_LABEL_WIDTH
local INLINE_GAP = controls.INLINE_GAP
local INLINE_DROPDOWN_WIDTH = controls.INLINE_DROPDOWN_WIDTH
local resolve = controls.Resolve

function controls.PointOptions(points)
    local options = {}
    for _, point in ipairs(points) do
        table.insert(options, { text = L["EVENT_APPEARANCE_POINT_" .. point], value = point })
    end
    return options
end

local menuFonts = {}
local menuFontCount = 0

local function menuFont(path, fontString)
    local font = menuFonts[path]
    if font == nil then
        local _, size, flags = fontString:GetFont()
        menuFontCount = menuFontCount + 1
        font = CreateFont(addonName .. "MenuFont" .. menuFontCount)
        local ok = pcall(font.SetFont, font, path, size, flags)
        menuFonts[path] = (ok and font:GetFont() ~= nil) and font or false
        font = menuFonts[path]
    end
    return font or nil
end

local function makeDropdown(parent, items, value, onSelected, width)
    local dropdown = CreateFrame("DropdownButton", nil, parent, "WowStyle1DropdownTemplate")
    dropdown:SetWidth(width)

    local ownFont = dropdown.Text and dropdown.Text:GetFontObject()
    local function showChoiceFont()
        if not dropdown.Text then
            return
        end
        local fontObject
        for _, item in ipairs(items) do
            if item.fontPath and item.value == value then
                fontObject = menuFont(item.fontPath, dropdown.Text)
            end
        end
        dropdown.Text:SetFontObject(fontObject or ownFont)
    end

    dropdown:SetupMenu(function(_, rootDescription)
        for _, item in ipairs(items) do
            local radio = rootDescription:CreateRadio(item.text, function(choice)
                return value == choice
            end, function(choice)
                value = choice
                showChoiceFont()
                onSelected(choice)
            end, item.value)
            if item.fontPath then
                radio:AddInitializer(function(button)
                    local fontObject = menuFont(item.fontPath, button.fontString)
                    if fontObject then
                        button.fontString:SetFontObject(fontObject)
                    end
                end)
            end
        end
        rootDescription:SetScrollMode(ns.media.MENU_MAX_HEIGHT)
    end)
    showChoiceFont()

    function dropdown.SetChoice(newValue)
        value = newValue
        showChoiceFont()
        dropdown:GenerateMenu()
    end

    return dropdown
end

function controls.InlineDropdown(parent, anchorTo, labelText, items, value, onSelected, extraWidth, labelWidth)
    local getter
    getter, value = resolve(value)
    labelWidth = labelWidth or INLINE_LABEL_WIDTH
    local dropdownWidth = INLINE_DROPDOWN_WIDTH + (extraWidth or 0)
    local row = CreateFrame("Frame", nil, parent)
    if anchorTo == parent then
        row:SetPoint("TOPLEFT", parent, "TOPLEFT", LABEL_GAP, -FIRST_ROW_OFFSET)
    else
        row:SetPoint("TOPLEFT", anchorTo, "BOTTOMLEFT", 0, -LABEL_GAP)
    end

    local label = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("LEFT", row, "LEFT", 0, 0)
    label:SetWidth(labelWidth)
    label:SetJustifyH("LEFT")
    label:SetText(labelText)

    local dropdown = makeDropdown(row, items, value, onSelected, dropdownWidth)
    dropdown:SetPoint("LEFT", label, "RIGHT", INLINE_GAP, 0)
    row:SetSize(labelWidth + INLINE_GAP + dropdownWidth, dropdown:GetHeight())
    row.dropdown = dropdown
    if getter then
        row.Resync = function()
            dropdown.SetChoice(getter())
        end
    end
    return row
end
