local addonName, TB = ...

local frame = TB.CreateModuleFrame('FarmTracker')
local MAX_TARGETS = 5

local state = {
    timerRunning = false,
    startTime = nil,
    elapsedTime = 0,
    sessionDrops = 0,
    pickingItem = false,
    currentMaxTargets = 3,
    trackedItemName = '',
    trackedItemIcon = nil,
}

local targetRows = {}
local favoriteRows = {}
local historyRows = {}

local function EnsureDB()
    if type(TinkerBoxDB.farmTracker) ~= 'table' then TinkerBoxDB.farmTracker = {} end
    local db = TinkerBoxDB.farmTracker
    if type(db.trackedItemName) ~= 'string' then db.trackedItemName = '' end
    if db.trackedItemIcon ~= nil and type(db.trackedItemIcon) ~= 'number' then db.trackedItemIcon = nil end
    if type(db.currentMaxTargets) ~= 'number' then db.currentMaxTargets = 3 end
    db.currentMaxTargets = math.max(1, math.min(MAX_TARGETS, math.floor(db.currentMaxTargets + 0.5)))
    if type(db.targets) ~= 'table' then db.targets = {} end
    for i = 1, MAX_TARGETS do
        if type(db.targets[i]) ~= 'table' then db.targets[i] = {name = '', count = 0} end
        if type(db.targets[i].name) ~= 'string' then db.targets[i].name = '' end
        if type(db.targets[i].count) ~= 'number' then db.targets[i].count = 0 end
    end
    if type(db.history) ~= 'table' then db.history = {} end
    if type(db.favorites) ~= 'table' then db.favorites = {} end
    return db
end

local function FormatTime(seconds)
    seconds = math.max(0, math.floor(tonumber(seconds) or 0))
    local mins = math.floor(seconds / 60)
    local secs = seconds % 60
    if mins >= 60 then
        local hours = math.floor(mins / 60)
        mins = mins % 60
        return string.format('%dh %02dm %02ds', hours, mins, secs)
    end
    return string.format('%dm %02ds', mins, secs)
end

local function GetElapsed()
    local elapsed = state.elapsedTime
    if state.timerRunning and state.startTime then elapsed = elapsed + (GetTime() - state.startTime) end
    return elapsed
end

local function GetTotalKills()
    local db = EnsureDB()
    local total = 0
    for i = 1, state.currentMaxTargets do
        total = total + (db.targets[i].count or 0)
    end
    return total
end

local function AddHistoryEntry()
    local db = EnsureDB()
    local totalKills = GetTotalKills()
    local elapsed = GetElapsed()
    if totalKills <= 0 and elapsed <= 0 and state.sessionDrops <= 0 then return end
    local itemName = state.trackedItemName ~= '' and state.trackedItemName or 'Kein Item'
    local entry = string.format('%s - %s (Dauer: %s, Kills: %d, Drops: %d)', date('%H:%M'), itemName, FormatTime(elapsed), totalKills, state.sessionDrops)
    table.insert(db.history, 1, entry)
    local limit = (TinkerBoxDB.settings and TinkerBoxDB.settings.historyLimit) or 50
    while #db.history > limit do table.remove(db.history) end
end

local function CreatePanel(parent, x, y, w, h)
    local panel = CreateFrame('Frame', nil, parent, 'BackdropTemplate')
    panel:SetPoint('TOPLEFT', parent, 'TOPLEFT', x, y)
    panel:SetSize(w, h)
    panel:SetBackdrop({
        bgFile = 'Interface\\ChatFrame\\ChatFrameBackground',
        edgeFile = 'Interface\\Buttons\\WHITE8x8',
        edgeSize = 1,
        insets = {left = 1, right = 1, top = 1, bottom = 1},
    })
    panel:SetBackdropColor(0.015, 0.08, 0.13, 0.72)
    panel:SetBackdropBorderColor(0.20, 0.58, 0.78, 0.55)
    return panel
end

local function CreateThemeButton(parent, width, height, label, red)
    local btn = CreateFrame('Button', nil, parent)
    btn:SetSize(width, height)
    local bg = btn:CreateTexture(nil, 'BACKGROUND')
    bg:SetAllPoints(btn)
    btn.bg = bg
    btn.isRed = red and true or false

    local txt = btn:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')
    txt:SetPoint('CENTER', 0, -1)
    txt:SetFont('Fonts\\FRIZQT__.TTF', 11, 'OUTLINE')
    txt:SetShadowColor(0, 0, 0, 1)
    txt:SetShadowOffset(1, -1)
    txt:SetText(label)
    btn.text = txt

    local function ApplyVisual(state)
        if btn.isRed then
            if state == 'hover' or state == 'down' then
                bg:SetTexture(TB.Assets.FarmButtonRedHover or TB.Assets.FarmButtonRed)
                bg:SetTexCoord(0, 1, 0, 1)
                bg:SetAlpha(state == 'down' and 1 or 0.97)
            else
                bg:SetTexture(TB.Assets.FarmButtonRed)
                bg:SetTexCoord(0, 1, 0, 1)
                bg:SetAlpha(1)
            end
        else
            if state == 'hover' or state == 'down' then
                bg:SetTexture(TB.Assets.FarmButtonBlue)
                bg:SetTexCoord(0, 1, 0, 1)
                bg:SetAlpha(state == 'down' and 1 or 0.96)
            else
                bg:SetTexture(TB.Assets.FarmButtonIdle)
                bg:SetTexCoord(0, 1, 0, 1)
                bg:SetAlpha(1)
            end
        end
    end

    ApplyVisual('idle')
    btn:SetScript('OnEnter', function() ApplyVisual('hover') end)
    btn:SetScript('OnLeave', function() ApplyVisual('idle') end)
    btn:SetScript('OnMouseDown', function(self, mouseButton)
        if mouseButton == 'LeftButton' then ApplyVisual('down') end
    end)
    btn:SetScript('OnMouseUp', function(self)
        if MouseIsOver(self) then ApplyVisual('hover') else ApplyVisual('idle') end
    end)
    btn.ApplyVisual = ApplyVisual
    return btn
