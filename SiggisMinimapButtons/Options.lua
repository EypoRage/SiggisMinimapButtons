----------------------------------------------------------------------
-- Siggi's Minimap Buttons – Options Panel
-- Interface Options panel to create, manage, and delete buttons.
----------------------------------------------------------------------

local ADDON_NAME, ns = ...

----------------------------------------------------------------------
-- Constants
----------------------------------------------------------------------
local ROW_HEIGHT     = 28
local HEADER_HEIGHT  = 120  -- space reserved for the top controls
local SCROLLBAR_W    = 24

----------------------------------------------------------------------
-- Main options frame (registered with Interface Options)
----------------------------------------------------------------------
local panel = CreateFrame("Frame", "SiggisMinimapButtonsOptionsPanel", UIParent)
panel.name = "Siggi's Minimap Buttons"

-- Title
local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetText("Siggi's Minimap Buttons")

local subtitle = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
subtitle:SetText("Because your minimap deserved more clutter. You're welcome. (Right-click buttons to delete... if you must.)")

----------------------------------------------------------------------
-- "New Button" controls
----------------------------------------------------------------------
local newLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
newLabel:SetPoint("TOPLEFT", subtitle, "BOTTOMLEFT", 0, -18)
newLabel:SetText("New button name:")

local nameBox = CreateFrame("EditBox", "SiggisMMBtnNewNameBox", panel, "InputBoxTemplate")
nameBox:SetSize(200, 22)
nameBox:SetPoint("LEFT", newLabel, "RIGHT", 10, 0)
nameBox:SetAutoFocus(false)
nameBox:SetMaxLetters(64)

-- Icon dropdown label
local iconLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
iconLabel:SetPoint("TOPLEFT", newLabel, "BOTTOMLEFT", 0, -14)
iconLabel:SetText("Icon:")

-- Icon preview
local iconPreview = panel:CreateTexture(nil, "ARTWORK")
iconPreview:SetSize(24, 24)
iconPreview:SetPoint("LEFT", iconLabel, "RIGHT", 8, 0)
iconPreview:SetTexture(ns.ICON_POOL[1])

local selectedIcon = nil  -- nil = random

-- Icon selector dropdown button
local iconDropdown = CreateFrame("Button", "SiggisMMBtnIconDropdown", panel, "UIPanelButtonTemplate")
iconDropdown:SetSize(120, 22)
iconDropdown:SetPoint("LEFT", iconPreview, "RIGHT", 8, 0)
iconDropdown:SetText("Choose Icon")

-- Build the icon dropdown menu
local iconMenu = CreateFrame("Frame", "SiggisMMBtnIconMenu", UIParent, "UIDropDownMenuTemplate")

local function IconMenu_Init(self, level)
    local info = UIDropDownMenu_CreateInfo()

    -- "Random" option
    info.text      = "Random"
    info.icon      = nil
    info.checked   = (selectedIcon == nil)
    info.func = function()
        selectedIcon = nil
        iconPreview:SetTexture(ns.ICON_POOL[1])
    end
    UIDropDownMenu_AddButton(info, level)

    -- Each icon in the pool
    for i, tex in ipairs(ns.ICON_POOL) do
        info = UIDropDownMenu_CreateInfo()
        info.text           = "Icon " .. i
        info.icon           = tex
        info.checked        = (selectedIcon == tex)
        info.func = function()
            selectedIcon = tex
            iconPreview:SetTexture(tex)
        end
        UIDropDownMenu_AddButton(info, level)
    end
end

iconDropdown:SetScript("OnClick", function(self)
    UIDropDownMenu_Initialize(iconMenu, IconMenu_Init, "MENU")
    ToggleDropDownMenu(1, nil, iconMenu, self, 0, 0)
end)

-- "Create" button
local createBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
createBtn:SetSize(120, 24)
createBtn:SetPoint("LEFT", iconDropdown, "RIGHT", 12, 0)
createBtn:SetText("Create Button")
createBtn:SetScript("OnClick", function()
    local name = nameBox:GetText()
    if name == "" then name = nil end
    ns:AddButton(name, selectedIcon)
    nameBox:SetText("")
end)

