local addonName, ns = ...

local CreateFrame = CreateFrame
local C_SpecializationInfo = C_SpecializationInfo
local UnitClass = UnitClass

local profiles = ns.profiles

local specSwitch = {}
ns.specSwitch = specSwitch

local CLASS_ID_RESULT = 3

function specSwitch.NumSpecs()
    local classID = select(CLASS_ID_RESULT, UnitClass("player"))
    local count = classID and C_SpecializationInfo.GetNumSpecializationsForClassID(classID) or 0
    return math.min(count, profiles.MAX_SPECS)
end

function specSwitch.NameAndIcon(spec)
    local _, name, _, icon = C_SpecializationInfo.GetSpecializationInfo(spec)
    return name, icon
end

profiles.ActiveSpec = function()
    local spec = C_SpecializationInfo.GetSpecialization()
    if not spec or not C_SpecializationInfo.CanPlayerUseTalentUI() or spec > specSwitch.NumSpecs() then
        return 0
    end
    return spec
end

local listener = CreateFrame("Frame")
listener:RegisterUnitEvent("PLAYER_SPECIALIZATION_CHANGED", "player")
listener:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
listener:RegisterEvent("PLAYER_ENTERING_WORLD")
listener:SetScript("OnEvent", function()
    profiles.ApplySpec()
end)
