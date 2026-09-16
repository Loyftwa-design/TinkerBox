local addonName, TB = ...
local frame = TB.CreateModuleFrame('CraftingList')

local recipeRows = {}
local reagentRows = {}
local shoppingHudFrame
local favoritesFrame
local UpdateDisplay
local UpdateShoppingHud
local UpdateFavorites

local function EnsureDB()
    TinkerBoxDB.craftingList = TinkerBoxDB.craftingList or {}
    TinkerBoxDB.craftingList.recipes = TinkerBoxDB.craftingList.recipes or {}
    TinkerBoxDB.craftingList.favorites = TinkerBoxDB.craftingList.favorites or {}
    return TinkerBoxDB.craftingList
end

local function CopyRecipe(recipe)
    if not recipe then return nil end
    local copy = {
        recipeID = recipe.recipeID,
        name = recipe.name,
        icon = recipe.icon,
        multiplier = recipe.multiplier or 1,
        reagents = {},
    }
    for _, reagent in ipairs(recipe.reagents or {}) do
        copy.reagents[#copy.reagents + 1] = {
            itemID = reagent.itemID,
            name = reagent.name,
            icon = reagent.icon,
            count = reagent.count,
        }
    end
    return copy
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

-- Titel ----------------------------------------------------------------------
local title = frame:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightLarge')
title:SetPoint('TOPLEFT', frame, 'TOPLEFT', 18, -30)
title:SetFont('Fonts\\FRIZQT__.TTF', 18, 'OUTLINE')
title:SetTextColor(1.00, 0.86, 0.25)
title:SetText('CraftingList')

local subtitle = frame:CreateFontString(nil, 'OVERLAY', 'GameFontDisableSmall')
subtitle:SetPoint('LEFT', title, 'RIGHT', 14, -1)
subtitle:SetText('Rezepte, Reagenzien und Einkaufsliste')

-- Aktionszeile ----------------------------------------------------------------
local actionPanel = CreatePanel(frame, 18, -62, 630, 66)

local addRecipeBtn = CreateThemeButton(actionPanel, 150, 30, 'Rezept hinzufügen')
addRecipeBtn:SetPoint('LEFT', actionPanel, 'LEFT', 14, 0)

local favoritesBtn = CreateThemeButton(actionPanel, 126, 30, 'Favoriten')
favoritesBtn:SetPoint('LEFT', addRecipeBtn, 'RIGHT', 10, 0)

local shoppingBtn = CreateThemeButton(actionPanel, 150, 30, 'Einkaufsliste')
shoppingBtn:SetPoint('LEFT', favoritesBtn, 'RIGHT', 10, 0)

local clearBtn = CreateThemeButton(actionPanel, 126, 30, 'Liste leeren', true)
clearBtn:SetPoint('RIGHT', actionPanel, 'RIGHT', -14, 0)

-- Listenbereich ---------------------------------------------------------------
local listPanel = CreatePanel(frame, 18, -138, 630, 274)

local headerRecipe = listPanel:CreateFontString(nil, 'OVERLAY', 'GameFontDisableSmall')
headerRecipe:SetPoint('TOPLEFT', listPanel, 'TOPLEFT', 16, -7)
headerRecipe:SetText('AKTIVE REZEPTE UND REAGENZIEN')

local emptyText = listPanel:CreateFontString(nil, 'OVERLAY', 'GameFontDisable')
emptyText:SetPoint('CENTER', listPanel, 'CENTER', 0, -4)
emptyText:SetText('Noch keine Rezepte aktiv.\\nÖffne dein Berufsbuch, wähle ein Rezept und klicke auf „Rezept hinzufügen“.')
emptyText:SetJustifyH('CENTER')
emptyText:SetWidth(520)

local scroll = CreateFrame('ScrollFrame', nil, listPanel)
scroll:SetPoint('TOPLEFT', listPanel, 'TOPLEFT', 10, -26)
scroll:SetPoint('BOTTOMRIGHT', listPanel, 'BOTTOMRIGHT', -10, 10)
scroll:EnableMouseWheel(true)

local scrollChild = CreateFrame('Frame', nil, scroll)
scrollChild:SetSize(600, 1)
scroll:SetScrollChild(scrollChild)

