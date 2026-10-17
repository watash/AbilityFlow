local addonName, ns = ...

local math = math
local pairs = pairs
local type = type

local tables = {}
ns.tables = tables

function tables.Same(first, second, tolerance)
    if tolerance and type(first) == "number" and type(second) == "number" then
        return math.abs(first - second) <= tolerance
    end
    if type(first) == "table" and type(second) == "table" then
        for key, value in pairs(first) do
            if not tables.Same(value, second[key], tolerance) then
                return false
            end
        end
        for key in pairs(second) do
            if first[key] == nil then
                return false
            end
        end
        return true
    end
    return first == second
end
