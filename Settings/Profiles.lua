local addonName, ns = ...

local pairs = pairs
local ipairs = ipairs
local type = type
local strtrim = strtrim
local strlenutf8 = strlenutf8
local next = next
local CopyTable = CopyTable
local GetRealmName = GetRealmName
local UnitName = UnitName
local sort = table.sort
local L = ns.L

local profiles = {}
ns.profiles = profiles

profiles.DEFAULT = "Default"
profiles.MAX_NAME_LENGTH = 24
profiles.MAX_SPECS = 4
local CONTINUATION_FIRST = 128
local CONTINUATION_LAST = 191

local DEFAULT = profiles.DEFAULT

local listeners = {}
local characterKey
local chosenName, chosenData

local fillers = {}
profiles.NEW_VALUES = {}

local function database()
    AbilityFlowDB.profiles = AbilityFlowDB.profiles or {}
    AbilityFlowDB.profileOf = AbilityFlowDB.profileOf or {}
    local all = AbilityFlowDB.profiles
    if not all[DEFAULT] then
        all[DEFAULT] = {}
    end
    return all, AbilityFlowDB.profileOf
end

local function specChoices()
    AbilityFlowDB.specProfiles = AbilityFlowDB.specProfiles or {}
    return AbilityFlowDB.specProfiles
end

profiles.ActiveSpec = function()
    return 0
end

local function ownKey()
    characterKey = characterKey or ((UnitName("player") or "") .. "-" .. (GetRealmName() or ""))
    return characterKey
end

local function resolve()
    if not chosenData then
        local all, of = database()
        local name = of[ownKey()]
        if not name or not all[name] then
            name = DEFAULT
        end
        chosenName, chosenData = name, all[name]
        profiles.Complete(chosenData)
    end
    return chosenData
end

function profiles.FillMissing(target, defaults)
    for key, default in pairs(defaults) do
        if target[key] == nil then
            target[key] = type(default) == "table" and CopyTable(default) or default
        elseif type(default) == "table" and type(target[key]) == "table" then
            profiles.FillMissing(target[key], default)
        end
    end
end

