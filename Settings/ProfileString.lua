local addonName, ns = ...

local pcall = pcall
local type = type
local strtrim = strtrim
local CopyTable = CopyTable
local C_EncodingUtil = C_EncodingUtil
local profiles = ns.profiles

local MARKER = "ABFLOW1:"
local FORMAT_NAME = "profile"

function profiles.Export(withTrack)
    local payload = {
        format = FORMAT_NAME,
        version = ns.schema.VERSION,
        name = profiles.DisplayName(profiles.CurrentName()),
        values = CopyTable(profiles.Current()),
    }
    local layoutName = ns.timeline.ActiveLayoutName()
    if layoutName and withTrack ~= false then
        payload.track = ns.values.Snapshot(layoutName, true)
    end
    local serialized = C_EncodingUtil.SerializeCBOR(payload)
    return MARKER .. C_EncodingUtil.EncodeBase64(C_EncodingUtil.CompressString(serialized))
end

function profiles.Decode(text)
    text = text and text:gsub("%s", "") or ""
    if text:sub(1, #MARKER) ~= MARKER then
        return nil, "PROFILE_ERROR_IMPORT"
    end
    local ok, decoded = pcall(C_EncodingUtil.DecodeBase64, text:sub(#MARKER + 1))
    if ok then
        ok, decoded = pcall(C_EncodingUtil.DecompressString, decoded)
    end
    if ok then
        ok, decoded = pcall(C_EncodingUtil.DeserializeCBOR, decoded)
    end
    if not ok or type(decoded) ~= "table" or decoded.format ~= FORMAT_NAME or type(decoded.values) ~= "table" then
        return nil, "PROFILE_ERROR_IMPORT"
    end
    if type(decoded.version) ~= "number" or decoded.version > ns.schema.VERSION then
        return nil, "PROFILE_ERROR_VERSION"
    end
    ns.schema.UpgradeProfile(decoded.values, decoded.version)
    local track = type(decoded.track) == "table" and ns.values.Sanitize(decoded.track) or nil
    local name = type(decoded.name) == "string" and strtrim(decoded.name) or nil
    return ns.appearance.Sanitize(decoded.values), track and next(track) and track or nil, name ~= "" and name or nil
end
