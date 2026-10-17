local addonName, ns = ...

local floor = math.floor

local countdownFormat = {}
ns.countdownFormat = countdownFormat

local SECONDS_PER_MINUTE = 60

function countdownFormat.Of(seconds)
    if seconds >= SECONDS_PER_MINUTE then
        return ("%d:%02d"):format(floor(seconds / SECONDS_PER_MINUTE), seconds % SECONDS_PER_MINUTE)
    end
    return tostring(seconds)
end
