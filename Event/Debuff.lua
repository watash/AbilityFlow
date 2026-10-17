local addonName, ns = ...

local debuff = {}
ns.debuff = debuff

debuff.TYPES = {
    { key = "ENRAGE", mask = 2, color = { r = 0.5, g = 0, b = 0, a = 1 }, frameAtlas = "UI-HUD-CoolDownManager-Debuff-Default" },
    { key = "BLEED", mask = 4, color = { r = 1, g = 0, b = 0, a = 1 }, frameAtlas = "UI-HUD-CoolDownManager-Debuff-Bleed" },
    { key = "MAGIC", mask = 8, color = { r = 0, g = 0.5, b = 1, a = 1 }, frameAtlas = "UI-HUD-CoolDownManager-Debuff-Magic" },
    { key = "DISEASE", mask = 16, color = { r = 1, g = 0.5, b = 0, a = 1 }, frameAtlas = "UI-HUD-CoolDownManager-Debuff-Disease" },
    { key = "CURSE", mask = 32, color = { r = 0.5, g = 0, b = 1, a = 1 }, frameAtlas = "UI-HUD-CoolDownManager-Debuff-Curse" },
    { key = "POISON", mask = 64, color = { r = 0, g = 1, b = 0, a = 1 }, frameAtlas = "UI-HUD-CoolDownManager-Debuff-Poison" },
}

debuff.MAGIC_MASK = 8

function debuff.ColorOf(key)
    for _, entry in ipairs(debuff.TYPES) do
        if entry.key == key then
            return entry.color
        end
    end
    return nil
end

function debuff.FrameAtlasOf(key)
    for _, entry in ipairs(debuff.TYPES) do
        if entry.key == key then
            return entry.frameAtlas
        end
    end
    return nil
end

function debuff.FindType(mask)
    for _, entry in ipairs(debuff.TYPES) do
        if bit.band(mask, entry.mask) ~= 0 then
            return entry
        end
    end
    return nil
end
