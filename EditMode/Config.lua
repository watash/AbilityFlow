local addonName, ns = ...

local strlenutf8 = strlenutf8

local timeline = ns.timeline
local values = ns.values
local media = ns.media
local L = ns.L
local editMode = LibStub("LibEditMode")

local config = {}
ns.editModeConfig = config

local TRACK_LENGTH_STEP = 1
local TRACK_WIDTH_STEP = 1
local EVENT_SCALE_STEP = 5
local WAITING_GAP_STEP = 1
local WAITING_TRANSPARENCY_STEP = 1
local OVERALL_TRANSPARENCY_STEP = 1
local MARK_SCALE_STEP = 5
local BORDER_OFFSET_STEP = 1
local BORDER_THICKNESS_STEP = 1

local TOOLTIP_LINE_CHARS = 30

local function wrapText(text)
    local lines = {}
    for paragraph in text:gmatch("[^\n]+") do
        local line = ""
        for word in paragraph:gmatch("%S+") do
            if line ~= "" and strlenutf8(line) + 1 + strlenutf8(word) > TOOLTIP_LINE_CHARS then
                lines[#lines + 1] = line
                line = word
            else
                line = line == "" and word or (line .. " " .. word)
            end
        end
        lines[#lines + 1] = line
    end
    return table.concat(lines, "\n")
end

local function percentFormatter()
    return function(value)
        return ("%d%%"):format(value)
    end
end

local function numberFormatter()
    return function(value)
        return ("%d"):format(value)
    end
end

local function isActive(layoutName)
    return layoutName == editMode:GetActiveLayoutName()
end

local function blizzlikeOn(layoutName)
    return values.Get("blizzlikeBackdrops", layoutName)
end

local COLOR_CODEC = {
    decode = function(color)
        return CreateColor(color.r, color.g, color.b, color.a)
    end,
    encode = function(color)
        local red, green, blue, alpha = color:GetRGBA()
        return { r = red, g = green, b = blue, a = alpha }
    end,
}

local function bound(callbacks, key, setting, apply, codec)
    if setting.desc then
        setting.desc = wrapText(setting.desc)
    end
    if setting.default == nil then
        setting.default = values.Default(key)
    end
    setting.get = function(layoutName)
        local saved = values.Get(key, layoutName)
        if codec then
            return codec.decode(saved)
        end
        return saved
    end
    setting.set = function(layoutName, shown)
        local saved = shown
        if codec then
            saved = codec.encode(shown)
        end
        values.Set(key, layoutName, saved)
        callbacks.refresh()
        if isActive(layoutName) then
            apply(saved, layoutName)
        end
    end
    return setting
end

local function geometrySettings(callbacks)
    return {
        bound(callbacks, "trackOrientations", {
            kind = editMode.SettingType.Dropdown,
            name = _G.HUD_EDIT_MODE_SETTING_ENCOUNTER_EVENTS_ORIENTATION or L.ORIENTATION,
            desc = L.ORIENTATION_DESC,
            values = {
                { text = _G.HUD_EDIT_MODE_SETTING_ENCOUNTER_EVENTS_ORIENTATION_VERTICAL or L.ORIENTATION_VERTICAL,
                    value = timeline.ORIENTATION_VERTICAL },
                { text = _G.HUD_EDIT_MODE_SETTING_ENCOUNTER_EVENTS_ORIENTATION_HORIZONTAL or L.ORIENTATION_HORIZONTAL,
                    value = timeline.ORIENTATION_HORIZONTAL },
            },
        }, function(value, layoutName)
            timeline.SetOrientation(value)
            timeline.SetDirection(values.Direction(layoutName))
            callbacks.resetChanged()
        end),
        bound(callbacks, "trackDirections", {
            kind = editMode.SettingType.Checkbox,
            name = L.INVERT_DIRECTION,
            default = false,
        }, function(_, layoutName)
            timeline.SetDirection(values.Direction(layoutName))
        end, {
            decode = function(direction)
                return direction == 2
            end,
            encode = function(inverted)
                return inverted and 2 or 1
            end,
        }),
        bound(callbacks, "trackLengths", {
            kind = editMode.SettingType.Slider,
            name = L.TRACK_LENGTH,
            minValue = values.RangeMin("trackLengths"),
            maxValue = values.RangeMax("trackLengths"),
            valueStep = TRACK_LENGTH_STEP,
            formatter = numberFormatter(),
        }, function(value)
            timeline.SetTrackLength(value)
            callbacks.resetChanged()
        end),
        bound(callbacks, "trackWidths", {
            kind = editMode.SettingType.Slider,
            name = L.TRACK_WIDTH,
            minValue = values.RangeMin("trackWidths"),
            maxValue = values.RangeMax("trackWidths"),
            valueStep = TRACK_WIDTH_STEP,
            formatter = numberFormatter(),
        }, function(value)
            timeline.SetTrackWidth(value)
            callbacks.resetChanged()
        end),
    }
end

local function trackLookSettings(callbacks)
    return {
        bound(callbacks, "iconScales", {
            kind = editMode.SettingType.Slider,
            name = L.EVENT_SCALE,
            minValue = values.RangeMin("iconScales"),
            maxValue = values.RangeMax("iconScales"),
            valueStep = EVENT_SCALE_STEP,
            formatter = percentFormatter(),
        }, function(value)
            timeline.SetEventScale(value)
        end),
        bound(callbacks, "tooltipAnchors", {
            kind = editMode.SettingType.Dropdown,
            name = _G.HUD_EDIT_MODE_SETTING_ENCOUNTER_EVENTS_TOOLTIPS or L.TOOLTIPS,
            values = function()
                return {
                    { text = _G.HUD_EDIT_MODE_SETTING_ENCOUNTER_EVENTS_TOOLTIPS_NONE or L.NONE, value = timeline.TOOLTIP_HIDDEN },
                    { text = _G.HUD_EDIT_MODE_SETTING_ENCOUNTER_EVENTS_TOOLTIPS_HUD or L.TOOLTIPS_DEFAULT, value = timeline.TOOLTIP_DEFAULT },
                    { text = _G.HUD_EDIT_MODE_SETTING_ENCOUNTER_EVENTS_TOOLTIPS_CURSOR or L.TOOLTIPS_CURSOR, value = timeline.TOOLTIP_CURSOR },
                }
            end,
        }, function(value)
            timeline.SetTooltipAnchor(value)
        end),
        bound(callbacks, "waitingGaps", {
            kind = editMode.SettingType.Slider,
            name = L.WAITING_GAP,
            desc = L.WAITING_GAP_DESC,
            minValue = values.RangeMin("waitingGaps"),
            maxValue = values.RangeMax("waitingGaps"),
            valueStep = WAITING_GAP_STEP,
            formatter = percentFormatter(),
        }, function(value)
            timeline.SetWaitingGap(value)
        end),
        bound(callbacks, "waitingTransparencies", {
            kind = editMode.SettingType.Slider,
            name = L.WAITING_TRANSPARENCY,
            desc = L.WAITING_TRANSPARENCY_DESC,
            minValue = values.RangeMin("waitingTransparencies"),
            maxValue = values.RangeMax("waitingTransparencies"),
            valueStep = WAITING_TRANSPARENCY_STEP,
            formatter = percentFormatter(),
        }, function(value)
            timeline.SetWaitingTransparency(value)
        end),
    }
end

local function markSettings(callbacks)
    local settings = {
        bound(callbacks, "markStyles", {
            kind = editMode.SettingType.Dropdown,
            name = L.MARK_STYLE,
            desc = L.MARK_STYLE_DESC,
            values = function()
                return {
                    { text = L.NONE, value = timeline.MARK_NONE },
                    { text = L.EVENT_APPEARANCE_ELEMENT_ICON, value = timeline.MARK_ICON },
                    { text = L.MARK_ICON_TEXT, value = timeline.MARK_ICON_TEXT },
                    { text = L.MARK_BAR, value = timeline.MARK_BAR },
                    { text = L.MARK_BAR_TEXT, value = timeline.MARK_BAR_TEXT },
                    { text = L.MARK_ICON_BAR, value = timeline.MARK_ICON_BAR },
                    { text = L.MARK_ALL, value = timeline.MARK_ALL },
                }
            end,
        }, function(value)
            timeline.SetMarkStyle(value)
        end),
        bound(callbacks, "markSteps", {
            kind = editMode.SettingType.Dropdown,
            name = L.MARK_STEP,
            values = {
                { text = L.MARK_STEP_SINGLE, value = timeline.MARK_STEP_SINGLE },
                { text = L.MARK_STEP_EVERY:format(5), value = 5 },
                { text = L.MARK_STEP_EVERY:format(10), value = 10 },
            },
        }, function(value)
            timeline.SetMarkStep(value)
        end),
        bound(callbacks, "markScales", {
            kind = editMode.SettingType.Slider,
            name = L.MARK_SCALE,
            minValue = values.RangeMin("markScales"),
            maxValue = values.RangeMax("markScales"),
            valueStep = MARK_SCALE_STEP,
            formatter = percentFormatter(),
        }, function(value)
            timeline.SetMarkScale(value)
        end),
    }
    return settings
end

local function overallSettings(callbacks)
    return {
        bound(callbacks, "overallTransparencies", {
            kind = editMode.SettingType.Slider,
            name = L.OVERALL_TRANSPARENCY,
            desc = L.OVERALL_TRANSPARENCY_DESC,
            minValue = values.RangeMin("overallTransparencies"),
            maxValue = values.RangeMax("overallTransparencies"),
            valueStep = OVERALL_TRANSPARENCY_STEP,
            formatter = percentFormatter(),
        }, function(value)
            timeline.SetOverallTransparency(value)
        end),
    }
end

local LOOK_PLAIN = "PLAIN"
local LOOK_BLIZZLIKE = "BLIZZLIKE"

local function backdropSettings(callbacks)
    return {
        bound(callbacks, "blizzlikeBackdrops", {
            kind = editMode.SettingType.Dropdown,
            name = L.BACKGROUND_STYLE,
            desc = L.BACKGROUND_STYLE_DESC,
            default = LOOK_BLIZZLIKE,
            values = {
                { text = L.BACKGROUND_STYLE_BLIZZLIKE, value = LOOK_BLIZZLIKE },
                { text = L.BACKGROUND_STYLE_PLAIN, value = LOOK_PLAIN },
            },
        }, function(value)
            timeline.SetBlizzlikeBackdrop(value)
            editMode:RefreshFrameSettings(timeline.frame)
        end, {
            decode = function(blizzlike)
                return blizzlike and LOOK_BLIZZLIKE or LOOK_PLAIN
            end,
            encode = function(look)
                return look == LOOK_BLIZZLIKE
            end,
        }),
        bound(callbacks, "backgroundColors", {
            kind = editMode.SettingType.ColorPicker,
            name = L.BACKGROUND_COLOR,
            default = COLOR_CODEC.decode(values.Default("backgroundColors")),
            hasOpacity = true,
        }, function(color)
            timeline.SetBackgroundColor(color.r, color.g, color.b, color.a)
        end, COLOR_CODEC),
    }
end

local function plainBackgroundSettings(callbacks)
    local function offWithBlizzlike(layoutName)
        return blizzlikeOn(layoutName)
    end
    local function offWithoutBorder(layoutName)
        return blizzlikeOn(layoutName) or values.Get("borderTextures", layoutName) == media.NONE
    end
    local function offReason(layoutName)
        if blizzlikeOn(layoutName) then
            return wrapText(L.DISABLED_NEEDS_SIMPLE)
        end
        return wrapText(L.DISABLED_NEEDS_BORDER)
    end
    local function applyBorder(_, layoutName)
        values.ApplyBorder(layoutName)
    end

    return {
        bound(callbacks, "backgroundTextures", {
            kind = editMode.SettingType.Dropdown,
            name = L.BACKGROUND_TEXTURE,
            disabled = offWithBlizzlike,
            disabledReason = offReason,
            values = media.BackgroundOptions,
            height = media.MENU_MAX_HEIGHT,
        }, function(_, layoutName)
            timeline.SetBackgroundTexture(values.BackgroundPath(layoutName))
        end),
        bound(callbacks, "borderTextures", {
            kind = editMode.SettingType.Dropdown,
            name = L.BORDER_TEXTURE,
            disabled = offWithBlizzlike,
            disabledReason = offReason,
            values = media.BorderOptions,
            height = media.MENU_MAX_HEIGHT,
        }, applyBorder),
        bound(callbacks, "borderColors", {
            kind = editMode.SettingType.ColorPicker,
            name = L.BORDER_COLOR,
            default = COLOR_CODEC.decode(values.Default("borderColors")),
            hasOpacity = true,
            disabled = offWithoutBorder,
            disabledReason = offReason,
        }, applyBorder, COLOR_CODEC),
        bound(callbacks, "borderThicknesses", {
            kind = editMode.SettingType.Slider,
            name = L.BORDER_THICKNESS,
            disabled = offWithoutBorder,
            disabledReason = offReason,
            minValue = values.RangeMin("borderThicknesses"),
            maxValue = values.RangeMax("borderThicknesses"),
            valueStep = BORDER_THICKNESS_STEP,
        }, applyBorder),
        bound(callbacks, "borderOffsets", {
            kind = editMode.SettingType.Slider,
            name = L.BORDER_OFFSET,
            disabled = offWithoutBorder,
            disabledReason = offReason,
            minValue = values.RangeMin("borderOffsets"),
            maxValue = values.RangeMax("borderOffsets"),
            valueStep = BORDER_OFFSET_STEP,
        }, applyBorder),
    }
end

local function joinSettings(...)
    local all = {}
    for i = 1, select("#", ...) do
        for _, setting in ipairs((select(i, ...))) do
            table.insert(all, setting)
        end
    end
    return all
end

function config.Build(callbacks)
    local divider = { { kind = editMode.SettingType.Divider, name = ns.text.Gold(L.EDIT_MODE_PROFILE_SETTINGS),
        profileDivider = true } }
    return joinSettings(geometrySettings(callbacks), divider, trackLookSettings(callbacks), markSettings(callbacks),
        overallSettings(callbacks), backdropSettings(callbacks), plainBackgroundSettings(callbacks))
end