end

-- Header / status -------------------------------------------------------------
local title = frame:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightLarge')
title:SetPoint('TOPLEFT', frame, 'TOPLEFT', 18, -34)
title:SetFont('Fonts\\FRIZQT__.TTF', 19, 'OUTLINE')
title:SetText('|cffffd75eFarmTracker|r')

local subtitle = frame:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
subtitle:SetPoint('LEFT', title, 'RIGHT', 12, 0)
subtitle:SetText('|cff8fdcffKills, Loot und Sessiondauer|r')

local stats = CreatePanel(frame, 18, -78, 630, 58)
local killsValue = stats:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightLarge')
killsValue:SetPoint('LEFT', stats, 'LEFT', 20, 5)
killsValue:SetText('0')
local killsLabel = stats:CreateFontString(nil, 'OVERLAY', 'GameFontDisableSmall')
killsLabel:SetPoint('TOP', killsValue, 'BOTTOM', 0, -2)
killsLabel:SetText('KILLS')

local timeValue = stats:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightLarge')
timeValue:SetPoint('CENTER', stats, 'CENTER', 0, 5)
timeValue:SetText('0m 00s')
local timeLabel = stats:CreateFontString(nil, 'OVERLAY', 'GameFontDisableSmall')
timeLabel:SetPoint('TOP', timeValue, 'BOTTOM', 0, -2)
timeLabel:SetText('DAUER')

local dropsValue = stats:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightLarge')
dropsValue:SetPoint('RIGHT', stats, 'RIGHT', -20, 5)
dropsValue:SetText('0')
local dropsLabel = stats:CreateFontString(nil, 'OVERLAY', 'GameFontDisableSmall')
dropsLabel:SetPoint('TOP', dropsValue, 'BOTTOM', 0, -2)
dropsLabel:SetText('DROPS')

-- Item -------------------------------------------------------------
local itemPanel = CreatePanel(frame, 18, -148, 630, 78)
local itemLabel = itemPanel:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
itemLabel:SetPoint('TOPLEFT', itemPanel, 'TOPLEFT', 14, -10)
itemLabel:SetText('Wunsch-Item')

local itemIcon = itemPanel:CreateTexture(nil, 'ARTWORK')
itemIcon:SetSize(32, 32)
itemIcon:SetPoint('TOPLEFT', itemPanel, 'TOPLEFT', 14, -34)
itemIcon:Hide()

local itemEdit = CreateFrame('EditBox', 'TinkerBoxFarmTrackerItemInput', itemPanel, 'BackdropTemplate')
itemEdit:SetSize(292, 30)
itemEdit:SetPoint('LEFT', itemIcon, 'RIGHT', 9, 0)
itemEdit:SetAutoFocus(false)
itemEdit:SetFontObject(GameFontHighlight)
itemEdit:SetTextInsets(8, 8, 0, 0)
itemEdit:SetBackdrop({bgFile='Interface\\ChatFrame\\ChatFrameBackground', edgeFile='Interface\\Buttons\\WHITE8x8', edgeSize=1})
itemEdit:SetBackdropColor(0.02, 0.05, 0.08, 0.88)
itemEdit:SetBackdropBorderColor(0.28, 0.63, 0.86, 0.8)

local pickBtn = CreateThemeButton(itemPanel, 112, 32, 'Item-Picker')
pickBtn:SetPoint('LEFT', itemEdit, 'RIGHT', 8, 0)
local favBtn = CreateThemeButton(itemPanel, 102, 32, 'Favoriten')
favBtn:SetPoint('LEFT', pickBtn, 'RIGHT', 6, 0)

-- Targets -------------------------------------------------------------
local targetPanel = CreatePanel(frame, 18, -238, 630, 148)
local targetHeader = targetPanel:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
targetHeader:SetPoint('TOPLEFT', targetPanel, 'TOPLEFT', 14, -10)
targetHeader:SetText('Farmziele')
local targetHint = targetPanel:CreateFontString(nil, 'OVERLAY', 'GameFontDisableSmall')
targetHint:SetPoint('LEFT', targetHeader, 'RIGHT', 12, 0)
targetHint:SetText('Linksklick: aktuelles Ziel übernehmen  •  Rechtsklick: Slot leeren')

local targetSlider = CreateFrame('Slider', 'TinkerBoxFarmTargetSlider', targetPanel, 'OptionsSliderTemplate')
targetSlider:SetSize(170, 14)
targetSlider:SetPoint('TOPRIGHT', targetPanel, 'TOPRIGHT', -20, -14)
targetSlider:SetMinMaxValues(1, MAX_TARGETS)
targetSlider:SetValueStep(1)
targetSlider:SetObeyStepOnDrag(true)
_G[targetSlider:GetName() .. 'Low']:SetText('1')
_G[targetSlider:GetName() .. 'High']:SetText('5')
_G[targetSlider:GetName() .. 'Text']:SetText('Ziele: 3')

