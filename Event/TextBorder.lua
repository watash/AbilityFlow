local addonName, ns = ...

local issecretvalue = issecretvalue
local max = math.max
local ipairs = ipairs
local pairs = pairs

local textBorder = {}
ns.textBorder = textBorder

local COORD_START = 0.0625
local COORD_END = 1 - COORD_START
local PIECES = {
    TopLeftCorner = { 0.5078125, COORD_START, 0.5078125, COORD_END, 0.6171875, COORD_START, 0.6171875, COORD_END },
    TopRightCorner = { 0.6328125, COORD_START, 0.6328125, COORD_END, 0.7421875, COORD_START, 0.7421875, COORD_END },
    BottomLeftCorner = { 0.7578125, COORD_START, 0.7578125, COORD_END, 0.8671875, COORD_START, 0.8671875, COORD_END },
    BottomRightCorner = { 0.8828125, COORD_START, 0.8828125, COORD_END, 0.9921875, COORD_START, 0.9921875, COORD_END },
    TopEdge = { 0.2578125, "repeatX", 0.3671875, "repeatX", 0.2578125, COORD_START, 0.3671875, COORD_START },
    BottomEdge = { 0.3828125, "repeatX", 0.4921875, "repeatX", 0.3828125, COORD_START, 0.4921875, COORD_START },
    LeftEdge = { 0.0078125, COORD_START, 0.0078125, "repeatY", 0.1171875, COORD_START, 0.1171875, "repeatY" },
    RightEdge = { 0.1328125, COORD_START, 0.1328125, "repeatY", 0.2421875, COORD_START, 0.2421875, "repeatY" },
}
local UNKNOWN_REPEAT = 1
local TEXTURE_LAYER = "BORDER"

local function retile(frame)
    local edge = frame.borderEdge
    if not edge then
        return
    end
    local width, height = frame:GetSize()
    local repeatX, repeatY = UNKNOWN_REPEAT, UNKNOWN_REPEAT
    if not issecretvalue(width) and not issecretvalue(height) then
        local scale = frame:GetEffectiveScale()
        repeatX = max(0, (width / edge) * scale - 2 - COORD_START)
        repeatY = max(0, (height / edge) * scale - 2 - COORD_START)
    end
    for name, coords in pairs(PIECES) do
        local values = {}
        for index, value in ipairs(coords) do
            if value == "repeatX" then
                value = repeatX
            elseif value == "repeatY" then
                value = repeatY
            end
            values[index] = value
        end
        frame.borderPieces[name]:SetTexCoord(values[1], values[2], values[3], values[4], values[5], values[6], values[7],
            values[8])
    end
end

local function makePieces(frame)
    local pieces = {}
    for name in pairs(PIECES) do
        pieces[name] = frame:CreateTexture(nil, TEXTURE_LAYER)
    end
    frame.borderPieces = pieces
    pieces.TopLeftCorner:SetPoint("TOPLEFT", frame, "TOPLEFT")
    pieces.TopRightCorner:SetPoint("TOPRIGHT", frame, "TOPRIGHT")
    pieces.BottomLeftCorner:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT")
    pieces.BottomRightCorner:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT")
    pieces.TopEdge:SetPoint("TOPLEFT", pieces.TopLeftCorner, "TOPRIGHT")
    pieces.TopEdge:SetPoint("TOPRIGHT", pieces.TopRightCorner, "TOPLEFT")
    pieces.BottomEdge:SetPoint("BOTTOMLEFT", pieces.BottomLeftCorner, "BOTTOMRIGHT")
    pieces.BottomEdge:SetPoint("BOTTOMRIGHT", pieces.BottomRightCorner, "BOTTOMLEFT")
    pieces.LeftEdge:SetPoint("TOPLEFT", pieces.TopLeftCorner, "BOTTOMLEFT")
    pieces.LeftEdge:SetPoint("BOTTOMLEFT", pieces.BottomLeftCorner, "TOPLEFT")
    pieces.RightEdge:SetPoint("TOPRIGHT", pieces.TopRightCorner, "BOTTOMRIGHT")
    pieces.RightEdge:SetPoint("BOTTOMRIGHT", pieces.BottomRightCorner, "TOPRIGHT")
    frame:SetScript("OnSizeChanged", retile)
end

function textBorder.Set(frame, file, edge, color)
    if not frame.borderPieces then
        makePieces(frame)
    end
    for name, piece in pairs(frame.borderPieces) do
        piece:SetTexture(file, "REPEAT", "REPEAT")
        piece:SetVertexColor(color.r, color.g, color.b, color.a)
        if name:find("Corner") then
            piece:SetSize(edge, edge)
        elseif name:find("Top") or name:find("Bottom") then
            piece:SetHeight(edge)
        else
            piece:SetWidth(edge)
        end
        piece:Show()
    end
    frame.borderEdge = edge
    retile(frame)
end

function textBorder.Clear(frame)
    frame.borderEdge = nil
    if frame.borderPieces then
        for _, piece in pairs(frame.borderPieces) do
            piece:Hide()
        end
    end
end
