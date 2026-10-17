local addonName, ns = ...

local general = {}
ns.appearanceGeneral = general

local ELEMENT_GAP = 12
general.ELEMENT_GAP = ELEMENT_GAP
general.TEXT_INDENT = ns.appearanceControls.ROW_INDENT
general.SCROLLBAR_WIDTH = 30
general.FALLBACK_PANEL_HEIGHT = 400
general.MEASURE_PADDING = 4
general.SCROLL_SLACK = 16

general.RESET_BUTTON_HEIGHT = ns.appearanceControls.RESET_BUTTON_HEIGHT
general.RESET_BUTTON_RIGHT_MARGIN = ns.appearanceControls.RESET_BUTTON_RIGHT_MARGIN
general.RESET_BUTTON_BOTTOM_MARGIN = ns.appearanceControls.RESET_BUTTON_BOTTOM_MARGIN

general.SUBTAB_ROW_HEIGHT = 32
general.SUBTAB_CONTENT_GAP = 8
general.SUBTAB_SPACING = ns.appearanceControls.SUBTAB_SPACING
general.SUBTAB_TEXT_PADDING = ns.appearanceControls.SUBTAB_TEXT_PADDING
general.SUBTAB_MIN_WIDTH = ns.appearanceControls.SUBTAB_MIN_WIDTH
general.SUBTAB_LEFT = 14
general.ORIENTATION_NOTE_WIDTH = 380
general.ORIENTATION_NOTE_GAP = 6
general.FIRST_ROW_CENTER = 20
general.HINT_FONT = "GameFontNormalLarge2"
general.NOTE_FONT = "GameFontNormalMed3"
general.HINT_SIDE_MARGIN = 40

general.ELEMENTS = { "icon", "cooldown", "name", "nameBackground", "debuff", "danger", "roles" }
general.OWN_TITLES = {
    debuff = "EVENT_APPEARANCE_TITLE_DEBUFF",
    danger = "EVENT_APPEARANCE_TITLE_DANGER",
    roles = "EVENT_APPEARANCE_TITLE_ROLES",
    cooldown = "EVENT_APPEARANCE_TITLE_COOLDOWN",
}

general.state = {
    scroll = nil,
    box = nil,
    child = nil,
    hintLabel = nil,
    nameLabel = nil,
    noteLabel = nil,
    resetButton = nil,
    undoButton = nil,
    orientationNote = nil,
    subtabs = {},
    panels = {},
    refreshers = {},
    panelHeights = {},
    firstRowShift = {},
    selected = nil,
    onChanged = nil,
}
