local addonName, ns = ...

local CreateFrame = CreateFrame
local L = ns.L

ns.timerTab = ns.timerTab or {}

local line = {}
ns.timerTab.line = line

local LINE_TEXTURE = "Interface\\AddOns\\AbilityFlow\\Media\\Textures\\line-fill.png"
local CAP_FAR_ATLAS = "combattimeline-line-left"
local CAP_NEAR_ATLAS = "combattimeline-line-right"
local SNAP_MARK_ATLAS = "GenericWidgetBar-Spark-arrows"
local LABEL_FONT = "SystemFont_Shadow_Med3"
line.THICKNESS = 8
local SPAN_ALPHA = 0.9
local SPAN_THICKNESS = 5
local SPAN_SELECTED_THICKNESS = 7
local SPAN_HIT_MARGIN = 3
local SPAN_LINE_GAP = 3
local SPAN_END_GAP = 2
local SPAN_LABEL_GAP = 7
local SPAN_TAIL = -1
line.LABEL_GAP = SPAN_LINE_GAP + SPAN_THICKNESS + SPAN_LABEL_GAP
line.BACKING_TOP_PADDING = 6
local BACKING_BOTTOM_GAP = 6
local CAPTION_GAP = 4
local CAPTION_HEIGHT = 12
local CAPTION_FONT = "GameFontHighlightSmall"
local CAPTION_COLOR = { 0.8, 0.8, 0.8 }
local LABEL_LIT_COLOR = { 1, 0.82, 0 }
line.SNAPPED_LABEL_SCALE = 1.4
local FILL_COORDS = { 0, 0, 0, 1, 1, 0, 1, 1 }

function line.Create(parent, count)
    local made = { count = count, segments = {}, labels = {} }

    made.backing = CreateFrame("Frame", nil, parent, "InsetFrameTemplate")
    made.backing:SetFrameLevel(parent:GetFrameLevel())

    made.farCap = parent:CreateTexture(nil, "ARTWORK")
    made.farCap:SetAtlas(CAP_FAR_ATLAS, true)
    made.nearCap = parent:CreateTexture(nil, "ARTWORK")
    made.nearCap:SetAtlas(CAP_NEAR_ATLAS, true)
    made.snapMark = parent:CreateTexture(nil, "OVERLAY")
    made.snapMark:SetAtlas(SNAP_MARK_ATLAS, true)
    made.snapMark:Hide()

    for index = 1, count do
        local label = parent:CreateFontString(nil, "OVERLAY", LABEL_FONT)
        label:SetJustifyH("CENTER")
        label:SetText(tostring(count - index + 1))
        label.normalR, label.normalG, label.normalB = label:GetTextColor()
        local _, height = label:GetFont()
        label.normalHeight = height
        made.labels[index] = label
    end
    return made
end

function line.SecondAt(made, index)
    return made.count - index + 1
end

function line.Layout(made, parent, centerY, xOffset, width, lineStart, lineEnd)
    made.centerY, made.xOffset, made.width = centerY, xOffset, width
    lineStart = lineStart or xOffset
    lineEnd = lineEnd or xOffset + width
    made.lineStart, made.lineEnd = lineStart, lineEnd

    made.farCap:ClearAllPoints()
    made.farCap:SetPoint("LEFT", parent, "TOPLEFT", lineStart, -centerY)
    made.nearCap:ClearAllPoints()
    made.nearCap:SetPoint("RIGHT", parent, "TOPLEFT", lineEnd, -centerY)

    local farLength, nearLength = made.farCap:GetWidth(), made.nearCap:GetWidth()
    local fillStart = lineStart + farLength
    local fillLength = math.max(0, lineEnd - lineStart - farLength - nearLength)
    local tileLength = farLength > 0 and farLength or 1
    local tileCount = math.max(1, math.floor(fillLength / tileLength + 0.5))
    local exactLength = fillLength / tileCount
    for index = 1, tileCount do
        local segment = made.segments[index]
        if not segment then
            segment = parent:CreateTexture(nil, "ARTWORK")
            made.segments[index] = segment
        end
        segment:SetTexture(LINE_TEXTURE, "CLAMP", "CLAMP")
        segment:SetTexCoord(unpack(FILL_COORDS))
        segment:SetHeight(line.THICKNESS)
        segment:ClearAllPoints()
        segment:SetPoint("LEFT", parent, "TOPLEFT", fillStart + (index - 1) * exactLength, -centerY)
        segment:SetPoint("RIGHT", parent, "TOPLEFT", fillStart + index * exactLength, -centerY)
        segment:Show()
    end
    for index = tileCount + 1, #made.segments do
        made.segments[index]:Hide()
    end

    local labelY = line.LabelTop(made)
    for index, label in ipairs(made.labels) do
        label:ClearAllPoints()
        label:SetPoint("TOP", parent, "TOPLEFT", line.LabelX(made, index), -labelY)
    end