for i = 1, MAX_TARGETS do
    local row = CreateFrame('Button', nil, targetPanel, 'BackdropTemplate')
    row:SetSize(590, 20)
    row:SetPoint('TOPLEFT', targetPanel, 'TOPLEFT', 14, -38 - ((i - 1) * 21))
    row:SetBackdrop({bgFile='Interface\\ChatFrame\\ChatFrameBackground'})
    row:SetBackdropColor(0, 0, 0, (i % 2 == 0) and 0.22 or 0.12)
    row:RegisterForClicks('LeftButtonUp', 'RightButtonUp')

    local slot = row:CreateFontString(nil, 'OVERLAY', 'GameFontDisableSmall')
    slot:SetPoint('LEFT', row, 'LEFT', 4, 0)
    slot:SetWidth(46)
    slot:SetJustifyH('LEFT')
    slot:SetText('Slot ' .. i)

    local name = row:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')
    name:SetPoint('LEFT', slot, 'RIGHT', 4, 0)
    name:SetWidth(430)
    name:SetJustifyH('LEFT')
    name:SetText('Frei')

    local count = row:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')
    count:SetPoint('RIGHT', row, 'RIGHT', -5, 0)
    count:SetWidth(70)
    count:SetJustifyH('RIGHT')
    count:SetText('0 Kills')

    row.nameText = name
    row.countText = count
    row.index = i
    targetRows[i] = row
end

-- Actions -------------------------------------------------------------
local actionPanel = CreateFrame('Frame', nil, frame)
actionPanel:SetPoint('BOTTOMLEFT', frame, 'BOTTOMLEFT', 18, 5)
actionPanel:SetSize(630, 44)

local sessionBtn = CreateThemeButton(actionPanel, 158, 38, 'Session starten')
sessionBtn:SetPoint('LEFT', actionPanel, 'LEFT', 0, 0)
local pauseBtnMain = CreateThemeButton(actionPanel, 116, 38, 'Pause')
pauseBtnMain:SetPoint('LEFT', sessionBtn, 'RIGHT', 8, 0)
local resetBtn = CreateThemeButton(actionPanel, 116, 38, 'Reset', true)
resetBtn:SetPoint('LEFT', pauseBtnMain, 'RIGHT', 8, 0)
local historyBtn = CreateThemeButton(actionPanel, 120, 38, 'Verlauf')
historyBtn:SetPoint('LEFT', resetBtn, 'RIGHT', 8, 0)

-- Mini tracker -------------------------------------------------------------
local miniTracker = CreateFrame('Frame', 'TinkerBoxFarmMiniTracker', UIParent)
miniTracker:SetSize(270, 206)
miniTracker:SetPoint('RIGHT', UIParent, 'RIGHT', -65, 10)
miniTracker:SetMovable(true)
miniTracker:EnableMouse(true)
miniTracker:RegisterForDrag('LeftButton')
miniTracker:SetScript('OnDragStart', miniTracker.StartMoving)
miniTracker:SetScript('OnDragStop', miniTracker.StopMovingOrSizing)
miniTracker:Hide()

local miniBg = miniTracker:CreateTexture(nil, 'BACKGROUND')
miniBg:SetAllPoints(miniTracker)
miniBg:SetColorTexture(0.11, 0.14, 0.18, 0.88)

local miniShade = miniTracker:CreateTexture(nil, 'ARTWORK')
miniShade:SetColorTexture(0.16, 0.21, 0.28, 0.20)
miniShade:SetPoint('TOPLEFT', miniTracker, 'TOPLEFT', 2, -2)
miniShade:SetPoint('TOPRIGHT', miniTracker, 'TOPRIGHT', -2, -2)
miniShade:SetHeight(48)

local miniBorderTop = miniTracker:CreateTexture(nil, 'BORDER')
miniBorderTop:SetColorTexture(0.52, 0.62, 0.76, 0.95)
miniBorderTop:SetPoint('TOPLEFT', miniTracker, 'TOPLEFT', 0, 0)
miniBorderTop:SetPoint('TOPRIGHT', miniTracker, 'TOPRIGHT', 0, 0)
miniBorderTop:SetHeight(1)
local miniBorderBottom = miniTracker:CreateTexture(nil, 'BORDER')
miniBorderBottom:SetColorTexture(0.52, 0.62, 0.76, 0.95)
miniBorderBottom:SetPoint('BOTTOMLEFT', miniTracker, 'BOTTOMLEFT', 0, 0)
miniBorderBottom:SetPoint('BOTTOMRIGHT', miniTracker, 'BOTTOMRIGHT', 0, 0)
miniBorderBottom:SetHeight(1)
local miniBorderLeft = miniTracker:CreateTexture(nil, 'BORDER')
miniBorderLeft:SetColorTexture(0.52, 0.62, 0.76, 0.95)
miniBorderLeft:SetPoint('TOPLEFT', miniTracker, 'TOPLEFT', 0, 0)
miniBorderLeft:SetPoint('BOTTOMLEFT', miniTracker, 'BOTTOMLEFT', 0, 0)
miniBorderLeft:SetWidth(1)
local miniBorderRight = miniTracker:CreateTexture(nil, 'BORDER')
miniBorderRight:SetColorTexture(0.52, 0.62, 0.76, 0.95)
miniBorderRight:SetPoint('TOPRIGHT', miniTracker, 'TOPRIGHT', 0, 0)
miniBorderRight:SetPoint('BOTTOMRIGHT', miniTracker, 'BOTTOMRIGHT', 0, 0)
miniBorderRight:SetWidth(1)

local miniTitle = miniTracker:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightLarge')
miniTitle:SetPoint('TOP', miniTracker, 'TOP', 0, -8)
miniTitle:SetFont('Fonts\\FRIZQT__.TTF', 15, 'OUTLINE')
miniTitle:SetTextColor(1.00, 0.86, 0.25)
miniTitle:SetShadowColor(0, 0, 0, 1)
miniTitle:SetShadowOffset(1, -1)
miniTitle:SetText('Farm-Session')

