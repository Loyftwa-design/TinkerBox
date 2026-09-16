local addonName, TB = ...
local frame = TB.CreateModuleFrame('Zusatzinfos')

local rows = {}
local MAX_ROWS = 10

local function EnsureDB()
    TinkerBoxDB.zusatzinfos = TinkerBoxDB.zusatzinfos or {}
    TinkerBoxDB.zusatzinfos.realmGold = TinkerBoxDB.zusatzinfos.realmGold or {}
    TinkerBoxDB.zusatzinfos.realmClasses = TinkerBoxDB.zusatzinfos.realmClasses or {}
    return TinkerBoxDB.zusatzinfos
end

local function CreatePanel(parent, x, y, width, height)
    local panel = CreateFrame('Frame', nil, parent, 'BackdropTemplate')
    panel:SetPoint('TOPLEFT', parent, 'TOPLEFT', x, y)
    panel:SetSize(width, height)
    panel:SetBackdrop({
        bgFile = 'Interface\\ChatFrame\\ChatFrameBackground',
        edgeFile = 'Interface\\Buttons\\WHITE8x8',
        edgeSize = 1,
    })
    panel:SetBackdropColor(0.02, 0.08, 0.12, 0.34)
    panel:SetBackdropBorderColor(0.10, 0.55, 0.78, 0.65)
    return panel
end

local function StoreCurrentCharacterGold()
    local db = EnsureDB()
    local realm = GetRealmName() or 'Unbekannter Realm'
    local player = UnitName('player') or 'Unbekannt'
    db.realmGold[realm] = db.realmGold[realm] or {}
    db.realmClasses[realm] = db.realmClasses[realm] or {}
    db.realmGold[realm][player] = GetMoney() or 0
    local _, classFile = UnitClass('player')
    if classFile then db.realmClasses[realm][player] = classFile end
end

-- Titel ----------------------------------------------------------------------
local title = frame:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightLarge')
title:SetPoint('TOPLEFT', frame, 'TOPLEFT', 18, -30)
title:SetFont('Fonts\\FRIZQT__.TTF', 18, 'OUTLINE')
title:SetTextColor(1.00, 0.86, 0.25)
title:SetText('Zusatzinfos')

local subtitle = frame:CreateFontString(nil, 'OVERLAY', 'GameFontDisableSmall')
subtitle:SetPoint('LEFT', title, 'RIGHT', 14, -1)
subtitle:SetText('Charaktergold und Gesamt-Gold')

-- Zusammenfassung ------------------------------------------------------------
local summary = CreatePanel(frame, 18, -62, 630, 42)

local charLabel = summary:CreateFontString(nil, 'OVERLAY', 'GameFontDisableSmall')
charLabel:SetPoint('TOPLEFT', summary, 'TOPLEFT', 18, -13)
charLabel:SetFont('Fonts\\FRIZQT__.TTF', 13, 'OUTLINE')
charLabel:SetTextColor(1, 1, 1)
charLabel:SetText('GESAMT-GOLD')

-- Feste Geld-Spalten wie in der Charakterübersicht darunter.
-- Die Offsets sind so gewählt, dass Gold/Silber/Kupfer oben und unten exakt fluchten.
local totalCopperIcon = summary:CreateTexture(nil, 'ARTWORK')
totalCopperIcon:SetSize(14, 14)
totalCopperIcon:SetPoint('RIGHT', summary, 'RIGHT', -28, 0)
totalCopperIcon:SetTexture('Interface\\MoneyFrame\\UI-CopperIcon')

local totalCopper = summary:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')
totalCopper:SetPoint('RIGHT', totalCopperIcon, 'LEFT', -3, 0)
totalCopper:SetWidth(22)
totalCopper:SetJustifyH('RIGHT')
totalCopper:SetFont('Fonts\\FRIZQT__.TTF', 14, 'OUTLINE')
totalCopper:SetTextColor(0.93, 0.65, 0.37)

local totalSilverIcon = summary:CreateTexture(nil, 'ARTWORK')
totalSilverIcon:SetSize(14, 14)
totalSilverIcon:SetPoint('RIGHT', summary, 'RIGHT', -74, 0)
totalSilverIcon:SetTexture('Interface\\MoneyFrame\\UI-SilverIcon')

local totalSilver = summary:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')
totalSilver:SetPoint('RIGHT', totalSilverIcon, 'LEFT', -3, 0)
totalSilver:SetWidth(22)
totalSilver:SetJustifyH('RIGHT')
totalSilver:SetFont('Fonts\\FRIZQT__.TTF', 14, 'OUTLINE')
totalSilver:SetTextColor(0.78, 0.78, 0.81)