nameBox:SetScript("OnEnterPressed", function(self)
    createBtn:Click()
end)

-- "Remove All" button
local removeAllBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
removeAllBtn:SetSize(120, 24)
removeAllBtn:SetPoint("LEFT", createBtn, "RIGHT", 8, 0)
removeAllBtn:SetText("Remove All")
removeAllBtn:SetScript("OnClick", function()
    StaticPopup_Show("SIEGLINDE_CONFIRM_REMOVEALL")
end)

StaticPopupDialogs["SIEGLINDE_CONFIRM_REMOVEALL"] = {
    text         = "Remove ALL Siggi's minimap buttons?",
    button1      = "Yes",
    button2      = "No",
    OnAccept     = function() ns:RemoveAllButtons() end,
    timeout      = 0,
    whileDead    = true,
    hideOnEscape = true,
}

----------------------------------------------------------------------
-- Scroll list of existing buttons
----------------------------------------------------------------------
local listHeader = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
listHeader:SetPoint("TOPLEFT", iconLabel, "BOTTOMLEFT", 0, -20)
listHeader:SetText("Existing Buttons:")

-- Container for the scrollframe
local listContainer = CreateFrame("Frame", nil, panel, "BackdropTemplate")
listContainer:SetPoint("TOPLEFT", listHeader, "BOTTOMLEFT", 0, -6)
listContainer:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -18, 16)
listContainer:SetBackdrop({
    bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile     = true,
    tileSize = 16,
    edgeSize = 16,
    insets   = { left = 4, right = 4, top = 4, bottom = 4 },
})

