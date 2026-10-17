local addonName, ns = ...

local timeline = ns.timeline

local art = {}
timeline.backdropArt = art

local LINE_TEXTURE = "Interface\\AddOns\\AbilityFlow\\Media\\Textures\\line-fill.png"
local LINE_THICKNESS = 8
timeline.LINE_THICKNESS = LINE_THICKNESS
timeline.LINE_TEXTURE = LINE_TEXTURE
local LINE_GROWTH_PER_TRACK_PIXEL = 0.15
local LINE_AS_TWO_PIECES = true
local CAP_MAX_LENGTH_SHARE = 0.45
local SHADOW_SPREAD = 1.4
local DIVIDER_GAP = 33
timeline.DIVIDER_GAP = DIVIDER_GAP

function timeline.GetLineScale()
    local extraTrack = math.max(0, timeline.GetTrackWidth() - timeline.TRACK_WIDTH)
    return 1 + extraTrack * LINE_GROWTH_PER_TRACK_PIXEL / LINE_THICKNESS
end
local DIVIDER_BAR_COLUMNS = 4
timeline.DIVIDER_BAR_COLUMNS = DIVIDER_BAR_COLUMNS
local DIVIDER_ART_COLUMNS = 56
local DIVIDER_ART_COLUMNS_LARGE = 112
local LARGE_ART_MARK = "2x"
local UNNAMED_FILE_MARK = "FileData ID"

local function dividerArtColumns()
    local info = C_Texture.GetAtlasInfo(timeline.DIVIDER_ATLAS)
    local name = info and type(info.file) == "number" and C_Texture.GetFilenameFromFileDataID(info.file)
    if type(name) == "string" and not name:find(UNNAMED_FILE_MARK, 1, true) and not name:lower():find(LARGE_ART_MARK, 1, true) then
        return DIVIDER_ART_COLUMNS
    end
    return DIVIDER_ART_COLUMNS_LARGE
end
local BREAK_OFFSET = 1
local BREAK_INTERVAL = 2
timeline.BREAK_OFFSET = BREAK_OFFSET
timeline.BREAK_INTERVAL = BREAK_INTERVAL
local BREAK_MASKS_PER_TEXTURE = 3
local BREAK_MASK_CROSS_SCALE = 2
local BREAK_END_MARGIN = 1e-6
local VERTICAL_MASK_ROTATION = math.rad(90)

art.LINE_AS_TWO_PIECES = LINE_AS_TWO_PIECES
art.CAP_MAX_LENGTH_SHARE = CAP_MAX_LENGTH_SHARE
art.SHADOW_SPREAD = SHADOW_SPREAD
art.BREAK_END_MARGIN = BREAK_END_MARGIN
art.BREAK_MASK_CROSS_SCALE = BREAK_MASK_CROSS_SCALE
art.BREAK_MASKS_PER_TEXTURE = BREAK_MASKS_PER_TEXTURE
art.VERTICAL_MASK_ROTATION = VERTICAL_MASK_ROTATION
art.DIVIDER_BAR_COLUMNS = DIVIDER_BAR_COLUMNS
art.dividerArtColumns = dividerArtColumns

function art.orientTexture(texture, atlas, horizontal, mirrored, flipped, from, to)
    texture:SetAtlas(atlas, true)
    if not horizontal then
        local width, height = texture:GetSize()
        texture:SetSize(height, width)
    end
    local tlU, tlV, blU, blV, trU, trV, brU, brV
    if horizontal then
        tlU, tlV, blU, blV, trU, trV, brU, brV = 0, 0, 0, 1, 1, 0, 1, 1
    else
        tlU, tlV, blU, blV, trU, trV, brU, brV = 0, 1, 1, 1, 0, 0, 1, 0
    end
    if mirrored then
        tlU, blU, trU, brU = 1 - tlU, 1 - blU, 1 - trU, 1 - brU
    end
    if flipped then
        tlV, blV, trV, brV = 1 - tlV, 1 - blV, 1 - trV, 1 - brV
    end
    if from then
        local span = to - from
        tlU, blU, trU, brU = from + span * tlU, from + span * blU, from + span * trU, from + span * brU
    end
    texture:SetTexCoord(tlU, tlV, blU, blV, trU, trV, brU, brV)
end