local totalGoldIcon = summary:CreateTexture(nil, 'ARTWORK')
totalGoldIcon:SetSize(14, 14)
totalGoldIcon:SetPoint('RIGHT', summary, 'RIGHT', -120, 0)
totalGoldIcon:SetTexture('Interface\\MoneyFrame\\UI-GoldIcon')

local totalGold = summary:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')
totalGold:SetPoint('RIGHT', totalGoldIcon, 'LEFT', -3, 0)
totalGold:SetWidth(115)
totalGold:SetJustifyH('RIGHT')
totalGold:SetFont('Fonts\\FRIZQT__.TTF', 14, 'OUTLINE')
totalGold:SetTextColor(1.00, 0.84, 0.00)


-- Charakterliste -------------------------------------------------------------
local listPanel = CreatePanel(frame, 18, -116, 630, 278)

local listTitle = listPanel:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
listTitle:SetPoint('TOPLEFT', listPanel, 'TOPLEFT', 14, -10)
listTitle:SetText('|cffffd75eCharakterübersicht|r')

local listHint = listPanel:CreateFontString(nil, 'OVERLAY', 'GameFontDisableSmall')
listHint:SetPoint('LEFT', listTitle, 'RIGHT', 12, 0)
listHint:SetText('')

local headerLine = listPanel:CreateTexture(nil, 'ARTWORK')
headerLine:SetTexture('Interface\\Buttons\\WHITE8x8')
headerLine:SetVertexColor(0.16, 0.50, 0.72, 0.35)
headerLine:SetPoint('TOPLEFT', listPanel, 'TOPLEFT', 14, -34)
headerLine:SetPoint('TOPRIGHT', listPanel, 'TOPRIGHT', -14, -34)
headerLine:SetHeight(1)

local nameHeader = listPanel:CreateFontString(nil, 'OVERLAY', 'GameFontDisableSmall')
nameHeader:SetPoint('TOPLEFT', listPanel, 'TOPLEFT', 18, -42)
nameHeader:SetText('CHARAKTER')

local goldHeader = listPanel:CreateFontString(nil, 'OVERLAY', 'GameFontDisableSmall')
goldHeader:SetPoint('TOPRIGHT', listPanel, 'TOPRIGHT', -18, -42)
goldHeader:SetText('GOLDSTAND')

local scroll = CreateFrame('ScrollFrame', nil, listPanel)
scroll:SetPoint('TOPLEFT', listPanel, 'TOPLEFT', 14, -60)
scroll:SetPoint('BOTTOMRIGHT', listPanel, 'BOTTOMRIGHT', -14, 12)
scroll:EnableMouseWheel(true)

local scrollChild = CreateFrame('Frame', nil, scroll)
scrollChild:SetSize(602, 200)
scroll:SetScrollChild(scrollChild)

-- Alle 10 Charakterplätze passen in den sichtbaren Bereich; kein Scrollbalken/Scrollen nötig.
scroll:EnableMouseWheel(false)

for i = 1, MAX_ROWS do
    local row = CreateFrame('Frame', nil, scrollChild, 'BackdropTemplate')
    row:SetSize(602, 20)
    row:SetPoint('TOPLEFT', scrollChild, 'TOPLEFT', 0, -((i - 1) * 20))
    row:SetBackdrop({bgFile='Interface\\ChatFrame\\ChatFrameBackground'})
    row:SetBackdropColor(0.02, 0.06, 0.09, (i % 2 == 0) and 0.32 or 0.18)

    local name = row:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')
    name:SetPoint('LEFT', row, 'LEFT', 6, 0)
    name:SetWidth(310)
    name:SetJustifyH('LEFT')
    name:SetFont('Fonts\\FRIZQT__.TTF', 14, 'OUTLINE')

    -- Feste Geld-Spalten: Gold, Silber und Kupfer stehen in jeder Zeile exakt gleich.
    local copperIcon = row:CreateTexture(nil, 'ARTWORK')
    copperIcon:SetSize(14, 14)
    copperIcon:SetPoint('RIGHT', row, 'RIGHT', -14, 0)
    copperIcon:SetTexture('Interface\\MoneyFrame\\UI-CopperIcon')

    local copper = row:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')
    copper:SetPoint('RIGHT', copperIcon, 'LEFT', -3, 0)
    copper:SetWidth(22)
    copper:SetJustifyH('RIGHT')
    copper:SetFont('Fonts\\FRIZQT__.TTF', 14, 'OUTLINE')
    copper:SetTextColor(0.93, 0.65, 0.37)

    local silverIcon = row:CreateTexture(nil, 'ARTWORK')
    silverIcon:SetSize(14, 14)
    silverIcon:SetPoint('RIGHT', row, 'RIGHT', -60, 0)
    silverIcon:SetTexture('Interface\\MoneyFrame\\UI-SilverIcon')

    local silver = row:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')
    silver:SetPoint('RIGHT', silverIcon, 'LEFT', -3, 0)
    silver:SetWidth(22)
    silver:SetJustifyH('RIGHT')
    silver:SetFont('Fonts\\FRIZQT__.TTF', 14, 'OUTLINE')
    silver:SetTextColor(0.78, 0.78, 0.81)

    local goldIcon = row:CreateTexture(nil, 'ARTWORK')
    goldIcon:SetSize(14, 14)
    goldIcon:SetPoint('RIGHT', row, 'RIGHT', -106, 0)
    goldIcon:SetTexture('Interface\\MoneyFrame\\UI-GoldIcon')

    local gold = row:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')
    gold:SetPoint('RIGHT', goldIcon, 'LEFT', -3, 0)
    gold:SetWidth(115)
    gold:SetJustifyH('RIGHT')
    gold:SetFont('Fonts\\FRIZQT__.TTF', 14, 'OUTLINE')
    gold:SetTextColor(1.00, 0.84, 0.00)

    row.name = name
    row.gold = gold
    row.silver = silver
    row.copper = copper
    row:Hide()
    rows[i] = row
