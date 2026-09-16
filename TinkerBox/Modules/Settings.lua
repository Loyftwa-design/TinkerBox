local addonName, TB = ...
local frame = TB.CreateModuleFrame('Settings')

local CHECK_EMPTY = 'Interface\\AddOns\\TinkerBox\\Media\\Controls\\checkbox_empty.tga'
local CHECK_CHECKED = 'Interface\\AddOns\\TinkerBox\\Media\\Controls\\checkbox_checked.tga'

local function EnsureSettings()
    TB.EnsureDB()
    local s = TinkerBoxDB.settings
    if s.showMinimap == nil then s.showMinimap = true end
    if s.enableChatMsgs == nil then s.enableChatMsgs = true end
    if s.uiScale == nil then s.uiScale = 0.82 end
    if s.historyLimit == nil then s.historyLimit = 50 end
    if s.lockMiniTracker == nil then s.lockMiniTracker = false end
    if s.lockShoppingHUD == nil then s.lockShoppingHUD = false end
    return s
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

    local txt = btn:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')
    txt:SetPoint('CENTER', 0, -1)
    txt:SetFont('Fonts\\FRIZQT__.TTF', 11, 'OUTLINE')
    txt:SetShadowColor(0, 0, 0, 1)
    txt:SetShadowOffset(1, -1)
    txt:SetText(label)

    local function ApplyVisual(state)
        if red then
            if state == 'hover' or state == 'down' then
                bg:SetTexture(TB.Assets.FarmButtonRedHover or TB.Assets.FarmButtonRed)
            else
                bg:SetTexture(TB.Assets.FarmButtonRed)
            end
        else
            if state == 'hover' or state == 'down' then
                bg:SetTexture(TB.Assets.FarmButtonBlue)
            else
                bg:SetTexture(TB.Assets.FarmButtonIdle)
            end
        end
        bg:SetTexCoord(0, 1, 0, 1)
        bg:SetAlpha(state == 'down' and 1 or 0.97)
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

    btn.bg = bg
    btn.text = txt
    return btn
end

local function CreateSettingCheck(parent, x, y, label, description)
    local check = CreateFrame('CheckButton', nil, parent)
    check:SetSize(30, 30)
    check:SetPoint('TOPLEFT', parent, 'TOPLEFT', x, y)

    local normal = check:CreateTexture(nil, 'BACKGROUND')
    normal:SetSize(32, 32)
    normal:SetPoint('CENTER')
    normal:SetTexture(CHECK_EMPTY)
    normal:SetTexCoord(0.04, 0.58, 0.01, 0.54)
    check:SetNormalTexture(normal)

    local checked = check:CreateTexture(nil, 'ARTWORK')
    checked:SetSize(32, 32)
    checked:SetPoint('CENTER')
    checked:SetTexture(CHECK_CHECKED)
    checked:SetTexCoord(0.02, 0.53, 0.01, 0.54)
    check:SetCheckedTexture(checked)

    local text = parent:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')
    text:SetPoint('LEFT', check, 'RIGHT', 8, 3)
    text:SetFont('Fonts\\FRIZQT__.TTF', 13, 'OUTLINE')
    text:SetTextColor(0.94, 0.96, 1.00)
    text:SetText(label)

    local sub = parent:CreateFontString(nil, 'OVERLAY', 'GameFontDisableSmall')
    sub:SetPoint('TOPLEFT', text, 'BOTTOMLEFT', 0, -2)
    sub:SetWidth(235)
    sub:SetJustifyH('LEFT')
    sub:SetText(description or '')

    check.label = text
    check.description = sub
    return check
end

local function ApplyMovementLocks()
    local s = EnsureSettings()

    local farmMini = _G.TinkerBoxFarmMiniTracker
    if farmMini then
        farmMini:SetMovable(not s.lockMiniTracker)
        if s.lockMiniTracker then
            farmMini:RegisterForDrag()
        else
            farmMini:RegisterForDrag('LeftButton')
        end
    end

    local shopping = _G.TinkerBoxCraftingShoppingHud
    if shopping then
        shopping:SetMovable(not s.lockShoppingHUD)
        if s.lockShoppingHUD then
            shopping:RegisterForDrag()
        else
            shopping:RegisterForDrag('LeftButton')
        end
    end
end

local title = frame:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightLarge')
title:SetPoint('TOPLEFT', frame, 'TOPLEFT', 18, -30)
title:SetFont('Fonts\\FRIZQT__.TTF', 18, 'OUTLINE')
title:SetTextColor(1.00, 0.86, 0.25)
title:SetText('Einstellungen')

local subtitle = frame:CreateFontString(nil, 'OVERLAY', 'GameFontDisableSmall')
subtitle:SetPoint('LEFT', title, 'RIGHT', 14, -1)
subtitle:SetText('Anzeige, Verhalten und gespeicherte Daten')

local uiPanel = CreatePanel(frame, 18, -62, 306, 300)