scroll:SetScript('OnMouseWheel', function(self, delta)
    local cur = self:GetVerticalScroll()
    local maxScroll = self:GetVerticalScrollRange()
    if delta > 0 then
        self:SetVerticalScroll(math.max(0, cur - 40))
    else
        self:SetVerticalScroll(math.min(maxScroll, cur + 40))
    end
end)

local footer = frame:CreateFontString(nil, 'OVERLAY', 'GameFontDisableSmall')
footer:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', -18, 12)
footer:SetText('Bestände werden automatisch mit deinem Inventar abgeglichen.')

-- Rezept-Erfassung aus Retail-Berufsbuch --------------------------------------
local function GetSelectedRetailRecipeID()
    if not ProfessionsFrame or not ProfessionsFrame:IsShown() then return nil end
    local craftingPage = ProfessionsFrame.CraftingPage
    local form = craftingPage and craftingPage.SchematicForm
    if not form or not form:IsShown() then return nil end

    local transaction = form.transaction
    if transaction then
        local candidates = { transaction.recipeID, transaction.spellID }
        for _, recipeID in ipairs(candidates) do
            if recipeID and C_TradeSkillUI.GetRecipeInfo(recipeID) then
                return recipeID
            end
        end
    end

    local recipeList = craftingPage and craftingPage.RecipeList
    if recipeList and recipeList.GetSelectedRecipeID then
        local recipeID = recipeList:GetSelectedRecipeID()
        if recipeID and C_TradeSkillUI.GetRecipeInfo(recipeID) then return recipeID end
    end
    return nil
end

local function GetCurrentRecipeData()
    local recipeID = GetSelectedRetailRecipeID()
    if not recipeID then
        return nil, 'Bitte öffne dein Berufsbuch und wähle ein Rezept aus.'
    end

    local info = C_TradeSkillUI.GetRecipeInfo(recipeID)
    local schematic = C_TradeSkillUI.GetRecipeSchematic(recipeID, false)
    if not info or not schematic then
        return nil, 'Rezeptdaten konnten nicht gelesen werden.'
    end

    local recipe = {
        recipeID = recipeID,
        name = info.name or schematic.name or ('Rezept ' .. recipeID),
        icon = info.icon or schematic.icon or 134400,
        multiplier = 1,
        reagents = {},
    }

    for _, slot in ipairs(schematic.reagentSlotSchematics or {}) do
        if not slot.hiddenInCraftingForm and slot.required ~= false and (slot.quantityRequired or 0) > 0 then
            local reagent = slot.reagents and slot.reagents[1]
            if reagent and reagent.itemID then
                local itemName, _, _, _, _, _, _, _, _, itemTexture = C_Item.GetItemInfo(reagent.itemID)
                if not itemName then
                    local _, _, _, _, instantIcon = C_Item.GetItemInfoInstant(reagent.itemID)
                    itemName = 'Item ' .. reagent.itemID
                    itemTexture = instantIcon
                end
                recipe.reagents[#recipe.reagents + 1] = {
                    itemID = reagent.itemID,
                    name = itemName,
                    icon = itemTexture or 134400,
                    count = slot.quantityRequired,
                }
            end
        end
    end

    return recipe
end

local function GetOwned(itemID, name)
    local query = itemID or name
    if not query then return 0 end
    if C_Item and C_Item.GetItemCount then
        local ok, count = pcall(C_Item.GetItemCount, query, true, false, true, true)
        if ok and count then return count end
    end
    return 0
end

