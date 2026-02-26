----------------------------------------------------------------------
-- Siggi's Minimap Buttons (Classic Era Anniversary)
-- Because your minimap wasn't cluttered enough already.
-- Spam it. Embrace the chaos. Trigger your friends.
----------------------------------------------------------------------

local ADDON_NAME, ns = ...

----------------------------------------------------------------------
-- Default saved-variable structure
----------------------------------------------------------------------
local DEFAULT_DB = {
    buttons = {},   -- { {icon=..., angle=..., dist=..., label=...}, ... }
    nextId  = 1,
}

----------------------------------------------------------------------
-- Icon pool – random textures for variety
----------------------------------------------------------------------
local ICON_POOL = {
    "Interface\\Icons\\INV_Misc_QuestionMark",
    "Interface\\Icons\\Ability_Rogue_Sprint",
    "Interface\\Icons\\Spell_Nature_Starfall",
    "Interface\\Icons\\INV_Misc_Gem_Diamond_02",
    "Interface\\Icons\\Spell_Holy_MagicalSentry",
    "Interface\\Icons\\INV_Misc_Bag_10_Blue",
    "Interface\\Icons\\Ability_Warrior_ShieldWall",
    "Interface\\Icons\\Spell_Fire_FlameBolt",
    "Interface\\Icons\\INV_Helmet_04",
    "Interface\\Icons\\Spell_Shadow_Possession",
    "Interface\\Icons\\INV_Potion_54",
    "Interface\\Icons\\Ability_Hunter_BeastCall",
    "Interface\\Icons\\Spell_Frost_FrostBolt02",
    "Interface\\Icons\\INV_Misc_Herb_02",
    "Interface\\Icons\\Ability_BackStab",
    "Interface\\Icons\\Spell_Nature_Thunderclap",
    "Interface\\Icons\\INV_Sword_39",
    "Interface\\Icons\\INV_Shield_09",
    "Interface\\Icons\\Spell_Holy_HolyBolt",
    "Interface\\Icons\\INV_Misc_Food_12",
}

----------------------------------------------------------------------
-- Runtime state
----------------------------------------------------------------------
local liveButtons = {}          -- frames keyed by button id
local db                        -- reference into SiggisMinimapButtonsDB

-- Expose internals to other files via namespace
ns.ICON_POOL = ICON_POOL
ns.GetDB = function() return db end
ns.GetLiveButtons = function() return liveButtons end
ns.optionsRefresh = nil         -- set by Options.lua

