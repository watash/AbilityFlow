local addonName, ns = ...

local C_Timer = C_Timer
local ipairs = ipairs
local math = math

local controls = ns.appearanceControls
local general = ns.appearanceGeneral
local state = general.state
local ELEMENT_GAP = general.ELEMENT_GAP
local FALLBACK_PANEL_HEIGHT = general.FALLBACK_PANEL_HEIGHT
local MEASURE_PADDING = general.MEASURE_PADDING
local SCROLL_SLACK = general.SCROLL_SLACK
local FIRST_ROW_CENTER = general.FIRST_ROW_CENTER

local function lowestBottom(frame, lowest)
    for _, region in ipairs({ frame:GetRegions() }) do
        local bottom = region:IsShown() and region:GetBottom()
        if bottom and (not lowest or bottom < lowest) then
            lowest = bottom
        end
    end
    for _, sub in ipairs({ frame:GetChildren() }) do
        if sub:IsShown() then
            lowest = lowestBottom(sub, lowest)
        end
    end
    return lowest
end

function general.Resize()
    local selected = state.selected
    local headingHeight = selected and 0 or state.hintLabel:GetHeight()
    local shift = selected and state.firstRowShift[selected] or 0
    local needed = headingHeight + ELEMENT_GAP + shift
    local viewport = state.scroll:GetHeight()
    if selected then
        local height = state.panelHeights[selected]
            or math.min(FALLBACK_PANEL_HEIGHT, viewport - headingHeight - ELEMENT_GAP)
        needed = needed + height
        if needed <= viewport + SCROLL_SLACK then
            height = math.min(height, viewport - headingHeight - ELEMENT_GAP - shift)
        end
        state.panels[selected]:SetHeight(height)
    else
        needed = needed + state.noteLabel:GetHeight()
        local total = state.hintLabel:GetHeight() + ELEMENT_GAP + state.noteLabel:GetHeight()
        state.hintLabel:ClearAllPoints()
        state.hintLabel:SetPoint("TOP", state.box, "CENTER", 0, total / 2)
    end
    local fits = needed <= viewport + SCROLL_SLACK
    if selected and not state.panelHeights[selected] then
        fits = true
    end
    state.child:SetHeight(fits and viewport or needed)
    if not fits then
        state.scroll.ScrollBar:Show()
    else
        state.scroll:SetVerticalScroll(0)
        state.scroll.ScrollBar:Hide()
    end
end

function general.AlignFirstRow(key, panel)
    local top = panel:GetTop()
    local center = top and controls.FirstRowCenter(panel, top)
    if center then
        state.firstRowShift[key] = FIRST_ROW_CENTER - center
        panel:ClearAllPoints()
        panel:SetPoint("TOPLEFT", state.child, "TOPLEFT", 0, -(ELEMENT_GAP + state.firstRowShift[key]))
    end
end

function general.Measure()
    local key = state.selected
    local panel = key and state.panels[key]
    if not panel then
        return
    end
    general.AlignFirstRow(key, panel)
    local top = panel:GetTop()
    local bottom = top and lowestBottom(panel)
    if top and bottom then
        state.panelHeights[key] = top - bottom + MEASURE_PADDING
    end
    general.Resize()
end

function general.MeasureSoon()
    C_Timer.After(0, general.Measure)
end
