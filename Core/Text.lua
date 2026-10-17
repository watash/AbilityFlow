local addonName, ns = ...

local ipairs = ipairs
local table = table

local text = {}
ns.text = text

text.WHITE = "ffffffff"
text.RED = "ffff3333"
text.GREEN = "ff33ff99"
text.GOLD = "ffffd100"

function text.Colored(value, colour)
    return "|c" .. colour .. value .. "|r"
end

function text.White(value)
    return text.Colored(value, text.WHITE)
end

function text.Red(value)
    return text.Colored(value, text.RED)
end

function text.Green(value)
    return text.Colored(value, text.GREEN)
end

function text.Gold(value)
    return text.Colored(value, text.GOLD)
end

local OPEN_QUOTES = { "«", '"' }
local CLOSE_QUOTE = { ["«"] = "»", ['"'] = '"' }
local PATH_SEPARATOR = " > "

local function openMarkAt(value, position)
    for _, mark in ipairs(OPEN_QUOTES) do
        if value:sub(position, position + #mark - 1) == mark then
            return mark
        end
    end
    return nil
end

function text.Quoted(value, outside, inside)
    local parts = {}
    local position = 1
    while true do
        local openStart, openMark
        for _, mark in ipairs(OPEN_QUOTES) do
            local start = value:find(mark, position, true)
            if start and (not openStart or start < openStart) then
                openStart, openMark = start, mark
            end
        end
        if not openStart then
            parts[#parts + 1] = text.Colored(value:sub(position), outside)
            break
        end
        local openEnd = openStart + #openMark - 1
        local closeStart, closeEnd = value:find(CLOSE_QUOTE[openMark], openEnd + 1, true)
        if not closeStart then
            parts[#parts + 1] = text.Colored(value:sub(position), outside)
            break
        end
        while value:sub(closeEnd + 1, closeEnd + #PATH_SEPARATOR) == PATH_SEPARATOR do
            local nextStart = closeEnd + #PATH_SEPARATOR + 1
            local nextMark = openMarkAt(value, nextStart)
            if not nextMark then
                break
            end
            local _, nextClose = value:find(CLOSE_QUOTE[nextMark], nextStart + #nextMark, true)
            if not nextClose then
                break
            end
            closeEnd = nextClose
        end
        if openStart > position then
            parts[#parts + 1] = text.Colored(value:sub(position, openStart - 1), outside)
        end
        parts[#parts + 1] = text.Colored(value:sub(openStart, closeEnd), inside)
        position = closeEnd + 1
    end
    return table.concat(parts)
end
