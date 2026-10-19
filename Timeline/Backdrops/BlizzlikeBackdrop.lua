local addonName, ns = ...

local timeline = ns.timeline

local art = timeline.backdropArt
local LINE_TEXTURE = timeline.LINE_TEXTURE
local LINE_AS_TWO_PIECES = art.LINE_AS_TWO_PIECES
local CAP_MAX_LENGTH_SHARE = art.CAP_MAX_LENGTH_SHARE
local SHADOW_SPREAD = art.SHADOW_SPREAD
local BREAK_OFFSET = timeline.BREAK_OFFSET
local BREAK_INTERVAL = timeline.BREAK_INTERVAL
local BREAK_END_MARGIN = art.BREAK_END_MARGIN
local BREAK_MASK_CROSS_SCALE = art.BREAK_MASK_CROSS_SCALE
local BREAK_MASKS_PER_TEXTURE = art.BREAK_MASKS_PER_TEXTURE
local VERTICAL_MASK_ROTATION = art.VERTICAL_MASK_ROTATION
local DIVIDER_BAR_COLUMNS = art.DIVIDER_BAR_COLUMNS
local orientTexture = art.orientTexture
local dividerArtColumns = art.dividerArtColumns

function timeline.CreateBlizzlikeBackdrop(frame)
    local enabled = false

    local shadow = frame:CreateTexture(nil, "BACKGROUND")
    shadow:Hide()
    local shadowMask = frame:CreateMaskTexture()
    shadow:AddMaskTexture(shadowMask)
    local capZero = frame:CreateTexture(nil, "ARTWORK")
    local capFar = frame:CreateTexture(nil, "ARTWORK")
    local function makeDivider()
        local divider = {
            bar = frame:CreateTexture(nil, "ARTWORK"),
            shadow = frame:CreateTexture(nil, "ARTWORK"),
            mask = frame:CreateMaskTexture(),
        }
        divider.shadow:AddMaskTexture(divider.mask)
        return divider
    end
    local dividerStart = makeDivider()
    local dividerEnd = makeDivider()
    local pieces = {}
    local breakMasks = {}

    local function growPieces(count)
        for i = #pieces + 1, count do
            pieces[i] = frame:CreateTexture(nil, "ARTWORK", nil, -1)
            pieces[i]:Hide()
        end
        return pieces
    end

    local function growMasks(count)
        for i = #breakMasks + 1, count do
            breakMasks[i] = frame:CreateMaskTexture(nil, "ARTWORK")
        end
        return breakMasks
    end

    local function layoutParts()
        if not enabled then
            shadow:Hide()
            shadowMask:Hide()
            capZero:Hide()
            capFar:Hide()
            for _, divider in ipairs({ dividerStart, dividerEnd }) do
                divider.bar:Hide()
                divider.shadow:Hide()
                divider.mask:Hide()
            end
            for _, piece in ipairs(pieces) do
                piece:Hide()
            end
            for _, mask in ipairs(breakMasks) do
                mask:Hide()
            end
            frame.background:Show()
            return
        end
        frame.background:Hide()

        local horizontal = timeline.Orientation() == timeline.ORIENTATION_HORIZONTAL
        local length = timeline.TrackLength()
        local dividerSize = timeline.currentIconSize()
        local zeroAtStart = timeline.EntersFromStart()
        local lineScale = timeline.LineScale()

        local function along(distance)
            return zeroAtStart and distance or (length - distance)
        end

        local barShare = DIVIDER_BAR_COLUMNS / dividerArtColumns()
        local function orientDivider(divider, mirrored)
            orientTexture(divider.bar, timeline.DIVIDER_ATLAS, horizontal, mirrored, true, 1 - barShare, 1)
            orientTexture(divider.mask, timeline.DIVIDER_ATLAS, horizontal, mirrored, true, 0, 1 - barShare)
        end
        orientDivider(dividerStart, not horizontal)
        orientDivider(dividerEnd, horizontal)
        local crossSize = dividerSize
        local inset = timeline.EndReach()
        local barLength = 2 * inset * barShare
        local shadowLength = 2 * inset - barLength
        for index, divider in ipairs({ dividerStart, dividerEnd }) do
            local isStart = index == 1
            divider.bar:ClearAllPoints()
            divider.shadow:ClearAllPoints()
            divider.mask:ClearAllPoints()
            local atZero = isStart == zeroAtStart
            local pull = atZero and -timeline.ExitDividerGap() or -timeline.EntryDividerGap()
            if atZero and timeline.queuedHidden then
                divider.bar:Hide()
                divider.shadow:Hide()
                divider.mask:Hide()
            else
                if horizontal then
                    divider.bar:SetSize(barLength, crossSize)
                    divider.shadow:SetSize(shadowLength, crossSize)
                    if isStart then
                        divider.bar:SetPoint("RIGHT", frame, "LEFT", pull, 0)
                        divider.shadow:SetPoint("RIGHT", divider.bar, "LEFT")
                    else
                        divider.bar:SetPoint("LEFT", frame, "RIGHT", -pull, 0)
                        divider.shadow:SetPoint("LEFT", divider.bar, "RIGHT")
                    end
                else
                    divider.bar:SetSize(crossSize, barLength)
                    divider.shadow:SetSize(crossSize, shadowLength)
                    if isStart then
                        divider.bar:SetPoint("TOP", frame, "BOTTOM", 0, pull)
                        divider.shadow:SetPoint("TOP", divider.bar, "BOTTOM")
                    else
                        divider.bar:SetPoint("BOTTOM", frame, "TOP", 0, -pull)
                        divider.shadow:SetPoint("BOTTOM", divider.bar, "TOP")
                    end
                end
                divider.shadow:SetColorTexture(timeline.BackgroundColor())
                divider.mask:SetAllPoints(divider.shadow)
                divider.bar:Show()
                divider.shadow:Show()
                divider.mask:Show()
            end
        end

        local capMirrored = zeroAtStart == horizontal
        orientTexture(capZero, "combattimeline-line-right", horizontal, capMirrored, false)
        orientTexture(capFar, "combattimeline-line-left", horizontal, capMirrored, false)
        for _, cap in ipairs({ capZero, capFar }) do
            local nativeLength = horizontal and cap:GetWidth() or cap:GetHeight()
            local nativeCross = horizontal and cap:GetHeight() or cap:GetWidth()
            local grownLength = LINE_AS_TWO_PIECES and length / 2 or math.min(nativeLength * lineScale, length * CAP_MAX_LENGTH_SHARE)
            local grownCross = nativeCross * lineScale
            if horizontal then
                cap:SetSize(grownLength, grownCross)
            else
                cap:SetSize(grownCross, grownLength)
            end
        end
        local capLength = horizontal and capZero:GetWidth() or capZero:GetHeight()
        capLength = math.max(capLength, 1)
        local lineThickness = horizontal and capZero:GetHeight() or capZero:GetWidth()
        local capZeroLow = zeroAtStart and 0 or (length - capLength)
        local capFarLow = zeroAtStart and (length - capLength) or 0
        capZero:ClearAllPoints()
        capFar:ClearAllPoints()
        if horizontal then
            capZero:SetPoint("LEFT", frame, "LEFT", capZeroLow, 0)
            capFar:SetPoint("LEFT", frame, "LEFT", capFarLow, 0)
        else
            capZero:SetPoint("BOTTOM", frame, "BOTTOM", 0, capZeroLow)
            capFar:SetPoint("BOTTOM", frame, "BOTTOM", 0, capFarLow)
        end
        capZero:Show()
        capFar:Show()

        local shadowThickness = timeline.TrackWidth() * SHADOW_SPREAD
        shadow:ClearAllPoints()
        shadow:SetColorTexture(timeline.BackgroundColor())
        shadowMask:SetAtlas(horizontal and "combattimeline-line-shadow" or "combattimeline-line-shadow-vertical", true)
        if shadowMask.ClearTextureSlice then
            shadowMask:ClearTextureSlice()
        end
        local entryReach, exitReach = timeline.WaitingExtents()
        local lowReach = zeroAtStart and exitReach or entryReach
        local highReach = zeroAtStart and entryReach or exitReach
        if horizontal then
            shadow:SetHeight(shadowThickness)
            shadow:SetPoint("LEFT", frame, "LEFT", -lowReach, 0)
            shadow:SetPoint("RIGHT", frame, "RIGHT", highReach, 0)
        else
            shadow:SetWidth(shadowThickness)
            shadow:SetPoint("TOP", frame, "TOP", 0, highReach)
            shadow:SetPoint("BOTTOM", frame, "BOTTOM", 0, -lowReach)
        end
        shadowMask:ClearAllPoints()
        shadowMask:SetAllPoints(shadow)
        shadowMask:Show()
        shadow:Show()

        local tileableLength = math.max(0, length - 2 * capLength)
        local tileCount = LINE_AS_TWO_PIECES and 0 or math.max(1, math.floor(tileableLength / capLength + 0.5))
        local tileLength = tileCount > 0 and tileableLength / tileCount or 0
        local pieceList = growPieces(tileCount)
        for i = 1, tileCount do
            local piece = pieceList[i]
            piece:SetTexture(LINE_TEXTURE, "CLAMP", "CLAMP")
            piece:ClearAllPoints()
            local first = capLength + (i - 1) * tileLength
            local last = capLength + i * tileLength
            local lo = math.min(along(first), along(last))
            local hi = math.max(along(first), along(last))
            if horizontal then
                piece:SetTexCoord(0, 0, 0, 1, 1, 0, 1, 1)
                piece:SetHeight(lineThickness)
                piece:SetPoint("LEFT", frame, "LEFT", lo, 0)
                piece:SetPoint("RIGHT", frame, "LEFT", hi, 0)
            else
                piece:SetTexCoord(0, 1, 1, 1, 0, 0, 1, 0)
                piece:SetWidth(lineThickness)
                piece:SetPoint("BOTTOM", frame, "BOTTOM", 0, lo)
                piece:SetPoint("TOP", frame, "BOTTOM", 0, hi)
            end
            piece:Show()
        end
        for i = tileCount + 1, #pieces do
            pieces[i]:Hide()
        end

        local threshold = timeline.TRACK_SPAN_SECONDS
        local breaks = {}
        for t = BREAK_OFFSET, threshold - BREAK_END_MARGIN, BREAK_INTERVAL do
            table.insert(breaks, t)
        end
        local masks = growMasks(#breaks)
        for _, mask in ipairs(masks) do
            for _, piece in ipairs(pieces) do
                piece:RemoveMaskTexture(mask)
            end
            capZero:RemoveMaskTexture(mask)
            capFar:RemoveMaskTexture(mask)
        end
        for i, breakTime in ipairs(breaks) do
            local mask = masks[i]
            local distance = breakTime / threshold * length
            local position = along(distance)
            mask:SetAtlas("combattimeline-line-break-mask", true)
            local maskWidth, maskHeight = mask:GetSize()
            mask:ClearAllPoints()
            if horizontal then
                mask:SetSize(maskWidth, maskHeight * BREAK_MASK_CROSS_SCALE)
                mask:SetPoint("CENTER", frame, "LEFT", position, 0)
                mask:SetRotation(0)
            else
                mask:SetSize(maskWidth * BREAK_MASK_CROSS_SCALE, maskHeight)
                mask:SetPoint("CENTER", frame, "BOTTOM", 0, position)
                mask:SetRotation(VERTICAL_MASK_ROTATION)
            end
            mask:Show()

            local target
            if distance < capLength then
                target = capZero
            elseif distance > length - capLength then
                target = capFar
            else
                local index = math.max(1, math.min(tileCount, math.floor((distance - capLength) / tileLength) + 1))
                target = pieceList[index]
            end
            target = target or capZero
            if target:GetNumMaskTextures() < BREAK_MASKS_PER_TEXTURE then
                target:AddMaskTexture(mask)
            end
        end
    end

    return {
        Layout = layoutParts,
        SetEnabled = function(value)
            enabled = value
        end,
        IsEnabled = function()
            return enabled
        end,
        Tint = function()
            shadow:SetColorTexture(timeline.BackgroundColor())
            dividerStart.shadow:SetColorTexture(timeline.BackgroundColor())
            dividerEnd.shadow:SetColorTexture(timeline.BackgroundColor())
        end,
    }
end
