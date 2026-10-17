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
    local data = profile.timerStyle
    if not data then
        data = newStyle()
        profile.timerStyle = data
    end
    return data
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

local function iconSpellIn(data, templateID)
    local template = data.templates[templateID]
    if not template then
        return nil
    end
    if not template.iconSpell then
        local taken = {}
        for _, other in pairs(data.templates) do
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

local function addTo(data, copyFrom)
    if #data.order >= timerStyle.MAX_TEMPLATES then
        return nil
    end
    local templateID = data.nextID
    data.nextID = templateID + 1
    local source = copyFrom and data.templates[copyFrom]
    data.templates[templateID] = source and CopyTable(source) or timerStyle.newTemplate()
    data.templates[templateID].iconSpell = nil
    table.insert(data.order, templateID)
    iconSpellIn(data, templateID)
    return templateID
end

function timerStyle.Add(copyFrom)
    return addTo(saved(), copyFrom)
end

function timerStyle.IconSpell(templateID)
    return iconSpellIn(saved(), templateID)
end

newStyle = function(glowInstead)
    local data = { enabled = true, seconds = {}, templates = {}, order = {}, nextID = 1 }
    local templateID = addTo(data)
    local template = data.templates[templateID]
    template.pulse = STARTER_PULSE and not glowInstead
    if glowInstead then
        template.useGlow = true
        template.glowType = ns.glow.PIXEL
    end
    template.flash = STARTER_FLASH
    template.tenths = STARTER_TENTHS
    data.seconds[STARTER_SECOND] = templateID
    return data
end

timerStyle.NewStyle = newStyle

ns.profiles.OnComplete(function(data)
    if data.timerStyle == nil then
        data.timerStyle = newStyle()
    end
end)

function timerStyle.Remove(templateID)
    local data = saved()
    data.templates[templateID] = nil
    for index, id in ipairs(data.order) do
        if id == templateID then
            table.remove(data.order, index)
            break
        end
    end
    for second = 1, timerStyle.SECONDS do
        if data.seconds[second] == templateID then
            data.seconds[second] = nil
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
