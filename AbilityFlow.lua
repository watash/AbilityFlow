local addonName, ns = ...

local DEFAULT_DEMO_SECONDS = { 8, 9, 14, 26 }

local savedFromNewer = false

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:RegisterEvent("PLAYER_LOGIN")

loader:SetScript("OnEvent", function(self, event, loadedAddon)
    if event == "ADDON_LOADED" and loadedAddon == addonName then
        AbilityFlowDB = AbilityFlowDB or {}
        local isNewDatabase = next(AbilityFlowDB) == nil
        savedFromNewer = not ns.schema.Upgrade(AbilityFlowDB)
        ns.firstRun.Prepare(isNewDatabase)
        ns.timeline.Enable()
        ns.appearance.Apply()
        self:UnregisterEvent("ADDON_LOADED")
    elseif event == "PLAYER_LOGIN" then
        ns.appearance.Apply()
        ns.timeline.EnablePlacement()
        ns.bigWigs.Enable()
        ns.bigWigsColors.Enable()
        ns.bigWigsTimers.Enable()
        ns.bigWigsNames.Enable()
        ns.bigWigsBars.Enable()
        ns.DBM.Enable()
        ns.dbmColors.Enable()
        ns.dbmTimers.Enable()
        ns.dbmNames.Enable()
        ns.dbmBars.Enable()
        ns.respawnName.Enable()
        ns.breakMessages.Enable()
        ns.NSRT.Enable()
        ns.nsrtWindows.Enable()
        ns.firstRun.Start()
        if savedFromNewer then
            print(ns.text.Green(addonName) .. ": " .. ns.L.SAVED_FROM_NEWER)
        end
        self:UnregisterEvent("PLAYER_LOGIN")
    end
end)

SLASH_ABILITYFLOW1 = "/abflow"
SLASH_ABILITYFLOW2 = "/aflow"

local COMMAND_HELP = {
    { usage = "/aflow, /abflow", text = "COMMAND_SETTINGS" },
    { usage = "/abflow test", text = "COMMAND_TEST" },
    { usage = "/abflow help", text = "COMMAND_HELP" },
}

local function printHelp()
    print(ns.text.Green(addonName) .. ": " .. ns.L.GAME_SETTINGS_VERSION:format(C_AddOns.GetAddOnMetadata(addonName, "Version") or ""))
    print(ns.text.Green(addonName) .. ": " .. ns.L.COMMANDS_HEADER)
    for _, entry in ipairs(COMMAND_HELP) do
        print(("  %s - %s"):format(entry.usage, ns.L[entry.text]))
    end
end

SlashCmdList["ABILITYFLOW"] = function(msg)
    local command, argument = msg:match("^(%S*)%s*(.-)$")
    command = command:lower()
    if command == "" or command == "settings" then
        ns.eventAppearance.Toggle()
    elseif command == "help" then
        printHelp()
    elseif command == "test" then
        local seconds = tonumber(argument)
        if argument:lower() == "clear" then
            ns.timeline.ClearDemoEvents()
        elseif argument:lower() == "pause" then
            ns.timeline.ToggleDemoPause()
        else
            ns.timeline.AddDemoEvents(seconds and seconds > 0 and { seconds } or DEFAULT_DEMO_SECONDS)
        end
    elseif ns.debugCommands and ns.debugCommands[command] then
        ns.debugCommands[command](argument)
    elseif command == "status" then
        print(("%s: available=%s enabled=%s cvar=%s"):format(
            ns.text.Green(addonName),
            tostring(C_EncounterTimeline.IsFeatureAvailable()),
            tostring(C_EncounterTimeline.IsFeatureEnabled()),
            tostring(GetCVar("encounterTimelineEnabled"))))
    else
        printHelp()
    end
end