-- ScrollFrame
local scrollFrame = CreateFrame("ScrollFrame", "SiggisMMBtnScrollFrame", listContainer, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", 6, -6)
scrollFrame:SetPoint("BOTTOMRIGHT", -SCROLLBAR_W - 4, 6)

local scrollChild = CreateFrame("Frame", nil, scrollFrame)
scrollChild:SetWidth(scrollFrame:GetWidth() or 400)
scrollChild:SetHeight(1) -- dynamically updated
scrollFrame:SetScrollChild(scrollChild)

----------------------------------------------------------------------
-- Row pool
----------------------------------------------------------------------
local rows = {}

local function CreateRow(parent, index)
    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(ROW_HEIGHT)
    row:SetPoint("TOPLEFT", 0, -(index - 1) * ROW_HEIGHT)
    row:SetPoint("RIGHT", 0, 0)

    -- Alternating background
    local bg = row:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(1, 1, 1, (index % 2 == 0) and 0.03 or 0.06)

    -- Icon
    local ico = row:CreateTexture(nil, "ARTWORK")
    ico:SetSize(20, 20)
    ico:SetPoint("LEFT", 6, 0)
    row.icon = ico

    -- ID text
    local idText = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    idText:SetPoint("LEFT", ico, "RIGHT", 6, 0)
    idText:SetWidth(36)
    idText:SetJustifyH("LEFT")
    row.idText = idText

    -- Label text
    local labelText = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    labelText:SetPoint("LEFT", idText, "RIGHT", 4, 0)
    labelText:SetWidth(200)
    labelText:SetJustifyH("LEFT")
    row.labelText = labelText

    -- Delete button
    local delBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    delBtn:SetSize(60, 20)
    delBtn:SetPoint("RIGHT", -6, 0)
    delBtn:SetText("Delete")
    row.deleteBtn = delBtn

    -- Rename button
    local renameBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    renameBtn:SetSize(70, 20)
    renameBtn:SetPoint("RIGHT", delBtn, "LEFT", -4, 0)
    renameBtn:SetText("Rename")
    row.renameBtn = renameBtn

    row:Hide()
    return row
end

----------------------------------------------------------------------
-- Refresh the list
----------------------------------------------------------------------
local function RefreshList()
    local db = ns.GetDB()
    if not db then return end

    -- Gather sorted ids
    local ids = {}
    for id in pairs(db.buttons) do
        ids[#ids + 1] = id
    end
    table.sort(ids)

    -- Ensure enough rows
    while #rows < #ids do
        rows[#rows + 1] = CreateRow(scrollChild, #rows + 1)
    end

    -- Update the scroll child height
    scrollChild:SetHeight(math.max(1, #ids * ROW_HEIGHT))

    -- Populate rows
    for i, id in ipairs(ids) do
        local row  = rows[i]
        local data = db.buttons[id]

        row.icon:SetTexture(data.icon)
        row.idText:SetText("#" .. id)
        row.labelText:SetText(data.label or "Unnamed")

        row.deleteBtn:SetScript("OnClick", function()
            ns:RemoveButton(id)
        end)

        row.renameBtn:SetScript("OnClick", function()
            StaticPopupDialogs["SIEGLINDE_RENAME"] = {
                text         = "Rename button #" .. id .. ":",
                button1      = "OK",
                button2      = "Cancel",
                hasEditBox   = true,
                OnShow = function(self)
                    self.editBox:SetText(data.label or "")
                    self.editBox:HighlightText()
                end,
                OnAccept = function(self)
                    local newName = self.editBox:GetText()
                    if newName and newName ~= "" then
                        data.label = newName
                        local liveButtons = ns.GetLiveButtons()
                        -- tooltip will update on next hover
                        print("|cff00ccffSiggi's Minimap Buttons:|r Button #" .. id .. " renamed to |cffffd200" .. newName .. "|r")
                        RefreshList()
                    end
                end,
                timeout      = 0,
                whileDead    = true,
                hideOnEscape = true,
                preferredIndex = 3,
            }
            StaticPopup_Show("SIEGLINDE_RENAME")
        end)

        -- Reposition in case of reuse
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", 0, -(i - 1) * ROW_HEIGHT)
        row:SetPoint("RIGHT", 0, 0)

        -- Fix alternating background
        local bg = row:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(1, 1, 1, (i % 2 == 0) and 0.03 or 0.06)

        row:Show()
    end

    -- Hide unused rows
    for i = #ids + 1, #rows do
        rows[i]:Hide()
    end
end

-- Expose the refresh function so core can call it
ns.optionsRefresh = RefreshList

-- Refresh whenever the panel is shown
panel:SetScript("OnShow", function()
    -- Update the scroll child width to match
    scrollChild:SetWidth(scrollFrame:GetWidth())
    RefreshList()
end)

----------------------------------------------------------------------
-- Register with Interface Options & hook slash command
----------------------------------------------------------------------
local hookFrame = CreateFrame("Frame")
hookFrame:RegisterEvent("ADDON_LOADED")
hookFrame:SetScript("OnEvent", function(self, event, addon)
    if addon ~= ADDON_NAME then return end
    self:UnregisterEvent("ADDON_LOADED")

    -- Register panel – use Settings API if available (Classic Era Anniversary),
    -- fall back to legacy InterfaceOptions_AddCategory otherwise.
    if Settings and Settings.RegisterCanvasLayoutCategory then
        local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
        Settings.RegisterAddOnCategory(category)
        ns._settingsCategory = category
    elseif InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(panel)
    end

    -- Wrap the existing slash handler to add "options" subcommand
    C_Timer.After(0, function()
        local orig = SlashCmdList["SIEGLINDE"]
        SlashCmdList["SIEGLINDE"] = function(msg)
            local cmd = msg:match("^(%S+)") or ""
            if cmd:lower() == "options" or cmd:lower() == "config" or cmd:lower() == "settings" then
                if ns._settingsCategory then
                    Settings.OpenToCategory(ns._settingsCategory:GetID())
                elseif InterfaceOptionsFrame_OpenToCategory then
                    InterfaceOptionsFrame_OpenToCategory(panel)
                    InterfaceOptionsFrame_OpenToCategory(panel)
                end
                return
            end
            if orig then orig(msg) end
        end
    end)
end)