function profiles.OnComplete(filler)
    fillers[#fillers + 1] = filler
end

local function putValues(target, values)
    for key, value in pairs(values) do
        if type(value) == "table" and type(target[key]) == "table" then
            putValues(target[key], value)
        elseif type(value) == "table" then
            target[key] = CopyTable(value)
        else
            target[key] = value
        end
    end
end

profiles.Put = putValues

function profiles.Complete(data)
    local isNew = next(data) == nil
    for _, filler in ipairs(fillers) do
        filler(data)
    end
    if isNew then
        putValues(data, profiles.NEW_VALUES)
    end
    return data
end

local function notify()
    for _, listener in ipairs(listeners) do
        listener()
    end
end

function profiles.OnChanged(listener)
    listeners[#listeners + 1] = listener
end

function profiles.Current()
    return resolve()
end

function profiles.CurrentName()
    resolve()
    return chosenName
end

function profiles.DisplayName(name)
    return name == DEFAULT and L.PROFILE_DEFAULT or name
end

function profiles.IsDefault(name)
    return name == DEFAULT
end

function profiles.Names()
    local names = {}
    for name in pairs((database())) do
        if name ~= DEFAULT then
            names[#names + 1] = name
        end
    end
    sort(names, function(first, second)
        return first:lower() < second:lower()
    end)
    table.insert(names, 1, DEFAULT)
    return names
end

function profiles.CheckName(text, except)
    local name = strtrim(text or "")
    if name == "" then
        return nil, "PROFILE_ERROR_EMPTY"
    elseif strlenutf8(name) > profiles.MAX_NAME_LENGTH then
        return nil, "PROFILE_ERROR_LONG"
    end
    local lowered = name:lower()
    for taken in pairs((database())) do
        if taken ~= except and (taken:lower() == lowered or profiles.DisplayName(taken):lower() == lowered) then
            return nil, "PROFILE_ERROR_EXISTS"
        end
    end
    return name
end

local function cutToLength(text, length)
    while strlenutf8(text) > length do
        local last = #text
        while last > 1 and text:byte(last) >= CONTINUATION_FIRST and text:byte(last) <= CONTINUATION_LAST do
            last = last - 1
        end
        text = text:sub(1, last - 1)
    end
    return text
end

function profiles.SuggestName(base)
    local number = 1
    local name = cutToLength(base, profiles.MAX_NAME_LENGTH)
    while not profiles.CheckName(name) do
        number = number + 1
        local suffix = " (" .. number .. ")"
        name = cutToLength(base, profiles.MAX_NAME_LENGTH - strlenutf8(suffix)) .. suffix
    end
    return name
end

function profiles.Create(name, data)
    local all = database()
    all[name] = data or {}
    profiles.Select(name)
end

function profiles.Duplicate(name)
    profiles.Create(name, CopyTable(resolve()))
end

function profiles.Select(name)
    local all, of = database()
    if not all[name] then
        return
    end
    of[ownKey()] = name
    local spec = profiles.ActiveSpec()
    local own = specChoices()[ownKey()]
    if own and own.enabled and spec > 0 then
        own[spec] = name
    end
    chosenName, chosenData = nil, nil
    notify()
end

function profiles.Rename(name, newName)
    local all, of = database()
    if name == DEFAULT or not all[name] or name == newName then
        return
    end
    all[newName] = all[name]
    all[name] = nil
    for character, used in pairs(of) do
        if used == name then
            of[character] = newName
        end
    end
    for _, choices in pairs(specChoices()) do
        for spec = 1, profiles.MAX_SPECS do
            if choices[spec] == name then
                choices[spec] = newName
            end
        end
    end
    chosenName, chosenData = nil, nil
    notify()
end

function profiles.OtherUsers(name)
    local _, of = database()
    local count = 0
    for character, used in pairs(of) do
        if used == name and character ~= ownKey() then
            count = count + 1
        end
    end
    return count
end

function profiles.SpecUsers(name)
    local count = 0
    for _, choices in pairs(specChoices()) do
        for spec = 1, profiles.MAX_SPECS do
            if choices[spec] == name then
                count = count + 1
            end
        end
    end
    return count
end

function profiles.Delete(name)
    local all, of = database()
    if name == DEFAULT or not all[name] then
        return
    end
    all[name] = nil
    for character, used in pairs(of) do
        if used == name then
            of[character] = nil
        end
    end
    for _, choices in pairs(specChoices()) do
        for spec = 1, profiles.MAX_SPECS do
            if choices[spec] == name then
                choices[spec] = DEFAULT
            end
        end
    end
    chosenName, chosenData = nil, nil
    notify()
end

function profiles.SpecEnabled()
    local own = specChoices()[ownKey()]
    return own ~= nil and own.enabled == true
end

function profiles.SetSpecEnabled(enabled)
    local choices = specChoices()
    local own = choices[ownKey()]
    if not own then
        if not enabled then
            return
        end
        own = {}
        choices[ownKey()] = own
    end
    own.enabled = enabled
    if enabled then
        local all = database()
        for spec = 1, profiles.MAX_SPECS do
            if not own[spec] or not all[own[spec]] then
                own[spec] = profiles.CurrentName()
            end
        end
    end
end

function profiles.SpecProfile(spec)
    local own = specChoices()[ownKey()]
    local name = own and own[spec]
    if name and (database())[name] then
        return name
    end
    return profiles.CurrentName()
end

function profiles.SetSpecProfile(spec, name)
    local own = specChoices()[ownKey()]
    if not own or not own.enabled or not (database())[name] then
        return
    end
    own[spec] = name
    if spec == profiles.ActiveSpec() and name ~= profiles.CurrentName() then
        profiles.Select(name)
    end
end

function profiles.ApplySpec()
    local spec = profiles.ActiveSpec()
    local own = specChoices()[ownKey()]
    local name = own and own.enabled and spec > 0 and own[spec]
    if not name or not (database())[name] or name == profiles.CurrentName() then
        return false
    end
    profiles.Select(name)
    return true
end

function profiles.Matches(value, pattern)
    if type(value) ~= type(pattern) then
        return false
    end
    if type(pattern) == "table" then
        for key, part in pairs(pattern) do
            if not profiles.Matches(value[key], part) then
                return false
            end
        end
    end
    return true
end
