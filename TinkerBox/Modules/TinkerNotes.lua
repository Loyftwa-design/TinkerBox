local addonName, TB = ...
local frame = TB.CreateModuleFrame('TinkerNotes')

local notesListFrame
local noteRows = {}
local selectedNoteIndex = nil

local function EnsureDB()
    TinkerBoxDB.notes = TinkerBoxDB.notes or {}

    -- Migration der einfachen Notiz aus älteren modularen Versionen.
    if type(TinkerBoxDB.notes) == 'table' and TinkerBoxDB.notes.text then
        local oldText = tostring(TinkerBoxDB.notes.text or '')
        TinkerBoxDB.notes.text = nil
        if oldText ~= '' and #TinkerBoxDB.notes == 0 then
            table.insert(TinkerBoxDB.notes, {
                title = 'Importierte Notiz',
                body = oldText,
            })
        end
    end

    return TinkerBoxDB.notes
end

local function CreatePanel(parent)
    local panel = CreateFrame('Frame', nil, parent, 'BackdropTemplate')
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
                bg:SetAlpha(state == 'down' and 1 or 0.97)
            else
                bg:SetTexture(TB.Assets.FarmButtonRed)
                bg:SetAlpha(1)
            end
        else
            if state == 'hover' or state == 'down' then
                bg:SetTexture(TB.Assets.FarmButtonBlue)
                bg:SetAlpha(state == 'down' and 1 or 0.96)
            else
                bg:SetTexture(TB.Assets.FarmButtonIdle)
                bg:SetAlpha(1)
            end
        end
        bg:SetTexCoord(0, 1, 0, 1)
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
    closeTex:SetAlpha(0.92)
    close:SetScript('OnClick', function() popup:Hide() end)
    close:SetScript('OnEnter', function() closeTex:SetAlpha(1) end)
    close:SetScript('OnLeave', function() closeTex:SetAlpha(0.92) end)

    return popup
end

-- Titel ----------------------------------------------------------------------
local title = frame:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightLarge')
title:SetPoint('TOPLEFT', frame, 'TOPLEFT', 18, -30)
title:SetFont('Fonts\\FRIZQT__.TTF', 18, 'OUTLINE')
title:SetTextColor(1.00, 0.86, 0.25)
title:SetText('TinkerNotes')

local subtitle = frame:CreateFontString(nil, 'OVERLAY', 'GameFontDisableSmall')
subtitle:SetPoint('LEFT', title, 'RIGHT', 14, -1)
subtitle:SetText('Notizen, Farm-Spots, IDs und ToDos')

-- Titel-Eingabe ---------------------------------------------------------------
local titlePanel = CreatePanel(frame)
titlePanel:SetPoint('TOPLEFT', frame, 'TOPLEFT', 18, -62)
titlePanel:SetSize(630, 56)

local titleLabel = titlePanel:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
titleLabel:SetPoint('LEFT', titlePanel, 'LEFT', 14, 0)
titleLabel:SetFont('Fonts\\FRIZQT__.TTF', 22, 'OUTLINE')
titleLabel:SetText('|cffffd75eTitel der Notiz|r')

local noteTitleInput = CreateFrame('EditBox', nil, titlePanel, 'BackdropTemplate')
noteTitleInput:SetPoint('TOPLEFT', titlePanel, 'TOPLEFT', 168, -10)
noteTitleInput:SetPoint('BOTTOMRIGHT', titlePanel, 'BOTTOMRIGHT', -14, 10)
noteTitleInput:SetAutoFocus(false)
noteTitleInput:SetFont('Fonts\\FRIZQT__.TTF', 13, 'OUTLINE')
noteTitleInput:SetTextInsets(8, 8, 0, 0)
noteTitleInput:SetBackdrop({
    bgFile = 'Interface\\ChatFrame\\ChatFrameBackground',
    edgeFile = 'Interface\\Buttons\\WHITE8x8',
    edgeSize = 1,
})
noteTitleInput:SetBackdropColor(0.01, 0.04, 0.07, 0.75)
noteTitleInput:SetBackdropBorderColor(0.15, 0.48, 0.68, 0.65)
noteTitleInput:SetScript('OnEscapePressed', function(self) self:ClearFocus() end)

local titlePlaceholder = noteTitleInput:CreateFontString(nil, 'OVERLAY', 'GameFontDisable')
titlePlaceholder:SetPoint('LEFT', noteTitleInput, 'LEFT', 9, 0)
titlePlaceholder:SetText('Titel eingeben ...')
noteTitleInput:SetScript('OnTextChanged', function(self)
    titlePlaceholder:SetShown(self:GetText() == '')
end)

