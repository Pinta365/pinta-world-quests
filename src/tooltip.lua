-- Custom tooltip for PintaWorldQuests
-- Uses a dedicated frame instead of GameTooltip.

local addonName, AddonTable = ...

local formatMoney = AddonTable.formatMoney

-- Stat display order
local STAT_PRIORITY = {
    ITEM_MOD_STRENGTH_SHORT       = 1,
    ITEM_MOD_AGILITY_SHORT        = 1,
    ITEM_MOD_INTELLECT_SHORT      = 1,
    ITEM_MOD_STAMINA_SHORT        = 2,
    ITEM_MOD_CRIT_RATING_SHORT    = 3,
    ITEM_MOD_HASTE_RATING_SHORT   = 3,
    ITEM_MOD_MASTERY_RATING_SHORT = 3,
    ITEM_MOD_VERSATILITY          = 3,
    ITEM_MOD_ARMOR                = 4,
    ITEM_MOD_LEECH_SHORT          = 4,
    ITEM_MOD_AVOIDANCE_SHORT      = 4,
    ITEM_MOD_SPEED_SHORT          = 4,
    ITEM_MOD_DAMAGE_PER_SECOND    = 4,
}

local CTTIP_W      = 310
local CTTIP_LINE_H = 16
local CTTIP_PAD_X  = 10
local CTTIP_PAD_Y  = 8

local cttipFrame
local cttipFonts  = {}
local cttipN      = 0
local cttipY      = 0

local function cttipEnsure()
    if cttipFrame then return end
    cttipFrame = CreateFrame("Frame", "PintaWQTooltip", UIParent, "BackdropTemplate")
    cttipFrame:SetFrameStrata("TOOLTIP")
    cttipFrame:SetFrameLevel(100)
    cttipFrame:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    cttipFrame:SetBackdropColor(0.09, 0.09, 0.09, 0.95)
    cttipFrame:SetBackdropBorderColor(0.4, 0.4, 0.4, 0.9)
    cttipFrame:Hide()
end

local function cttipReset()
    cttipN = 0
    cttipY = CTTIP_PAD_Y
    for _, fs in ipairs(cttipFonts) do fs:Hide() end
end

local function cttipSep()
    cttipY = cttipY + 5
end

local function cttipLine(text, r, g, b)
    cttipEnsure()
    cttipN = cttipN + 1
    local fs = cttipFonts[cttipN]
    if not fs then
        fs = cttipFrame:CreateFontString(nil, "overlay", "GameFontNormalSmall")
        fs:SetWidth(CTTIP_W - CTTIP_PAD_X * 2)
        fs:SetJustifyH("LEFT")
        cttipFonts[cttipN] = fs
    end
    fs:ClearAllPoints()
    fs:SetPoint("TOPLEFT", cttipFrame, "TOPLEFT", CTTIP_PAD_X, -cttipY)
    fs:SetText(text or "")
    fs:SetTextColor(r or 1, g or 1, b or 1)
    fs:Show()
    cttipY = cttipY + CTTIP_LINE_H + 2
end

local function cttipShow(anchor)
    cttipEnsure()
    cttipFrame:SetSize(CTTIP_W, cttipY + CTTIP_PAD_Y)
    cttipFrame:ClearAllPoints()
    local right = anchor:GetRight()
    if right and (right + CTTIP_W + 8) > GetScreenWidth() then
        cttipFrame:SetPoint("TOPRIGHT", anchor, "TOPLEFT", -4, 0)
    else
        cttipFrame:SetPoint("TOPLEFT", anchor, "TOPRIGHT", 4, 0)
    end
    cttipFrame:Show()
end

local function cttipHide()
    if cttipFrame then cttipFrame:Hide() end
end

-- Row tooltip

