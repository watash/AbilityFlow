local addonName, ns = ...

local ipairs = ipairs
local math = math
local C_Texture = C_Texture

local statusMark = ns.statusMark
local MODE_PAUSED, MODE_QUEUED = statusMark.MODE_PAUSED, statusMark.MODE_QUEUED
local TEXT_BLOCKED, TEXT_CAPTION = statusMark.TEXT_BLOCKED, statusMark.TEXT_CAPTION
local COLOR_FIELD_SUFFIX = statusMark.COLOR_FIELD_SUFFIX
local STATUS_TEXTS, STATUS_TEXTS_BARE = statusMark.TEXTS, statusMark.TEXTS_BARE
local unbracketed = statusMark.Unbracketed
local eventStyle = ns.eventStyle

local OVERLAY_ATLASES = {
    [MODE_PAUSED] = "combattimeline-fx-pause",
    [MODE_QUEUED] = "combattimeline-fx-queued",
}

local TINT_FACTORS = {
    [MODE_PAUSED] = { 0.2, 0.2, 0.21, lift = 0.52 },
    [MODE_QUEUED] = { 0.6, 0.35, 0.6, lift = 0.3 },
}

function statusMark.IsFramed(event)
    return event.statusMark ~= nil and event.statusMark.mode ~= nil
end

function statusMark.HasSign(event)
    return event.statusMark ~= nil and event.statusMark.signMode ~= nil
end

function statusMark.IsOn(event)
    return statusMark.IsFramed(event) or statusMark.HasSign(event)
end

function statusMark.Set(event, mode, blocked, caption)
    blocked = blocked == true
    if type(caption) == "function" then
        caption = caption()
    end
    caption = type(caption) == "string" and caption ~= "" and caption or nil
    local mark = event.statusMark
    if not mark then
        if not mode and not blocked and not caption then
            return
        end
        mark = statusMark.build(event)
        event.statusMark = mark
    end
    local textKey
    if mode == MODE_PAUSED then
        textKey = MODE_PAUSED
    elseif blocked then
        textKey = TEXT_BLOCKED
    else
        textKey = mode
    end
    if caption and textKey == MODE_QUEUED then
        textKey = nil
    end
    local visual = ns.appearance.Get("states", "marks") and mode or nil
    if visual and not C_Texture.GetAtlasInfo(OVERLAY_ATLASES[visual]) then
        visual = nil
    end
    local signMode = ns.appearance.Get("states", "signs") and mode or nil
    local tint = visual and ns.appearance.Get("states", "tintedFrame")
        and ns.appearance.Get("states", visual .. COLOR_FIELD_SUFFIX) or nil
    local shownKey = ns.appearance.Get("states", "captions") and textKey or nil
    local color = shownKey and ns.appearance.Get("states", shownKey .. COLOR_FIELD_SUFFIX) or nil
    if not textKey and caption and ns.appearance.Get("states", "captions") then
        shownKey, color = TEXT_CAPTION, ns.options.Get("captionColor")
    end
    local brackets = ns.appearance.Get("states", "brackets") ~= false
    if mark.mode == visual and mark.signMode == signMode and mark.tint == tint and mark.textKey == shownKey
        and mark.color == color and mark.caption == caption and mark.brackets == brackets then
        return
    end
    mark.brackets = brackets
    local frameChanged = mark.mode ~= visual
    local signChanged = mark.signMode ~= signMode
    local tintChanged = mark.tint ~= tint
    mark.tint = tint
    mark.mode, mark.signMode, mark.textKey, mark.color, mark.caption = visual, signMode, shownKey, color, caption
    mark.status:SetShown(shownKey ~= nil)
    if shownKey then
        if shownKey == TEXT_CAPTION then
            mark.status:SetText(brackets and caption or unbracketed(caption))
        else
            mark.status:SetText((brackets and STATUS_TEXTS or STATUS_TEXTS_BARE)[shownKey])
        end
        mark.status:SetTextColor(color.r, color.g, color.b)
    end
    if signChanged then
        statusMark.hideSigns(mark)
    end
    if frameChanged then
        statusMark.swapOutline(event, visual ~= nil)
        if visual then
            mark.overlay:SetAtlas(OVERLAY_ATLASES[visual])
        end
    end
    if frameChanged or tintChanged then
        mark.overlay:SetDesaturated(tint ~= nil)
        if tint then
            local factors = TINT_FACTORS[visual]
            local red = math.min(tint.r * factors[1] + factors.lift, 1)
            local green = math.min(tint.g * factors[2] + factors.lift, 1)
            local blue = math.min(tint.b * factors[3] + factors.lift, 1)
            mark.overlay:SetVertexColor(red, green, blue)
            mark.boost:SetAtlas(OVERLAY_ATLASES[visual])
            mark.boost:SetDesaturated(true)
            mark.boost:SetVertexColor(red, green, blue)
        else
            mark.overlay:SetVertexColor(1, 1, 1)
        end
    end
    statusMark.Layout(event)
    if signChanged then
        if signMode == MODE_QUEUED then
            mark.holder:Show()
            for _, group in ipairs(mark.groups) do
                group:Play()
            end
        elseif signMode == MODE_PAUSED then
            mark.pauseSign:Show()
            mark.pauseGroup:Play()
        end
    end
end

function statusMark.Clear(event)
    local mark = event.statusMark
    if not mark or not (mark.mode or mark.signMode or mark.textKey) then
        return
    end
    mark.mode, mark.signMode, mark.tint, mark.textKey, mark.color, mark.caption = nil, nil, nil, nil, nil, nil
    mark.overlay:SetDesaturated(false)
    mark.overlay:SetVertexColor(1, 1, 1)
    mark.boost:Hide()
    statusMark.hideSigns(mark)
    statusMark.swapOutline(event, false)
    mark.overlay:Hide()
    if event.stateRing then
        ns.eventFrame.PaintRing(event.stateRing, nil)
        event.stateTint:Hide()
    end
    mark.status:Hide()
    event.nameLift = nil
    eventStyle.PlaceName(event)
end
