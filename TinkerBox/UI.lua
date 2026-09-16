local addonName, TB = ...

-- Der Haupt-Frame im Spritesheet enthält bereits Titel, Rahmen und X-Button.
-- Deshalb wird nichts davon noch einmal darüber gezeichnet.
local mainFrame = CreateFrame('Frame', 'TinkerBoxMainFrame', UIParent)
mainFrame:SetSize(985, 606)
mainFrame:SetPoint('CENTER', UIParent, 'CENTER', 0, 0)
mainFrame:SetMovable(true)
mainFrame:EnableMouse(true)
mainFrame:RegisterForDrag('LeftButton')
mainFrame:SetScript('OnDragStart', mainFrame.StartMoving)
mainFrame:SetScript('OnDragStop', mainFrame.StopMovingOrSizing)
mainFrame:Hide()
TB.UI.mainFrame = mainFrame

local bg = mainFrame:CreateTexture(nil, 'BACKGROUND')
bg:SetAllPoints(mainFrame)
TB.ApplyAsset(bg, TB.Assets.MainFrame, 'MainFrame')
TB.UI.bg = bg

local scale = (TinkerBoxDB and TinkerBoxDB.settings and TinkerBoxDB.settings.uiScale) or 0.82
mainFrame:SetScale(scale)

-- Unsichtbare Klickfläche über dem bereits im Rahmen enthaltenen roten X.
local closeBtn = CreateFrame('Button', nil, mainFrame)
closeBtn:SetSize(58, 58)
closeBtn:SetPoint('TOPRIGHT', mainFrame, 'TOPRIGHT', -10, -40)
closeBtn:SetScript('OnClick', function() mainFrame:Hide() end)
closeBtn:SetScript('OnEnter', function(self) self:SetAlpha(0.92) end)
closeBtn:SetScript('OnLeave', function(self) self:SetAlpha(1) end)
TB.UI.closeBtn = closeBtn

-- Rechte Inhaltsfläche: exakt innerhalb des großen blauen Panels.
local contentArea = CreateFrame('Frame', nil, mainFrame)
contentArea:SetPoint('TOPLEFT', mainFrame, 'TOPLEFT', 255, -112)
contentArea:SetPoint('BOTTOMRIGHT', mainFrame, 'BOTTOMRIGHT', -52, 58)
TB.UI.contentArea = contentArea

-- Linke Navigationsspalte.
local navArea = CreateFrame('Frame', nil, mainFrame)
navArea:SetPoint('TOPLEFT', mainFrame, 'TOPLEFT', 40, -105)
navArea:SetSize(198, 438)
TB.UI.navArea = navArea


local navData = {
    {'Home', 'Home'},
    {'FarmTracker', 'FarmTracker'},
    {'CraftingList', 'CraftingList'},
    {'GoldTracker', 'GoldKasse'},
    {'Zusatzinfos', 'Zusatzinfos'},
    {'TinkerNotes', 'TinkerNotes'},
}

local function PositionNavContent(btn)
    btn.icon:ClearAllPoints()
    btn.text:ClearAllPoints()

    -- Einheitliche Innenausrichtung für aktive, inaktive und Hover-Zustände.
    -- So springt beim Wechsel nichts mehr.
    btn.icon:SetPoint('LEFT', btn, 'LEFT', 18, -5)
    btn.text:SetPoint('LEFT', btn, 'LEFT', 56, -4)
end

local function SetButtonState(btn, active, hovered)
    if active then
        TB.ApplyAsset(btn.bg, TB.Assets.MenuActive, 'MenuActive')
        btn.bg:SetAlpha(0.95)
        btn.text:SetTextColor(1.00, 0.86, 0.25)
        btn.icon:SetAlpha(1)
        PositionNavContent(btn)
    elseif hovered then
        TB.ApplyAsset(btn.bg, TB.Assets.MenuActive, 'MenuActive')
        btn.bg:SetAlpha(0.72)
        btn.text:SetTextColor(1.00, 0.92, 0.55)
        btn.icon:SetAlpha(1)
        PositionNavContent(btn)
    else
        TB.ApplyAsset(btn.bg, TB.Assets.MenuIdle, 'MenuIdle')
        btn.bg:SetAlpha(0.34)
        btn.text:SetTextColor(0.86, 0.90, 0.96)
        btn.icon:SetAlpha(0.90)
        PositionNavContent(btn)
    end
end

local function CreateNavButton(key, label, y)
    local btn = CreateFrame('Button', nil, navArea)
    btn:SetSize(186, 50)
    btn:SetPoint('TOP', navArea, 'TOP', 0, y)
    btn.key = key

    local bg = btn:CreateTexture(nil, 'BACKGROUND')
    bg:SetAllPoints(btn)
    btn.bg = bg

    local icon = btn:CreateTexture(nil, 'ARTWORK')
    icon:SetSize(30, 30)
    icon:SetPoint('LEFT', btn, 'LEFT', 18, -5)
    TB.ApplyAsset(icon, TB.Assets.Nav[key], key)
    btn.icon = icon

    local text = btn:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')
    text:SetPoint('LEFT', btn, 'LEFT', 56, -4)
    text:SetWidth(118)
    text:SetJustifyH('LEFT')
    text:SetFont('Fonts\\FRIZQT__.TTF', 16, 'OUTLINE')
    text:SetShadowColor(0, 0, 0, 1)
    text:SetShadowOffset(1, -1)
    text:SetText(label)
    btn.text = text

    btn:SetScript('OnEnter', function(self)
        if TB.UI.activeNav ~= self.key then SetButtonState(self, false, true) end
    end)
    btn:SetScript('OnLeave', function(self)
        SetButtonState(self, TB.UI.activeNav == self.key, false)
    end)
    btn:SetScript('OnClick', function(self)
        TB.ShowModule(self.key)
    end)

    SetButtonState(btn, false, false)
    TB.UI.navButtons[key] = btn
    return btn
end

TB.UI.navButtons = {}
for i, data in ipairs(navData) do
    CreateNavButton(data[1], data[2], -((i - 1) * 54))
end

-- Einstellungen bewusst getrennt unten: gehört zur App, aber nicht zum normalen Arbeitsablauf.
local settingsDivider = navArea:CreateTexture(nil, 'ARTWORK')
settingsDivider:SetSize(174, 18)
settingsDivider:SetPoint('BOTTOM', navArea, 'BOTTOM', 0, 70)
TB.ApplyAsset(settingsDivider, TB.Assets.DividerMenu, 'DividerMenu')
settingsDivider:SetAlpha(0.92)

CreateNavButton('Settings', 'Einstellungen', -396)

function TB.UI.SetActiveNav(key)
    TB.UI.activeNav = key
    for navKey, btn in pairs(TB.UI.navButtons) do
        SetButtonState(btn, navKey == key, false)
    end
end

-- Kompatibilitätsobjekte: Module aus 2.1 dürfen die beiden Felder noch ansprechen,
-- sie werden aber nicht sichtbar gerendert und erzeugen somit keinen doppelten Titel.
local hiddenHeader = mainFrame:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')
hiddenHeader:Hide()
local hiddenSub = mainFrame:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')
hiddenSub:Hide()
TB.UI.headerText = hiddenHeader
TB.UI.subText = hiddenSub