local uiTitle = uiPanel:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
uiTitle:SetPoint('TOPLEFT', uiPanel, 'TOPLEFT', 14, -11)
uiTitle:SetFont('Fonts\\FRIZQT__.TTF', 14, 'OUTLINE')
uiTitle:SetText('|cffffd75eBenutzeroberfläche|r')

local cbMinimap = CreateSettingCheck(uiPanel, 14, -38,
    'Minimap-Button anzeigen',
    'TinkerBox über die Minimap öffnen oder schließen.')

local cbLockFarm = CreateSettingCheck(uiPanel, 14, -96,
    'Farm-Session fixieren',
    'Verhindert das Verschieben des Farm-Session-Fensters.')

local cbLockShopping = CreateSettingCheck(uiPanel, 14, -154,
    'Einkaufsliste fixieren',
    'Verhindert das Verschieben der CraftingList-Einkaufsliste.')

local scaleLabel = uiPanel:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')
scaleLabel:SetPoint('TOPLEFT', uiPanel, 'TOPLEFT', 18, -220)
scaleLabel:SetFont('Fonts\\FRIZQT__.TTF', 13, 'OUTLINE')
scaleLabel:SetText('UI-Skalierung')

local scaleValue = uiPanel:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
scaleValue:SetPoint('TOPRIGHT', uiPanel, 'TOPRIGHT', -18, -220)
scaleValue:SetFont('Fonts\\FRIZQT__.TTF', 13, 'OUTLINE')
scaleValue:SetTextColor(1.00, 0.86, 0.25)

local scaleSlider = CreateFrame('Slider', 'TinkerBoxScaleSliderV2', uiPanel, 'OptionsSliderTemplate')
scaleSlider:SetPoint('TOPLEFT', uiPanel, 'TOPLEFT', 26, -250)
scaleSlider:SetSize(252, 16)
scaleSlider:SetMinMaxValues(0.65, 1.00)
scaleSlider:SetValueStep(0.01)
scaleSlider:SetObeyStepOnDrag(true)
_G[scaleSlider:GetName() .. 'Low']:SetText('65%')
_G[scaleSlider:GetName() .. 'High']:SetText('100%')
_G[scaleSlider:GetName() .. 'Text']:SetText('')

local dataPanel = CreatePanel(frame, 342, -62, 306, 300)

local dataTitle = dataPanel:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
dataTitle:SetPoint('TOPLEFT', dataPanel, 'TOPLEFT', 14, -11)
dataTitle:SetFont('Fonts\\FRIZQT__.TTF', 14, 'OUTLINE')
dataTitle:SetText('|cffffd75eSystem & Daten|r')

local cbChat = CreateSettingCheck(dataPanel, 14, -38,
    'Chat-Benachrichtigungen',
    'Zeigt Statusmeldungen von TinkerBox im Chat an.')

local historyLabel = dataPanel:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')
historyLabel:SetPoint('TOPLEFT', dataPanel, 'TOPLEFT', 18, -112)
historyLabel:SetFont('Fonts\\FRIZQT__.TTF', 13, 'OUTLINE')
historyLabel:SetText('Verlaufs-Limit')

local historyValue = dataPanel:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
historyValue:SetPoint('TOPRIGHT', dataPanel, 'TOPRIGHT', -18, -112)
historyValue:SetFont('Fonts\\FRIZQT__.TTF', 13, 'OUTLINE')
historyValue:SetTextColor(1.00, 0.86, 0.25)

local historyHint = dataPanel:CreateFontString(nil, 'OVERLAY', 'GameFontDisableSmall')
historyHint:SetPoint('TOPLEFT', historyLabel, 'BOTTOMLEFT', 0, -5)
historyHint:SetWidth(265)
historyHint:SetJustifyH('LEFT')
historyHint:SetText('Maximale Anzahl gespeicherter Einträge für Verlauf und Notizen.')

local historySlider = CreateFrame('Slider', 'TinkerBoxHistorySliderV2', dataPanel, 'OptionsSliderTemplate')
historySlider:SetPoint('TOPLEFT', dataPanel, 'TOPLEFT', 26, -169)
historySlider:SetSize(252, 16)
historySlider:SetMinMaxValues(10, 100)
historySlider:SetValueStep(5)
historySlider:SetObeyStepOnDrag(true)
_G[historySlider:GetName() .. 'Low']:SetText('10')
_G[historySlider:GetName() .. 'High']:SetText('100')
_G[historySlider:GetName() .. 'Text']:SetText('')

local resetDivider = dataPanel:CreateTexture(nil, 'ARTWORK')
resetDivider:SetTexture('Interface\\Buttons\\WHITE8x8')
resetDivider:SetVertexColor(0.16, 0.50, 0.72, 0.32)
resetDivider:SetPoint('TOPLEFT', dataPanel, 'TOPLEFT', 14, -215)
resetDivider:SetPoint('TOPRIGHT', dataPanel, 'TOPRIGHT', -14, -215)
resetDivider:SetHeight(1)

