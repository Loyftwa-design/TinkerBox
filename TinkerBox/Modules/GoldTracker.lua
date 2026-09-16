local addonName, TB = ...
local frame = TB.CreateModuleFrame('GoldTracker')

local historyFrame
local sessionFrame
local historyScroll
local UpdateHistoryDisplay
local UpdateSessionDisplay
local UpdateDisplay

local function EnsureDB()
    TinkerBoxDB.goldTracker = TinkerBoxDB.goldTracker or {}
    local gt = TinkerBoxDB.goldTracker
    gt.history = gt.history or {}
    gt.earned = tonumber(gt.earned) or 0
    gt.spent = tonumber(gt.spent) or 0
    gt.startMoney = tonumber(gt.startMoney) or GetMoney() or 0
    gt.lastMoney = tonumber(gt.lastMoney) or GetMoney() or 0
    return gt
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
    btn:SetScript('OnMouseDown', function(_, button)
        if button == 'LeftButton' then ApplyVisual('down') end
    end)
    btn:SetScript('OnMouseUp', function(self)
        if MouseIsOver(self) then ApplyVisual('hover') else ApplyVisual('idle') end
    end)
    return btn
end

local function CreatePopup(name, title, width, height)
    local popup = CreateFrame('Frame', name, UIParent, 'BackdropTemplate')
    popup:SetSize(width, height)
    popup:SetPoint('CENTER', TB.UI.mainFrame, 'CENTER', 390, 0)
    popup:SetMovable(true)
    popup:EnableMouse(true)
    popup:RegisterForDrag('LeftButton')
    popup:SetScript('OnDragStart', popup.StartMoving)
    popup:SetScript('OnDragStop', popup.StopMovingOrSizing)
    popup:SetBackdrop({
        bgFile = 'Interface\\ChatFrame\\ChatFrameBackground',
        edgeFile = 'Interface\\Buttons\\WHITE8x8',
        edgeSize = 1,
    })
    popup:SetBackdropColor(0.11, 0.14, 0.18, 0.90)
    popup:SetBackdropBorderColor(0.52, 0.62, 0.76, 0.95)
    popup:Hide()

    local heading = popup:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightLarge')
    heading:SetPoint('TOP', popup, 'TOP', 0, -8)
    heading:SetFont('Fonts\\FRIZQT__.TTF', 16, 'OUTLINE')
    heading:SetTextColor(1.00, 0.86, 0.25)
    heading:SetText(title)

    local divider = popup:CreateTexture(nil, 'ARTWORK')
    TB.ApplyAsset(divider, TB.Assets.DividerBottom, 'DividerMenu')
    divider:SetSize(width - 70, 20)
    divider:SetPoint('TOP', popup, 'TOP', 0, -22)

    local close = CreateFrame('Button', nil, popup)
    close:SetSize(32, 32)
    close:SetPoint('TOPRIGHT', popup, 'TOPRIGHT', -2, -2)
    local closeTex = close:CreateTexture(nil, 'ARTWORK')
    closeTex:SetAllPoints(close)
    TB.ApplyAsset(closeTex, TB.Assets.Close, 'Close')
    close:SetScript('OnClick', function() popup:Hide() end)
    close:SetScript('OnEnter', function() closeTex:SetAlpha(1) end)
    close:SetScript('OnLeave', function() closeTex:SetAlpha(0.92) end)
    closeTex:SetAlpha(0.92)

    popup.heading = heading
    popup.divider = divider
    return popup
end

local function EnforceHistoryLimit()
    local gt = EnsureDB()
    local limit = (TinkerBoxDB.settings and tonumber(TinkerBoxDB.settings.historyLimit)) or 50
    while #gt.history > limit do table.remove(gt.history) end
end

local function AddHistoryEntry(day, earned, spent)
    if not day or day == '' then return end
    earned = tonumber(earned) or 0
    spent = tonumber(spent) or 0
    if earned <= 0 and spent <= 0 then return end
    local gt = EnsureDB()
    table.insert(gt.history, 1, {
        date = day,
        earned = earned,
        spent = spent,
        net = earned - spent,
    })
    EnforceHistoryLimit()