local miniTitleDivider = miniTracker:CreateTexture(nil, 'ARTWORK')
TB.ApplyAsset(miniTitleDivider, TB.Assets.DividerBottom, 'DividerMenu')
miniTitleDivider:SetSize(180, 20)
miniTitleDivider:SetPoint('TOP', miniTracker, 'TOP', 0, -22)

local miniClose = CreateFrame('Button', nil, miniTracker)
miniClose:SetSize(32, 32)
miniClose:SetPoint('TOPRIGHT', miniTracker, 'TOPRIGHT', -2, -2)
local miniCloseTex = miniClose:CreateTexture(nil, 'ARTWORK')
miniCloseTex:SetAllPoints(miniClose)
TB.ApplyAsset(miniCloseTex, TB.Assets.Close, 'Close')
miniClose.tex = miniCloseTex
miniClose:SetScript('OnEnter', function(self) self.tex:SetAlpha(1) end)
miniClose:SetScript('OnLeave', function(self) self.tex:SetAlpha(0.92) end)
miniClose:SetScript('OnMouseDown', function(self) self.tex:SetAlpha(0.85) end)
miniClose:SetScript('OnMouseUp', function(self) self.tex:SetAlpha(1) end)
miniClose:SetScript('OnClick', function() miniTracker:Hide() end)
miniCloseTex:SetAlpha(0.92)

local miniItemIcon = miniTracker:CreateTexture(nil, 'ARTWORK')
miniItemIcon:SetSize(26, 26)
miniItemIcon:SetPoint('TOPLEFT', miniTracker, 'TOPLEFT', 20, -48)
miniItemIcon:Hide()

local miniItem = miniTracker:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')
miniItem:SetPoint('TOPLEFT', miniTracker, 'TOPLEFT', 20, -50)
miniItem:SetWidth(168)
miniItem:SetJustifyH('LEFT')
miniItem:SetWordWrap(false)
miniItem:SetFont('Fonts\\FRIZQT__.TTF', 12, 'OUTLINE')
miniItem:SetShadowColor(0, 0, 0, 1)
miniItem:SetShadowOffset(1, -1)

local miniDivider = miniTracker:CreateTexture(nil, 'ARTWORK')
miniDivider:SetTexture('Interface\\Buttons\\WHITE8x8')
miniDivider:SetVertexColor(0.34, 0.48, 0.66, 0.58)
miniDivider:SetSize(228, 1)
miniDivider:SetPoint('TOPLEFT', miniTracker, 'TOPLEFT', 20, -80)

local miniKills = miniTracker:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')
miniKills:SetPoint('TOPLEFT', miniTracker, 'TOPLEFT', 20, -95)
miniKills:SetFont('Fonts\\FRIZQT__.TTF', 12, 'OUTLINE')

local miniTime = miniTracker:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')
miniTime:SetPoint('TOPLEFT', miniKills, 'BOTTOMLEFT', 0, -8)
miniTime:SetFont('Fonts\\FRIZQT__.TTF', 12, 'OUTLINE')

local miniDrops = miniTracker:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')
miniDrops:SetPoint('TOPLEFT', miniTime, 'BOTTOMLEFT', 0, -8)
miniDrops:SetFont('Fonts\\FRIZQT__.TTF', 12, 'OUTLINE')

local miniPause = CreateThemeButton(miniTracker, 96, 30, 'Pause')
miniPause:SetPoint('BOTTOMLEFT', miniTracker, 'BOTTOMLEFT', 16, 12)

local miniResume = CreateThemeButton(miniTracker, 96, 30, 'Weiter')
miniResume:SetPoint('BOTTOMRIGHT', miniTracker, 'BOTTOMRIGHT', -16, 12)

-- Favorites popup -------------------------------------------------------------
local favFrame = CreateFrame('Frame', 'TinkerBoxFarmFavorites', UIParent)
favFrame:SetSize(265, 352)
favFrame:SetPoint('CENTER', TB.UI.mainFrame, 'CENTER', 395, 0)
favFrame:SetMovable(true)
favFrame:EnableMouse(true)
favFrame:RegisterForDrag('LeftButton')
favFrame:SetScript('OnDragStart', favFrame.StartMoving)
favFrame:SetScript('OnDragStop', favFrame.StopMovingOrSizing)
favFrame:Hide()

local favBg = favFrame:CreateTexture(nil, 'BACKGROUND')
favBg:SetAllPoints(favFrame)
favBg:SetColorTexture(0.11, 0.14, 0.18, 0.88)

local favShade = favFrame:CreateTexture(nil, 'ARTWORK')
favShade:SetColorTexture(0.16, 0.21, 0.28, 0.20)
favShade:SetPoint('TOPLEFT', favFrame, 'TOPLEFT', 2, -2)
favShade:SetPoint('TOPRIGHT', favFrame, 'TOPRIGHT', -2, -2)
favShade:SetHeight(54)

local favBorderTop = favFrame:CreateTexture(nil, 'BORDER')
favBorderTop:SetColorTexture(0.52, 0.62, 0.76, 0.95)
favBorderTop:SetPoint('TOPLEFT', favFrame, 'TOPLEFT', 0, 0)
favBorderTop:SetPoint('TOPRIGHT', favFrame, 'TOPRIGHT', 0, 0)
favBorderTop:SetHeight(1)
local favBorderBottom = favFrame:CreateTexture(nil, 'BORDER')
favBorderBottom:SetColorTexture(0.52, 0.62, 0.76, 0.95)
favBorderBottom:SetPoint('BOTTOMLEFT', favFrame, 'BOTTOMLEFT', 0, 0)
favBorderBottom:SetPoint('BOTTOMRIGHT', favFrame, 'BOTTOMRIGHT', 0, 0)
favBorderBottom:SetHeight(1)
local favBorderLeft = favFrame:CreateTexture(nil, 'BORDER')
favBorderLeft:SetColorTexture(0.52, 0.62, 0.76, 0.95)
favBorderLeft:SetPoint('TOPLEFT', favFrame, 'TOPLEFT', 0, 0)
favBorderLeft:SetPoint('BOTTOMLEFT', favFrame, 'BOTTOMLEFT', 0, 0)
favBorderLeft:SetWidth(1)
local favBorderRight = favFrame:CreateTexture(nil, 'BORDER')
favBorderRight:SetColorTexture(0.52, 0.62, 0.76, 0.95)
favBorderRight:SetPoint('TOPRIGHT', favFrame, 'TOPRIGHT', 0, 0)
favBorderRight:SetPoint('BOTTOMRIGHT', favFrame, 'BOTTOMRIGHT', 0, 0)
favBorderRight:SetWidth(1)

