local addonName, ns = ...

local timerStyle = ns.timerStyle

function timerStyle.Evaluate(remaining)
    local data = timerStyle.Saved()
    if not data.enabled then
        return nil
    end
    local second = math.ceil(remaining)
    if second < 1 or second > timerStyle.SECONDS then
        return nil
    end
    for nearest = second, timerStyle.SECONDS do
        local template = data.templates[data.seconds[nearest]]
        if template then
            return template
        end
    end
    return nil
end

function timerStyle.FlashesAt(second, ignoreSwitch)
    local data = timerStyle.Saved()
    if (not data.enabled and not ignoreSwitch) or second < 1 or second > timerStyle.SECONDS then
        return false
    end
    local template = data.templates[data.seconds[second]]
    return template ~= nil and template.flash == true
end
