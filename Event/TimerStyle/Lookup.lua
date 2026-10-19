local addonName, ns = ...

local timerStyle = ns.timerStyle

function timerStyle.TemplateFor(remaining)
    local style = timerStyle.Saved()
    if not style.enabled then
        return nil
    end
    local second = math.ceil(remaining)
    if second < 1 or second > timerStyle.SECONDS then
        return nil
    end
    for nearest = second, timerStyle.SECONDS do
        local template = style.templates[style.seconds[nearest]]
        if template then
            return template
        end
    end
    return nil
end

function timerStyle.FlashesAt(second, ignoreSwitch)
    local style = timerStyle.Saved()
    if (not style.enabled and not ignoreSwitch) or second < 1 or second > timerStyle.SECONDS then
        return false
    end
    local template = style.templates[style.seconds[second]]
    return template ~= nil and template.flash == true
end
