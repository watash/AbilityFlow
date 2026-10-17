local addonName, ns = ...

local floor = math.floor

local endReach = {}
ns.endReach = endReach

function endReach.Of(iconSize, artWidth, artHeight)
    local reach = iconSize / 2
    if artWidth and artHeight and artHeight > 0 then
        reach = artWidth * iconSize / artHeight / 2
    end
    return floor(reach + 0.5)
end
