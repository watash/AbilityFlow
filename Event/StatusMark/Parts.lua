local addonName, ns = ...

local ipairs = ipairs
local CreateFrame = CreateFrame

local statusMark = ns.statusMark
local COLOR_FIELD_SUFFIX = statusMark.COLOR_FIELD_SUFFIX
local eventStyle = ns.eventStyle

local TINT_BOOST_ALPHA = 0.5
local DOT_ATLAS = "combattimeline-fx-queued-icon"
local PAUSE_SIGN_ATLAS = "combattimeline-fx-pause-icon"
local DOT_COUNT = 3
local ICON_REFERENCE_SIZE = 35
local OVERLAY_SIDE = 7 / ICON_REFERENCE_SIZE
local OVERLAY_TOP = 6 / ICON_REFERENCE_SIZE
local DOT_SIZE = 10 / ICON_REFERENCE_SIZE
local DOT_LIFT = 4 / ICON_REFERENCE_SIZE
local DOT_JUMP = 10 / ICON_REFERENCE_SIZE
local PAUSE_SIGN_SIZE = 16 / ICON_REFERENCE_SIZE
local PAUSE_SIGN_INSET = 4 / ICON_REFERENCE_SIZE
local OVERLAY_SUBLEVEL = 3
local FLAT_TINT_ALPHA = 0.12
local RISE_SECONDS = 0.2
local FALL_SECONDS = 0.3
local STEP_SECONDS = 0.2
local PAUSE_SIGN_GROWTH = 1.1
local PAUSE_SIGN_HALF_SECONDS = 0.25
local STATUS_GAP = 2
local STATUS_LINE_RATIO = 1.2

function statusMark.build(event)
    local mark = { dots = {}, groups = {}, rises = {}, falls = {} }
    mark.overlay = event.container:CreateTexture(nil, "OVERLAY", nil, OVERLAY_SUBLEVEL)
    mark.overlay:SetSnapToPixelGrid(false)
    mark.overlay:SetTexelSnappingBias(0)
    mark.overlay:Hide()
    mark.boost = event.container:CreateTexture(nil, "OVERLAY", nil, OVERLAY_SUBLEVEL)
    mark.boost:SetSnapToPixelGrid(false)
    mark.boost:SetTexelSnappingBias(0)
    mark.boost:SetBlendMode("ADD")
    mark.boost:SetAlpha(TINT_BOOST_ALPHA)
    mark.boost:Hide()

    mark.status = event.nameHolder:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    mark.status:Hide()

    mark.holder = CreateFrame("Frame", nil, event.signHolder)
    mark.holder:Hide()
    for index = 1, DOT_COUNT do
        local dot = mark.holder:CreateTexture(nil, "OVERLAY")
        dot:SetAtlas(DOT_ATLAS)
        dot:SetSnapToPixelGrid(false)
        dot:SetTexelSnappingBias(0)
        mark.dots[index] = dot

        local group = dot:CreateAnimationGroup()
        local rise = group:CreateAnimation("Translation")
        rise:SetSmoothing("OUT")
        rise:SetDuration(RISE_SECONDS)
        rise:SetStartDelay((index - 1) * STEP_SECONDS)
        rise:SetOrder(1)
        local fall = group:CreateAnimation("Translation")
        fall:SetSmoothing("OUT")
        fall:SetDuration(FALL_SECONDS)
        fall:SetStartDelay((index - 1) * STEP_SECONDS + RISE_SECONDS)
        fall:SetOrder(1)
        mark.groups[index], mark.rises[index], mark.falls[index] = group, rise, fall
    end

    mark.pauseSign = event.signHolder:CreateTexture(nil, "OVERLAY")
    mark.pauseSign:SetAtlas(PAUSE_SIGN_ATLAS)
    mark.pauseSign:SetSnapToPixelGrid(false)
    mark.pauseSign:SetTexelSnappingBias(0)
    mark.pauseSign:Hide()
    mark.pauseGroup = mark.pauseSign:CreateAnimationGroup()
    local grow = mark.pauseGroup:CreateAnimation("Scale")
    grow:SetSmoothing("IN_OUT")
    grow:SetDuration(PAUSE_SIGN_HALF_SECONDS)
    grow:SetScaleFrom(1, 1)
    grow:SetScaleTo(PAUSE_SIGN_GROWTH, PAUSE_SIGN_GROWTH)
    grow:SetOrder(1)
    local shrink = mark.pauseGroup:CreateAnimation("Scale")
    shrink:SetSmoothing("IN_OUT")
    shrink:SetDuration(PAUSE_SIGN_HALF_SECONDS)
    shrink:SetScaleFrom(1, 1)
    shrink:SetScaleTo(1 / PAUSE_SIGN_GROWTH, 1 / PAUSE_SIGN_GROWTH)
    shrink:SetOrder(2)
    return mark
