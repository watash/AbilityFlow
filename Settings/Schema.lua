local addonName, ns = ...

local pairs = pairs

local schema = {}
ns.schema = schema

schema.VERSION = 1

schema.DATABASE_STEPS = {}
schema.PROFILE_STEPS = {}
local DATABASE_STEPS = schema.DATABASE_STEPS
local PROFILE_STEPS = schema.PROFILE_STEPS

function schema.UpgradeProfile(values, from)
    for version = from + 1, schema.VERSION do
        local step = PROFILE_STEPS[version]
        if step then
            step(values)
        end
    end
end

function schema.Upgrade(database)
    local from = database.version
    if from == nil then
        database.version = schema.VERSION
        return true
    end
    if from > schema.VERSION then
        return false
    end
    for version = from + 1, schema.VERSION do
        local step = DATABASE_STEPS[version]
        if step then
            step(database)
        end
        local profileStep = PROFILE_STEPS[version]
        if profileStep and database.profiles then
            for _, values in pairs(database.profiles) do
                profileStep(values)
            end
        end
        database.version = version
    end
    return true
end