local favTitle = favFrame:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightLarge')
favTitle:SetPoint('TOP', favFrame, 'TOP', 0, -8)
favTitle:SetFont('Fonts\\FRIZQT__.TTF', 17, 'OUTLINE')
favTitle:SetTextColor(1.00, 0.86, 0.25)
favTitle:SetShadowColor(0, 0, 0, 1)
favTitle:SetShadowOffset(1, -1)
favTitle:SetText('Farm-Favoriten')

local favTitleDivider = favFrame:CreateTexture(nil, 'ARTWORK')
TB.ApplyAsset(favTitleDivider, TB.Assets.DividerBottom, 'DividerMenu')
favTitleDivider:SetSize(198, 20)
favTitleDivider:SetPoint('TOP', favFrame, 'TOP', 0, -22)

local favClose = CreateFrame('Button', nil, favFrame)
favClose:SetSize(32, 32)
favClose:SetPoint('TOPRIGHT', favFrame, 'TOPRIGHT', -2, -2)
local favCloseTex = favClose:CreateTexture(nil, 'ARTWORK')
favCloseTex:SetAllPoints(favClose)
TB.ApplyAsset(favCloseTex, TB.Assets.Close, 'Close')
favClose.tex = favCloseTex
favClose:SetScript('OnEnter', function(self) self.tex:SetAlpha(1) end)
favClose:SetScript('OnLeave', function(self) self.tex:SetAlpha(0.92) end)
favClose:SetScript('OnMouseDown', function(self) self.tex:SetAlpha(0.85) end)
favClose:SetScript('OnMouseUp', function(self) self.tex:SetAlpha(1) end)
favClose:SetScript('OnClick', function() favFrame:Hide() end)
favCloseTex:SetAlpha(0.92)

local addFavBtn = CreateThemeButton(favFrame, 170, 30, 'Aktuelles Item speichern')
addFavBtn:SetPoint('TOP', favFrame, 'TOP', 0, -42)

local favListHeader = favFrame:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
favListHeader:SetPoint('TOPLEFT', favFrame, 'TOPLEFT', 16, -84)
favListHeader:SetText('|cffffd75eGespeicherte Items|r')

for i = 1, 10 do
    local row = CreateFrame('Button', nil, favFrame, 'BackdropTemplate')
    row:SetSize(233, 21)
    row:SetPoint('TOPLEFT', favFrame, 'TOPLEFT', 16, -102 - ((i - 1) * 22))
    row:RegisterForClicks('LeftButtonUp', 'RightButtonUp')
    row:SetBackdrop({bgFile='Interface\\ChatFrame\\ChatFrameBackground'})
    row:SetBackdropColor(0.06, 0.09, 0.12, (i % 2 == 0) and 0.28 or 0.18)

    local highlight = row:CreateTexture(nil, 'HIGHLIGHT')
    highlight:SetAllPoints(row)
    highlight:SetTexture('Interface\\Buttons\\WHITE8x8')
    highlight:SetVertexColor(0.12, 0.55, 0.85, 0.16)

    local icon = row:CreateTexture(nil, 'ARTWORK')
    icon:SetSize(22, 22)
    icon:SetPoint('LEFT', row, 'LEFT', 3, 0)

    local txt = row:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')
    txt:SetPoint('LEFT', icon, 'RIGHT', 8, -1)
    txt:SetWidth(193)
    txt:SetJustifyH('LEFT')
    txt:SetWordWrap(false)
    txt:SetFont('Fonts\\FRIZQT__.TTF', 12, 'OUTLINE')
    txt:SetShadowColor(0, 0, 0, 1)
    txt:SetShadowOffset(1, -1)

    row.icon = icon
    row.text = txt
    row.index = i
    favoriteRows[i] = row
end

local favHelp = favFrame:CreateFontString(nil, 'OVERLAY', 'GameFontDisableSmall')
favHelp:SetPoint('BOTTOM', favFrame, 'BOTTOM', 0, 9)
favHelp:SetWidth(225)
favHelp:SetJustifyH('CENTER')
favHelp:SetText('Linksklick: auswählen   •   Rechtsklick: löschen')

-- History popup -------------------------------------------------------------
local historyFrame = CreateFrame('Frame', 'TinkerBoxFarmHistory', UIParent)
historyFrame:SetSize(265, 352)
historyFrame:SetPoint('CENTER', TB.UI.mainFrame, 'CENTER', 395, 0)
historyFrame:SetMovable(true)
historyFrame:EnableMouse(true)
historyFrame:RegisterForDrag('LeftButton')
historyFrame:SetScript('OnDragStart', historyFrame.StartMoving)
historyFrame:SetScript('OnDragStop', historyFrame.StopMovingOrSizing)
historyFrame:Hide()

local historyBg = historyFrame:CreateTexture(nil, 'BACKGROUND')
historyBg:SetAllPoints(historyFrame)
historyBg:SetColorTexture(0.11, 0.14, 0.18, 0.88)