end

local function showFrame(event, mark)
    local framed = mark.mode ~= nil
    local flat = event.flatBorder == true
    mark.overlay:SetShown(framed and not flat)
    mark.boost:SetShown(framed and not flat and mark.tint ~= nil)
    local ring, tintOver = event.stateRing, event.stateTint
    if not ring then
        return
    end
    local color = framed and flat and ns.appearance.Get("states", mark.mode .. COLOR_FIELD_SUFFIX) or nil
    tintOver:SetShown(color ~= nil)
    if color then
        tintOver:SetColorTexture(color.r, color.g, color.b, FLAT_TINT_ALPHA)
    end
    ns.eventFrame.PaintRing(ring, color and (event.flatReach or 0) > 0 and { r = color.r, g = color.g, b = color.b, a = 1 } or nil)
end

function statusMark.Layout(event)
    local mark = event.statusMark
    if not mark then
        return
    end
    local width = event:GetWidth()
    mark.overlay:ClearAllPoints()
    mark.overlay:SetPoint("TOPLEFT", event.container, "TOPLEFT", -width * OVERLAY_SIDE, width * OVERLAY_TOP)
    mark.overlay:SetPoint("BOTTOMRIGHT", event.container, "BOTTOMRIGHT", width * OVERLAY_SIDE, -width * OVERLAY_SIDE)
    mark.boost:ClearAllPoints()
    mark.boost:SetAllPoints(mark.overlay)
    local name = event.texts.name
    local path, size, flags = name:GetFont()
    if path then
        mark.status:SetFont(path, size, flags)
    end
    mark.status:ClearAllPoints()
    if eventStyle.NameSideOf(event) == "LEFT" then
        mark.status:SetPoint("TOPRIGHT", name, "BOTTOMRIGHT", 0, -STATUS_GAP)
        mark.status:SetJustifyH("RIGHT")
    else
        mark.status:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -STATUS_GAP)
        mark.status:SetJustifyH("LEFT")
    end
    event.nameLift = mark.textKey and size and (size * STATUS_LINE_RATIO + STATUS_GAP) / 2 or nil
    eventStyle.PlaceName(event)
    local dotSize = width * DOT_SIZE
    mark.holder:SetSize(dotSize * DOT_COUNT, dotSize)
    mark.holder:ClearAllPoints()
    mark.holder:SetPoint("BOTTOM", event.texture, "BOTTOM", 0, width * DOT_LIFT)
    for index, dot in ipairs(mark.dots) do
        dot:SetSize(dotSize, dotSize)
        dot:ClearAllPoints()
        dot:SetPoint("LEFT", mark.holder, "LEFT", (index - 1) * dotSize, 0)
        mark.rises[index]:SetOffset(0, width * DOT_JUMP)
        mark.falls[index]:SetOffset(0, -width * DOT_JUMP)
    end
    mark.pauseSign:SetSize(width * PAUSE_SIGN_SIZE, width * PAUSE_SIGN_SIZE)
    mark.pauseSign:ClearAllPoints()
    mark.pauseSign:SetPoint("BOTTOMRIGHT", event.texture, "BOTTOMRIGHT", -width * PAUSE_SIGN_INSET, width * PAUSE_SIGN_INSET)
    showFrame(event, mark)
end

function statusMark.swapOutline(event, on)
    local mark = event.statusMark
    if event.debuffBorders then
        for _, fills in ipairs(event.debuffBorders) do
            for _, fill in ipairs(fills) do
                fill:SetShown(not on and event.debuffBorderShown == true and not event.typeFillsHidden)
            end
        end
    end
    if event.ownFrame then
        event.ownFrame:SetShown(not on and event.ownFrameShown == true)
    end
    if on then
        if not mark.outlinesHidden then
            mark.outlinesHidden = event.outlines ~= nil and event.outlines[1]:IsShown()
        end
        if mark.outlinesHidden then
            for _, outline in ipairs(event.outlines) do
                outline:Hide()
            end
        end
    elseif mark.outlinesHidden then
        mark.outlinesHidden = false
        ns.eventStyle.ApplyBorder(event)
    end
end

function statusMark.hideSigns(mark)
    for _, group in ipairs(mark.groups) do
        group:Stop()
    end
    mark.pauseGroup:Stop()
    mark.holder:Hide()
    mark.pauseSign:Hide()
end