end

local function HistoryEntryNet(entry)
    if type(entry) == 'table' then
        return tonumber(entry.net) or ((tonumber(entry.earned) or 0) - (tonumber(entry.spent) or 0))
    end
    if type(entry) ~= 'string' then return 0 end
    local sign = entry:find('Bilanz:%s*%-') and -1 or 1
    local g, s, c = entry:match('Bilanz:.-(%d+)g%s+(%d+)s%s+(%d+)k')
    if not g then return 0 end
    return sign * ((tonumber(g) or 0) * 10000 + (tonumber(s) or 0) * 100 + (tonumber(c) or 0))
end

local function HistoryEntryText(entry)
    if type(entry) == 'string' then return entry end
    if type(entry) ~= 'table' then return '' end
    local earned = tonumber(entry.earned) or 0
    local spent = tonumber(entry.spent) or 0
    local net = tonumber(entry.net) or (earned - spent)
    local netColor = net >= 0 and '|cff55ff55+' or '|cffff6666'
    return string.format('%s  |  Einnahmen: %s  |  Ausgaben: %s  |  Bilanz: %s%s|r',
        tostring(entry.date or ''), TB.FormatMoney(earned), TB.FormatMoney(spent), netColor, TB.FormatMoney(net))
end

local function EnsureDay()
    local gt = EnsureDB()
    local today = date('%Y-%m-%d')
    local currentMoney = GetMoney() or 0

    if gt.date and gt.date ~= '' and gt.date ~= today then
        AddHistoryEntry(gt.date, gt.earned, gt.spent)
        gt.date = today
        gt.startMoney = currentMoney
        gt.lastMoney = currentMoney
        gt.earned = 0
        gt.spent = 0
        gt.sessionStartEarned = 0
        gt.sessionStartSpent = 0
        if UpdateHistoryDisplay then UpdateHistoryDisplay() end
    elseif not gt.date or gt.date == '' then
        gt.date = today
        gt.startMoney = currentMoney
        gt.lastMoney = currentMoney
        gt.earned = 0
        gt.spent = 0
    end
end

local title = frame:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightLarge')
title:SetPoint('TOPLEFT', frame, 'TOPLEFT', 18, -30)
title:SetFont('Fonts\\FRIZQT__.TTF', 18, 'OUTLINE')
title:SetTextColor(1.00, 0.86, 0.25)
title:SetText('GoldKasse')

local subtitle = frame:CreateFontString(nil, 'OVERLAY', 'GameFontDisableSmall')
subtitle:SetPoint('LEFT', title, 'RIGHT', 14, -1)
subtitle:SetText('Tages-Kassensturz und Gold-Session')

local summary = CreatePanel(frame, 18, -62, 630, 82)

local currentLabel = summary:CreateFontString(nil, 'OVERLAY', 'GameFontDisableSmall')
currentLabel:SetPoint('TOPLEFT', summary, 'TOPLEFT', 18, -12)
currentLabel:SetText('AKTUELL')
local currentValue = summary:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightLarge')
currentValue:SetPoint('TOPLEFT', currentLabel, 'BOTTOMLEFT', 0, -7)
currentValue:SetFont('Fonts\\FRIZQT__.TTF', 16, 'OUTLINE')

local earnedLabel = summary:CreateFontString(nil, 'OVERLAY', 'GameFontDisableSmall')
earnedLabel:SetPoint('TOP', summary, 'TOP', -70, -12)
earnedLabel:SetText('EINNAHMEN HEUTE')
local earnedValue = summary:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightLarge')
earnedValue:SetPoint('TOP', earnedLabel, 'BOTTOM', 0, -7)
earnedValue:SetFont('Fonts\\FRIZQT__.TTF', 16, 'OUTLINE')

