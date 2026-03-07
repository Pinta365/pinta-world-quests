-- List UI for PintaWorldQuests

local addonName, AddonTable = ...

local FRAME_WIDTH        = 300
local ROW_HEIGHT         = 30    -- verbose mode
local MAP_COMPACT_ITEM_H = 38    -- compact map overlay
local VISIBLE_ROWS       = 14
local HEADER_HEIGHT      = 26

local formatTimeLeft = AddonTable.formatTimeLeft

-- Reward colors and icon
local function getStripeColor(questID)
    if HaveQuestRewardData(questID) and GetNumQuestLogRewards(questID) > 0 then
        local _, _, _, itemQuality = GetQuestLogRewardInfo(1, questID)
        local c = itemQuality and ITEM_QUALITY_COLORS[itemQuality]
        if c then return c.r, c.g, c.b end
    end
    return 0.5, 0.5, 0.5
end

local function getRewardTexture(questID)
    if not HaveQuestRewardData(questID) then return nil end
    if GetNumQuestLogRewards(questID) > 0 then
        local _, tex = GetQuestLogRewardInfo(1, questID)
        if tex then return tex end
    end
    local currencies = C_QuestInfoSystem.GetQuestRewardCurrencies(questID)
    if currencies and #currencies > 0 and currencies[1].texture then
        return currencies[1].texture
    end
    if GetQuestLogRewardMoney(questID) > 0 then
        return "Interface\\Icons\\INV_Misc_Coin_01"
    end
    return nil
end

-- Reward subtitle (gear slot or item category)

local SLOT_NAMES = {
    INVTYPE_HEAD           = "Head",
    INVTYPE_NECK           = "Neck",
    INVTYPE_SHOULDER       = "Shoulder",
    INVTYPE_CHEST          = "Chest",
    INVTYPE_ROBE           = "Chest",
    INVTYPE_WAIST          = "Waist",
    INVTYPE_LEGS           = "Legs",
    INVTYPE_FEET           = "Feet",
    INVTYPE_WRIST          = "Wrist",
    INVTYPE_HAND           = "Hands",
    INVTYPE_FINGER         = "Finger",
    INVTYPE_TRINKET        = "Trinket",
    INVTYPE_CLOAK          = "Back",
    INVTYPE_WEAPON         = "One-Hand",
    INVTYPE_SHIELD         = "Off-Hand",
    INVTYPE_2HWEAPON       = "Two-Hand",
    INVTYPE_WEAPONMAINHAND = "Main Hand",
    INVTYPE_WEAPONOFFHAND  = "Off-Hand",
    INVTYPE_HOLDABLE       = "Off-Hand",
    INVTYPE_RANGED         = "Ranged",
    INVTYPE_RANGEDRIGHT    = "Ranged",
    INVTYPE_BODY           = "Shirt",
    INVTYPE_TABARD         = "Tabard",
}

local function getRewardSubtitle(questID)
    if not HaveQuestRewardData(questID) then return "" end
    if GetNumQuestLogRewards(questID) > 0 then
        local _, _, _, _, _, itemID = GetQuestLogRewardInfo(1, questID)
        if itemID then
            local _, _, _, _, _, itemType, itemSubType, _, equipSlot = C_Item.GetItemInfo(itemID)
            if equipSlot and equipSlot ~= "" and SLOT_NAMES[equipSlot] then
                return SLOT_NAMES[equipSlot]
            elseif itemSubType and itemSubType ~= "" then
                return itemSubType
            elseif itemType and itemType ~= "" then
                return itemType
            end
        end
    end
    local currencies = C_QuestInfoSystem.GetQuestRewardCurrencies(questID)
    if currencies and #currencies > 0 and currencies[1].name then
        return currencies[1].name
    end
    if GetQuestLogRewardMoney(questID) > 0 then
        return "Gold"
    end
    return ""
end

-- Row interaction

local function rowOnEnter(self)
    AddonTable.showRowTooltip(self)
    if self.questID and not InCombatLockdown() then
        self._prevSuperTrack = C_SuperTrack.GetSuperTrackedQuestID()
        C_SuperTrack.SetSuperTrackedQuestID(self.questID)
    end
end

local function rowOnLeave(self)
    AddonTable.cttipHide()
    if self._prevSuperTrack ~= nil and not InCombatLockdown() then
        C_SuperTrack.SetSuperTrackedQuestID(self._prevSuperTrack)
        self._prevSuperTrack = nil
    end
end

local function rowOnClick(self, btn)
    if btn ~= "LeftButton" or not self.questID then return end
    if IsShiftKeyDown() then
        local link = GetQuestLink(self.questID)
        if link then ChatEdit_InsertLink(link) end
        return
    end
    if not InCombatLockdown() then
        local entry = AddonTable.questCache[self.questID]
        if entry and entry.mapID then
            C_Map.OpenWorldMap(entry.mapID)
        end
    end
end

-- Row widget

local rowPool = {}

local function createRow(parent)
    local row = CreateFrame("Button", nil, parent)
    row:SetSize(FRAME_WIDTH - 8, ROW_HEIGHT)

    local hl = row:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    hl:SetColorTexture(1, 1, 1, 0.06)

    local stripe = row:CreateTexture(nil, "background")
    stripe:SetWidth(3)
    stripe:SetPoint("topleft",    row, "topleft",    2, -3)
    stripe:SetPoint("bottomleft", row, "bottomleft", 2,  3)
    row.stripe = stripe

    local sep = row:CreateTexture(nil, "background")
    sep:SetSize(FRAME_WIDTH - 16, 1)
    sep:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 6, 0)
    sep:SetColorTexture(1, 1, 1, 0.05)

    local icon = row:CreateTexture(nil, "artwork")
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    icon:Hide()
    row.icon = icon

    local titleText = row:CreateFontString(nil, "overlay", "GameFontNormal")
    titleText:SetJustifyH("LEFT")
    titleText:SetWordWrap(false)
    row.titleText = titleText

    local subtitleText = row:CreateFontString(nil, "overlay", "GameFontNormalTiny")
    subtitleText:SetTextColor(0.5, 0.5, 0.5)
    subtitleText:SetJustifyH("LEFT")
    row.subtitleText = subtitleText

    local timeText = row:CreateFontString(nil, "overlay", "GameFontNormal")
    timeText:SetPoint("RIGHT", row, "RIGHT", -6, 0)
    timeText:SetJustifyH("RIGHT")
    timeText:SetWidth(52)
    row.timeText = timeText

    row:SetScript("OnEnter", rowOnEnter)
    row:SetScript("OnLeave", rowOnLeave)
    row:SetScript("OnClick", rowOnClick)

    return row
end

local function getRow(index, parent)
    if not rowPool[index] then
        rowPool[index] = createRow(parent)
    end
    return rowPool[index]
end

