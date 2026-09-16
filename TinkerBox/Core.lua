local addonName, TB = ...
_G.TinkerBox = TB
TB.VERSION = "1.0.0"
TB.Modules = TB.Modules or {}
TB.UI = TB.UI or {}
TB.Events = TB.Events or {}
TB.Assets = {
    MainFrame = "Interface\\AddOns\\TinkerBox\\Media\\Frames\\main_frame.tga",
    PopupWide = "Interface\\AddOns\\TinkerBox\\Media\\Frames\\popup_wide.tga",
    PopupMedium = "Interface\\AddOns\\TinkerBox\\Media\\Frames\\popup_medium.tga",
    FavoritesFrameClean = "Interface\\AddOns\\TinkerBox\\Media\\Frames\\favorites_frame_clean.tga",
    PopupSmall = "Interface\\AddOns\\TinkerBox\\Media\\Frames\\popup_small.tga",
    SessionFrameClean = "Interface\\AddOns\\TinkerBox\\Media\\Frames\\session_frame_clean.tga",
    Close = "Interface\\AddOns\\TinkerBox\\Media\\Buttons\\close_large.tga",
    ButtonBlue = "Interface\\AddOns\\TinkerBox\\Media\\Buttons\\blue_long_1.tga",
    ButtonBlue2 = "Interface\\AddOns\\TinkerBox\\Media\\Buttons\\blue_long_2.tga",
    ButtonDark = "Interface\\AddOns\\TinkerBox\\Media\\Buttons\\dark_long.tga",
    MenuActive = "Interface\\AddOns\\TinkerBox\\Media\\Buttons\\menu_active.tga",
    MenuIdle = "Interface\\AddOns\\TinkerBox\\Media\\Buttons\\menu_idle.tga",
    ButtonRed = "Interface\\AddOns\\TinkerBox\\Media\\Buttons\\red_long_1.tga",
    FarmButtonIdle = "Interface\\AddOns\\TinkerBox\\Media\\Buttons\\farm_button_idle.tga",
    FarmButtonBlue = "Interface\\AddOns\\TinkerBox\\Media\\Buttons\\farm_button_blue.tga",
    FarmButtonRed = "Interface\\AddOns\\TinkerBox\\Media\\Buttons\\farm_button_red.tga",
    FarmButtonRedHover = "Interface\\AddOns\\TinkerBox\\Media\\Buttons\\farm_button_red_hover.tga",
    DividerTop = "Interface\\AddOns\\TinkerBox\\Media\\Decoration\\divider_blue_top.tga",
    DividerBottom = "Interface\\AddOns\\TinkerBox\\Media\\Decoration\\divider_blue_bottom.tga",
    DividerMenu = "Interface\\AddOns\\TinkerBox\\Media\\Decoration\\divider_blue_bottom.tga",
    HeaderSmall = "Interface\\AddOns\\TinkerBox\\Media\\Decoration\\header_small.tga",
    HomeArt = "Interface\\AddOns\\TinkerBox\\Media\\Decoration\\welcome.tga",
    Nav = {
        Home = "Interface\\AddOns\\TinkerBox\\Media\\Navigation\\home.tga",
        FarmTracker = "Interface\\AddOns\\TinkerBox\\Media\\Navigation\\farmtracker.tga",
        CraftingList = "Interface\\AddOns\\TinkerBox\\Media\\Navigation\\crafting.tga",
        GoldTracker = "Interface\\AddOns\\TinkerBox\\Media\\Navigation\\gold.tga",
        Zusatzinfos = "Interface\\AddOns\\TinkerBox\\Media\\Navigation\\zusatzinfos.tga",
        TinkerNotes = "Interface\\AddOns\\TinkerBox\\Media\\Navigation\\notes.tga",
        Settings = "Interface\\AddOns\\TinkerBox\\Media\\Navigation\\settings.tga",
    },
 }

TB.AssetCoords = {
    MainFrame = {0, 0.9619140625, 0, 0.591796875},
    ButtonBlue = {0.03125, 0.8359375, 0.0, 0.546875},
    ButtonBlue2 = {0.06640625, 0.87109375, 0.078125, 0.625},
    ButtonDark = {0.06640625, 0.8671875, 0.078125, 0.5390625},
    ButtonRed = {0, 0.859375, 0, 0.640625},
    MenuActive = {0, 1, 0, 1},
    MenuIdle = {0, 1, 0, 1},
    Close = {0, 0.7421875, 0, 0.78125},
    Home = {0, 0.8046875, 0, 0.8046875},
    FarmTracker = {0, 0.8203125, 0, 0.796875},
    CraftingList = {0, 0.8125, 0, 0.796875},
    GoldTracker = {0, 0.8203125, 0, 0.8046875},
    TinkerNotes = {0, 0.7890625, 0, 0.7734375},
    Zusatzinfos = {0, 0.8203125, 0, 0.78125},
    Settings = {0, 0.8125, 0, 0.8515625},
    DividerMenu = {0.0078125, 0.556640625, 0.046875, 0.5},
}

