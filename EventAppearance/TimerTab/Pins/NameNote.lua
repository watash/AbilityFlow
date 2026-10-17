local addonName, ns = ...

local math = math
local timerStyle = ns.timerStyle
local appearance = ns.appearance
local previewEvent = ns.timerTab.event
local pins = ns.timerTab.pins
local state = pins.state

pins.NAME_SIZE_FORMAT = "%d%%"
local ARROW_SIZE_SHARE = previewEvent.NOTE_ARROW_SHARE
local NOTE_NAME_PERCENT = previewEvent.NOTE_NAME_PERCENT
local NOTE_COLOR = { r = 1, g = 1, b = 1 }
local NOTE_ARROWS = {
    bigger = { up = true, r = GREEN_FONT_COLOR.r, g = GREEN_FONT_COLOR.g, b = GREEN_FONT_COLOR.b },
    smaller = { up = false, r = RED_FONT_COLOR.r, g = RED_FONT_COLOR.g, b = RED_FONT_COLOR.b },
}

local function nameBackgroundOf(template)
    local mode = template and template.nameBackground
    local shown
    if mode == timerStyle.BACKGROUND_SHOW then
        shown = true
    elseif mode == timerStyle.BACKGROUND_HIDE then
        shown = false
    else
        shown = appearance.Get("nameBackground", "enabled")
    end
    if not shown then
        return false, nil
    end
    local own = template and template.nameBackgroundUseColor and template.nameBackgroundColor
    return true, own or appearance.Get("nameBackground", "color")
end

function pins.placeName(sample, event)
    previewEvent.SetNameSide(sample, false)
    sample:ClearAllPoints()
    local sampleScale = sample:GetScale()
    local height = sample.texts.name:GetStringHeight() * sampleScale
    local drop = math.max(pins.iconHeightOverLine() - pins.NAME_LINE_MARGIN - height,
        pins.NAME_BORDER_GAP + (event.flatReach or 0) * event:GetScale())
    sample:SetPoint("TOP", event, "BOTTOM", 0, -drop / sampleScale)
end

function pins.paintNameFitted(sample, event, template, text, kind)
    local iconWidth = previewEvent.PinTextWidth()
    local note = text and NOTE_ARROWS[kind] or nil
    sample.noteKind = text and kind or nil
    sample.noteText = text
    local baseSize = appearance.Get("name", "size")
    local arrowSide = baseSize * ARROW_SIZE_SHARE * previewEvent.PinTextScale()
    if text then
        local scale = previewEvent.PinTextScale()
        sample:SetScale(scale)
        local arrow = note and { up = note.up, r = note.r, g = note.g, b = note.b, side = arrowSide / scale }
        previewEvent.PaintName(sample, template, text, NOTE_COLOR, arrow, NOTE_NAME_PERCENT)
        pins.placeName(sample, event)
        if kind == "background" then
            local shown, used = nameBackgroundOf(template)
            previewEvent.PaintSwatch(sample, baseSize * previewEvent.PinTextScale() / scale, shown and used or nil)
        end
        pins.fitNoteTip(sample)
        return
    end
    sample:SetScale(previewEvent.PinTextScale())
    previewEvent.PaintName(sample, template, text)
    local fit = iconWidth / previewEvent.NameSampleWidth(sample)
    if fit < sample:GetScale() then
        sample:SetScale(fit)
        previewEvent.PaintName(sample, template, text)
    end
    pins.placeName(sample, event)
    pins.fitNoteTip(sample)
end

local function nameLook(template)
    local shown, used = nameBackgroundOf(template)
    local color = ""
    if shown then
        color = ("%.2f,%.2f,%.2f,%.2f"):format(used.r, used.g, used.b, used.a or 1)
    end
    return table.concat({ timerStyle.NameScaleOf(template), tostring(shown), color }, "|")
end

local function changeKind(template, before)
    if nameLook(template) == nameLook(before) then
        return nil
    end
    local scale, was = timerStyle.NameScaleOf(template), timerStyle.NameScaleOf(before)
    local kind = "background"
    if scale > was then
        kind = "bigger"
    elseif scale < was then
        kind = "smaller"
    end
    return kind, scale
end

local function arrangedAt(index)
    local placed = state.placed[index]
    local dragging = state.dragging
    if not dragging or state.releasing then
        return placed
    end
    local snapped = state.snapped
    if index == snapped then
        return dragging
    end
    if index == state.liftedFrom then
        local occupant = snapped and state.placed[snapped]
        if occupant and occupant ~= dragging then
            return occupant
        end
        return nil
    end
    if placed == dragging then
        return nil
    end
    return placed
end

local function arrangedIndexOf(pin)
    if not state.dragging or state.releasing then
        return pin.index
    end
    local snapped = state.snapped
    if snapped and state.placed[snapped] == pin then
        return state.liftedFrom
    end
    return pin.index
end

local function templateBefore(at)
    for index = at - 1, 1, -1 do
        local other = arrangedAt(index)
        if other then
            return timerStyle.Template(other.templateID)
        end
    end
    return nil
end

function pins.nameChangeAt(templateID, at)
    local kind, scale = changeKind(timerStyle.Template(templateID), templateBefore(at))
    if kind then
        return pins.NAME_SIZE_FORMAT:format(scale), kind
    end
    return nil
end

function pins.sampleText(pin)
    if pin == state.dragging then
        return nil
    end
    local at = pin.index and arrangedIndexOf(pin)
    if at then
        return pins.nameChangeAt(pin.templateID, at)
    end
    return nil
end

function pins.refreshNotes()
    for _, pin in pairs(state.placed) do
        if pin ~= state.dragging then
            local change, kind = pins.sampleText(pin)
            pin.showName = change ~= nil
            pins.paintNameFitted(pin.nameSample, pin.event, timerStyle.Template(pin.templateID), change, kind)
            previewEvent.SetNameDesaturated(pin.nameSample, pin.desaturated)
            pin.nameSample:SetShown(pin.event:IsShown() and pin.showName)
        end
    end
end