-- Editor ---------------------------------------------------------------------
local editorPanel = CreatePanel(frame)
editorPanel:SetPoint('TOPLEFT', frame, 'TOPLEFT', 18, -128)
editorPanel:SetSize(630, 242)

local editorLabel = editorPanel:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
editorLabel:SetPoint('TOPLEFT', editorPanel, 'TOPLEFT', 14, -10)
editorLabel:SetText('|cffffd75eNotiz|r')

local notesScrollFrame = CreateFrame('ScrollFrame', nil, editorPanel, 'BackdropTemplate')
notesScrollFrame:SetPoint('TOPLEFT', editorPanel, 'TOPLEFT', 14, -34)
notesScrollFrame:SetPoint('BOTTOMRIGHT', editorPanel, 'BOTTOMRIGHT', -14, 14)
notesScrollFrame:EnableMouseWheel(true)
notesScrollFrame:SetBackdrop({
    bgFile = 'Interface\\ChatFrame\\ChatFrameBackground',
    edgeFile = 'Interface\\Buttons\\WHITE8x8',
    edgeSize = 1,
})
notesScrollFrame:SetBackdropColor(0.01, 0.04, 0.07, 0.66)
notesScrollFrame:SetBackdropBorderColor(0.15, 0.48, 0.68, 0.55)

local notesEditBox = CreateFrame('EditBox', nil, notesScrollFrame)
notesEditBox:SetMultiLine(true)
notesEditBox:SetAutoFocus(false)
notesEditBox:SetFont('Fonts\\FRIZQT__.TTF', 13, '')
notesEditBox:SetWidth(590)
notesEditBox:SetTextInsets(6, 6, 6, 6)
notesEditBox:SetJustifyH('LEFT')
notesEditBox:SetJustifyV('TOP')
notesEditBox:SetScript('OnEscapePressed', function(self) self:ClearFocus() end)
notesEditBox:SetScript('OnTextChanged', function(self)
    local h = math.max(200, self:GetStringHeight() + 24)
    self:SetHeight(h)
end)
notesScrollFrame:SetScrollChild(notesEditBox)

notesScrollFrame:SetScript('OnMouseWheel', function(self, delta)
    local cur = self:GetVerticalScroll()
    local maxScroll = self:GetVerticalScrollRange()
    if delta > 0 then
        self:SetVerticalScroll(math.max(0, cur - 28))
    else
        self:SetVerticalScroll(math.min(maxScroll, cur + 28))
    end
end)

-- Buttons --------------------------------------------------------------------
local saveNoteBtn = CreateThemeButton(frame, 150, 32, 'Notiz speichern')
saveNoteBtn:SetPoint('BOTTOM', frame, 'BOTTOM', -154, 18)

local notesListBtn = CreateThemeButton(frame, 150, 32, 'Gespeicherte')
notesListBtn:SetPoint('LEFT', saveNoteBtn, 'RIGHT', 14, 0)

local newNoteBtn = CreateThemeButton(frame, 130, 32, 'Neu')
newNoteBtn:SetPoint('LEFT', notesListBtn, 'RIGHT', 14, 0)

-- Gespeicherte Notizen --------------------------------------------------------
notesListFrame = CreatePopup('TinkerBoxNotesListFrame', 'Gespeicherte Notizen', 300, 390)

local clearBtn = CreateThemeButton(notesListFrame, 145, 30, 'Liste leeren', true)
clearBtn:SetPoint('TOP', notesListFrame, 'TOP', 0, -48)

local listHeader = notesListFrame:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
listHeader:SetPoint('TOPLEFT', notesListFrame, 'TOPLEFT', 18, -91)
listHeader:SetText('|cffffd75eNotizen|r')

local listHint = notesListFrame:CreateFontString(nil, 'OVERLAY', 'GameFontDisableSmall')
listHint:SetPoint('BOTTOM', notesListFrame, 'BOTTOM', 0, 12)
listHint:SetText('Linksklick: öffnen  •  X: löschen')

local listScroll = CreateFrame('ScrollFrame', nil, notesListFrame)
listScroll:SetPoint('TOPLEFT', notesListFrame, 'TOPLEFT', 16, -112)
listScroll:SetPoint('BOTTOMRIGHT', notesListFrame, 'BOTTOMRIGHT', -16, 36)
listScroll:EnableMouseWheel(true)

local listChild = CreateFrame('Frame', nil, listScroll)
listChild:SetSize(268, 1)
listScroll:SetScrollChild(listChild)

listScroll:SetScript('OnMouseWheel', function(self, delta)
    local cur = self:GetVerticalScroll()
    local maxScroll = self:GetVerticalScrollRange()
    if delta > 0 then
        self:SetVerticalScroll(math.max(0, cur - 28))
    else
        self:SetVerticalScroll(math.min(maxScroll, cur + 28))
    end
end)