local spentLabel = summary:CreateFontString(nil, 'OVERLAY', 'GameFontDisableSmall')
spentLabel:SetPoint('TOP', summary, 'TOP', 100, -12)
spentLabel:SetText('AUSGABEN HEUTE')
local spentValue = summary:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightLarge')
spentValue:SetPoint('TOP', spentLabel, 'BOTTOM', 0, -7)
spentValue:SetFont('Fonts\\FRIZQT__.TTF', 16, 'OUTLINE')

local netLabel = summary:CreateFontString(nil, 'OVERLAY', 'GameFontDisableSmall')
netLabel:SetPoint('TOPRIGHT', summary, 'TOPRIGHT', -18, -12)
netLabel:SetText('BILANZ')
local netValue = summary:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightLarge')
netValue:SetPoint('TOPRIGHT', netLabel, 'BOTTOMRIGHT', 0, -7)
netValue:SetFont('Fonts\\FRIZQT__.TTF', 16, 'OUTLINE')

local chartPanel = CreatePanel(frame, 18, -154, 630, 176)
local chartTitle = chartPanel:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
chartTitle:SetPoint('TOPLEFT', chartPanel, 'TOPLEFT', 14, -10)
chartTitle:SetText('|cffffd75eVerlauf der letzten Tage|r')

local chartHint = chartPanel:CreateFontString(nil, 'OVERLAY', 'GameFontDisableSmall')
chartHint:SetPoint('LEFT', chartTitle, 'RIGHT', 12, 0)
chartHint:SetText('kumulierte Bilanz')

local zeroLine = chartPanel:CreateTexture(nil, 'ARTWORK')
zeroLine:SetTexture('Interface\\Buttons\\WHITE8x8')
zeroLine:SetVertexColor(0.45, 0.55, 0.65, 0.40)
zeroLine:SetPoint('LEFT', chartPanel, 'LEFT', 24, -12)
zeroLine:SetPoint('RIGHT', chartPanel, 'RIGHT', -24, -12)
zeroLine:SetHeight(1)

local chartBars = {}
for i = 1, 6 do
    local bar = chartPanel:CreateTexture(nil, 'ARTWORK')
    bar:SetTexture('Interface\\Buttons\\WHITE8x8')
    bar:SetSize(54, 4)

    local value = chartPanel:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
    value:SetFont('Fonts\\FRIZQT__.TTF', 9, 'OUTLINE')
    value:SetJustifyH('CENTER')

    local dateLabel = chartPanel:CreateFontString(nil, 'OVERLAY', 'GameFontDisableSmall')
    dateLabel:SetFont('Fonts\\FRIZQT__.TTF', 8, 'OUTLINE')
    dateLabel:SetJustifyH('CENTER')

    chartBars[i] = { bar = bar, value = value, dateLabel = dateLabel }
end

local emptyChart = chartPanel:CreateFontString(nil, 'OVERLAY', 'GameFontDisable')
emptyChart:SetPoint('CENTER', chartPanel, 'CENTER', 0, -4)
emptyChart:SetText('Noch kein Tagesverlauf vorhanden.')

local sessionBtn = CreateThemeButton(frame, 150, 32, 'Session starten')
sessionBtn:SetPoint('BOTTOMLEFT', frame, 'BOTTOMLEFT', 18, 14)

local historyBtn = CreateThemeButton(frame, 130, 32, 'Verlauf')
historyBtn:SetPoint('LEFT', sessionBtn, 'RIGHT', 12, 0)

local info = frame:CreateFontString(nil, 'OVERLAY', 'GameFontDisableSmall')
info:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', -18, 20)
info:SetText('Goldänderungen werden automatisch erfasst.')

sessionFrame = CreatePopup('TinkerBoxGoldSession', 'Gold-Session', 196, 184)

local sessEarnedLabel = sessionFrame:CreateFontString(nil, 'OVERLAY', 'GameFontDisableSmall')
sessEarnedLabel:SetPoint('TOPLEFT', sessionFrame, 'TOPLEFT', 20, -58)
sessEarnedLabel:SetText('EINNAHMEN')
local sessEarned = sessionFrame:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')
sessEarned:SetPoint('TOPRIGHT', sessionFrame, 'TOPRIGHT', -20, -58)
sessEarned:SetJustifyH('RIGHT')