local function showRowTooltip(row)
    if not row.questID then return end
    local entry = AddonTable.questCache[row.questID]
    if not entry then return end

    local extended = PintaWorldQuestsDB and PintaWorldQuestsDB.extendedTooltips

    cttipReset()

    local r = entry.stripeR or 0.9
    local g = entry.stripeG or 0.9
    local b = entry.stripeB or 0.9
    local titleLine = entry.title or "World Quest"
    if entry.isElite then titleLine = titleLine .. "  \226\152\133 Elite" end
    cttipLine(titleLine, r, g, b)

    if extended then
        local objs = C_QuestLog.GetQuestObjectives and C_QuestLog.GetQuestObjectives(entry.questID)
        if objs and #objs > 0 then
            cttipSep()
            for _, obj in ipairs(objs) do
                local cr = obj.finished and 0.4 or 0.75
                cttipLine(obj.text or "", cr, cr, cr)
            end
        end

        if HaveQuestRewardData(entry.questID) then
            cttipSep()
            cttipLine("Rewards", 1, 0.82, 0)

            local xp = GetQuestLogRewardXP and GetQuestLogRewardXP(entry.questID)
            if xp and xp > 0 and not IsPlayerAtEffectiveMaxLevel() then
                local xpStr = BONUS_OBJECTIVE_EXPERIENCE_FORMAT and BONUS_OBJECTIVE_EXPERIENCE_FORMAT:format(xp)
                              or ((BreakUpLargeNumbers and BreakUpLargeNumbers(xp) or tostring(xp)) .. " XP")
                cttipLine(xpStr, 0.7, 0.7, 0.7)
            end

            if GetNumQuestLogRewards(entry.questID) > 0 then
                local name, texture, count, quality, _, _, itemLevel = GetQuestLogRewardInfo(1, entry.questID)
                if name then
                    local qc = quality and ITEM_QUALITY_COLORS[quality]
                    local qr, qg, qb = qc and qc.r or 0.8, qc and qc.g or 0.8, qc and qc.b or 0.8
                    local icon    = texture or entry.rewardTexture
                    local iconStr = icon and ("|T" .. icon .. ":15:15:0:0|t ") or ""
                    local nameStr = (count and count > 1) and (name .. " x" .. count) or name
                    cttipLine(iconStr .. nameStr, qr, qg, qb)
                    if entry.rewardSubtitle and entry.rewardSubtitle ~= "" then
                        cttipLine(entry.rewardSubtitle, 0.55, 0.55, 0.55)
                    end
                    if itemLevel and itemLevel > 0 then
                        cttipLine("Item Level " .. itemLevel, 1, 1, 1)
                    end
                    local link = GetQuestLogItemLink and GetQuestLogItemLink("reward", 1, entry.questID)
                    local stats = link and C_Item and C_Item.GetItemStats and C_Item.GetItemStats(link)
                    if stats then
                        local statList = {}
                        for statKey, val in pairs(stats) do
                            statList[#statList + 1] = { key = statKey, val = val }
                        end
                        table.sort(statList, function(a, b)
                            local pa = STAT_PRIORITY[a.key] or 99
                            local pb = STAT_PRIORITY[b.key] or 99
                            if pa ~= pb then return pa < pb end
                            return a.key < b.key
                        end)
                        for _, s in ipairs(statList) do
                            local label = _G[s.key] or s.key
                            cttipLine("+" .. math.floor(s.val + 0.5) .. " " .. label, 0.0, 0.8, 0.1)
                        end
                    end
                end
            end

            local currencies = C_QuestInfoSystem.GetQuestRewardCurrencies(entry.questID)
            if currencies and #currencies > 0 then
                for _, c in ipairs(currencies) do
                    local nameStr = c.name or "Currency"
                    if c.numItems and c.numItems > 1 then nameStr = nameStr .. " x" .. c.numItems end
                    cttipLine(nameStr, 1, 0.9, 0.5)
                end
            end

            local copper = GetQuestLogRewardMoney(entry.questID)
            if copper and copper > 0 then
                cttipLine(formatMoney(copper), 1, 0.82, 0.1)
            end
        else
            cttipLine("Reward loading...", 0.5, 0.5, 0.5)
        end

    else
        if HaveQuestRewardData(entry.questID) then
            if GetNumQuestLogRewards(entry.questID) > 0 then
                local name, texture, count, quality, _, _, itemLevel = GetQuestLogRewardInfo(1, entry.questID)
                if name then
                    local qc = quality and ITEM_QUALITY_COLORS[quality]
                    local qr, qg, qb = qc and qc.r or 0.8, qc and qc.g or 0.8, qc and qc.b or 0.8
                    local icon    = texture or entry.rewardTexture
                    local iconStr = icon and ("|T" .. icon .. ":15:15:0:0|t ") or ""
                    local nameStr = (count and count > 1) and (name .. " x" .. count) or name
                    local detail  = entry.rewardSubtitle or ""
                    if itemLevel and itemLevel > 0 then
                        detail = detail ~= "" and (detail .. "  " .. itemLevel) or tostring(itemLevel)
                    end
                    cttipLine(iconStr .. nameStr, qr, qg, qb)
                    if detail ~= "" then
                        cttipLine(detail, 0.55, 0.55, 0.55)
                    end
                end
            end
            local currencies = C_QuestInfoSystem.GetQuestRewardCurrencies(entry.questID)
            if currencies and #currencies > 0 then
                for _, c in ipairs(currencies) do
                    local nameStr = c.name or "Currency"
                    if c.numItems and c.numItems > 1 then nameStr = nameStr .. " x" .. c.numItems end
                    cttipLine(nameStr, 1, 0.9, 0.5)
                end
            end
            local copper = GetQuestLogRewardMoney(entry.questID)
            if copper and copper > 0 then
                cttipLine(formatMoney(copper), 1, 0.82, 0.1)
            end
        else
            cttipLine("Reward loading...", 0.5, 0.5, 0.5)
        end
    end

    local timeLeft = entry.expiresAt - GetTime()
    if timeLeft > 0 then
        local tr, tg, tb = 0.9, 0.9, 0.9
        local tStr
        if timeLeft < 3600 then
            tr, tg, tb = 1, 0.27, 0.27
            tStr = string.format("%d:%02d", math.floor(timeLeft / 60), math.floor(timeLeft % 60))
        elseif timeLeft < 10800 then
            tr, tg, tb = 1, 1, 0.27
            tStr = string.format("%dh %dm", math.floor(timeLeft / 3600), math.floor((timeLeft % 3600) / 60))
        elseif timeLeft < 86400 then
            tStr = string.format("%dh", math.floor(timeLeft / 3600))
        else
            tStr = string.format("%dd", math.floor(timeLeft / 86400))
        end
        local hex = string.format("|cff%02x%02x%02x", tr * 255, tg * 255, tb * 255)
        cttipLine("|cff888888Expires|r  " .. hex .. tStr .. "|r", 1, 1, 1)
    end

    cttipShow(row)
end

local function showButtonTooltip(anchor, text)
    cttipReset()
    cttipLine(text, 1, 1, 1)
    cttipShow(anchor)
end

AddonTable.showRowTooltip    = showRowTooltip
AddonTable.showButtonTooltip = showButtonTooltip
AddonTable.cttipHide         = cttipHide
