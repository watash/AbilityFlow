local addonName, ns = ...

local bossMods = {}
ns.bossMods = bossMods

local BIGWIGS = "BigWigs"
local DBM = "DBM"
bossMods.BIGWIGS = BIGWIGS
bossMods.DBM = DBM

function bossMods.Active()
    if ns.bigWigsNames.IsAvailable() then
        return BIGWIGS
    end
    if ns.dbmNames.IsAvailable() then
        return DBM
    end
    return nil
end

function bossMods.DbmLeftOut()
    return ns.bigWigsNames.IsAvailable() and ns.dbmNames.IsAvailable()
end
