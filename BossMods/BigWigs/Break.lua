local addonName, ns = ...

local bigWigs = {}
ns.bigWigs = bigWigs

local MESSAGE_BREAK_START = "BigWigs_StartBreak"
local MESSAGE_BREAK_STOP = "BigWigs_StopBreak"

local receiver = {}

function bigWigs.Enable()
    local loader = _G.BigWigsLoader
    if not loader or not loader.RegisterMessage then
        return
    end
    loader.RegisterMessage(receiver, MESSAGE_BREAK_START, function(_, _, seconds, initiator, _, _, text, icon)
        if issecretvalue(initiator) then
            initiator = nil
        end
        ns.breakTimer.Start(seconds, text, icon, initiator, initiator and UnitGUID(initiator) or nil)
    end)
    loader.RegisterMessage(receiver, MESSAGE_BREAK_STOP, function()
        ns.breakTimer.Stop()
    end)
end
