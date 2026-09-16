local addonName, TB = ...
local button = CreateFrame('Button', 'TinkerBoxMinimapButton', Minimap)
button:SetSize(31, 31)
button:SetFrameStrata('MEDIUM')
button:SetFrameLevel(8)
button:SetMovable(true)
button:RegisterForDrag('LeftButton')
button:EnableMouse(true)

local icon = button:CreateTexture(nil, 'ARTWORK')
icon:SetSize(22, 22)
icon:SetPoint('CENTER', 0, 1)
icon:SetTexture('Interface\\AddOns\\TinkerBox\\Assets\\MinimapIcon')
icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

local overlay = button:CreateTexture(nil, 'OVERLAY')
overlay:SetSize(53, 53)
overlay:SetPoint('TOPLEFT', 0, 0)
overlay:SetTexture('Interface\\Minimap\\MiniMap-TrackingBorder')
button:SetHighlightTexture('Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight')

local function updatePosition()
    if not TinkerBoxDB or TinkerBoxDB.minimapPos == nil then return end
    local angle = math.rad(TinkerBoxDB.minimapPos)
    button:ClearAllPoints()
    button:SetPoint('CENTER', Minimap, 'CENTER', math.cos(angle) * 80, math.sin(angle) * 80)
end

button:SetScript('OnEnter', function(self)
    GameTooltip:SetOwner(self, 'ANCHOR_LEFT')
    GameTooltip:AddLine('|cffffd75eTinkerBox|r')
    GameTooltip:AddLine('Linksklick: Öffnen / Schließen', 1, 1, 1)
    GameTooltip:AddLine('Ziehen: Position am Minimap-Rand ändern', 0.8, 0.8, 0.8)
    GameTooltip:Show()
end)

button:SetScript('OnLeave', function()
    GameTooltip:Hide()
end)

button:SetScript('OnDragStart', function(self)
    self:SetScript('OnUpdate', function()
        local xpos, ypos = GetCursorPosition()
        local xmin, ymin = Minimap:GetCenter()
        xpos = xpos / self:GetEffectiveScale() - xmin
        ypos = ypos / self:GetEffectiveScale() - ymin
        TinkerBoxDB.minimapPos = math.deg(math.atan2(ypos, xpos))
        updatePosition()
    end)
end)

button:SetScript('OnDragStop', function(self)
    self:SetScript('OnUpdate', nil)
end)

button:SetScript('OnClick', function()
    if TB.UI.mainFrame:IsShown() then
        TB.UI.mainFrame:Hide()
    else
        TB.UI.mainFrame:Show()
        TB.ShowModule('Home')
    end
end)

TB.Minimap = { UpdatePosition = updatePosition }