-- Applies entry data to a row in compact or verbose layout.
local function applyRowToEntry(row, entry, isCompact)
    if HaveQuestRewardData(entry.questID) then
        if not entry.rewardCategory or entry.rewardCategory == "other" then
            AddonTable.classifyQuestReward(entry)
        end
        if not entry.rewardTexture then
            entry.rewardTexture = getRewardTexture(entry.questID)
        end
        if not entry.stripeR then
            entry.stripeR, entry.stripeG, entry.stripeB = getStripeColor(entry.questID)
        end
        if not entry.rewardSubtitle then
            entry.rewardSubtitle = getRewardSubtitle(entry.questID)
        end
    end

    local r = entry.stripeR or 0.5
    local g = entry.stripeG or 0.5
    local b = entry.stripeB or 0.5

    row.timeText:SetText(formatTimeLeft(entry.currentTimeLeft))

    if isCompact then
        row:SetHeight(MAP_COMPACT_ITEM_H)
        row.stripe:Hide()
        if entry.rewardTexture then
            row.icon:SetSize(20, 20)
            row.icon:ClearAllPoints()
            row.icon:SetPoint("TOP", row, "TOP", 0, -5)
            row.icon:SetTexture(entry.rewardTexture)
            row.icon:Show()
        else
            row.icon:Hide()
        end
        row.timeText:ClearAllPoints()
        row.timeText:SetPoint("BOTTOM", row, "BOTTOM", 0, 5)
        row.timeText:SetJustifyH("CENTER")
        row.timeText:SetWidth(48)
        row.titleText:Hide()
        row.subtitleText:Hide()
    else
        row:SetHeight(ROW_HEIGHT)
        row.stripe:SetColorTexture(r, g, b)
        if entry.rewardTexture then
            row.icon:SetSize(20, 20)
            row.icon:ClearAllPoints()
            row.icon:SetPoint("LEFT", row, "LEFT", 8, 0)
            row.icon:SetTexture(entry.rewardTexture)
            row.icon:Show()
        else
            row.icon:Hide()
        end
        row.timeText:ClearAllPoints()
        row.timeText:SetPoint("RIGHT", row, "RIGHT", -10, 0)
        row.timeText:SetJustifyH("RIGHT")
        row.timeText:SetWidth(52)
        row.titleText:ClearAllPoints()
        row.titleText:SetPoint("topleft",  row, "topleft",  30, -4)
        row.titleText:SetPoint("topright", row, "topright", -62, -4)
        row.titleText:SetText(entry.title or "")
        row.titleText:SetTextColor(r, g, b)
        row.titleText:Show()

        local sub = entry.rewardSubtitle or ""
        if entry.isElite then
            sub = sub ~= "" and ("Elite · " .. sub) or "Elite"
        end
        row.subtitleText:ClearAllPoints()
        row.subtitleText:SetPoint("bottomleft", row, "bottomleft", 30, 4)
        row.subtitleText:SetText(sub)
        row.subtitleText:Show()
    end

    row:SetAlpha(1.0)
end

-- Zone header widget

local ZONE_HEADER_H = 18
local headerPool    = {}

local function createZoneHeader(parent)
    local hdr = CreateFrame("Frame", nil, parent)
    hdr:SetHeight(ZONE_HEADER_H)

    local bg = hdr:CreateTexture(nil, "background")
    bg:SetAllPoints()
    bg:SetColorTexture(1, 1, 1, 0.06)

    local text = hdr:CreateFontString(nil, "overlay", "GameFontNormalSmall")
    text:SetPoint("LEFT",  hdr, "LEFT",  8, 0)
    text:SetPoint("RIGHT", hdr, "RIGHT", -8, 0)
    text:SetJustifyH("LEFT")
    text:SetTextColor(0.82, 0.76, 0.44)
    hdr.text = text

    return hdr
end

local function getZoneHeader(index, parent)
    if not headerPool[index] then
        headerPool[index] = createZoneHeader(parent)
    end
    return headerPool[index]
end

-- Shared header button helper

local function makeHeaderBtn(parent, w, labelText, onClick)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(w, 14)
    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.2, 0.15, 0.28, 0.85)
    local hl = btn:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    hl:SetColorTexture(1, 1, 1, 0.12)
    if labelText then
        local label = btn:CreateFontString(nil, "overlay", "GameFontNormalTiny")
        label:SetAllPoints()
        label:SetJustifyH("CENTER")
        label:SetText(labelText)
    end
    btn:SetScript("OnClick", onClick)
    return btn
end

local function makeGearBtn(parent, onClick)
    local btn = makeHeaderBtn(parent, 18, nil, onClick)
    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetSize(12, 12)
    icon:SetPoint("CENTER")
    icon:SetTexture("Interface\\ICONS\\Trade_Engineering")
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    return btn
end

-- Main frame