local resetLabel = dataPanel:CreateFontString(nil, 'OVERLAY', 'GameFontDisableSmall')
resetLabel:SetPoint('TOP', resetDivider, 'BOTTOM', 0, -10)
resetLabel:SetText('Setzt alle TinkerBox-Daten und Einstellungen zurück.')

local resetBtn = CreateThemeButton(dataPanel, 190, 32, 'Alle Daten löschen & Reset', true)
resetBtn:SetPoint('BOTTOM', dataPanel, 'BOTTOM', 0, 14)

local createdText = frame:CreateFontString(nil, 'OVERLAY', 'GameFontDisableSmall')
createdText:SetPoint('TOPLEFT', uiPanel, 'BOTTOMLEFT', 0, -6)
createdText:SetWidth(306)
createdText:SetFont('Fonts\\FRIZQT__.TTF', 11, 'OUTLINE')
createdText:SetTextColor(0.72, 0.76, 0.82)
createdText:SetJustifyH('LEFT')
createdText:SetText('Created by Loyftwa')

local versionText = frame:CreateFontString(nil, 'OVERLAY', 'GameFontDisableSmall')
versionText:SetPoint('TOPLEFT', dataPanel, 'BOTTOMLEFT', 0, -6)
versionText:SetWidth(306)
versionText:SetFont('Fonts\\FRIZQT__.TTF', 11, 'OUTLINE')
versionText:SetTextColor(0.72, 0.76, 0.82)
versionText:SetJustifyH('RIGHT')
versionText:SetText('TinkerBox v' .. tostring(TB.VERSION or '1.0.0'))

cbMinimap:SetScript('OnClick', function(self)
    local s = EnsureSettings()
    s.showMinimap = self:GetChecked() and true or false
    if TinkerBoxMinimapButton then
        if s.showMinimap then TinkerBoxMinimapButton:Show() else TinkerBoxMinimapButton:Hide() end
    end
end)

cbLockFarm:SetScript('OnClick', function(self)
    EnsureSettings().lockMiniTracker = self:GetChecked() and true or false
    ApplyMovementLocks()
end)

cbLockShopping:SetScript('OnClick', function(self)
    EnsureSettings().lockShoppingHUD = self:GetChecked() and true or false
    ApplyMovementLocks()
end)

cbChat:SetScript('OnClick', function(self)
    EnsureSettings().enableChatMsgs = self:GetChecked() and true or false
end)

scaleSlider:SetScript('OnValueChanged', function(self, value)
    local s = EnsureSettings()
    value = math.floor((value * 100) + 0.5) / 100
    s.uiScale = value
    scaleValue:SetText(string.format('%d%%', math.floor(value * 100 + 0.5)))
    if TB.UI.mainFrame then TB.UI.mainFrame:SetScale(value) end
end)

historySlider:SetScript('OnValueChanged', function(self, value)
    local s = EnsureSettings()
    local rounded = math.floor((value + 2.5) / 5) * 5
    rounded = math.max(10, math.min(100, rounded))
    s.historyLimit = rounded
    historyValue:SetText(tostring(rounded))
end)

resetBtn:SetScript('OnClick', function()
    StaticPopupDialogs['TINKERBOX_FACTORY_RESET'] = {
        text = '|cffff5555WARNUNG:|r\\nMöchtest du wirklich ALLE gespeicherten TinkerBox-Daten löschen?\\n\\nFavoriten, Listen, Notizen, Goldverlauf und Einstellungen werden zurückgesetzt. Danach wird das UI neu geladen.',
        button1 = 'Ja, alles löschen',
        button2 = 'Abbrechen',
        OnAccept = function()
            TinkerBoxDB = {}
            ReloadUI()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }
    StaticPopup_Show('TINKERBOX_FACTORY_RESET')
end)

local function Refresh()
    local s = EnsureSettings()
    cbMinimap:SetChecked(s.showMinimap ~= false)
    cbLockFarm:SetChecked(s.lockMiniTracker == true)
    cbLockShopping:SetChecked(s.lockShoppingHUD == true)
    cbChat:SetChecked(s.enableChatMsgs ~= false)

    scaleSlider:SetValue(tonumber(s.uiScale) or 0.82)
    scaleValue:SetText(string.format('%d%%', math.floor((tonumber(s.uiScale) or 0.82) * 100 + 0.5)))

    historySlider:SetValue(tonumber(s.historyLimit) or 50)
    historyValue:SetText(tostring(tonumber(s.historyLimit) or 50))

    ApplyMovementLocks()
end

frame.Refresh = Refresh
frame.ApplyMovementLocks = ApplyMovementLocks
frame:SetScript('OnShow', function()
    TB.UI.headerText:SetText('Einstellungen')
    TB.UI.subText:SetText('Anzeige, Verhalten und gespeicherte Daten')
    Refresh()
end)

local settingsEvent = CreateFrame('Frame')
settingsEvent:RegisterEvent('PLAYER_LOGIN')
settingsEvent:SetScript('OnEvent', function()
    EnsureSettings()
    ApplyMovementLocks()
end)
