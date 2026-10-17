local addonName, ns = ...

local ipairs = ipairs
local math = math

local timeline = ns.timeline
local trackPreview = ns.appearanceTrackPreview
local state = trackPreview.state

local DIVIDER_ALPHA = trackPreview.DIVIDER_ALPHA
local PART_GAP = trackPreview.PART.GAP

local function followLine(active, step)
    local move = step / timeline.FadeSeconds()
    if active or not timeline.IsFadeAnimated() then
        state.lineFade = math.min(state.lineFade + move, 1)
    else
        state.lineFade = math.max(state.lineFade - move, 0)
    end
    local alpha = state.lineFade * state.lineFade
    for _, half in ipairs(state.halves) do
        half.texture:SetAlpha(alpha)
    end
    for _, divider in ipairs(state.dividers) do
        divider:SetAlpha(DIVIDER_ALPHA * alpha)
    end
    state.plainBackground:SetAlpha(alpha)
    state.plainBorder:SetAlpha(alpha)
end

function trackPreview.Play(step)
    local wanted = timeline.EntersFromStart() and 1 or -1
    if wanted ~= state.direction then
        state.direction = wanted
        trackPreview.StyleIcons()
    end
    if timeline.IsBlizzlikeBackdrop() ~= state.laidOutBlizzlike then
        trackPreview.LayoutTrack()
        if trackPreview.onLookChanged then
            trackPreview.onLookChanged()
        end
    end
    state.sceneTime = state.sceneTime + step
    local roundSeconds, lagSeconds, totalSeconds = state.roundSeconds, state.lagSeconds, state.totalSeconds
    local round = math.floor(state.sceneTime / roundSeconds)
    local clock = state.sceneTime - round * roundSeconds
    local busy = false
    for index, actor in ipairs(state.actors) do
        local time = clock - (index - 1) * lagSeconds
        if time >= 0 and time < totalSeconds then
            trackPreview.DrawActor(actor, time, round % 2 == 1, step)
            busy = busy or time < state.starts[PART_GAP]
        else
            trackPreview.HideActor(actor)
        end
    end
    followLine(busy, step)
end

function trackPreview.Restart()
    state.paused = false
    state.sceneTime = 0
    state.lineFade = timeline.IsFadeAnimated() and 0 or 1
    state.direction = timeline.EntersFromStart() and 1 or -1
    trackPreview.StyleIcons()
    trackPreview.Play(0)
end
