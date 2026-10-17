local addonName, ns = ...

local UIParent = UIParent
local GameTooltip = GameTooltip
local L = ns.L
local BIGGER_COLOR = GREEN_FONT_COLOR
local SMALLER_COLOR = RED_FONT_COLOR
local timerStyle = ns.timerStyle
local previewEvent = ns.timerTab.event
local pins = ns.timerTab.pins
local state = pins.state

function pins.ActionLine(action, effect, other)
    local text = NORMAL_FONT_COLOR:WrapTextInColorCode(action)
    if other then
        text = text .. " " .. L.TIMER_ACTION_OR .. " " .. NORMAL_FONT_COLOR:WrapTextInColorCode(other)
    end
    return text .. NORMAL_FONT_COLOR:WrapTextInColorCode(":") .. " " .. effect
end

local NOTE_TIP_PAD = 2

function pins.fitNoteTip(sample)
    local tip = sample.tipArea
    if not tip then
        return
    end
    local target = sample.texts.name
    local extra = sample.arrowExtra or 0
    if sample.noteKind == "background" and sample.swatch then
        target = sample.swatch
        extra = 0
    end
    tip:ClearAllPoints()
    tip:SetPoint("TOPLEFT", target, "TOPLEFT", -NOTE_TIP_PAD, NOTE_TIP_PAD)
    tip:SetPoint("BOTTOMRIGHT", target, "BOTTOMRIGHT", NOTE_TIP_PAD + extra, -NOTE_TIP_PAD)
    tip:SetShown(sample.noteKind ~= nil)
end

local function showNoteTip(sample, anchor)
    if state.dragging or not sample.noteKind then
        return
    end
    local percent = sample.noteText
    if sample.noteKind == "bigger" then
        percent = BIGGER_COLOR:WrapTextInColorCode(percent)
    elseif sample.noteKind == "smaller" then
        percent = SMALLER_COLOR:WrapTextInColorCode(percent)
    end
    GameTooltip:SetOwner(anchor, "ANCHOR_RIGHT")
    GameTooltip:AddLine(L["TIMER_PIN_NAME_" .. sample.noteKind:upper()]:format(percent), 1, 1, 1, true)
    GameTooltip:Show()
end

function pins.dim(pin, full)
    local event = pin.event
    previewEvent.SetDesaturated(event, not full)
    previewEvent.SetNameDesaturated(pin.nameSample, not full)
    if not full then
        previewEvent.GreyCountdown(event)
        previewEvent.GreyGlow(event, timerStyle.Template(pin.templateID))
    end
end

function pins.paint(pin, look)
    local context = state.context
    local event = pin.event
    local template = timerStyle.Template(pin.templateID)
    look = look or previewEvent.CurrentLook()
    previewEvent.Apply(event, previewEvent.FitScale(look, context.footprint, context.scale) * pins.SCALE_RATIO, false, look)
    previewEvent.Paint(event, template, look)
    event.texts.cooldown:SetText(previewEvent.SampleText(template,
        pin.index and pins.secondAt(pin.index) or timerStyle.DisplayNumber(pin.templateID) or pin.templateID))
    previewEvent.SetIcon(event, pin.templateID)
    local sample = pin.nameSample
    local change, kind = pins.sampleText(pin)
    pin.showName = change ~= nil
    pins.placeName(sample, event)
    pins.paintNameFitted(sample, event, template, change, kind)
    pins.dim(pin, not pin.desaturated)
    sample:SetShown(event:IsShown() and pin.showName)
    local margin = previewEvent.BorderMargin(look)
    event:SetHitRectInsets(-margin, -margin, -margin, -margin)
end

function pins.setLevel(pin, level)
    previewEvent.SetLevel(pin.event, level)
    previewEvent.SetNameLevel(pin.nameSample, level + pins.SAMPLE_LEVEL_OVER)
end

function pins.setFullColor(pin, full)
    if pin.desaturated == not full then
        return
    end
    pin.desaturated = not full
    pins.dim(pin, full)
    if full then
        local template = timerStyle.Template(pin.templateID)
        previewEvent.Paint(pin.event, template, previewEvent.CurrentLook())
        pins.paintNameFitted(pin.nameSample, pin.event, template, pins.sampleText(pin))
    end
end

function pins.retire(pin, keepData)
    if pin.retired then
        return
    end
    pin.retired = true
    pin.event:SetScript("OnUpdate", nil)
    pin.event:Hide()
    ns.timerPaint.Stop(pin.event)
    local index = pin.index
    if index and state.placed[index] == pin then
        state.placed[index] = nil
    end
    pin.index = nil
    if index then
        pins.paintLabel(index)
        if not keepData then
            pins.saveLabel(index)
        end
    end
    table.insert(state.pool, pin)
end

function pins.acquire(templateID)
    local pin = table.remove(state.pool)
    if not pin then
        local event = previewEvent.Create(UIParent, previewEvent.TEMPLATE_FILE_ID)
        previewEvent.SetStrata(event, pins.STRATA)
        local sample = previewEvent.CreateNameSample(UIParent, pins.STRATA)
        sample:Hide()
        local tip = CreateFrame("Frame", nil, sample)
        tip:EnableMouse(true)
        tip:SetScript("OnEnter", function(self)
            showNoteTip(sample, self)
        end)
        tip:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
        sample.tipArea = tip
        event:HookScript("OnShow", function() sample:SetShown(pin.showName ~= false) end)
        event:HookScript("OnHide", function() sample:Hide() end)
        pin = { event = event, baseLevel = event:GetFrameLevel(), nameSample = sample }
        previewEvent.SetNameLevel(sample, pin.baseLevel + pins.SAMPLE_LEVEL_OVER)
        event:EnableMouse(true)
        event:RegisterForDrag("LeftButton")
        event:SetScript("OnEnter", function(self)
            if pin.index and not state.dragging then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:AddLine(pins.ActionLine(L.TIMER_ACTION_DRAG, L.TIMER_PIN_DO_MOVE), 1, 1, 1, true)
                GameTooltip:AddLine(pins.ActionLine(L.TIMER_ACTION_RIGHT_CLICK, L.TIMER_PIN_DO_REMOVE, L.TIMER_ACTION_DRAG_OFF), 1, 1, 1, true)
                GameTooltip:AddLine(pins.ActionLine(L.TIMER_ACTION_CLICK, L.TIMER_PIN_DO_SELECT), 1, 1, 1, true)
                GameTooltip:Show()
            end
        end)
        event:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
        event:SetScript("OnDragStart", function()
            GameTooltip:Hide()
            pins.onDragStart(pin)
        end)
        event:SetScript("OnDragStop", function()
            pins.EndDrag()
        end)
        event:SetScript("OnMouseUp", function(_, button)
            if button == "RightButton" then
                GameTooltip:Hide()
                pins.retire(pin)
                state.context.changed()
            elseif button == "LeftButton" and not pin.wasDragged and pin.index then
                ns.timerTab.templates.Select(pin.templateID)
            end
            pin.wasDragged = false
        end)
    end
    pin.templateID = templateID
    pin.retired = false
    pin.index = nil
    pin.desaturated = false
    return pin
end