local historyShade = historyFrame:CreateTexture(nil, 'ARTWORK')
historyShade:SetColorTexture(0.16, 0.21, 0.28, 0.20)
historyShade:SetPoint('TOPLEFT', historyFrame, 'TOPLEFT', 2, -2)
historyShade:SetPoint('TOPRIGHT', historyFrame, 'TOPRIGHT', -2, -2)
historyShade:SetHeight(54)

local historyBorderTop = historyFrame:CreateTexture(nil, 'BORDER')
historyBorderTop:SetColorTexture(0.52, 0.62, 0.76, 0.95)
historyBorderTop:SetPoint('TOPLEFT', historyFrame, 'TOPLEFT', 0, 0)
historyBorderTop:SetPoint('TOPRIGHT', historyFrame, 'TOPRIGHT', 0, 0)
historyBorderTop:SetHeight(1)
local historyBorderBottom = historyFrame:CreateTexture(nil, 'BORDER')
historyBorderBottom:SetColorTexture(0.52, 0.62, 0.76, 0.95)
historyBorderBottom:SetPoint('BOTTOMLEFT', historyFrame, 'BOTTOMLEFT', 0, 0)
historyBorderBottom:SetPoint('BOTTOMRIGHT', historyFrame, 'BOTTOMRIGHT', 0, 0)
historyBorderBottom:SetHeight(1)
local historyBorderLeft = historyFrame:CreateTexture(nil, 'BORDER')
historyBorderLeft:SetColorTexture(0.52, 0.62, 0.76, 0.95)
historyBorderLeft:SetPoint('TOPLEFT', historyFrame, 'TOPLEFT', 0, 0)
historyBorderLeft:SetPoint('BOTTOMLEFT', historyFrame, 'BOTTOMLEFT', 0, 0)
historyBorderLeft:SetWidth(1)
local historyBorderRight = historyFrame:CreateTexture(nil, 'BORDER')
historyBorderRight:SetColorTexture(0.52, 0.62, 0.76, 0.95)
historyBorderRight:SetPoint('TOPRIGHT', historyFrame, 'TOPRIGHT', 0, 0)
historyBorderRight:SetPoint('BOTTOMRIGHT', historyFrame, 'BOTTOMRIGHT', 0, 0)
historyBorderRight:SetWidth(1)

local historyTitle = historyFrame:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightLarge')
historyTitle:SetPoint('TOP', historyFrame, 'TOP', 0, -8)
historyTitle:SetFont('Fonts\\FRIZQT__.TTF', 17, 'OUTLINE')
historyTitle:SetTextColor(1.00, 0.86, 0.25)
historyTitle:SetShadowColor(0, 0, 0, 1)
historyTitle:SetShadowOffset(1, -1)
historyTitle:SetText('Farm-Verlauf')

local historyTitleDivider = historyFrame:CreateTexture(nil, 'ARTWORK')
TB.ApplyAsset(historyTitleDivider, TB.Assets.DividerBottom, 'DividerMenu')
historyTitleDivider:SetSize(198, 20)
historyTitleDivider:SetPoint('TOP', historyFrame, 'TOP', 0, -22)

local historyClose = CreateFrame('Button', nil, historyFrame)
historyClose:SetSize(32, 32)
historyClose:SetPoint('TOPRIGHT', historyFrame, 'TOPRIGHT', -2, -2)
local historyCloseTex = historyClose:CreateTexture(nil, 'ARTWORK')
historyCloseTex:SetAllPoints(historyClose)
TB.ApplyAsset(historyCloseTex, TB.Assets.Close, 'Close')
historyClose.tex = historyCloseTex
historyClose:SetScript('OnEnter', function(self) self.tex:SetAlpha(1) end)
historyClose:SetScript('OnLeave', function(self) self.tex:SetAlpha(0.92) end)
historyClose:SetScript('OnMouseDown', function(self) self.tex:SetAlpha(0.85) end)
historyClose:SetScript('OnMouseUp', function(self) self.tex:SetAlpha(1) end)
historyClose:SetScript('OnClick', function() historyFrame:Hide() end)
historyCloseTex:SetAlpha(0.92)

local clearHistoryBtn = CreateThemeButton(historyFrame, 160, 30, 'Verlauf leeren', true)
clearHistoryBtn:SetPoint('TOP', historyFrame, 'TOP', 0, -42)

local historyHeader = historyFrame:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
historyHeader:SetPoint('TOPLEFT', historyFrame, 'TOPLEFT', 16, -84)
historyHeader:SetText('|cffffd75eGespeicherte Sessions|r')

local historyScroll = CreateFrame('ScrollingMessageFrame', nil, historyFrame)
historyScroll:SetPoint('TOPLEFT', historyFrame, 'TOPLEFT', 16, -102)
historyScroll:SetPoint('BOTTOMRIGHT', historyFrame, 'BOTTOMRIGHT', -16, 26)
historyScroll:SetFontObject(GameFontHighlightSmall)
historyScroll:SetFading(false)
historyScroll:SetMaxLines(100)
historyScroll:SetJustifyH('LEFT')
historyScroll:EnableMouseWheel(true)
historyScroll:SetScript('OnMouseWheel', function(self, delta)
    if delta > 0 then self:ScrollUp() else self:ScrollDown() end
end)

local historyHelp = historyFrame:CreateFontString(nil, 'OVERLAY', 'GameFontDisableSmall')
historyHelp:SetPoint('BOTTOM', historyFrame, 'BOTTOM', 0, 9)
historyHelp:SetWidth(225)
historyHelp:SetJustifyH('CENTER')
historyHelp:SetText('Neueste Session steht oben')