local function ClearEditor()
    selectedNoteIndex = nil
    noteTitleInput:SetText('')
    notesEditBox:SetText('')
    noteTitleInput:ClearFocus()
    notesEditBox:ClearFocus()
end

local function UpdateNotesList()
    local db = EnsureDB()

    for _, row in ipairs(noteRows) do
        row:Hide()
        row:ClearAllPoints()
    end

    local y = 0
    for i, noteData in ipairs(db) do
        local row = noteRows[i]

        if not row then
            row = CreateFrame('Button', nil, listChild, 'BackdropTemplate')
            row:SetSize(268, 28)
            row:SetBackdrop({ bgFile = 'Interface\\ChatFrame\\ChatFrameBackground' })
            row:SetBackdropColor(0.02, 0.06, 0.09, (i % 2 == 0) and 0.32 or 0.18)

            local del = CreateFrame('Button', nil, row)
            del:SetSize(20, 20)
            del:SetPoint('LEFT', row, 'LEFT', 3, 0)

            local delBg = del:CreateTexture(nil, 'ARTWORK')
            delBg:SetAllPoints(del)
            TB.ApplyAsset(delBg, TB.Assets.Close, 'Close')
            delBg:SetAlpha(0.92)

            del:SetScript('OnEnter', function()
                delBg:SetAlpha(1)
            end)
            del:SetScript('OnLeave', function()
                delBg:SetAlpha(0.92)
            end)

            local txt = row:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')
            txt:SetPoint('LEFT', del, 'RIGHT', 7, 0)
            txt:SetPoint('RIGHT', row, 'RIGHT', -6, 0)
            txt:SetJustifyH('LEFT')
            txt:SetWordWrap(false)
            txt:SetFont('Fonts\\FRIZQT__.TTF', 12, 'OUTLINE')

            row.del = del
            row.text = txt
            noteRows[i] = row
        end

        row:SetPoint('TOPLEFT', listChild, 'TOPLEFT', 0, -y)
        row.text:SetText(noteData.title or 'Unbenannte Notiz')
        row.noteIndex = i

        row.del:SetScript('OnClick', function()
            table.remove(EnsureDB(), row.noteIndex)
            if selectedNoteIndex == row.noteIndex then
                ClearEditor()
            elseif selectedNoteIndex and selectedNoteIndex > row.noteIndex then
                selectedNoteIndex = selectedNoteIndex - 1
            end
            UpdateNotesList()
        end)

        row:SetScript('OnClick', function()
            local data = EnsureDB()[row.noteIndex]
            if not data then return end
            selectedNoteIndex = row.noteIndex
            noteTitleInput:SetText(data.title or '')
            notesEditBox:SetText(data.body or '')
            notesListFrame:Hide()
        end)

        row:Show()
        y = y + 30
    end

    listChild:SetHeight(math.max(1, y))
end

-- Aktionen -------------------------------------------------------------------
saveNoteBtn:SetScript('OnClick', function()
    local db = EnsureDB()
    local titleText = noteTitleInput:GetText() or ''
    local bodyText = notesEditBox:GetText() or ''

    if titleText == '' and bodyText == '' then
        TB.Message('Bitte zuerst einen Titel oder Text eingeben.')
        return
    end

    local finalTitle = titleText ~= '' and titleText or 'Unbenannte Notiz'

    -- Wie in der alten TinkerNotes-Funktion wird beim Speichern ein neuer Eintrag angelegt.
    table.insert(db, 1, {
        title = finalTitle,
        body = bodyText,
    })

    local limit = (TinkerBoxDB.settings and tonumber(TinkerBoxDB.settings.historyLimit)) or 50
    while #db > limit do
        table.remove(db)
    end

    ClearEditor()
    UpdateNotesList()
    TB.Message('Notiz gespeichert.')
end)

newNoteBtn:SetScript('OnClick', ClearEditor)

notesListBtn:SetScript('OnClick', function()
    if notesListFrame:IsShown() then
        notesListFrame:Hide()
    else
        UpdateNotesList()
        notesListFrame:Show()
    end
end)

clearBtn:SetScript('OnClick', function()
    TinkerBoxDB.notes = {}
    ClearEditor()
    UpdateNotesList()
end)

notesListFrame:SetScript('OnShow', UpdateNotesList)

-- Modul ----------------------------------------------------------------------
frame:SetScript('OnShow', function()
    EnsureDB()
    TB.UI.headerText:SetText('TinkerNotes')
    TB.UI.subText:SetText('Notizen, Farm-Spots, IDs und ToDos')
end)

frame:SetScript('OnHide', function()
    if notesListFrame then notesListFrame:Hide() end
end)

frame.NoteTitle = noteTitleInput
frame.EditBox = notesEditBox
frame.NotesListFrame = notesListFrame