function TB.ApplyAsset(texture, path, coordKey)
    texture:SetTexture(path)
    local c = TB.AssetCoords[coordKey]
    if c then texture:SetTexCoord(c[1], c[2], c[3], c[4]) end
end

local function defaults()
    return {
        minimapPos = 200,
        notes = { text = "" },
        goldTracker = { startMoney = 0, earned = 0, spent = 0, lastMoney = 0, date = "", history = {}, sessionStartEarned = 0, sessionStartSpent = 0 },
        zusatzinfos = { realmGold = {} },
        farmTracker = { trackedItemName = '', trackedItemIcon = nil, currentMaxTargets = 3, targets = {}, history = {}, favorites = {} },
        craftingList = { items = {}, recipes = {}, favorites = {} },
        settings = { showMinimap = true, enableChatMsgs = true, uiScale = 0.82, historyLimit = 50, lockMiniTracker = false, lockShoppingHUD = false },
    }
end

function TB.EnsureDB()
    local d = defaults()
    TinkerBoxDB = TinkerBoxDB or {}
    for k,v in pairs(d) do
        if TinkerBoxDB[k] == nil then
            if type(v) == 'table' then
                local t = {}
                for k2,v2 in pairs(v) do t[k2] = v2 end
                TinkerBoxDB[k] = t
            else
                TinkerBoxDB[k] = v
            end
        end
    end
    if type(TinkerBoxDB.goldTracker.history) ~= 'table' then TinkerBoxDB.goldTracker.history = {} end
    if type(TinkerBoxDB.zusatzinfos.realmGold) ~= 'table' then TinkerBoxDB.zusatzinfos.realmGold = {} end
    if type(TinkerBoxDB.farmTracker) ~= 'table' then TinkerBoxDB.farmTracker = {} end
    if type(TinkerBoxDB.craftingList) ~= 'table' then TinkerBoxDB.craftingList = { items = {} } end
    if type(TinkerBoxDB.craftingList.items) ~= 'table' then TinkerBoxDB.craftingList.items = {} end
    if type(TinkerBoxDB.craftingList.recipes) ~= 'table' then TinkerBoxDB.craftingList.recipes = {} end
    if type(TinkerBoxDB.craftingList.favorites) ~= 'table' then TinkerBoxDB.craftingList.favorites = {} end
    if TinkerBoxDB.settings.historyLimit == nil then TinkerBoxDB.settings.historyLimit = 50 end
    if TinkerBoxDB.settings.lockMiniTracker == nil then TinkerBoxDB.settings.lockMiniTracker = false end
    if TinkerBoxDB.settings.lockShoppingHUD == nil then TinkerBoxDB.settings.lockShoppingHUD = false end
end

function TB.Message(msg)
    if TinkerBoxDB and TinkerBoxDB.settings and TinkerBoxDB.settings.enableChatMsgs == false then return end
    DEFAULT_CHAT_FRAME:AddMessage('|cff33ccffTinkerBox:|r ' .. msg)
end

function TB.FormatMoney(copper)
    copper = tonumber(copper) or 0
    local gold = math.floor(copper / 10000)
    local silver = math.floor((copper % 10000) / 100)
    local cop = math.floor(copper % 100)
    return string.format('|cffffd700%d|r|TInterface\\MoneyFrame\\UI-GoldIcon:0:0:2:0|t |cffc7c7cf%d|r|TInterface\\MoneyFrame\\UI-SilverIcon:0:0:2:0|t |cffeda55f%d|r|TInterface\\MoneyFrame\\UI-CopperIcon:0:0:2:0|t', gold, silver, cop)
end

function TB.FormatNumber(value)
    local number = math.floor(tonumber(value) or 0)
    local sign = number < 0 and '-' or ''
    local s = tostring(math.abs(number))
    local out = ''
    while #s > 3 do
        out = '.' .. string.sub(s, -3) .. out
        s = string.sub(s, 1, #s - 3)
    end
    return sign .. s .. out
end

function TB.CreateModuleFrame(name)
    local parent = TB.UI.contentArea
    local f = CreateFrame('Frame', nil, parent)
    f:SetAllPoints(parent)
    f:Hide()
    TB.Modules[name] = f
    return f
end

function TB.ShowModule(name)
    for moduleName, frame in pairs(TB.Modules) do
        if frame then
            if moduleName == name then frame:Show() else frame:Hide() end
        end
    end
    TB.UI.currentModule = name
    if TB.UI and TB.UI.SetActiveNav then TB.UI.SetActiveNav(name) end
end

function TB.CreateArtButton(parent, width, height, texturePath, label)
    local btn = CreateFrame('Button', nil, parent)
    btn:SetSize(width, height)
    local tex = btn:CreateTexture(nil, 'BACKGROUND')
    tex:SetAllPoints(btn)
    tex:SetTexture(texturePath)
    btn.texture = tex
    local txt = btn:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')
    txt:SetPoint('CENTER', 0, 0)
    txt:SetText(label or '')
    btn.text = txt
    btn:SetHighlightTexture('Interface\\Buttons\\ButtonHilight-Square')
    return btn
end