-- Behaviour -----------------------------------------------------------------
local function UpdateFavoriteDisplay()
    local db = EnsureDB()
    for i, row in ipairs(favoriteRows) do
        local fav = db.favorites[i]
        if fav then
            row.icon:SetTexture(fav.icon or 134400)
            row.text:SetText(fav.name or '')
            row:Show()
        else
            row:Hide()
        end
    end
end

local function UpdateHistoryDisplay()
    local db = EnsureDB()
    historyScroll:Clear()
    if #db.history == 0 then
        historyScroll:AddMessage('|cff7f8c96Noch kein Verlauf vorhanden.|r')
        return
    end
    for _, entry in ipairs(db.history) do
        historyScroll:AddMessage(entry)
    end
end

local function UpdateTargetRows()
    local db = EnsureDB()
    for i = 1, MAX_TARGETS do
        local row = targetRows[i]
        if i <= state.currentMaxTargets then
            row:Show()
            local data = db.targets[i]
            if data.name == '' then
                row.nameText:SetText('|cff7f8c96Frei – Ziel anwählen und hier klicken|r')
            else
                row.nameText:SetText(data.name)
            end
            row.countText:SetText((data.count or 0) .. ' Kills')
        else
            row:Hide()
        end
    end
end

local function UpdateDisplay()
    local db = EnsureDB()
    local elapsed = GetElapsed()
    local total = GetTotalKills()
    killsValue:SetText(tostring(total))
    timeValue:SetText(FormatTime(elapsed))
    dropsValue:SetText(tostring(state.sessionDrops))
    UpdateTargetRows()

    if state.trackedItemName == '' then
        itemIcon:Hide()
        miniItemIcon:Hide()
        miniItem:ClearAllPoints()
        miniItem:SetPoint('TOPLEFT', miniTracker, 'TOPLEFT', 20, -50)
        miniItem:SetText('|cff7f8c96Kein Item gewählt|r')
    else
        if state.trackedItemIcon then
            itemIcon:SetTexture(state.trackedItemIcon); itemIcon:Show()
            miniItemIcon:SetTexture(state.trackedItemIcon); miniItemIcon:Show()
            miniItem:ClearAllPoints()
            miniItem:SetPoint('LEFT', miniItemIcon, 'RIGHT', 8, 0)
        else
            itemIcon:Hide(); miniItemIcon:Hide()
            miniItem:ClearAllPoints()
            miniItem:SetPoint('TOPLEFT', miniTracker, 'TOPLEFT', 20, -50)
        end
        miniItem:SetText(state.trackedItemName)
    end
    itemEdit:SetText(state.trackedItemName)
    miniKills:SetText('Kills: ' .. total)
    miniTime:SetText('Dauer: ' .. FormatTime(elapsed) .. (state.timerRunning and '' or ' |cff888888(Pause)|r'))
    miniDrops:SetText('Drops: ' .. state.sessionDrops)

    if state.timerRunning then
        sessionBtn.text:SetText('Session läuft')
        pauseBtnMain.text:SetText('Pause')
    elseif elapsed > 0 then
        sessionBtn.text:SetText('Weiter')
        pauseBtnMain.text:SetText('Pausiert')
    else
        sessionBtn.text:SetText('Session starten')
        pauseBtnMain.text:SetText('Pause')
    end
end

local function SetTrackedItem(itemString)
    local db = EnsureDB()
    itemString = itemString or ''
    if itemString == '' then
        state.trackedItemName = ''
        state.trackedItemIcon = nil
        db.trackedItemName = ''
        db.trackedItemIcon = nil
        state.pickingItem = false
        UpdateDisplay()
        return
    end

    local itemName, itemLink, _, _, _, _, _, _, _, itemTexture
    if C_Item and C_Item.GetItemInfo then
        itemName, itemLink, _, _, _, _, _, _, _, itemTexture = C_Item.GetItemInfo(itemString)
    elseif GetItemInfo then
        itemName, itemLink, _, _, _, _, _, _, _, itemTexture = GetItemInfo(itemString)
    end

    state.trackedItemName = itemName or itemString
    state.trackedItemIcon = itemTexture
    db.trackedItemName = state.trackedItemName
    db.trackedItemIcon = state.trackedItemIcon
    state.pickingItem = false
    pickBtn.text:SetText('Item-Picker')
    UpdateDisplay()
end

itemEdit:SetScript('OnEnterPressed', function(self)
    SetTrackedItem(self:GetText())
    self:ClearFocus()
end)
itemEdit:SetScript('OnEscapePressed', function(self) self:ClearFocus() end)

pickBtn:SetScript('OnClick', function()
    state.pickingItem = not state.pickingItem
    pickBtn.text:SetText(state.pickingItem and 'Shift-Klick…' or 'Item-Picker')
    if state.pickingItem then TB.Message('Item-Picker aktiv: Shift-Klicke ein Item im Chat, Inventar oder Berufsbuch.') end
end)

if HandleModifiedItemClick then
    hooksecurefunc('HandleModifiedItemClick', function(link)
        if state.pickingItem and link then SetTrackedItem(link) end
    end)
end

-- Best-effort support for direct bag clicks on different Retail UI generations.
local function PickBagItem(self, button)
    if not state.pickingItem or button ~= 'LeftButton' then return end
    local bag, slot
    if self.GetBagID then bag = self:GetBagID() end
    if not bag and self.GetParent and self:GetParent() and self:GetParent().GetID then bag = self:GetParent():GetID() end
    if self.GetID then slot = self:GetID() end
    if bag ~= nil and slot and C_Container and C_Container.GetContainerItemLink then
        local link = C_Container.GetContainerItemLink(bag, slot)
        if link then SetTrackedItem(link) end
    end