local sessSpentLabel = sessionFrame:CreateFontString(nil, 'OVERLAY', 'GameFontDisableSmall')
sessSpentLabel:SetPoint('TOPLEFT', sessEarnedLabel, 'BOTTOMLEFT', 0, -18)
sessSpentLabel:SetText('AUSGABEN')
local sessSpent = sessionFrame:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')
sessSpent:SetPoint('TOPRIGHT', sessEarned, 'BOTTOMRIGHT', 0, -18)
sessSpent:SetJustifyH('RIGHT')

local sessNetLabel = sessionFrame:CreateFontString(nil, 'OVERLAY', 'GameFontDisableSmall')
sessNetLabel:SetPoint('TOPLEFT', sessSpentLabel, 'BOTTOMLEFT', 0, -18)
sessNetLabel:SetText('GEWINN')
local sessNet = sessionFrame:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')
sessNet:SetPoint('TOPRIGHT', sessSpent, 'BOTTOMRIGHT', 0, -18)
sessNet:SetJustifyH('RIGHT')

local sessReset = CreateThemeButton(sessionFrame, 120, 30, 'Session Reset', true)
sessReset:SetPoint('BOTTOM', sessionFrame, 'BOTTOM', 0, 14)

historyFrame = CreatePopup('TinkerBoxGoldHistory', 'Gold-Verlauf', 293, 405)

local clearHistoryBtn = CreateThemeButton(historyFrame, 155, 30, 'Verlauf leeren', true)
clearHistoryBtn:SetPoint('TOP', historyFrame, 'TOP', 0, -48)

historyScroll = CreateFrame('ScrollingMessageFrame', nil, historyFrame)
historyScroll:SetPoint('TOPLEFT', historyFrame, 'TOPLEFT', 18, -94)
historyScroll:SetPoint('BOTTOMRIGHT', historyFrame, 'BOTTOMRIGHT', -18, 20)
historyScroll:SetFont(STANDARD_TEXT_FONT, 12, 'OUTLINE')
historyScroll:SetMaxLines(200)
historyScroll:SetFading(false)
historyScroll:SetJustifyH('LEFT')
historyScroll:EnableMouseWheel(true)
historyScroll:SetScript('OnMouseWheel', function(self, delta)
    if delta > 0 then self:ScrollUp() else self:ScrollDown() end
end)