local function buildUI()
    local frameH = HEADER_HEIGHT + ROW_HEIGHT * VISIBLE_ROWS

    local main = CreateFrame("Frame", "PintaWQFrame", UIParent, "BackdropTemplate")
    main:SetSize(FRAME_WIDTH, frameH)
    main:SetPoint("topright", UIParent, "topright", -240, -300)
    main:SetFrameStrata("HIGH")
    main:SetMovable(true)
    main:SetClampedToScreen(true)
    main:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 12,
        insets   = {left=3, right=3, top=3, bottom=3},
    })
    main:SetBackdropColor(0.04, 0.03, 0.07, PintaWorldQuestsDB.backgroundOpacity or 0.8)
    main:SetScale(PintaWorldQuestsDB.listScale or 1.0)
    main:SetBackdropBorderColor(0.28, 0.22, 0.35, 0.90)
    main:Hide()

    local header = CreateFrame("Frame", nil, main)
    header:SetPoint("topleft",  main, "topleft",  0, 0)
    header:SetPoint("topright", main, "topright", 0, 0)
    header:SetHeight(HEADER_HEIGHT)
    header:EnableMouse(true)
    header:RegisterForDrag("LeftButton")
    header:SetScript("OnDragStart", function() main:StartMoving() end)
    header:SetScript("OnDragStop",  function() main:StopMovingOrSizing() end)

    local divider = header:CreateTexture(nil, "background")
    divider:SetPoint("bottomleft",  header, "bottomleft",  6, 0)
    divider:SetPoint("bottomright", header, "bottomright", -6, 0)
    divider:SetHeight(1)
    divider:SetColorTexture(0.28, 0.22, 0.35, 0.80)

    local headerText = header:CreateFontString(nil, "overlay", "GameFontNormalSmall")
    headerText:SetPoint("LEFT", header, "LEFT", 8, 0)
    main.headerText = headerText

    local closeBtn = CreateFrame("Button", nil, header)
    closeBtn:SetSize(16, 16)
    closeBtn:SetPoint("RIGHT", header, "RIGHT", -5, 0)
    closeBtn:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
    closeBtn:SetPushedTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Down")
    closeBtn:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight", "ADD")
    closeBtn:SetScript("OnClick", function()
        PintaWorldQuestsDB.listVisible = false
        main:Hide()
    end)

    local minBtn = CreateFrame("Button", nil, header)
    minBtn:SetSize(16, 16)
    minBtn:SetPoint("RIGHT", closeBtn, "LEFT", -2, 1)
    minBtn:SetNormalTexture("Interface\\Buttons\\Arrow-Up-Up")
    minBtn:SetPushedTexture("Interface\\Buttons\\Arrow-Up-Down")
    minBtn:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight", "ADD")

    local sortBtn = CreateFrame("Button", nil, header)
    sortBtn:SetSize(30, 14)
    sortBtn:SetPoint("RIGHT", closeBtn, "LEFT", -24, 0)

    local sortBg = sortBtn:CreateTexture(nil, "BACKGROUND")
    sortBg:SetAllPoints()
    sortBg:SetColorTexture(0.2, 0.15, 0.28, 0.85)

    local sortHL = sortBtn:CreateTexture(nil, "HIGHLIGHT")
    sortHL:SetAllPoints()
    sortHL:SetColorTexture(1, 1, 1, 0.12)

    local sortLabel = sortBtn:CreateFontString(nil, "overlay", "GameFontNormalTiny")
    sortLabel:SetAllPoints()
    sortLabel:SetJustifyH("CENTER")

    local SORT_CYCLE = { zone = "time", time = "zone" }
    local SORT_NEXT_LABEL = { zone = "Time", time = "Zone" }
    local SORT_TOOLTIP = {
        zone = "Sorted by zone",
        time = "Sorted by time remaining",
    }

    local function updateSortBtn()
        local mode = PintaWorldQuestsDB.sortMode or "zone"
        sortLabel:SetText("|cffaaaaaa" .. (SORT_NEXT_LABEL[mode] or "Time") .. "|r")
    end
    updateSortBtn()

    sortBtn:SetScript("OnClick", function()
        local mode = PintaWorldQuestsDB.sortMode or "zone"
        PintaWorldQuestsDB.sortMode = SORT_CYCLE[mode] or "zone"
        updateSortBtn()
        if AddonTable.refreshList then AddonTable.refreshList() end
    end)
    sortBtn:SetScript("OnEnter", function(self)
        local mode = PintaWorldQuestsDB.sortMode or "zone"
        AddonTable.showButtonTooltip(self, SORT_TOOLTIP[mode] or "Sort")
    end)
    sortBtn:SetScript("OnLeave", function() AddonTable.cttipHide() end)

    local expPopup, expCatcher

    local expBtn = CreateFrame("Button", nil, header)
    expBtn:SetSize(36, 14)
    expBtn:SetPoint("RIGHT", sortBtn, "LEFT", -4, 0)

    local expBg = expBtn:CreateTexture(nil, "BACKGROUND")
    expBg:SetAllPoints()
    expBg:SetColorTexture(0.2, 0.15, 0.28, 0.85)

    local expHL = expBtn:CreateTexture(nil, "HIGHLIGHT")
    expHL:SetAllPoints()
    expHL:SetColorTexture(1, 1, 1, 0.12)

    local expLabel = expBtn:CreateFontString(nil, "overlay", "GameFontNormalTiny")
    expLabel:SetAllPoints()
    expLabel:SetJustifyH("CENTER")

    local function updateExpLabel()
        local filter = PintaWorldQuestsDB and PintaWorldQuestsDB.expansionFilter
        if not filter then
            expLabel:SetText("|cffaaaaaaAuto|r")
        else
            for _, exp in ipairs(AddonTable.EXPANSIONS or {}) do
                if exp.root == filter then
                    expLabel:SetText("|cffaaaaaa" .. exp.short .. "|r")
                    return
                end
            end
        end
    end
    updateExpLabel()

    local function closeExpPopup()
        if expPopup  then expPopup:Hide()  end
        if expCatcher then expCatcher:Hide() end
    end

    expBtn:SetScript("OnClick", function(self)
        if expPopup and expPopup:IsShown() then closeExpPopup(); return end

        if not expPopup then
            expCatcher = CreateFrame("Button", nil, UIParent)
            expCatcher:SetAllPoints()
            expCatcher:SetFrameStrata("DIALOG")
            expCatcher:SetAlpha(0)
            expCatcher:SetScript("OnClick", closeExpPopup)
            expCatcher:Hide()

            expPopup = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
            expPopup:SetFrameStrata("DIALOG")
            expPopup:SetFrameLevel(expCatcher:GetFrameLevel() + 1)
            expPopup:SetBackdrop({
                bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                edgeSize = 10,
                insets   = {left=3, right=3, top=3, bottom=3},
            })
            expPopup:SetBackdropColor(0.06, 0.05, 0.10, 0.96)
            expPopup:SetBackdropBorderColor(0.28, 0.22, 0.35, 0.90)
            expPopup:Hide()

            local rowH = 20
            local opts = AddonTable.EXPANSIONS or {}
            expPopup:SetWidth(140)
            expPopup:SetHeight(#opts * rowH + 8)

            for i, exp in ipairs(opts) do
                local capturedExp = exp
                local row = CreateFrame("Button", nil, expPopup)
                row:SetHeight(rowH)
                row:SetPoint("LEFT",  expPopup, "LEFT",  6, 0)
                row:SetPoint("RIGHT", expPopup, "RIGHT", -6, 0)
                row:SetPoint("TOP",   expPopup, "TOP",   0, -(4 + (i - 1) * rowH))

                local rowHL = row:CreateTexture(nil, "HIGHLIGHT")
                rowHL:SetAllPoints()
                rowHL:SetColorTexture(1, 1, 1, 0.08)

                local rowLabel = row:CreateFontString(nil, "overlay", "GameFontNormalSmall")
                rowLabel:SetPoint("LEFT",  row, "LEFT",  4, 0)
                rowLabel:SetPoint("RIGHT", row, "RIGHT", -4, 0)
                rowLabel:SetJustifyH("LEFT")
                rowLabel:SetText(capturedExp.name)

                row:SetScript("OnClick", function()
                    PintaWorldQuestsDB.expansionFilter = capturedExp.root
                    closeExpPopup()
                    updateExpLabel()
                    if capturedExp.root then
                        AddonTable.scanExpansion(capturedExp.root)
                    else
                        AddonTable.scanExpansionZones()
                    end
                    if AddonTable.refreshList then AddonTable.refreshList() end
                end)
            end
        end

        expPopup:ClearAllPoints()
        expPopup:SetPoint("BOTTOMRIGHT", self, "TOPRIGHT", 0, 2)
        expPopup:Show()
        expCatcher:Show()
    end)
    expBtn:SetScript("OnEnter", function(self)
        AddonTable.showButtonTooltip(self, "Filter by expansion")
    end)
    expBtn:SetScript("OnLeave", function() AddonTable.cttipHide() end)

    -- Reward filter button + popup

    local REWARD_CATEGORIES = {
        { key = "gear",      label = "Gear",             icon = "Interface\\Icons\\INV_Chest_Chain_11" },
        { key = "currency",  label = "Currency",          icon = "Interface\\Icons\\INV_Misc_Coin_17" },
        { key = "gold",      label = "Gold",              icon = "Interface\\Icons\\INV_Misc_Coin_01" },
        { key = "resources", label = "Resources",         icon = "Interface\\Icons\\INV_Misc_Herb_AncientLichen" },
        { key = "capstone",  label = "Special Assignments", icon = "Interface\\Icons\\INV_Misc_Map02" },
        { key = "dungeon",   label = "Dungeons & Raids",  icon = "Interface\\Icons\\INV_Misc_Bone_Skull_01" },
        { key = "pvp",       label = "PvP",               icon = "Interface\\Icons\\Achievement_PVP_P_01" },
        { key = "petbattle", label = "Pet Battles",       icon = "Interface\\Icons\\PetJournalPortrait" },
        { key = "other",     label = "Other",             icon = "Interface\\Icons\\INV_Misc_QuestionMark" },
    }

    local filterPopup, filterCatcher

    local filterBtn = CreateFrame("Button", nil, header)
    filterBtn:SetSize(18, 14)
    filterBtn:SetPoint("RIGHT", expBtn, "LEFT", -4, 0)

    local filterBg = filterBtn:CreateTexture(nil, "BACKGROUND")
    filterBg:SetAllPoints()
    filterBg:SetColorTexture(0.2, 0.15, 0.28, 0.85)
    filterBtn.bg = filterBg

    local filterHL = filterBtn:CreateTexture(nil, "HIGHLIGHT")
    filterHL:SetAllPoints()
    filterHL:SetColorTexture(1, 1, 1, 0.12)

    local filterIcon = filterBtn:CreateTexture(nil, "ARTWORK")
    filterIcon:SetSize(12, 12)
    filterIcon:SetPoint("CENTER")
    filterIcon:SetAtlas("adventureguide-icon-filter")
    if not filterIcon:GetTexture() then
        filterIcon:SetTexture("Interface\\Icons\\INV_Misc_Spyglass_03")
        filterIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    end

    local function updateFilterBtnTint()
        local rf = PintaWorldQuestsDB and PintaWorldQuestsDB.rewardFilter or {}
        local anyHidden = false
        for _, v in pairs(rf) do
            if v then anyHidden = true; break end
        end
        if anyHidden then
            filterBg:SetColorTexture(0.45, 0.35, 0.15, 0.95)
        else
            filterBg:SetColorTexture(0.2, 0.15, 0.28, 0.85)
        end
    end
    updateFilterBtnTint()

    local function closeFilterPopup()
        if filterPopup  then filterPopup:Hide()  end
        if filterCatcher then filterCatcher:Hide() end
    end

    filterBtn:SetScript("OnClick", function(self)
        if filterPopup and filterPopup:IsShown() then closeFilterPopup(); return end

        if not filterPopup then
            filterCatcher = CreateFrame("Button", nil, UIParent)
            filterCatcher:SetAllPoints()
            filterCatcher:SetFrameStrata("DIALOG")
            filterCatcher:SetAlpha(0)
            filterCatcher:SetScript("OnClick", closeFilterPopup)
            filterCatcher:Hide()

            filterPopup = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
            filterPopup:SetFrameStrata("DIALOG")
            filterPopup:SetFrameLevel(filterCatcher:GetFrameLevel() + 1)
            filterPopup:SetBackdrop({
                bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                edgeSize = 10,
                insets   = {left=3, right=3, top=3, bottom=3},
            })
            filterPopup:SetBackdropColor(0.06, 0.05, 0.10, 0.96)
            filterPopup:SetBackdropBorderColor(0.28, 0.22, 0.35, 0.90)
            filterPopup:Hide()

            local rowH = 20
            filterPopup:SetWidth(160)
            filterPopup:SetHeight((#REWARD_CATEGORIES + 1) * rowH + 10)

            -- Toggle all row
            local toggleAllRow = CreateFrame("Button", nil, filterPopup)
            toggleAllRow:SetHeight(rowH)
            toggleAllRow:SetPoint("LEFT",  filterPopup, "LEFT",  6, 0)
            toggleAllRow:SetPoint("RIGHT", filterPopup, "RIGHT", -6, 0)
            toggleAllRow:SetPoint("TOP",   filterPopup, "TOP",   0, -4)

            local toggleAllHL = toggleAllRow:CreateTexture(nil, "HIGHLIGHT")
            toggleAllHL:SetAllPoints()
            toggleAllHL:SetColorTexture(1, 1, 1, 0.08)

            local toggleAllLabel = toggleAllRow:CreateFontString(nil, "overlay", "GameFontNormalSmall")
            toggleAllLabel:SetPoint("LEFT",  toggleAllRow, "LEFT",  4, 0)
            toggleAllLabel:SetPoint("RIGHT", toggleAllRow, "RIGHT", -4, 0)
            toggleAllLabel:SetJustifyH("LEFT")
            toggleAllLabel:SetTextColor(0.65, 0.55, 0.85)

            local function updateToggleAllLabel()
                local rf = PintaWorldQuestsDB and PintaWorldQuestsDB.rewardFilter or {}
                local anyHidden = false
                for _, v in pairs(rf) do
                    if v then anyHidden = true; break end
                end
                toggleAllLabel:SetText(anyHidden and "Select All" or "Deselect All")
            end
            toggleAllRow.updateToggleAllLabel = updateToggleAllLabel
            updateToggleAllLabel()

            toggleAllRow:SetScript("OnClick", function()
                if not PintaWorldQuestsDB.rewardFilter then
                    PintaWorldQuestsDB.rewardFilter = {}
                end
                local rf = PintaWorldQuestsDB.rewardFilter
                local anyHidden = false
                for _, v in pairs(rf) do
                    if v then anyHidden = true; break end
                end
                if anyHidden then
                    wipe(rf)
                else
                    for _, cat in ipairs(REWARD_CATEGORIES) do
                        rf[cat.key] = true
                    end
                end
                for _, child in pairs({filterPopup:GetChildren()}) do
                    if child.updateRow then child.updateRow() end
                end
                updateToggleAllLabel()
                updateFilterBtnTint()
                if AddonTable.refreshList then AddonTable.refreshList() end
            end)

            local divider = filterPopup:CreateTexture(nil, "ARTWORK")
            divider:SetHeight(1)
            divider:SetPoint("LEFT",  filterPopup, "LEFT",  10, 0)
            divider:SetPoint("RIGHT", filterPopup, "RIGHT", -10, 0)
            divider:SetPoint("TOP",   filterPopup, "TOP",   0, -(4 + rowH))
            divider:SetColorTexture(0.28, 0.22, 0.35, 0.60)

            for i, cat in ipairs(REWARD_CATEGORIES) do
                local capturedCat = cat
                local row = CreateFrame("Button", nil, filterPopup)
                row:SetHeight(rowH)
                row:SetPoint("LEFT",  filterPopup, "LEFT",  6, 0)
                row:SetPoint("RIGHT", filterPopup, "RIGHT", -6, 0)
                row:SetPoint("TOP",   filterPopup, "TOP",   0, -(6 + i * rowH))

                local rowHL2 = row:CreateTexture(nil, "HIGHLIGHT")
                rowHL2:SetAllPoints()
                rowHL2:SetColorTexture(1, 1, 1, 0.08)

                local catIcon = row:CreateTexture(nil, "ARTWORK")
                catIcon:SetSize(14, 14)
                catIcon:SetPoint("LEFT", row, "LEFT", 4, 0)
                catIcon:SetTexture(capturedCat.icon)
                catIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

                local rowLabel = row:CreateFontString(nil, "overlay", "GameFontNormalSmall")
                rowLabel:SetPoint("LEFT",  catIcon, "RIGHT", 4, 0)
                rowLabel:SetPoint("RIGHT", row, "RIGHT", -20, 0)
                rowLabel:SetJustifyH("LEFT")
                rowLabel:SetText(capturedCat.label)

                local check = row:CreateTexture(nil, "ARTWORK")
                check:SetSize(12, 12)
                check:SetPoint("RIGHT", row, "RIGHT", -4, 0)
                check:SetAtlas("checkmark-minimal")
                if not check:GetTexture() then
                    check:SetTexture("Interface\\RAIDFRAME\\ReadyCheck-Ready")
                end
                row.check = check

                local function updateRow()
                    local rf = PintaWorldQuestsDB and PintaWorldQuestsDB.rewardFilter or {}
                    if rf[capturedCat.key] then
                        row.check:Hide()
                        rowLabel:SetTextColor(0.4, 0.4, 0.4)
                        catIcon:SetDesaturated(true)
                    else
                        row.check:Show()
                        rowLabel:SetTextColor(0.8, 0.8, 0.8)
                        catIcon:SetDesaturated(false)
                    end
                end
                row.updateRow = updateRow

                row:SetScript("OnClick", function()
                    if not PintaWorldQuestsDB.rewardFilter then
                        PintaWorldQuestsDB.rewardFilter = {}
                    end
                    local rf = PintaWorldQuestsDB.rewardFilter
                    rf[capturedCat.key] = not rf[capturedCat.key] or nil
                    updateRow()
                    updateToggleAllLabel()
                    updateFilterBtnTint()
                    if AddonTable.refreshList then AddonTable.refreshList() end
                end)

                updateRow()
            end
        else
            for _, child in pairs({filterPopup:GetChildren()}) do
                if child.updateRow then child.updateRow() end
                if child.updateToggleAllLabel then child.updateToggleAllLabel() end
            end
        end

        filterPopup:ClearAllPoints()
        filterPopup:SetPoint("BOTTOMRIGHT", self, "TOPRIGHT", 0, 2)
        filterPopup:Show()
        filterCatcher:Show()
    end)
    filterBtn:SetScript("OnEnter", function(self)
        AddonTable.showButtonTooltip(self, "Filter by reward type")
    end)
    filterBtn:SetScript("OnLeave", function() AddonTable.cttipHide() end)

    local settingsBtn = makeGearBtn(header, function()
        if InCombatLockdown() then return end
        if Settings and AddonTable.settingsCategory then
            Settings.OpenToCategory(AddonTable.settingsCategory.ID)
        elseif AddonTable.optionsPanel then
            InterfaceOptionsFrame_OpenToCategory(AddonTable.optionsPanel)
        end
    end)
    settingsBtn:SetPoint("RIGHT", filterBtn, "LEFT", -4, 0)
    settingsBtn:SetScript("OnEnter", function(self)
        AddonTable.showButtonTooltip(self, "Open Settings")
    end)
    settingsBtn:SetScript("OnLeave", function() AddonTable.cttipHide() end)

    headerText:SetPoint("RIGHT", settingsBtn, "LEFT", -6, 0)

    main:HookScript("OnHide", closeExpPopup)
    main:HookScript("OnHide", closeFilterPopup)
    main:HookScript("OnHide", function() AddonTable.cttipHide() end)

    local SCROLLBAR_W = 6

    local scrollFrame = CreateFrame("ScrollFrame", nil, main)
    scrollFrame:SetPoint("topleft",     main, "topleft",     4,            -HEADER_HEIGHT)
    scrollFrame:SetPoint("bottomright", main, "bottomright", -(4 + SCROLLBAR_W + 2), 4)
    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local current = self:GetVerticalScroll()
        local max     = self:GetVerticalScrollRange()
        self:SetVerticalScroll(math.max(0, math.min(max, current - delta * ROW_HEIGHT)))
    end)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetWidth(FRAME_WIDTH - 8 - SCROLLBAR_W - 2)
    content:SetHeight(ROW_HEIGHT)
    scrollFrame:SetScrollChild(content)

    local track = main:CreateTexture(nil, "background")
    track:SetWidth(SCROLLBAR_W)
    track:SetPoint("topright",    main, "topright",    -(4), -HEADER_HEIGHT - 2)
    track:SetPoint("bottomright", main, "bottomright", -(4),  4)
    track:SetColorTexture(1, 1, 1, 0.04)

    local thumb = CreateFrame("Button", nil, main)
    thumb:SetWidth(SCROLLBAR_W)
    thumb:SetPoint("topright", main, "topright", -4, -HEADER_HEIGHT - 2)

    local thumbTex = thumb:CreateTexture(nil, "artwork")
    thumbTex:SetAllPoints()
    thumbTex:SetColorTexture(0.6, 0.5, 0.8, 0.5)
    thumb.tex = thumbTex

    local thumbHL = thumb:CreateTexture(nil, "HIGHLIGHT")
    thumbHL:SetAllPoints()
    thumbHL:SetColorTexture(0.8, 0.7, 1.0, 0.4)

    local minimized = false

    local function updateThumb()
        local max = scrollFrame:GetVerticalScrollRange()
        if max <= 0 or minimized then thumb:Hide(); track:Hide(); return end
        track:Show()
        thumb:Show()
        local trackH   = track:GetHeight()
        local ratio    = scrollFrame:GetHeight() / (scrollFrame:GetHeight() + max)
        local thumbH   = math.max(20, trackH * ratio)
        local scrolled = scrollFrame:GetVerticalScroll() / max
        local travel   = trackH - thumbH
        thumb:SetHeight(thumbH)
        thumb:SetPoint("topright", main, "topright", -4,
            -(HEADER_HEIGHT + 2 + scrolled * travel))
    end

    scrollFrame:SetScript("OnVerticalScroll", function(self, value)
        updateThumb()
    end)

    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local current = self:GetVerticalScroll()
        local max     = self:GetVerticalScrollRange()
        self:SetVerticalScroll(math.max(0, math.min(max, current - delta * ROW_HEIGHT)))
        updateThumb()
    end)

    thumb:SetScript("OnMouseDown", function(self, btn)
        if btn ~= "LeftButton" then return end
        local startY  = select(2, GetCursorPosition()) / UIParent:GetEffectiveScale()
        local startScroll = scrollFrame:GetVerticalScroll()
        local max = scrollFrame:GetVerticalScrollRange()
        local trackH  = track:GetHeight()
        local thumbH  = thumb:GetHeight()
        local travel  = trackH - thumbH

        self:SetScript("OnUpdate", function()
            local curY   = select(2, GetCursorPosition()) / UIParent:GetEffectiveScale()
            local delta  = startY - curY
            local frac   = travel > 0 and (delta / travel) or 0
            scrollFrame:SetVerticalScroll(math.max(0, math.min(max, startScroll + frac * max)))
            updateThumb()
        end)
    end)
    thumb:SetScript("OnMouseUp", function(self)
        self:SetScript("OnUpdate", nil)
    end)

    local function setMinimized(state)
        minimized = state
        PintaWorldQuestsDB.minimized = state
        if minimized then
            minBtn:SetNormalTexture("Interface\\Buttons\\Arrow-Down-Up")
            minBtn:SetPushedTexture("Interface\\Buttons\\Arrow-Down-Down")
            minBtn:ClearAllPoints()
            minBtn:SetPoint("RIGHT", closeBtn, "LEFT", -2, -5)
            scrollFrame:Hide()
            track:Hide()
            thumb:Hide()
            main:SetHeight(HEADER_HEIGHT)
        else
            minBtn:SetNormalTexture("Interface\\Buttons\\Arrow-Up-Up")
            minBtn:SetPushedTexture("Interface\\Buttons\\Arrow-Up-Down")
            minBtn:ClearAllPoints()
            minBtn:SetPoint("RIGHT", closeBtn, "LEFT", -2, 1)
            scrollFrame:Show()
            track:Show()
            main:SetHeight(frameH)
            updateThumb()
        end
    end
    minBtn:SetScript("OnClick", function()
        setMinimized(not minimized)
        if AddonTable.refreshList then AddonTable.refreshList() end
    end)
    minBtn:SetScript("OnEnter", function(self)
        AddonTable.showButtonTooltip(self, minimized and "Expand" or "Minimize")
    end)
    minBtn:SetScript("OnLeave", function() AddonTable.cttipHide() end)

    local noQuestsText = main:CreateFontString(nil, "overlay", "GameFontNormal")
    noQuestsText:SetPoint("CENTER", scrollFrame, "CENTER")
    noQuestsText:SetText("|cff888888No active world quests|r")
    noQuestsText:Hide()
    main.noQuestsText = noQuestsText

    if PintaWorldQuestsDB.minimized then setMinimized(true) end

    AddonTable.mainFrame    = main
    AddonTable.listContent  = content
    AddonTable.updateThumb  = updateThumb
end

-- Public: refresh list display

function AddonTable.refreshList()
    local content = AddonTable.listContent
    if not content then return end
    AddonTable.cttipHide()

    local now         = GetServerTime()
    local sortMode    = PintaWorldQuestsDB and PintaWorldQuestsDB.sortMode or "zone"
    local totalQuests = 0
    local allEntries  = {}

    local filterRoot  = PintaWorldQuestsDB and PintaWorldQuestsDB.expansionFilter
    local filterZones = filterRoot and AddonTable.EXPANSION_ZONES and AddonTable.EXPANSION_ZONES[filterRoot]
    local rewardFilter = PintaWorldQuestsDB and PintaWorldQuestsDB.rewardFilter or {}

    local minTime, maxTime = math.huge, 0
    for questID, entry in pairs(AddonTable.questCache) do
        local timeLeft = entry.expiresAt - now
        if timeLeft > 0 then
            local include = true
            if filterZones then
                include = (entry.mapID == filterRoot)
                if not include then
                    for _, zid in ipairs(filterZones) do
                        if entry.mapID == zid then include = true; break end
                    end
                end
            end
            if include and entry.rewardCategory and rewardFilter[entry.rewardCategory] then
                include = false
            end
            if include then
                entry.currentTimeLeft = timeLeft
                allEntries[#allEntries + 1] = entry
                totalQuests = totalQuests + 1
                if timeLeft < minTime then minTime = timeLeft end
                if timeLeft > maxTime then maxTime = timeLeft end
            end
        else
            AddonTable.questCache[questID] = nil
        end
    end

    local main = AddonTable.mainFrame
    if main then
        if PintaWorldQuestsDB.minimized and totalQuests > 0 then
            main.headerText:SetText(string.format(
                "|cff45D388WQs|r |cff888888(%d)|r  %s|cff888888-|r%s",
                totalQuests, formatTimeLeft(minTime), formatTimeLeft(maxTime)))
        else
            main.headerText:SetFormattedText(
                "|cff45D388World Quests|r |cff888888(%d)|r", totalQuests)
        end
        if PintaWorldQuestsDB.listVisible then
            main:Show()
        end
        if main.noQuestsText then
            if totalQuests == 0 and not PintaWorldQuestsDB.minimized then
                local anyHidden = false
                for _, v in pairs(rewardFilter) do
                    if v then anyHidden = true; break end
                end
                if anyHidden then
                    main.noQuestsText:SetText("|cff888888No quests match current filters|r")
                else
                    main.noQuestsText:SetText("|cff888888No active world quests|r")
                end
                main.noQuestsText:Show()
            else
                main.noQuestsText:Hide()
            end
        end
    end

    local yOffset = 0
    local rowIdx  = 0
    local hdrIdx  = 0

    if sortMode == "time" then
        table.sort(allEntries, function(a, b)
            return (a.currentTimeLeft or 0) < (b.currentTimeLeft or 0)
        end)
        for _, entry in ipairs(allEntries) do
            rowIdx = rowIdx + 1
            local row = getRow(rowIdx, content)
            row:ClearAllPoints()
            row:SetPoint("topleft", content, "topleft", 0, -yOffset)
            row:Show()
            row.questID = entry.questID
            applyRowToEntry(row, entry, false)
            yOffset = yOffset + ROW_HEIGHT
        end
    else
        local byZone    = {}
        local zoneNames = {}
        for _, entry in ipairs(allEntries) do
            local mid = entry.mapID or 0
            if not byZone[mid] then
                byZone[mid] = {}
                local info = mid ~= 0 and C_Map.GetMapInfo(mid)
                zoneNames[mid] = (info and info.name) or "Unknown"
            end
            byZone[mid][#byZone[mid] + 1] = entry
        end
        for _, entries in pairs(byZone) do
            table.sort(entries, function(a, b)
                return (a.currentTimeLeft or 0) < (b.currentTimeLeft or 0)
            end)
        end
        local zones = {}
        for mapID in pairs(byZone) do zones[#zones + 1] = mapID end
        table.sort(zones, function(a, b)
            return (zoneNames[a] or "") < (zoneNames[b] or "")
        end)
        for _, mapID in ipairs(zones) do
            hdrIdx = hdrIdx + 1
            local hdr = getZoneHeader(hdrIdx, content)
            hdr:ClearAllPoints()
            hdr:SetPoint("topleft",  content, "topleft",  0, -yOffset)
            hdr:SetPoint("topright", content, "topright", 0, -yOffset)
            hdr.text:SetText(zoneNames[mapID])
            hdr:Show()
            yOffset = yOffset + ZONE_HEADER_H
            for _, entry in ipairs(byZone[mapID]) do
                rowIdx = rowIdx + 1
                local row = getRow(rowIdx, content)
                row:ClearAllPoints()
                row:SetPoint("topleft", content, "topleft", 0, -yOffset)
                row:Show()
                row.questID = entry.questID
                applyRowToEntry(row, entry, false)
                yOffset = yOffset + ROW_HEIGHT
            end
        end
    end

    content:SetHeight(math.max(yOffset, ROW_HEIGHT))

    for i = rowIdx + 1, #rowPool    do rowPool[i]:Hide()    end
    for i = hdrIdx + 1, #headerPool do headerPool[i]:Hide() end

    if AddonTable.updateThumb then AddonTable.updateThumb() end
end

-- In-map panel

local MAP_PANEL_WIDTH         = 180
local MAP_PANEL_WIDTH_COMPACT = 50
local MAP_ROW_HEIGHT          = 24
local MAP_HEADER_H            = 20
local MAP_MAX_ROWS            = 15

local mapRowPool = {}

local function createMapRow(parent)
    local row = CreateFrame("Button", nil, parent)
    row:SetSize(MAP_PANEL_WIDTH - 8, MAP_ROW_HEIGHT)

    local hl = row:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    hl:SetColorTexture(1, 1, 1, 0.06)

    local stripe = row:CreateTexture(nil, "background")
    stripe:SetSize(3, MAP_ROW_HEIGHT - 4)
    stripe:SetPoint("LEFT", row, "LEFT", 2, 0)
    row.stripe = stripe

    local sep = row:CreateTexture(nil, "background")
    sep:SetPoint("bottomleft",  row, "bottomleft",  6, 0)
    sep:SetPoint("bottomright", row, "bottomright", -4, 0)
    sep:SetHeight(1)
    sep:SetColorTexture(1, 1, 1, 0.04)

    local icon = row:CreateTexture(nil, "artwork")
    icon:SetSize(16, 16)
    icon:SetPoint("LEFT", row, "LEFT", 8, 0)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    icon:Hide()
    row.icon = icon

    local titleText = row:CreateFontString(nil, "overlay", "GameFontNormalSmall")
    titleText:SetJustifyH("LEFT")
    titleText:SetWordWrap(false)
    row.titleText = titleText

    local subtitleText = row:CreateFontString(nil, "overlay", "GameFontNormalTiny")
    subtitleText:SetTextColor(0.5, 0.5, 0.5)
    subtitleText:SetJustifyH("LEFT")
    row.subtitleText = subtitleText

    local timeText = row:CreateFontString(nil, "overlay", "GameFontNormalSmall")
    timeText:SetPoint("RIGHT", row, "RIGHT", -4, 0)
    timeText:SetJustifyH("RIGHT")
    timeText:SetWidth(10)
    row.timeText = timeText

    row:SetScript("OnEnter", rowOnEnter)
    row:SetScript("OnLeave", rowOnLeave)
    row:SetScript("OnClick", rowOnClick)

    return row
end

local function getMapRow(i, parent)
    if not mapRowPool[i] then
        mapRowPool[i] = createMapRow(parent)
    end
    return mapRowPool[i]
end

local function buildMapPanel()
    local panel = CreateFrame("Frame", "PintaWQMapPanel", WorldMapFrame:GetCanvasContainer())
    panel:SetWidth(MAP_PANEL_WIDTH)
    panel:SetHeight(MAP_HEADER_H + MAP_ROW_HEIGHT)
    panel:SetFrameStrata("HIGH")
    panel:SetFrameLevel(WorldMapFrame:GetFrameLevel() + 20)

    local bg = panel:CreateTexture(nil, "background")
    bg:SetAllPoints()
    bg:SetTexture("Interface\\Buttons\\WHITE8X8")
    panel.backgroundTexture = bg

    local optBtn = makeGearBtn(panel, function()
        if InCombatLockdown() then return end
        if Settings and AddonTable.settingsCategory then
            Settings.OpenToCategory(AddonTable.settingsCategory.ID)
        elseif AddonTable.optionsPanel then
            InterfaceOptionsFrame_OpenToCategory(AddonTable.optionsPanel)
        end
    end)
    optBtn:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -4, -3)
    optBtn:SetScript("OnEnter", function(self)
        AddonTable.showButtonTooltip(self, "Open Settings")
    end)
    optBtn:SetScript("OnLeave", function() AddonTable.cttipHide() end)
    panel.optBtn = optBtn

    local listBtn = makeHeaderBtn(panel, 22, "WQ", function()
        local f = AddonTable.mainFrame
        if f then
            if f:IsShown() then
                PintaWorldQuestsDB.listVisible = false
                f:Hide()
            else
                PintaWorldQuestsDB.listVisible = true
                f:Show()
            end
        end
    end)
    listBtn:SetPoint("RIGHT", optBtn, "LEFT", -2, 0)
    listBtn:SetScript("OnEnter", function(self)
        AddonTable.showButtonTooltip(self, "Toggle Quest List")
    end)
    listBtn:SetScript("OnLeave", function() AddonTable.cttipHide() end)
    panel.listBtn = listBtn

    local compactBtn = CreateFrame("Button", nil, panel)
    compactBtn:SetSize(18, 14)
    local compactBtnBg = compactBtn:CreateTexture(nil, "BACKGROUND")
    compactBtnBg:SetAllPoints()
    compactBtnBg:SetColorTexture(0.2, 0.15, 0.28, 0.85)
    local compactBtnHL = compactBtn:CreateTexture(nil, "HIGHLIGHT")
    compactBtnHL:SetAllPoints()
    compactBtnHL:SetColorTexture(1, 1, 1, 0.12)
    local compactBtnLabel = compactBtn:CreateFontString(nil, "overlay", "GameFontNormalTiny")
    compactBtnLabel:SetAllPoints()
    compactBtnLabel:SetJustifyH("CENTER")
    compactBtnLabel:SetText("C")
    compactBtn:SetScript("OnClick", function()
        PintaWorldQuestsDB.compactMode = not PintaWorldQuestsDB.compactMode
        if AddonTable.refreshMapPanel then AddonTable.refreshMapPanel() end
    end)
    compactBtn:SetScript("OnEnter", function(self)
        local mode = PintaWorldQuestsDB and PintaWorldQuestsDB.compactMode
        AddonTable.showButtonTooltip(self, mode and "Compact mode: ON" or "Compact mode: OFF")
    end)
    compactBtn:SetScript("OnLeave", function() AddonTable.cttipHide() end)
    compactBtn:SetPoint("RIGHT", listBtn, "LEFT", -2, 0)
    panel.compactBtn    = compactBtn
    panel.compactBtnBg  = compactBtnBg

    local headerText = panel:CreateFontString(nil, "overlay", "GameFontNormalSmall")
    headerText:SetPoint("topleft",  panel, "topleft",  6,   -4)
    headerText:SetPoint("topright", panel, "topright", -70, -4)
    headerText:SetWordWrap(false)
    panel.headerText = headerText

    local divider = panel:CreateTexture(nil, "background")
    divider:SetPoint("topleft",  panel, "topleft",  4, -(MAP_HEADER_H - 1))
    divider:SetPoint("topright", panel, "topright", -4, -(MAP_HEADER_H - 1))
    divider:SetHeight(1)
    divider:SetColorTexture(0.28, 0.22, 0.35, 0.70)

    local content = CreateFrame("Frame", nil, panel)
    content:SetPoint("topleft",  panel, "topleft",  4, -MAP_HEADER_H)
    content:SetPoint("topright", panel, "topright", -4, -MAP_HEADER_H)
    content:SetHeight(MAP_ROW_HEIGHT)
    panel.content = content

    panel:Hide()
    AddonTable.mapPanel = panel
    AddonTable.applyMapPanelSide()
end

function AddonTable.applyMapPanelSide()
    local panel = AddonTable.mapPanel
    if not panel then return end
    panel:ClearAllPoints()
    local isRight = PintaWorldQuestsDB and PintaWorldQuestsDB.mapPanelSide == "right"
    if isRight then
        panel:SetPoint("topright", WorldMapFrame:GetCanvasContainer(), "topright", -8, -56)
    else
        panel:SetPoint("topleft", WorldMapFrame:GetCanvasContainer(), "topleft", 8, -56)
    end
    if panel.backgroundTexture then
        local opaque = CreateColor(0, 0, 0, 0.82)
        local clear  = CreateColor(0, 0, 0, 0)
        if isRight then
            panel.backgroundTexture:SetGradient("HORIZONTAL", clear, opaque)
        else
            panel.backgroundTexture:SetGradient("HORIZONTAL", opaque, clear)
        end
    end
end

local function collectDescendantMaps(mid, result)
    result[mid] = true
    local children = C_Map.GetMapChildrenInfo(mid)
    if children then
        for _, child in ipairs(children) do
            collectDescendantMaps(child.mapID, result)
        end
    end
end

function AddonTable.refreshMapPanel(mapID)
    local panel = AddonTable.mapPanel
    if not panel then return end
    AddonTable.cttipHide()

    mapID = mapID or (WorldMapFrame and WorldMapFrame:GetMapID())
    if not mapID then panel:Hide(); return end

    local validMaps = {}
    collectDescendantMaps(mapID, validMaps)

    local now    = GetServerTime()
    local quests = {}
    for _, entry in pairs(AddonTable.questCache) do
        if validMaps[entry.mapID] then
            local timeLeft = entry.expiresAt - now
            if timeLeft > 0 then
                entry.currentTimeLeft = timeLeft
                quests[#quests + 1] = entry
            end
        end
    end

    if #quests == 0 then panel:Hide(); return end

    table.sort(quests, function(a, b)
        return (a.currentTimeLeft or 0) < (b.currentTimeLeft or 0)
    end)

    local isCompact = PintaWorldQuestsDB and PintaWorldQuestsDB.compactMode
    local mapRowH   = isCompact and MAP_COMPACT_ITEM_H or ROW_HEIGHT
    local shown     = math.min(#quests, MAP_MAX_ROWS)

    if panel.compactBtnBg then
        if isCompact then
            panel.compactBtnBg:SetColorTexture(0.35, 0.22, 0.50, 0.95)
        else
            panel.compactBtnBg:SetColorTexture(0.2, 0.15, 0.28, 0.85)
        end
    end

    panel:SetWidth(isCompact and MAP_PANEL_WIDTH_COMPACT or MAP_PANEL_WIDTH)

    if isCompact then
        panel.headerText:Hide()
        panel.optBtn:Show()
        panel.listBtn:Show()
        panel.compactBtn:ClearAllPoints()
        panel.compactBtn:SetPoint("TOPLEFT", panel, "TOPLEFT", 2, -3)
        panel.listBtn:ClearAllPoints()
        panel.listBtn:SetPoint("LEFT", panel.compactBtn, "RIGHT", 2, 0)
        panel.optBtn:ClearAllPoints()
        panel.optBtn:SetPoint("LEFT", panel.listBtn, "RIGHT", 2, 0)
        local totalH = MAP_HEADER_H + shown * mapRowH + 4
        panel:SetHeight(totalH)
        panel.content:SetHeight(shown * mapRowH)
        panel.content:SetPoint("topleft",  panel, "topleft",  4, -MAP_HEADER_H)
        panel.content:SetPoint("topright", panel, "topright", -4, -MAP_HEADER_H)
    else
        panel.headerText:Show()
        panel.optBtn:Show()
        panel.listBtn:Show()
        panel.optBtn:ClearAllPoints()
        panel.optBtn:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -4, -3)
        panel.listBtn:ClearAllPoints()
        panel.listBtn:SetPoint("RIGHT", panel.optBtn, "LEFT", -2, 0)
        panel.compactBtn:ClearAllPoints()
        panel.compactBtn:SetPoint("RIGHT", panel.listBtn, "LEFT", -2, 0)
        local mapInfo  = C_Map.GetMapInfo(mapID)
        local zoneName = mapInfo and mapInfo.name or ""
        panel.headerText:SetFormattedText(
            "|cff45D388%s|r |cff888888(%d)|r", zoneName, #quests)
        local totalH = MAP_HEADER_H + shown * mapRowH + 4
        panel:SetHeight(totalH)
        panel.content:SetHeight(shown * mapRowH)
        panel.content:SetPoint("topleft",  panel, "topleft",  4, -MAP_HEADER_H)
        panel.content:SetPoint("topright", panel, "topright", -4, -MAP_HEADER_H)
    end

    for i = 1, shown do
        local entry = quests[i]
        local row   = getMapRow(i, panel.content)
        row:ClearAllPoints()
        row:SetPoint("topleft",  panel.content, "topleft",  0, -(i - 1) * mapRowH)
        row:SetPoint("topright", panel.content, "topright", 0, -(i - 1) * mapRowH)
        row:Show()
        row.questID = entry.questID
        applyRowToEntry(row, entry, isCompact)
    end

    for i = shown + 1, #mapRowPool do mapRowPool[i]:Hide() end

    panel:Show()
end

-- Public: init

function AddonTable.initUI()
    buildUI()
    buildMapPanel()

    C_Timer.NewTicker(15, function()
        if AddonTable.mainFrame and AddonTable.mainFrame:IsShown() then
            AddonTable.refreshList()
        end
        if AddonTable.mapPanel and AddonTable.mapPanel:IsShown() then
            AddonTable.refreshMapPanel()
        end
    end)

    C_Timer.NewTicker(5, function()
        local now = GetServerTime()
        for _, row in ipairs(rowPool) do
            if row:IsShown() and row.questID then
                local entry = AddonTable.questCache[row.questID]
                if entry then
                    row.timeText:SetText(formatTimeLeft(entry.expiresAt - now))
                end
            end
        end
        for _, row in ipairs(mapRowPool) do
            if row:IsShown() and row.questID then
                local entry = AddonTable.questCache[row.questID]
                if entry then
                    row.timeText:SetText(formatTimeLeft(entry.expiresAt - now))
                end
            end
        end
        local main = AddonTable.mainFrame
        if main and PintaWorldQuestsDB.minimized then
            local filterRoot  = PintaWorldQuestsDB and PintaWorldQuestsDB.expansionFilter
            local filterZones = filterRoot and AddonTable.EXPANSION_ZONES and AddonTable.EXPANSION_ZONES[filterRoot]
            local minT, maxT, count = math.huge, 0, 0
            for _, entry in pairs(AddonTable.questCache) do
                local t = entry.expiresAt - now
                if t > 0 then
                    local include = true
                    if filterZones then
                        include = (entry.mapID == filterRoot)
                        if not include then
                            for _, zid in ipairs(filterZones) do
                                if entry.mapID == zid then include = true; break end
                            end
                        end
                    end
                    if include then
                        count = count + 1
                        if t < minT then minT = t end
                        if t > maxT then maxT = t end
                    end
                end
            end
            if count > 0 then
                main.headerText:SetText(string.format(
                    "|cff45D388WQs|r |cff888888(%d)|r  %s|cff888888-|r%s",
                    count, formatTimeLeft(minT), formatTimeLeft(maxT)))
            end
        end
    end)

    hooksecurefunc(WorldMapFrame, "OnMapChanged", function(self)
        local mapID = self:GetMapID()
        AddonTable.scanMap(mapID)
        AddonTable.refreshMapPanel(mapID)
    end)

    AddonTable.initCommands()
end
