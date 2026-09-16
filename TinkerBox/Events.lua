local addonName, TB = ...
local eventFrame = CreateFrame('Frame')
eventFrame:RegisterEvent('PLAYER_LOGIN')
eventFrame:RegisterEvent('PLAYER_MONEY')
eventFrame:RegisterEvent('CURRENCY_DISPLAY_UPDATE')
eventFrame:RegisterEvent('COMBAT_LOG_EVENT_UNFILTERED')
eventFrame:RegisterEvent('CHAT_MSG_LOOT')

eventFrame:SetScript('OnEvent', function(_, event, ...)
    if event == 'PLAYER_LOGIN' then
        TB.EnsureDB()
        if TinkerBoxDB.settings.showMinimap == false and TinkerBoxMinimapButton then TinkerBoxMinimapButton:Hide() end
        if TB.Minimap then TB.Minimap.UpdatePosition() end
        if TB.UI and TB.UI.mainFrame then TB.UI.mainFrame:SetScale(TinkerBoxDB.settings.uiScale or 0.82) end
        if TB.Modules.GoldTracker and TB.Modules.GoldTracker.Refresh then TB.Modules.GoldTracker.Refresh() end
        if TB.Modules.Zusatzinfos and TB.Modules.Zusatzinfos.StoreCurrent then TB.Modules.Zusatzinfos.StoreCurrent() end
        if TB.Modules.FarmTracker and TB.Modules.FarmTracker.Initialize then TB.Modules.FarmTracker.Initialize() end
        TB.ShowModule('Home')
    elseif event == 'PLAYER_MONEY' then
        local gt = TinkerBoxDB.goldTracker
        if TB.Modules.GoldTracker and TB.Modules.GoldTracker.EnsureDay then
            TB.Modules.GoldTracker.EnsureDay()
        else
            local today = date('%Y-%m-%d')
            if gt.date ~= today then
                gt.date = today
                gt.startMoney = GetMoney()
                gt.earned = 0
                gt.spent = 0
                gt.lastMoney = GetMoney()
            end
        end
        local current = GetMoney()
        local diff = current - (gt.lastMoney or current)
        if diff > 0 then gt.earned = (gt.earned or 0) + diff elseif diff < 0 then gt.spent = (gt.spent or 0) + math.abs(diff) end
        gt.lastMoney = current
        if TB.Modules.GoldTracker and TB.Modules.GoldTracker.OnMoneyChanged then TB.Modules.GoldTracker.OnMoneyChanged() end
        if TB.Modules.Zusatzinfos and TB.Modules.Zusatzinfos.StoreCurrent then TB.Modules.Zusatzinfos.StoreCurrent() end
        if TB.Modules.Zusatzinfos and TB.Modules.Zusatzinfos:IsShown() and TB.Modules.Zusatzinfos.Refresh then TB.Modules.Zusatzinfos.Refresh() end
    elseif event == 'CURRENCY_DISPLAY_UPDATE' then
        if TB.Modules.Zusatzinfos and TB.Modules.Zusatzinfos:IsShown() and TB.Modules.Zusatzinfos.Refresh then TB.Modules.Zusatzinfos.Refresh() end
    elseif event == 'COMBAT_LOG_EVENT_UNFILTERED' then
        if TB.Modules.FarmTracker and TB.Modules.FarmTracker.OnCombatLogEvent then TB.Modules.FarmTracker.OnCombatLogEvent() end
    elseif event == 'CHAT_MSG_LOOT' then
        local msg = ...
        if TB.Modules.FarmTracker and TB.Modules.FarmTracker.OnLootMessage then TB.Modules.FarmTracker.OnLootMessage(msg) end
    end
end)
