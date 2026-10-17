local addonName, ns = ...

local templates = {}
ns.timerTab.templates = templates

templates.state = {
    widgets = {},
    nameSamples = {},
    colorBars = {},
    free = {},
}
local state = templates.state

function templates.Setup(tab)
    state.context = tab
end

function templates.Select(templateID)
    state.context.selected = templateID
    templates.Layout()
    state.context.onSelect(templateID)
end

function templates.Build()
    templates.BuildRow()
    templates.BuildAddButton()
end
