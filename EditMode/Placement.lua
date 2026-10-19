local addonName, ns = ...

local C_EditMode = C_EditMode
local C_EncounterTimeline = C_EncounterTimeline
local C_Timer = C_Timer
local ipairs = ipairs
local _G = _G

local timeline = ns.timeline
local L = ns.L
local store = ns.store
local values = ns.values
local undo = ns.editModeUndo
local editDialog = ns.editModeDialog
local config = ns.editModeConfig
local editMode = LibStub("LibEditMode")

local DEFAULT_ANCHOR = { point = "BOTTOMRIGHT", relativePoint = "BOTTOM", x = -457, y = 336 }
local DEFAULT_SCALE = 1.0
local SELECTION_LEVEL_OVER_TRACK = 1

local PROFILES_TAB = "Profiles"

local resetPosition = { point = "CENTER", x = 0, y = 0 }

local refreshUndoButton

local editStart

local shownInEditMode = false
local addedSamples = false

local applyingLayout = false

local DEFAULT_POSITION_TOLERANCE = 0.01

local function computeResetPosition()
    resetPosition.x = DEFAULT_ANCHOR.x - timeline.TRACK_WIDTH * DEFAULT_SCALE / 2
    resetPosition.y = DEFAULT_ANCHOR.y + timeline.DEFAULT_TRACK_LENGTH * DEFAULT_SCALE / 2 - UIParent:GetHeight() / 2
end

local function isDefaultPosition(point, x, y)
    return point == resetPosition.point and math.abs(x - resetPosition.x) <= DEFAULT_POSITION_TOLERANCE
        and math.abs(y - resetPosition.y) <= DEFAULT_POSITION_TOLERANCE
end

local function shiftInto(low, size, limit)
    if size >= limit or low < 0 then
        return -low
    end
    if low + size > limit then
        return limit - (low + size)
    end
    return 0
end

local function keepOnScreen(layoutName, persist)
    local frame = timeline.frame
    local saved = store.Raw("timelinePositions", layoutName)
    local left, bottom, width, height = frame:GetRect()
    if not saved or not left then
        return
    end
    local shiftX = shiftInto(left, width, UIParent:GetWidth())
    local shiftY = shiftInto(bottom, height, UIParent:GetHeight())
    if shiftX == 0 and shiftY == 0 then
        return
    end
    local x, y = saved.x + shiftX, saved.y + shiftY
    frame:ClearAllPoints()
    frame:SetPoint(saved.point, UIParent, saved.point, x, y)
    if persist then
        store.Set("timelinePositions", layoutName, { point = saved.point, x = x, y = y })
    end
end

local function applyPosition(layoutName, persist)
    local frame = timeline.frame
    applyingLayout = true
    values.Apply(layoutName)
    applyingLayout = false
    frame:SetScale(DEFAULT_SCALE)
    computeResetPosition()
    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "CENTER", resetPosition.x, resetPosition.y)

    local saved = store.Raw("timelinePositions", layoutName)
    if saved and isDefaultPosition(saved.point, saved.x, saved.y) then
        store.Set("timelinePositions", layoutName, nil)
        saved = nil
    end
    if saved then
        frame:ClearAllPoints()
        frame:SetPoint(saved.point, UIParent, saved.point, saved.x, saved.y)
        keepOnScreen(layoutName, persist == true)
    end
end

function timeline.ImportTrack(track)
    local layoutName = editMode:GetActiveLayoutName()
    if not layoutName then
        return nil
    end
    values.Import(layoutName, track)
    applyPosition(layoutName, true)
    if editMode:IsInEditMode() then
        editMode:RefreshFrameSettings(timeline.frame)
        refreshUndoButton()
    end
    return layoutName
end

function timeline.ActiveLayoutName()
    return editMode:GetActiveLayoutName()
end

local BASE_LAYOUTS = {
    { "EDIT_MODE_MODERN_SYSTEM_MAP", "Modern" },
    { "EDIT_MODE_CLASSIC_SYSTEM_MAP", "Classic" },
    { "EDIT_MODE_GAMEPAD_SYSTEM_MAP", "Gamepad" },
}