-- Dynamische Rezept- und Reagenzienzeilen -------------------------------------
local function GetRecipeRow(index)
    if recipeRows[index] then return recipeRows[index] end

    local row = CreateFrame('Frame', nil, scrollChild, 'BackdropTemplate')
    row:SetSize(598, 43)
    row:SetBackdrop({bgFile='Interface\\ChatFrame\\ChatFrameBackground'})
    row:SetBackdropColor(0.04, 0.10, 0.15, 0.46)

    local icon = row:CreateTexture(nil, 'ARTWORK')
    icon:SetSize(28, 28)
    icon:SetPoint('LEFT', row, 'LEFT', 8, 0)

    local name = row:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')
    name:SetPoint('TOPLEFT', icon, 'TOPRIGHT', 8, -1)
    name:SetWidth(360)
    name:SetJustifyH('LEFT')
    name:SetWordWrap(false)
    name:SetFont('Fonts\\FRIZQT__.TTF', 12, 'OUTLINE')

    local qtyLabel = row:CreateFontString(nil, 'OVERLAY', 'GameFontDisableSmall')
    qtyLabel:SetPoint('BOTTOMLEFT', icon, 'BOTTOMRIGHT', 8, 1)
    qtyLabel:SetText('Anzahl:')

    local qty = CreateFrame('EditBox', nil, row, 'InputBoxTemplate')
    qty:SetSize(42, 22)
    qty:SetPoint('LEFT', qtyLabel, 'RIGHT', 6, 0)
    qty:SetAutoFocus(false)
    qty:SetNumeric(true)
    qty:SetMaxLetters(3)
    qty:SetJustifyH('CENTER')
    qty:SetFontObject(GameFontHighlight)

    local remove = CreateThemeButton(row, 78, 25, 'Entfernen', true)
    remove:SetPoint('RIGHT', row, 'RIGHT', -8, 0)

    row.icon = icon
    row.name = name
    row.qty = qty
    row.remove = remove
    recipeRows[index] = row
    return row
end

local function GetReagentRow(index)
    if reagentRows[index] then return reagentRows[index] end

    local row = CreateFrame('Frame', nil, scrollChild)
    row:SetSize(575, 21)

    local icon = row:CreateTexture(nil, 'ARTWORK')
    icon:SetSize(18, 18)
    icon:SetPoint('LEFT', row, 'LEFT', 38, 0)

    local text = row:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
    text:SetPoint('LEFT', icon, 'RIGHT', 7, 0)
    text:SetWidth(500)
    text:SetJustifyH('LEFT')

    row.icon = icon
    row.text = text
    reagentRows[index] = row
    return row
end

