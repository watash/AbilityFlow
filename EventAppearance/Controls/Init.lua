local addonName, ns = ...

local type = type
local ipairs = ipairs
local C_Timer = C_Timer
local InCombatLockdown = InCombatLockdown
local CreateFrame = CreateFrame
local pairs = pairs

local controls = {}
ns.appearanceControls = controls

controls.LABEL_GAP = 14
controls.ROW_INDENT = controls.LABEL_GAP
controls.CHECKBOX_PICTURE_PADDING = 4
controls.FIRST_ROW_OFFSET = 12
controls.CHECKBOX_LABEL_GAP = 4
controls.RESET_BUTTON_HEIGHT = 22
controls.RESET_BUTTON_PADDING = 14
controls.SUBTAB_TEXT_PADDING = 15
controls.SUBTAB_MIN_WIDTH = 70
controls.SUBTAB_SPACING = 5
controls.RESET_BUTTON_RIGHT_MARGIN = 10
controls.RESET_BUTTON_BOTTOM_MARGIN = 8
controls.DISABLED_ALPHA = 0.4
controls.INLINE_LABEL_WIDTH = 90
controls.INLINE_GAP = 8
controls.INLINE_DROPDOWN_WIDTH = 120
controls.INLINE_VALUE_OFFSET = controls.INLINE_LABEL_WIDTH + controls.INLINE_GAP
controls.WIDE_SLIDER_EXTRA = 120
controls.WIDE_LIST_EXTRA = controls.WIDE_SLIDER_EXTRA + 25
controls.VALUE_WIDTH = 40
controls.EDITABLE_SLIDER_WIDTH = 120

function controls.Resolve(value)
    if type(value) == "function" then
        return value, value()
    end
    return nil, value
end

local waitingForKeys = {}
local keyWatcher

local function letKeysGo(frame)
    if InCombatLockdown() then
        waitingForKeys[frame] = true
        if not keyWatcher then
            keyWatcher = CreateFrame("Frame")
            keyWatcher:RegisterEvent("PLAYER_REGEN_ENABLED")
            keyWatcher:SetScript("OnEvent", function()
                for waiting in pairs(waitingForKeys) do
                    waitingForKeys[waiting] = nil
                    waiting:SetPropagateKeyboardInput(true)
                end
            end)
        end
        return
    end
    frame:SetPropagateKeyboardInput(true)
end

function controls.CloseOnEscape(frame)
    frame:EnableKeyboard(true)
    letKeysGo(frame)
    frame:SetScript("OnKeyDown", function(self, key)
        if InCombatLockdown() then
            if key == "ESCAPE" then
                self:Hide()
            end
            return
        end
        if key == "ESCAPE" then
            self:SetPropagateKeyboardInput(false)
            self:Hide()
        else
            self:SetPropagateKeyboardInput(true)
        end
    end)
    frame:HookScript("OnHide", function(self)
        C_Timer.After(0, function()
            if not InCombatLockdown() and not self:IsShown() then
                self:SetPropagateKeyboardInput(true)
            end
        end)
    end)
end

function controls.ResyncAll(frame)
    if frame.Resync then
        frame.Resync()
    end
    for _, child in ipairs({ frame:GetChildren() }) do
        controls.ResyncAll(child)
    end
end
