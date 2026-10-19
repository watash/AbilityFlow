local addonName, ns = ...

local timerStyle = ns.timerStyle

local ICON_SPELLS = {
    133, 116, 1953, 11366, 589, 17, 8092, 51505, 774, 8921, 5176, 100, 12294, 23922, 1784, 1752, 853, 642,
    20271, 43265, 188196, 2825, 122, 45438, 686, 5782, 49576, 605, 2006,
    34026, 257284, 191427, 195072, 100780, 343744, 357208, 434300,
}
timerStyle.ICON_SPELLS = ICON_SPELLS

local STARTER_SECOND = 5
local STARTER_PULSE = true
local STARTER_FLASH = true
local STARTER_TENTHS = true

local newStyle

local function saved()
    local profile = ns.profiles.Current()
    local style = profile.timerStyle
    if not style then
        style = newStyle()
        profile.timerStyle = style
    end
    return style
end
timerStyle.Saved = saved

function timerStyle.IsEnabled()
    return saved().enabled
end

function timerStyle.SetEnabled(value)
    saved().enabled = value
end

function timerStyle.Order()
    return saved().order
end

function timerStyle.Template(templateID)
    return saved().templates[templateID]
end

function timerStyle.CanAdd()
    return #saved().order < timerStyle.MAX_TEMPLATES
end

local function iconSpellIn(style, templateID)
    local template = style.templates[templateID]
    if not template then
        return nil
    end
    if not template.iconSpell then
        local taken = {}
        for _, other in pairs(style.templates) do
            if other.iconSpell then
                taken[other.iconSpell] = true
            end
        end
        local free = {}
        for _, spellID in ipairs(ICON_SPELLS) do
            if not taken[spellID] then
                free[#free + 1] = spellID
            end
        end
        template.iconSpell = free[math.random(#free)] or ICON_SPELLS[1]
    end
    return template.iconSpell
end

local function addTo(style, copyFrom)
    if #style.order >= timerStyle.MAX_TEMPLATES then
        return nil
    end
    local templateID = style.nextID
    style.nextID = templateID + 1
    local source = copyFrom and style.templates[copyFrom]
    style.templates[templateID] = source and CopyTable(source) or timerStyle.newTemplate()
    style.templates[templateID].iconSpell = nil
    table.insert(style.order, templateID)
    iconSpellIn(style, templateID)
    return templateID
end

function timerStyle.Add(copyFrom)
    return addTo(saved(), copyFrom)
end

function timerStyle.IconSpell(templateID)
    return iconSpellIn(saved(), templateID)
end

newStyle = function(glowInstead)
    local style = { enabled = true, seconds = {}, templates = {}, order = {}, nextID = 1 }
    local templateID = addTo(style)
    local template = style.templates[templateID]
    template.pulse = STARTER_PULSE and not glowInstead
    if glowInstead then
        template.useGlow = true
        template.glowType = ns.glow.PIXEL
    end
    template.flash = STARTER_FLASH
    template.tenths = STARTER_TENTHS
    style.seconds[STARTER_SECOND] = templateID
    return style
end

timerStyle.NewStyle = newStyle

ns.profiles.OnComplete(function(profile)
    if profile.timerStyle == nil then
        profile.timerStyle = newStyle()
    end
end)

function timerStyle.Remove(templateID)
    local style = saved()
    style.templates[templateID] = nil
    for index, id in ipairs(style.order) do
        if id == templateID then
            table.remove(style.order, index)
            break
        end
    end
    for second = 1, timerStyle.SECONDS do
        if style.seconds[second] == templateID then
            style.seconds[second] = nil
        end
    end
end

function timerStyle.DisplayNumber(templateID)
    for index, id in ipairs(saved().order) do
        if id == templateID then
            return index
        end
    end
end

function timerStyle.TemplateAt(second)
    return saved().seconds[second]
end

function timerStyle.IsUsed(templateID)
    local seconds = saved().seconds
    for second = 1, timerStyle.SECONDS do
        if seconds[second] == templateID then
            return true
        end
    end
    return false
end

function timerStyle.SetTemplateAt(second, templateID)
    saved().seconds[second] = templateID
end