end
if ContainerFrameItemButton_OnClick then hooksecurefunc('ContainerFrameItemButton_OnClick', PickBagItem) end
if ContainerFrameItemButtonMixin and ContainerFrameItemButtonMixin.OnClick then hooksecurefunc(ContainerFrameItemButtonMixin, 'OnClick', PickBagItem) end

for i, row in ipairs(targetRows) do
    row:SetScript('OnClick', function(_, button)
        local db = EnsureDB()
        if button == 'RightButton' then
            db.targets[i].name = ''
            db.targets[i].count = 0
        else
            local targetName = UnitName('target')
            if targetName then
                db.targets[i].name = targetName
                db.targets[i].count = 0
            else
                TB.Message('Kein Ziel ausgewählt.')
            end
        end
        UpdateDisplay()
    end)
end

targetSlider:SetScript('OnValueChanged', function(self, value)
    local val = math.floor(value + 0.5)
    state.currentMaxTargets = val
    EnsureDB().currentMaxTargets = val
    _G[self:GetName() .. 'Text']:SetText('Ziele: ' .. val)
    UpdateDisplay()
end)

local function StartOrResume()
    if not state.timerRunning then
        state.timerRunning = true
        state.startTime = GetTime()
    end
    miniTracker:Show()
    UpdateDisplay()
end

local function Pause()
    if state.timerRunning and state.startTime then
        state.elapsedTime = state.elapsedTime + (GetTime() - state.startTime)
        state.startTime = nil
        state.timerRunning = false
        TB.Message('FarmTracker pausiert.')
        UpdateDisplay()
    end
end

sessionBtn:SetScript('OnClick', StartOrResume)
miniResume:SetScript('OnClick', StartOrResume)
pauseBtnMain:SetScript('OnClick', Pause)
miniPause:SetScript('OnClick', Pause)

resetBtn:SetScript('OnClick', function()
    AddHistoryEntry()
    local db = EnsureDB()
    state.timerRunning = false
    state.startTime = nil
    state.elapsedTime = 0
    state.sessionDrops = 0
    for i = 1, MAX_TARGETS do db.targets[i].count = 0 end
    SetTrackedItem('')
    UpdateHistoryDisplay()
    TB.Message('FarmTracker zurückgesetzt; Session wurde im Verlauf gespeichert.')
end)

favBtn:SetScript('OnClick', function()
    UpdateFavoriteDisplay()
    if favFrame:IsShown() then favFrame:Hide() else favFrame:Show() end
end)

addFavBtn:SetScript('OnClick', function()
    if state.trackedItemName == '' then TB.Message('Wähle zuerst ein Wunsch-Item.') return end
    local db = EnsureDB()
    for _, fav in ipairs(db.favorites) do
        if fav.name == state.trackedItemName then TB.Message('Dieses Item ist bereits in den Favoriten.') return end
    end
    if #db.favorites >= 10 then TB.Message('Maximal 10 Farm-Favoriten.') return end
    table.insert(db.favorites, {name=state.trackedItemName, icon=state.trackedItemIcon})
    UpdateFavoriteDisplay()
end)

for i, row in ipairs(favoriteRows) do
    row:SetScript('OnClick', function(_, button)
        local db = EnsureDB()
        local fav = db.favorites[i]
        if not fav then return end
        if button == 'RightButton' then
            table.remove(db.favorites, i)
            UpdateFavoriteDisplay()
        else
            SetTrackedItem(fav.name)
            favFrame:Hide()
        end
    end)
end

historyBtn:SetScript('OnClick', function()
    if historyFrame:IsShown() then
        historyFrame:Hide()
    else
        historyFrame:Show()
        UpdateHistoryDisplay()
    end
end)
clearHistoryBtn:SetScript('OnClick', function()
    EnsureDB().history = {}
    UpdateHistoryDisplay()
end)

local ticker = CreateFrame('Frame', nil, frame)
local throttle = 0
ticker:SetScript('OnUpdate', function(_, elapsed)
    if not state.timerRunning then return end
    throttle = throttle + elapsed
    if throttle >= 0.25 then
        throttle = 0
        if frame:IsShown() or miniTracker:IsShown() then UpdateDisplay() end
    end
end)

-- Public module API used by Events.lua ----------------------------------------
frame.Initialize = function()
    local db = EnsureDB()
    state.trackedItemName = db.trackedItemName or ''
    state.trackedItemIcon = db.trackedItemIcon
    state.currentMaxTargets = db.currentMaxTargets or 3
    targetSlider:SetValue(state.currentMaxTargets)
    UpdateFavoriteDisplay()
    UpdateHistoryDisplay()
    UpdateDisplay()
end

frame.OnCombatLogEvent = function()
    if not state.timerRunning then return end
    local _, subevent, _, sourceGUID, _, _, _, _, destName = CombatLogGetCurrentEventInfo()
    if subevent ~= 'PARTY_KILL' or sourceGUID ~= UnitGUID('player') or not destName then return end
    local db = EnsureDB()
    for i = 1, state.currentMaxTargets do
        local target = db.targets[i]
        if target and target.name ~= '' and target.name == destName then
            target.count = (target.count or 0) + 1
        end
    end
    UpdateDisplay()
end

frame.OnLootMessage = function(msg)
    if not state.timerRunning or state.trackedItemName == '' or type(msg) ~= 'string' then return end
    if string.find(msg, state.trackedItemName, 1, true) then
        state.sessionDrops = state.sessionDrops + 1
        UpdateDisplay()
    end
end

frame.Refresh = UpdateDisplay
frame.MiniTracker = miniTracker
frame.FavoritesFrame = favFrame
frame.HistoryFrame = historyFrame

frame:SetScript('OnShow', function()
    UpdateDisplay()
end)
