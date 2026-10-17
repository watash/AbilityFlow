local addonName, ns = ...

local store = {}
ns.store = store

local function section(key)
    AbilityFlowDB[key] = AbilityFlowDB[key] or {}
    return AbilityFlowDB[key]
end

function store.Raw(key, layoutName)
    if not layoutName then
        return nil
    end
    return section(key)[layoutName]
end

function store.Get(key, layoutName, default)
    local value = store.Raw(key, layoutName)
    if value == nil then
        return default
    end
    return value
end

function store.Set(key, layoutName, value)
    if layoutName then
        section(key)[layoutName] = value
    end
end