function timeline.LayoutNames()
    local names = {}
    for _, base in ipairs(BASE_LAYOUTS) do
        if _G[base[1]] then
            names[#names + 1] = base[2]
        end
    end
    for _, layout in ipairs(C_EditMode.GetLayouts().layouts) do
        names[#names + 1] = layout.layoutName
    end
    return names
end

local function onPositionChanged(_, layoutName, point, x, y)
    store.Set("timelinePositions", layoutName, not isDefaultPosition(point, x, y) and { point = point, x = x, y = y } or nil)
    refreshUndoButton()
end

local function undoEditChanges()
    if not editStart or not editStart.layoutName then
        return
    end
    undo.Restore(editStart)
    values.Apply(editStart.layoutName)
    applyPosition(editStart.layoutName)
    editMode:RefreshFrameSettings(timeline.frame)
end

refreshUndoButton = function()
    local canUndo = editStart ~= nil and undo.HasChanges(editStart)
    editDialog.Refresh(editMode.internal.dialog, canUndo, not values.IsDefault(editMode:GetActiveLayoutName()))
end

local function hasSampleEvents()
    for _, eventID in ipairs(C_EncounterTimeline.GetEventList()) do
        local info = C_EncounterTimeline.GetEventInfo(eventID)
        if info and info.source == Enum.EncounterTimelineEventSource.EditMode then
            return true
        end
    end
    return false
end

local function onEditModeEnter()
    editStart = undo.Begin(editMode:GetActiveLayoutName())
    shownInEditMode = not (C_EncounterTimeline.IsFeatureAvailable() and not C_EncounterTimeline.IsFeatureEnabled())
    if not shownInEditMode then
        return
    end
    timeline.setHeld(true)
    timeline.setShownNow(true)
    timeline.SetIconsTakeMouse(false)
    C_Timer.After(0, function()
        if EncounterTimeline and not EncounterTimeline:IsForbidden() and EncounterTimeline.editModeEventTimer then
            return
        end
        if hasSampleEvents() then
            return
        end
        C_EncounterTimeline.AddEditModeEvents()
        addedSamples = true
    end)
end

local function onEditModeExit()
    if not shownInEditMode then
        return
    end
    shownInEditMode = false
    if addedSamples then
        addedSamples = false
        C_EncounterTimeline.CancelEditModeEvents()
    end
    timeline.setHeld(false)
    timeline.setShownNow(timeline.HasEvents())
    timeline.SetIconsTakeMouse(true)
end

local function openEventAppearance()
    ns.eventAppearance.Toggle()
end

local function openProfiles()
    ns.eventAppearance.Toggle(PROFILES_TAB)
end

function timeline.EnablePlacement()
    editMode:AddFrame(timeline.frame, onPositionChanged, resetPosition, L.TIMELINE_NAME:format(addonName))
    editMode:RegisterCallback("layout", applyPosition)
    editMode:RegisterCallback("enter", onEditModeEnter)
    editMode:RegisterCallback("exit", onEditModeExit)
    editMode:AddFrameSettingsButton(timeline.frame, { text = L.EVENT_APPEARANCE, click = openEventAppearance })
    editMode:AddFrameSettingsButton(timeline.frame, { text = L.EVENT_APPEARANCE_TAB_PROFILES, click = openProfiles })
    editMode:AddFrameSettingsButton(timeline.frame, { text = L.UNDO_CHANGES, click = undoEditChanges })
    editDialog.SetOwnSelection(editMode.frameSelections[timeline.frame])
    hooksecurefunc(editMode.internal.dialog, "Update", function(libDialog)
        editDialog.FitToTrackSettings(libDialog)
        refreshUndoButton()
    end)
    editDialog.WidenMargins(editMode.internal.dialog)
    editDialog.FitToScreen(editMode.internal.dialog)

    editMode:AddFrameSettings(timeline.frame, config.Build({
        refresh = refreshUndoButton,
        resetChanged = computeResetPosition,
    }))

    timeline.onFrameMoved = function()
        if applyingLayout or not editMode:IsInEditMode() then
            return
        end
        local point, _, _, x, y = timeline.frame:GetPoint(1)
        onPositionChanged(timeline.frame, editMode:GetActiveLayoutName(), point, x, y)
    end

    local selection = editMode.frameSelections[timeline.frame]
    editDialog.InstallSelectionTooltip(selection, addonName)
    if selection then
        selection:SetFrameStrata(timeline.frame:GetFrameStrata())
        selection:SetFrameLevel(timeline.frame:GetFrameLevel() + SELECTION_LEVEL_OVER_TRACK)
    end

    timeline.onBackdropReachChanged = function(reachX, reachY)
        if not selection then
            return
        end
        selection:ClearAllPoints()
        selection:SetPoint("TOPLEFT", timeline.frame, "TOPLEFT", -reachX, reachY)
        selection:SetPoint("BOTTOMRIGHT", timeline.frame, "BOTTOMRIGHT", reachX, -reachY)
    end
    timeline.RefreshBackdropReach()

    ns.profiles.OnChanged(function()
        if editMode:IsInEditMode() then
            editMode:RefreshFrameSettings(timeline.frame)
            refreshUndoButton()
        end
    end)
end
