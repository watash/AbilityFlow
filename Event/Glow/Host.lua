local addonName, ns = ...

local CreateFrame = CreateFrame

local glow = ns.glow

local FULL_SIZE = glow.FULL_SHARE

local hosts = setmetatable({}, { __mode = "k" })

function glow.surroundingScale(frame)
    local parent = frame:GetParent()
    return (parent or frame):GetEffectiveScale() * frame:GetScale()
end

function glow.FrameSize(frame)
    if frame.glowSize then
        return frame.glowSize()
    end
    return frame:GetWidth(), frame:GetHeight()
end

function glow.host(frame, percent, shiftShare)
    local parent = frame:GetParent() or frame
    local host = hosts[frame]
    if not host then
        host = CreateFrame("Frame", nil, parent)
        hosts[frame] = host
    end
    host:SetFrameLevel(frame:GetFrameLevel())
    host:SetAlpha(1)
    local frameScale = frame:GetScale()
    host:SetScale(percent / FULL_SIZE)
    local width, height = glow.FrameSize(frame)
    host:SetSize(width * frameScale, height * frameScale)
    host:ClearAllPoints()
    host:SetPoint("CENTER", frame, "CENTER", (shiftShare or 0) * width * frameScale, 0)
    return host
end