UpdateDisplay = function()
    local db = EnsureDB()
    for _, row in pairs(recipeRows) do row:Hide() end
    for _, row in pairs(reagentRows) do row:Hide() end

    emptyText:SetShown(#db.recipes == 0)
    if #db.recipes == 0 then
        scrollChild:SetHeight(1)
        if shoppingHudFrame and shoppingHudFrame:IsShown() then UpdateShoppingHud() end
        return
    end

    local y = -2
    local recipeRowCount = 0
    local reagentRowCount = 0

    for recipeIndex, recipe in ipairs(db.recipes) do
        recipe.multiplier = tonumber(recipe.multiplier) or 1
        recipeRowCount = recipeRowCount + 1
        local row = GetRecipeRow(recipeRowCount)
        row:ClearAllPoints()
        row:SetPoint('TOPLEFT', scrollChild, 'TOPLEFT', 0, y)
        row.icon:SetTexture(recipe.icon or 134400)
        row.name:SetText(recipe.name or ('Rezept ' .. tostring(recipe.recipeID or '?')))
        row.qty:SetText(tostring(recipe.multiplier))
        row.recipeIndex = recipeIndex
        row:Show()

        row.qty:SetScript('OnEnterPressed', function(self)
            self:ClearFocus()
            local value = tonumber(self:GetText())
            if value and value > 0 and db.recipes[recipeIndex] then
                db.recipes[recipeIndex].multiplier = math.max(1, math.min(999, math.floor(value)))
                UpdateDisplay()
            else
                self:SetText(tostring(recipe.multiplier or 1))
            end
        end)
        row.qty:SetScript('OnEscapePressed', function(self)
            self:ClearFocus()
            self:SetText(tostring(recipe.multiplier or 1))
        end)
        row.remove:SetScript('OnClick', function()
            table.remove(db.recipes, recipeIndex)
            UpdateDisplay()
        end)

        y = y - 47

        for _, reagent in ipairs(recipe.reagents or {}) do
            reagentRowCount = reagentRowCount + 1
            local reg = GetReagentRow(reagentRowCount)
            reg:ClearAllPoints()
            reg:SetPoint('TOPLEFT', scrollChild, 'TOPLEFT', 0, y)
            reg.icon:SetTexture(reagent.icon or 134400)

            local needed = (tonumber(reagent.count) or 0) * recipe.multiplier
            local owned = GetOwned(reagent.itemID, reagent.name)
            local color = owned >= needed and '|cff63d471' or '|cffffffff'
            reg.text:SetText(color .. owned .. '/' .. needed .. '|r  ' .. (reagent.name or ('Item ' .. tostring(reagent.itemID or '?'))))
            reg:Show()
            y = y - 21
        end
        y = y - 8
    end

    scrollChild:SetHeight(math.max(1, math.abs(y) + 8))
    if shoppingHudFrame and shoppingHudFrame:IsShown() then UpdateShoppingHud() end
end

-- Einkaufsliste ---------------------------------------------------------------
shoppingHudFrame = CreatePopup('TinkerBoxCraftingShoppingHud', 'Einkaufsliste', 300, 360)

local hudScroll = CreateFrame('ScrollingMessageFrame', nil, shoppingHudFrame)
hudScroll:SetPoint('TOPLEFT', shoppingHudFrame, 'TOPLEFT', 18, -48)
hudScroll:SetPoint('BOTTOMRIGHT', shoppingHudFrame, 'BOTTOMRIGHT', -18, 18)
hudScroll:SetFont(STANDARD_TEXT_FONT, 14, 'OUTLINE')
hudScroll:SetMaxLines(250)
hudScroll:SetFading(false)
hudScroll:SetJustifyH('LEFT')
hudScroll:EnableMouseWheel(true)
hudScroll:SetScript('OnMouseWheel', function(self, delta)
    if delta > 0 then self:ScrollUp() else self:ScrollDown() end
end)

UpdateShoppingHud = function()
    local db = EnsureDB()
    hudScroll:Clear()
    if #db.recipes == 0 then
        hudScroll:AddMessage('Keine Rezepte aktiv.')
        return
    end

    local totals = {}
    local order = {}
    for _, recipe in ipairs(db.recipes) do
        local multiplier = tonumber(recipe.multiplier) or 1
        for _, reagent in ipairs(recipe.reagents or {}) do
            local key = reagent.itemID or reagent.name
            if key then
                if not totals[key] then
                    totals[key] = {
                        itemID = reagent.itemID,
                        name = reagent.name,
                        icon = reagent.icon,
                        count = 0,
                    }
                    order[#order + 1] = key
                end
                totals[key].count = totals[key].count + ((tonumber(reagent.count) or 0) * multiplier)
            end
        end
    end

    for _, key in ipairs(order) do
        local data = totals[key]
        local owned = GetOwned(data.itemID, data.name)
        local missing = math.max(0, data.count - owned)
        local color = missing == 0 and '|cff63d471' or '|cffffffff'
        local suffix = missing > 0 and ('  |cffff6b5fFehlt: ' .. missing .. '|r') or '  |cff63d471Bereit|r'
        hudScroll:AddMessage('|T' .. tostring(data.icon or 134400) .. ':20|t ' .. color .. owned .. '/' .. data.count .. ' ' .. (data.name or 'Unbekannt') .. '|r' .. suffix)
    end
end

shoppingHudFrame:SetScript('OnShow', UpdateShoppingHud)

-- Favoriten -------------------------------------------------------------------
favoritesFrame = CreatePopup('TinkerBoxCraftingFavorites', 'Crafting-Favoriten', 285, 360)

local saveFavoriteBtn = CreateThemeButton(favoritesFrame, 188, 30, 'Aktuelles Rezept speichern')
saveFavoriteBtn:SetPoint('TOP', favoritesFrame, 'TOP', 0, -46)

local favoritesHeader = favoritesFrame:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
favoritesHeader:SetPoint('TOPLEFT', favoritesFrame, 'TOPLEFT', 16, -86)
favoritesHeader:SetText('|cffffd75eGespeicherte Rezepte|r')

local favoriteButtons = {}
for i = 1, 10 do
    local btn = CreateFrame('Button', nil, favoritesFrame, 'BackdropTemplate')
    btn:SetSize(253, 22)
    btn:SetPoint('TOPLEFT', favoritesFrame, 'TOPLEFT', 16, -106 - ((i - 1) * 23))
    btn:RegisterForClicks('LeftButtonUp', 'RightButtonUp')
    btn:SetBackdrop({bgFile='Interface\\ChatFrame\\ChatFrameBackground'})
    btn:SetBackdropColor(0.06, 0.09, 0.12, (i % 2 == 0) and 0.28 or 0.18)

    local icon = btn:CreateTexture(nil, 'ARTWORK')
    icon:SetSize(20, 20)
    icon:SetPoint('LEFT', btn, 'LEFT', 3, 0)

    local text = btn:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')
    text:SetPoint('LEFT', icon, 'RIGHT', 7, 0)
    text:SetWidth(220)
    text:SetJustifyH('LEFT')
    text:SetWordWrap(false)
    text:SetFont('Fonts\\FRIZQT__.TTF', 11, 'OUTLINE')

    btn.icon = icon
    btn.text = text
    btn.index = i
    favoriteButtons[i] = btn
end

local favoritesHelp = favoritesFrame:CreateFontString(nil, 'OVERLAY', 'GameFontDisableSmall')
favoritesHelp:SetPoint('BOTTOM', favoritesFrame, 'BOTTOM', 0, 10)
favoritesHelp:SetText('Linksklick: hinzufügen   •   Rechtsklick: löschen')

UpdateFavorites = function()
    local db = EnsureDB()
    for i, btn in ipairs(favoriteButtons) do
        local fav = db.favorites[i]
        if fav then
            btn.icon:SetTexture(fav.icon or 134400)
            btn.text:SetText(fav.name or 'Unbekanntes Rezept')
            btn:Show()
            btn:SetScript('OnClick', function(_, button)
                if button == 'LeftButton' then
                    db.recipes[#db.recipes + 1] = CopyRecipe(fav)
                    UpdateDisplay()
                elseif button == 'RightButton' then
                    table.remove(db.favorites, i)
                    UpdateFavorites()
                end
            end)
        else
            btn:Hide()
        end
    end
end

saveFavoriteBtn:SetScript('OnClick', function()
    local db = EnsureDB()
    local recipe, err = GetCurrentRecipeData()
    if not recipe then
        TB.Message(err or 'Kein Rezept ausgewählt.')
        return
    end
    for _, fav in ipairs(db.favorites) do
        if fav.recipeID == recipe.recipeID then
            TB.Message('Dieses Rezept ist bereits in den Favoriten.')
            return
        end
    end
    if #db.favorites >= 10 then
        TB.Message('Es können maximal 10 Crafting-Favoriten gespeichert werden.')
        return
    end
    db.favorites[#db.favorites + 1] = CopyRecipe(recipe)
    UpdateFavorites()
end)

favoritesFrame:SetScript('OnShow', UpdateFavorites)

-- Aktionen --------------------------------------------------------------------
addRecipeBtn:SetScript('OnClick', function()
    local db = EnsureDB()
    local recipe, err = GetCurrentRecipeData()
    if not recipe then
        TB.Message(err or 'Kein Rezept ausgewählt.')
        return
    end

    for _, existing in ipairs(db.recipes) do
        if existing.recipeID == recipe.recipeID then
            existing.multiplier = (tonumber(existing.multiplier) or 1) + 1
            UpdateDisplay()
            return
        end
    end

    db.recipes[#db.recipes + 1] = recipe
    UpdateDisplay()
end)

favoritesBtn:SetScript('OnClick', function()
    if favoritesFrame:IsShown() then favoritesFrame:Hide() else favoritesFrame:Show() end
end)

shoppingBtn:SetScript('OnClick', function()
    if shoppingHudFrame:IsShown() then shoppingHudFrame:Hide() else shoppingHudFrame:Show() end
end)

clearBtn:SetScript('OnClick', function()
    EnsureDB().recipes = {}
    UpdateDisplay()
end)

frame:RegisterEvent('BAG_UPDATE_DELAYED')
frame:RegisterEvent('PLAYER_ENTERING_WORLD')
frame:SetScript('OnEvent', function()
    if frame:IsShown() then UpdateDisplay() end
    if shoppingHudFrame:IsShown() then UpdateShoppingHud() end
end)

frame:SetScript('OnShow', function()
    EnsureDB()
    UpdateDisplay()
end)

frame:SetScript('OnHide', function()
    if favoritesFrame then favoritesFrame:Hide() end
    if shoppingHudFrame then shoppingHudFrame:Hide() end
end)

TB.CraftingListRefresh = UpdateDisplay
