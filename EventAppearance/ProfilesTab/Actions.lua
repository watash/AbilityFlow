local addonName, ns = ...

local L = ns.L
local profiles = ns.profiles
local dialogs = ns.appearanceDialogs

local actions = {}
ns.profileActions = actions

local function askName(prompt, buttonText, suggested, make)
    dialogs.Prompt(prompt, buttonText, suggested, function(typed)
        local name, problem = profiles.CheckName(typed)
        if name then
            make(name)
        else
            dialogs.Message(L[problem])
        end
    end)
end

function actions.CreateWithLook(preset)
    askName(L.PROFILE_PROMPT_NEW, L.PROFILE_CREATE, profiles.SuggestName(L.PROFILE_NEW_NAME), function(name)
        ns.presets.Create(preset, name)
    end)
end

function actions.Duplicate()
    local base = L.PROFILE_COPY_NAME:format(profiles.DisplayName(profiles.CurrentName()))
    askName(L.PROFILE_PROMPT_COPY, L.PROFILE_DUPLICATE, profiles.SuggestName(base), function(name)
        profiles.Duplicate(name)
    end)
end

function actions.Rename(old)
    if profiles.IsDefault(old) then
        return
    end
    dialogs.Prompt(L.PROFILE_PROMPT_RENAME, L.PROFILE_RENAME, old, function(typed)
        local name, problem = profiles.CheckName(typed, old)
        if name then
            profiles.Rename(old, name)
        else
            dialogs.Message(L[problem])
        end
    end)
end

function actions.DeleteProfile(name)
    if profiles.IsDefault(name) then
        return
    end
    local text = L.PROFILE_CONFIRM_DELETE:format(profiles.DisplayName(name))
    if profiles.OtherUsers(name) > 0 or profiles.SpecUsers(name) > 0 then
        text = text .. "\n\n" .. ns.text.Red(L.PROFILE_CONFIRM_DELETE_USED)
    end
    dialogs.Confirm(text, L.PROFILE_DELETE, function()
        profiles.Delete(name)
    end)
end

function actions.Export()
    local check
    if ns.timeline.ActiveLayoutName() then
        check = {
            text = L.PROFILE_EXPORT_TRACK,
            checked = true,
            onChanged = function(checked)
                return profiles.Export(checked)
            end,
        }
    end
    dialogs.Copy(L.PROFILE_EXPORT_HINT, profiles.Export(), check)
end

local function makeImported(values, track, oldName)
    local suggested = profiles.SuggestName(oldName or L.PROFILE_IMPORTED_NAME)
    askName(L.PROFILE_PROMPT_IMPORTED, L.PROFILE_IMPORT, suggested,
        function(name)
            profiles.Create(name, values)
            if track then
                ns.timeline.ImportTrack(track)
            end
        end)
end

function actions.Import()
    dialogs.Paste(L.PROFILE_PROMPT_IMPORT, L.PROFILE_IMPORT, function(pasted)
        local values, track, oldName = profiles.Decode(pasted)
        if not values then
            dialogs.Message(L[track]:format(addonName))
            return
        end
        local layoutName = track and ns.timeline.ActiveLayoutName()
        if not layoutName then
            makeImported(values, nil, oldName)
            return
        end
        dialogs.Choose(L.PROFILE_IMPORT_TRACK_WARNING:format(layoutName), L.PROFILE_IMPORT_WITH_TRACK,
            L.PROFILE_IMPORT_PROFILE_ONLY, function()
                makeImported(values, track, oldName)
            end, function()
                makeImported(values, nil, oldName)
            end)
    end)
end