----------------------------------------------------------------------
-- Helpers
----------------------------------------------------------------------
local function RandomIcon()
    return ICON_POOL[math.random(#ICON_POOL)]
end

-- Position a minimap button frame using angle (degrees) and distance
-- from Minimap center.  Classic-style circular minimap maths.
local function PositionButton(frame, angle, dist)
    local rads = math.rad(angle)
    local x = math.cos(rads) * dist
    local y = math.sin(rads) * dist
    frame:ClearAllPoints()
    frame:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

----------------------------------------------------------------------
-- Create the actual minimap button frame
----------------------------------------------------------------------
local function CreateMinimapButton(id, data)
    local size = 31

    -- Main frame
    local btn = CreateFrame("Button", "SiggisMMBtn" .. id, Minimap)
    btn:SetSize(size, size)
    btn:SetFrameStrata("MEDIUM")
    btn:SetFrameLevel(8)
    btn:SetMovable(true)
    btn:EnableMouse(true)
    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    btn:RegisterForDrag("LeftButton")

    -- Icon texture
    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetSize(21, 21)
    icon:SetPoint("CENTER")
    icon:SetTexture(data.icon)
    btn.icon = icon

    -- Border (standard minimap button)
    local border = btn:CreateTexture(nil, "OVERLAY")
    border:SetSize(53, 53)
    border:SetPoint("TOPLEFT")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    btn.border = border

    -- Highlight
    local highlight = btn:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetSize(24, 24)
    highlight:SetPoint("CENTER")
    highlight:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    btn.highlight = highlight

    -- Tooltip
    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine(data.label or ("Dummy #" .. id), 1, 1, 1)
        GameTooltip:AddLine("Left-drag to move", 0.7, 0.7, 0.7)
        GameTooltip:AddLine("Right-click to delete", 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    -- Dragging around the minimap
    local isDragging = false
    btn:SetScript("OnDragStart", function(self)
        isDragging = true
        self:LockHighlight()
        self:SetScript("OnUpdate", function(self)
            local mx, my = Minimap:GetCenter()
            local cx, cy = GetCursorPosition()
            local scale = Minimap:GetEffectiveScale()
            cx, cy = cx / scale, cy / scale
            local dx, dy = cx - mx, cy - my
            local dist = math.sqrt(dx * dx + dy * dy)
            local radius = (Minimap:GetWidth() / 2) + 5
            if dist < 10 then dist = 10 end
            if dist > radius then dist = radius end
            local angle = math.deg(math.atan2(dy, dx))
            data.angle = angle
            data.dist  = dist
            PositionButton(self, angle, dist)
        end)
    end)
    btn:SetScript("OnDragStop", function(self)
        isDragging = false
        self:UnlockHighlight()
        self:SetScript("OnUpdate", nil)
    end)

    -- Click handler
    btn:SetScript("OnClick", function(self, button)
        if button == "RightButton" then
            ns:RemoveButton(id)
        end
    end)

    -- Initial position
    PositionButton(btn, data.angle, data.dist)
    btn:Show()

    liveButtons[id] = btn
    return btn
end

----------------------------------------------------------------------
-- Public API (ns namespace)
----------------------------------------------------------------------

--- Add a new minimap button and persist it.
function ns:AddButton(label, icon)
    local id = db.nextId
    db.nextId = id + 1

    local angle = math.random(0, 359)
    local radius = (Minimap:GetWidth() / 2) + 5

    local data = {
        icon  = icon or RandomIcon(),
        angle = angle,
        dist  = radius,
        label = label or ("Dummy #" .. id),
    }
    db.buttons[id] = data
    CreateMinimapButton(id, data)
    if ns.optionsRefresh then ns.optionsRefresh() end
    print("|cff00ccffSiggi's Minimap Buttons:|r Created button |cffffd200" .. data.label .. "|r (id " .. id .. ")")
end

--- Remove a minimap button by id.
function ns:RemoveButton(id)
    if liveButtons[id] then
        liveButtons[id]:Hide()
        liveButtons[id]:SetParent(nil)
        liveButtons[id] = nil
    end
    if db.buttons[id] then
        local label = db.buttons[id].label or tostring(id)
        db.buttons[id] = nil
        if ns.optionsRefresh then ns.optionsRefresh() end
        print("|cff00ccffSiggi's Minimap Buttons:|r Removed button |cffffd200" .. label .. "|r (id " .. id .. ")")
    end
end

--- Remove ALL buttons.
function ns:RemoveAllButtons()
    local ids = {}
    for id in pairs(db.buttons) do
        ids[#ids + 1] = id
    end
    for _, id in ipairs(ids) do
        ns:RemoveButton(id)
    end
    print("|cff00ccffSiggi's Minimap Buttons:|r All buttons removed.")
end

--- List all buttons in chat.
function ns:ListButtons()
    local count = 0
    for id, data in pairs(db.buttons) do
        count = count + 1
        print(("  |cffffd200#%d|r  %s"):format(id, data.label or "Unnamed"))
    end
    if count == 0 then
        print("|cff00ccffSiggi's Minimap Buttons:|r No buttons exist.")
    else
        print("|cff00ccffSiggi's Minimap Buttons:|r " .. count .. " button(s) total.")
    end
end

----------------------------------------------------------------------
-- Slash commands
----------------------------------------------------------------------
local function HandleSlash(msg)
    local cmd, rest = msg:match("^(%S+)%s*(.*)")
    cmd = cmd and cmd:lower() or ""

    if cmd == "add" or cmd == "new" or cmd == "create" then
        local label = (rest ~= "" and rest) or nil
        ns:AddButton(label)

    elseif cmd == "remove" or cmd == "delete" or cmd == "del" then
        local id = tonumber(rest)
        if id then
            if db.buttons[id] then
                ns:RemoveButton(id)
            else
                print("|cff00ccffSiggi's Minimap Buttons:|r No button with id " .. id)
            end
        else
            print("|cff00ccffSiggi's Minimap Buttons:|r Usage: /siggi remove <id>")
        end

    elseif cmd == "removeall" or cmd == "clear" then
        ns:RemoveAllButtons()

    elseif cmd == "list" then
        ns:ListButtons()

    elseif cmd == "icon" then
        -- /sieglinde icon <id> <texturePath>
        local idStr, tex = rest:match("^(%d+)%s+(.+)")
        local id = tonumber(idStr)
        if id and tex and db.buttons[id] then
            db.buttons[id].icon = tex
            if liveButtons[id] then
                liveButtons[id].icon:SetTexture(tex)
            end
            print("|cff00ccffSiggi's Minimap Buttons:|r Icon updated for button #" .. id)
        else
            print("|cff00ccffSiggi's Minimap Buttons:|r Usage: /siggi icon <id> <texturePath>")
        end

    elseif cmd == "rename" then
        local idStr, newName = rest:match("^(%d+)%s+(.+)")
        local id = tonumber(idStr)
        if id and newName and db.buttons[id] then
            db.buttons[id].label = newName
            print("|cff00ccffSiggi's Minimap Buttons:|r Button #" .. id .. " renamed to |cffffd200" .. newName .. "|r")
        else
            print("|cff00ccffSiggi's Minimap Buttons:|r Usage: /siggi rename <id> <newName>")
        end

    else
        print("|cff00ccffSiggi's Minimap Buttons|r")
        print("  |cffffd200/siggi add [label]|r – Create a new button")
        print("  |cffffd200/siggi remove <id>|r – Remove a button by id")
        print("  |cffffd200/siggi removeall|r – Remove all buttons")
        print("  |cffffd200/siggi list|r – List all buttons")
        print("  |cffffd200/siggi rename <id> <name>|r – Rename a button")
        print("  |cffffd200/siggi icon <id> <path>|r – Change a button's icon")
        print("  |cffffd200/siggi options|r – Open the options panel")
        print("  You can also right-click any dummy button to delete it.")
    end
end

----------------------------------------------------------------------
-- Initialisation
----------------------------------------------------------------------
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")

frame:SetScript("OnEvent", function(self, event, addon)
    if addon ~= ADDON_NAME then return end
    self:UnregisterEvent("ADDON_LOADED")

    -- Initialise saved variables
    if not SiggisMinimapButtonsDB then
        SiggisMinimapButtonsDB = CopyTable(DEFAULT_DB)
    end
    db = SiggisMinimapButtonsDB
    if not db.buttons then db.buttons = {} end
    if not db.nextId  then db.nextId  = 1 end

    -- Recreate persisted buttons
    for id, data in pairs(db.buttons) do
        CreateMinimapButton(id, data)
    end

    -- Register slash commands
    SLASH_SIEGLINDE1 = "/siggi"
    SLASH_SIEGLINDE2 = "/sgl"
    SlashCmdList["SIEGLINDE"] = HandleSlash

    print("|cff00ccffSiggi's Minimap Buttons|r loaded – type |cffffd200/siggi|r or |cffffd200/sgl|r for help.")
end)
