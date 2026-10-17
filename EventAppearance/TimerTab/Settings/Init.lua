local addonName, ns = ...

local appearance = ns.appearance

ns.timerTab = ns.timerTab or {}

local settings = {}
ns.timerTab.settings = settings

settings.builders = {}

settings.ROW_GAP = 14
settings.SWATCH_BESIDE_GAP = 12
settings.WIDE_SLIDER_EXTRA = 60
settings.WIDE_LIST_EXTRA = settings.WIDE_SLIDER_EXTRA + 25
settings.SLIDER_EXTRA = 40
settings.SECOND_COLUMN_LEFT = 350
settings.DISABLED_ALPHA = 0.4
settings.FULL_ALPHA = 1

function settings.ownColor(template)
    return template.color or appearance.Get("cooldown", "color")
end