end

function line.PaintSpans(made, parent, spans, onClick)
    made.spans = made.spans or {}
    made.spanButtons = made.spanButtons or {}
    local top = made.centerY + line.THICKNESS / 2 + SPAN_LINE_GAP
    for index, span in ipairs(spans) do
        local texture = made.spans[index]
        if not texture then
            texture = parent:CreateTexture(nil, "ARTWORK")
            made.spans[index] = texture
            local button = CreateFrame("Button", nil, parent)
            button:RegisterForClicks("LeftButtonUp")
            button:SetScript("OnClick", function()
                if button.templateID then
                    onClick(button.templateID)
                end
            end)
            made.spanButtons[index] = button
        end
        local thickness = span.selected and SPAN_SELECTED_THICKNESS or SPAN_THICKNESS
        local barTop = top - (thickness - SPAN_THICKNESS) / 2
        texture:SetColorTexture(span.color[1], span.color[2], span.color[3], SPAN_ALPHA * (span.fade or 1))
        texture:SetHeight(thickness)
        texture:ClearAllPoints()
        local from = span.from + SPAN_END_GAP
        local to = span.to >= made.lineEnd and made.lineEnd + SPAN_TAIL or span.to - SPAN_END_GAP
        texture:SetPoint("TOPLEFT", parent, "TOPLEFT", from, -barTop)
        texture:SetPoint("TOPRIGHT", parent, "TOPLEFT", to, -barTop)
        texture:Show()

        local button = made.spanButtons[index]
        button.templateID = span.templateID
        button:ClearAllPoints()
        button:SetPoint("TOPLEFT", parent, "TOPLEFT", from, -(barTop - SPAN_HIT_MARGIN))
        button:SetPoint("BOTTOMRIGHT", parent, "TOPLEFT", to, -(barTop + thickness + SPAN_HIT_MARGIN))
        button:SetShown(span.templateID ~= nil)
    end
    for index = #spans + 1, #made.spans do
        made.spans[index]:Hide()
        made.spanButtons[index]:Hide()
    end
end

function line.LabelTop(made)
    return made.centerY + line.THICKNESS / 2 + line.LABEL_GAP
end

function line.LabelX(made, index)
    local gap = made.width / made.count
    return made.xOffset + gap / 2 + (index - 1) * gap
end

function line.IndexAtX(made, x)
    local gap = made.width / made.count
    local index = math.floor((x - made.xOffset) / gap) + 1
    return math.min(math.max(index, 1), made.count)
end

function line.LayoutBacking(made, parent, snapAbove)
    local top = made.centerY - snapAbove - line.BACKING_TOP_PADDING
    made.backingTop = top
    local captionTop = line.LabelTop(made) + (made.labels[1].normalHeight or 0) + CAPTION_GAP
    local bottom = captionTop + CAPTION_HEIGHT + BACKING_BOTTOM_GAP
    if not made.caption then
        made.caption = parent:CreateFontString(nil, "OVERLAY", CAPTION_FONT)
        made.caption:SetTextColor(CAPTION_COLOR[1], CAPTION_COLOR[2], CAPTION_COLOR[3])
        made.caption:SetText(L.TIMER_LINE_CAPTION)
    end
    made.caption:ClearAllPoints()
    local middle = (made.lineStart + made.lineEnd) / 2
    made.caption:SetPoint("TOP", parent, "TOPLEFT", middle, -captionTop)
    made.backing:ClearAllPoints()
    made.backing:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -top)
    made.backing:SetPoint("BOTTOMRIGHT", parent, "TOPRIGHT", 0, -bottom)
    return bottom
end

function line.ShowSnapMark(made, index)
    if not made.snapMark then
        return
    end
    if not index or not made.centerY then
        made.snapMark:Hide()
        return
    end
    made.snapMark:ClearAllPoints()
    made.snapMark:SetPoint("CENTER", made.labels[index]:GetParent(), "TOPLEFT", line.LabelX(made, index), -made.centerY)
    made.snapMark:Show()
end

function line.PaintLabel(made, index, lit, enlarged)
    local label = made.labels[index]
    if lit then
        label:SetTextColor(LABEL_LIT_COLOR[1], LABEL_LIT_COLOR[2], LABEL_LIT_COLOR[3])
    else
        label:SetTextColor(label.normalR, label.normalG, label.normalB)
    end
    label:SetFontHeight(label.normalHeight * (enlarged and line.SNAPPED_LABEL_SCALE or 1))
end