local function UpdateChart()
    local gt = EnsureDB()
    local history = gt.history or {}
    local values = {}
    local running = 0

    local first = math.max(1, #history - 5)
    for i = #history, first, -1 do
        local entry = history[i]
        running = running + HistoryEntryNet(entry)
        values[#values + 1] = { net = running, entry = entry }
    end

    emptyChart:SetShown(#values == 0)
    local maxAbs = 1
    for _, v in ipairs(values) do maxAbs = math.max(maxAbs, math.abs(v.net)) end

    for i = 1, 6 do
        local obj = chartBars[i]
        local data = values[i]
        obj.bar:ClearAllPoints()
        obj.value:ClearAllPoints()
        obj.dateLabel:ClearAllPoints()
        if data then
            local h = math.max(5, math.floor((math.abs(data.net) / maxAbs) * 72))
            local x = 45 + ((i - 1) * 92)
            obj.bar:SetSize(48, h)
            obj.bar:SetPoint('BOTTOMLEFT', chartPanel, 'BOTTOMLEFT', x, 40)
            if data.net >= 0 then obj.bar:SetVertexColor(0.20, 0.80, 0.36, 0.78) else obj.bar:SetVertexColor(0.90, 0.22, 0.22, 0.78) end
            obj.value:SetPoint('BOTTOM', obj.bar, 'TOP', 0, 3)
            local gold = math.floor(math.abs(data.net) / 10000)
            obj.value:SetText((data.net >= 0 and '+' or '-') .. gold .. 'g')
            obj.dateLabel:SetPoint('TOP', obj.bar, 'BOTTOM', 0, -4)
            local e = data.entry
            local d = type(e) == 'table' and tostring(e.date or '') or tostring(e):match('^(%d%d%d%d%-%d%d%-%d%d)') or ''
            obj.dateLabel:SetText(d ~= '' and d:sub(6) or '')
            obj.bar:Show(); obj.value:Show(); obj.dateLabel:Show()
        else
            obj.bar:Hide(); obj.value:Hide(); obj.dateLabel:Hide()
        end
    end
end

UpdateDisplay = function()
    EnsureDay()
    local gt = EnsureDB()
    local currentMoney = GetMoney() or 0
    local balance = (gt.earned or 0) - (gt.spent or 0)

    currentValue:SetText(TB.FormatMoney(currentMoney))
    earnedValue:SetText(TB.FormatMoney(gt.earned or 0))
    spentValue:SetText(TB.FormatMoney(gt.spent or 0))
    if balance >= 0 then
        netValue:SetText('|cff55ff55+' .. TB.FormatMoney(balance) .. '|r')
    else
        netValue:SetText('|cffff6666' .. TB.FormatMoney(balance) .. '|r')
    end
    UpdateChart()
end

UpdateSessionDisplay = function()
    local gt = EnsureDB()
    local earnedNow = gt.earned or 0
    local spentNow = gt.spent or 0
    local sEarned = math.max(0, earnedNow - (gt.sessionStartEarned or earnedNow))
    local sSpent = math.max(0, spentNow - (gt.sessionStartSpent or spentNow))
    local net = sEarned - sSpent

    sessEarned:SetText(TB.FormatMoney(sEarned))
    sessSpent:SetText(TB.FormatMoney(sSpent))
    if net >= 0 then
        sessNet:SetText('|cff55ff55+' .. TB.FormatMoney(net) .. '|r')
    else
        sessNet:SetText('|cffff6666' .. TB.FormatMoney(net) .. '|r')
    end
end

UpdateHistoryDisplay = function()
    if not historyScroll then return end
    historyScroll:Clear()
    local gt = EnsureDB()
    if #gt.history == 0 then
        historyScroll:AddMessage('Noch kein Verlauf gespeichert.')
        return
    end
    for _, entry in ipairs(gt.history) do
        historyScroll:AddMessage(HistoryEntryText(entry))
    end
end

sessionBtn:SetScript('OnClick', function()
    local gt = EnsureDB()
    gt.sessionStartEarned = gt.earned or 0
    gt.sessionStartSpent = gt.spent or 0
    sessionFrame:Show()
    UpdateSessionDisplay()
    TB.Message('Gold-Session gestartet.')
end)

sessReset:SetScript('OnClick', function()
    local gt = EnsureDB()
    gt.sessionStartEarned = gt.earned or 0
    gt.sessionStartSpent = gt.spent or 0
    UpdateSessionDisplay()
    TB.Message('Gold-Session wurde zurückgesetzt.')
end)

historyBtn:SetScript('OnClick', function()
    if historyFrame:IsShown() then historyFrame:Hide() else historyFrame:Show() end
end)

historyFrame:SetScript('OnShow', UpdateHistoryDisplay)

clearHistoryBtn:SetScript('OnClick', function()
    EnsureDB().history = {}
    UpdateHistoryDisplay()
    UpdateChart()
end)

frame:SetScript('OnShow', function()
    UpdateDisplay()
end)

frame:SetScript('OnHide', function()
    if historyFrame then historyFrame:Hide() end
    if sessionFrame then sessionFrame:Hide() end
end)

frame.EnsureDay = EnsureDay
frame.Refresh = UpdateDisplay
frame.OnMoneyChanged = function()
    if frame:IsShown() then UpdateDisplay() end
    if sessionFrame and sessionFrame:IsShown() then UpdateSessionDisplay() end
    if historyFrame and historyFrame:IsShown() then UpdateHistoryDisplay() end
end
