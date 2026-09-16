local addonName, TB = ...
local frame = TB.CreateModuleFrame('Home')

-- Das Welcome-Artwork bleibt bewusst etwas tiefer im Inhaltsbereich,
-- ist aber kompakter, damit der Text darunter genug Luft bekommt.
local art = frame:CreateTexture(nil, 'ARTWORK')
art:SetTexture(TB.Assets.HomeArt)
art:SetSize(512, 256)
art:SetPoint('TOP', frame, 'TOP', 0, -38)

local intro = frame:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightLarge')
intro:SetPoint('TOP', art, 'BOTTOM', 0, -24)
intro:SetText('|cffFFD100Willkommen in TinkerBox ' .. tostring(TB.VERSION or '1.0.0') .. '|r')

local tagline = frame:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')
tagline:SetPoint('TOP', intro, 'BOTTOM', 0, -14)
tagline:SetWidth(560)
tagline:SetJustifyH('CENTER')
tagline:SetText('Deine Tüftler-Zentrale für Farmen, Crafting und Organisation.')

local hint = frame:CreateFontString(nil, 'OVERLAY', 'GameFontDisable')
hint:SetPoint('TOP', tagline, 'BOTTOM', 0, -12)
hint:SetWidth(560)
hint:SetJustifyH('CENTER')
hint:SetText('Wähle links eine Rubrik aus, um zu starten.')

frame:SetScript('OnShow', function()
    art:Show()
    intro:Show()
    tagline:Show()
    hint:Show()
end)
