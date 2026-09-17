local addonName, TB = ...

-- Gold-Session bewusst unabhängig vom TinkerBox-Hauptfenster halten.
-- Sie verhält sich damit wie ein eigener Tracker: frei verschiebbar und nur
-- über ihr eigenes X zu schließen.

local goldModule = TB.Modules and TB.Modules.GoldTracker
local sessionFrame = _G.TinkerBoxGoldSession
local historyFrame = _G.TinkerBoxGoldHistory

if not goldModule or not sessionFrame then return end

local function EnsureGoldDB()
    TinkerBoxDB.goldTracker = TinkerBoxDB.goldTracker or {}
    return TinkerBoxDB.goldTracker
end

local function RestoreSessionPosition()
    local db = EnsureGoldDB()
    local pos = db.sessionWindowPos

    sessionFrame:ClearAllPoints()

    if type(pos) == 'table'
        and type(pos.x) == 'number'
        and type(pos.y) == 'number' then
        sessionFrame:SetPoint(
            pos.point or 'CENTER',
            UIParent,
            pos.relativePoint or 'CENTER',
            pos.x,
            pos.y
        )
    else
        -- Unabhängige Standardposition neben der Bildschirmmitte.
        sessionFrame:SetPoint('CENTER', UIParent, 'CENTER', 260, 0)
    end
end

local function SaveSessionPosition()
    local point, _, relativePoint, x, y = sessionFrame:GetPoint(1)
    if not point then return end

    local db = EnsureGoldDB()
    db.sessionWindowPos = {
        point = point,
        relativePoint = relativePoint or point,
        x = tonumber(x) or 0,
        y = tonumber(y) or 0,
    }
end

sessionFrame:SetMovable(true)
sessionFrame:EnableMouse(true)
sessionFrame:RegisterForDrag('LeftButton')
sessionFrame:SetClampedToScreen(true)

sessionFrame:SetScript('OnDragStart', function(self)
    self:StartMoving()
end)

sessionFrame:SetScript('OnDragStop', function(self)
    self:StopMovingOrSizing()
    SaveSessionPosition()
end)

RestoreSessionPosition()

-- Der ursprüngliche GoldTracker schließt Session + Verlauf beim Ausblenden
-- der GoldKasse. Der Verlauf darf weiter an die Rubrik gebunden bleiben,
-- die laufende Gold-Session dagegen nicht.
goldModule:SetScript('OnHide', function()
    if historyFrame then historyFrame:Hide() end
end)