end

local emptyText = listPanel:CreateFontString(nil, 'OVERLAY', 'GameFontDisable')
emptyText:SetPoint('CENTER', listPanel, 'CENTER', 0, -8)
emptyText:SetText('Noch keine Charakterdaten gespeichert.')

local info = frame:CreateFontString(nil, 'OVERLAY', 'GameFontDisableSmall')
info:SetPoint('TOPRIGHT', listPanel, 'BOTTOMRIGHT', 0, -8)
info:SetText('Gespeichert werden nur Charaktere, mit denen TinkerBox auf diesem Realm geladen wurde.')

local function GetClassColorCode(classFile)
    local c = classFile and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFile]
    if not c then return '|cffffffff' end
    local r = math.floor((c.r or 1) * 255 + 0.5)
    local g = math.floor((c.g or 1) * 255 + 0.5)
    local b = math.floor((c.b or 1) * 255 + 0.5)
    return string.format('|cff%02x%02x%02x', r, g, b)
end

local function Refresh()
    local db = EnsureDB()
    StoreCurrentCharacterGold()

    local realm = GetRealmName() or 'Unbekannter Realm'
    local player = UnitName('player') or 'Unbekannt'

    local realmData = db.realmGold[realm] or {}
    local realmTotal = 0
    local names = {}
    for charName, money in pairs(realmData) do
        realmTotal = realmTotal + (tonumber(money) or 0)
        names[#names + 1] = charName
    end
    table.sort(names, function(a, b) return string.lower(a) < string.lower(b) end)

    local totalGoldAmount = math.floor(realmTotal / 10000)
    local totalSilverAmount = math.floor((realmTotal % 10000) / 100)
    local totalCopperAmount = math.floor(realmTotal % 100)
    totalGold:SetText(tostring(totalGoldAmount))
    totalSilver:SetText(tostring(totalSilverAmount))
    totalCopper:SetText(tostring(totalCopperAmount))

    for _, row in ipairs(rows) do row:Hide() end
    emptyText:SetShown(#names == 0)

    for i, charName in ipairs(names) do
        local row = rows[i]
        if not row then break end
        local realmClasses = db.realmClasses[realm] or {}
        local color = GetClassColorCode(realmClasses[charName])
        row.name:SetText(color .. charName .. '|r')
        local money = tonumber(realmData[charName]) or 0
        local gold = math.floor(money / 10000)
        local silver = math.floor((money % 10000) / 100)
        local copper = math.floor(money % 100)
        row.gold:SetText(tostring(gold))
        row.silver:SetText(tostring(silver))
        row.copper:SetText(tostring(copper))
        row:Show()
    end

    scrollChild:SetHeight(math.max(1, math.min(MAX_ROWS, #names) * 20))
end

frame.Refresh = Refresh
frame.StoreCurrent = StoreCurrentCharacterGold
frame:RegisterEvent('PLAYER_ENTERING_WORLD')
frame:RegisterEvent('PLAYER_MONEY')
frame:RegisterEvent('CURRENCY_DISPLAY_UPDATE')
frame:SetScript('OnEvent', function()
    StoreCurrentCharacterGold()
    if frame:IsShown() then Refresh() end
end)

frame:SetScript('OnShow', function()
    TB.UI.headerText:SetText('Zusatzinfos')
    TB.UI.subText:SetText('Charaktergold und Gesamt-Gold')
    Refresh()
end)
