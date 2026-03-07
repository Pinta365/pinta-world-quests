-- World quest data layer for PintaWorldQuests

local addonName, AddonTable = ...

local GetQuestsForPlayerByMapID = C_TaskQuest.GetQuestsOnMap or C_TaskQuest.GetQuestsForPlayerByMapID
local GetQuestTimeLeftSeconds   = C_TaskQuest.GetQuestTimeLeftSeconds

-- Get the map ID from a data provider via C API.
local function getViewedMapID(dataProvider)
    local ok, mapID = pcall(function()
        return dataProvider:GetMap():GetMapID()
    end)
    return ok and mapID or nil
end

-- questID -> mapID (or true if mapID unknown) for in-flight async requests
local pendingDataRequests = {}

AddonTable.questCache = {}

AddonTable.lastKnownRoot = nil

-- Coalesce rapid scanMap calls into a single UI refresh next frame.
local refreshPending = false
local function scheduleRefresh()
    if not refreshPending then
        refreshPending = true
        C_Timer.After(0, function()
            refreshPending = false
            if AddonTable.refreshList     then AddonTable.refreshList()     end
            if AddonTable.refreshMapPanel then AddonTable.refreshMapPanel() end
        end)
    end
end

-- Known expansion roots → their main zone mapIDs.
local EXPANSION_ZONES = {
    [2537] = { 2395, 2437, 2405, 2413 },                           -- Midnight
    [2274] = { 2248, 2214, 2215, 2255, 2369, 2371 },               -- TWW
    [1978] = { 2022, 2023, 2024, 2025, 2151, 2133, 2200 },         -- Dragonflight
    [1550] = { 1533, 1536, 1565, 1525, 1543, 1961, 1970 },         -- Shadowlands
    [619]  = { 630, 641, 650, 634, 680, 646, 790, 905, 885, 830, 882 },  -- Legion
    [875]  = { 862, 863, 864, 895, 942, 896, 1355, 1462, 876 },    -- BFA (Zandalar + Kul Tiras, Nazjatar, Mechagon)
}

-- Maps any alt root → canonical expansion root stored in EXPANSION_ZONES
local ROOT_ALIASES = {
    [876] = 875,  -- Kul Tiras → BFA
}

AddonTable.EXPANSION_ZONES = EXPANSION_ZONES
-- Chronological order (newest first); Auto first, then current → legacy.
AddonTable.EXPANSIONS = {
    { name = "Auto",                   short = "Auto", root = nil  },
    { name = "Midnight",               short = "Mid",  root = 2537 },
    { name = "The War Within",         short = "TWW",  root = 2274 },
    { name = "Dragonflight",           short = "DF",   root = 1978 },
    { name = "Shadowlands",            short = "SL",   root = 1550 },
    { name = "Battle for Azeroth",     short = "BFA",  root = 875  },
    { name = "Legion",                 short = "Leg",  root = 619  },
}

-- Expansion detection & scan

-- Walk up from playerMapID; return the first ancestor that is a key in
-- EXPANSION_ZONES (= the expansion root we recognise), or nil if unknown.
-- ROOT_ALIASES normalises alternate roots (e.g. Kul Tiras) to canonical roots.
local function detectExpansionRoot(playerMapID)
    local current = playerMapID
    for _ = 1, 8 do
        if EXPANSION_ZONES[current] then return current end
        if ROOT_ALIASES[current] then return ROOT_ALIASES[current] end
        local info = C_Map.GetMapInfo(current)
        if not info or not info.parentMapID or info.parentMapID == 0 then break end
        current = info.parentMapID
    end
    return nil
end

function AddonTable.scanExpansionZones()
    local filterRoot = PintaWorldQuestsDB and PintaWorldQuestsDB.expansionFilter
    if filterRoot then
        AddonTable.scanExpansion(filterRoot)
        return
    end

    local playerMapID = C_Map.GetBestMapForUnit("player")
    local root = playerMapID and detectExpansionRoot(playerMapID)

    if root then
        AddonTable.lastKnownRoot = root
        AddonTable.Debug("scanExpansionZones: root", root, (C_Map.GetMapInfo(root) or {}).name or "?")
        AddonTable.scanExpansion(root)
    elseif AddonTable.lastKnownRoot then
        AddonTable.Debug("scanExpansionZones: fallback to last known root", AddonTable.lastKnownRoot)
        AddonTable.scanExpansion(AddonTable.lastKnownRoot)
    elseif playerMapID then
        AddonTable.Debug("scanExpansionZones: unknown zone, scanning current map", playerMapID)
        AddonTable.scanMap(playerMapID)
    end
end

-- Async data loading

local function requestQuestData(questID, mapID)
    if pendingDataRequests[questID] then return end
    pendingDataRequests[questID] = mapID or true
    C_QuestLog.RequestLoadQuestByID(questID)
end

local function onQuestDataLoaded(questID, success)
    local storedMapID = pendingDataRequests[questID]
    if storedMapID == nil then return end
    pendingDataRequests[questID] = nil
    if success then
        local mapID = (type(storedMapID) == "number") and storedMapID or nil
        AddonTable.processQuest(questID, mapID)
        scheduleRefresh()
    end
end

-- Quest processing

function AddonTable.processQuest(questID, mapID)
    local title = C_QuestLog.GetTitleForQuestID(questID)
    if not title then
        requestQuestData(questID, mapID)
        return
    end

    local timeLeft = GetQuestTimeLeftSeconds(questID) or 0
    local tagInfo  = C_QuestLog.GetQuestTagInfo(questID)

    local existing = AddonTable.questCache[questID]
    local entry = {
        questID        = questID,
        mapID          = mapID or (existing and existing.mapID),
        title          = title,
        expiresAt      = GetServerTime() + timeLeft,
        tagName        = tagInfo and tagInfo.tagName or "",
        quality        = tagInfo and tagInfo.quality or Enum.WorldQuestQuality.Common,
        isElite        = tagInfo and tagInfo.isElite or false,
        rewardTexture  = existing and existing.rewardTexture,
        stripeR        = existing and existing.stripeR,
        stripeG        = existing and existing.stripeG,
        stripeB        = existing and existing.stripeB,
        rewardSubtitle = existing and existing.rewardSubtitle,
    }
    AddonTable.questCache[questID] = entry

    if not HaveQuestRewardData(questID) then
        C_TaskQuest.RequestPreloadRewardData(questID)
    end

    if not existing then
        AddonTable.Debug(string.format("%d | %s | %dm | zone:%s | %s%s",
            questID, title, math.floor(timeLeft / 60),
            entry.mapID and (C_Map.GetMapInfo(entry.mapID) or {}).name or "?",
            tagInfo and tagInfo.tagName or "?",
            entry.isElite and " [ELITE]" or ""))
    end
end

-- Map scan

function AddonTable.scanExpansion(root)
    local zones = EXPANSION_ZONES[root]
    if not zones then return end
    for _, mapID in ipairs(zones) do
        AddonTable.scanMap(mapID)
    end
    AddonTable.scanMap(root)
end

function AddonTable.scanMap(mapID)
    local tasks = GetQuestsForPlayerByMapID(mapID)

    if not tasks or #tasks == 0 then return end

    local activeIDs = {}
    for _, task in ipairs(tasks) do
        activeIDs[task.questID] = true
    end
    for questID, entry in pairs(AddonTable.questCache) do
        if entry.mapID == mapID and not activeIDs[questID] then
            AddonTable.questCache[questID] = nil
        end
    end

    AddonTable.Debug("scanMap", mapID, "found", #tasks, "tasks")

    for _, task in ipairs(tasks) do
        local questID = task.questID
        if C_QuestLog.IsWorldQuest(questID) then
            AddonTable.processQuest(questID, task.mapID or mapID)
        end
    end

    scheduleRefresh()
end

-- Hooks and events

local lastHookScan = 0
local HOOK_SCAN_THROTTLE = 10  -- seconds

hooksecurefunc(WorldQuestDataProviderMixin, "RefreshAllData", function(self, fromOnShow)
    local mapID = getViewedMapID(self)
    if not mapID then return end
    local now = GetTime()
    if now - lastHookScan < HOOK_SCAN_THROTTLE then return end
    lastHookScan = now
    AddonTable.scanMap(mapID)
end)

local PIN_MASK = "Interface\\CharacterFrame\\TempPortraitAlphaMask"

local pinIconOverlays = {}

hooksecurefunc(WorldQuestPinMixin, "RefreshVisuals", function(pin)
    local overlay = pinIconOverlays[pin]
    if not PintaWorldQuestsDB or not PintaWorldQuestsDB.skinQuestPins
    or IsInInstance() then
        if overlay then overlay:Hide() end
        return
    end
    local qid = pin.questID
    local ok, cleaned = pcall(function() return tonumber(tostring(qid)) end)
    local entry = AddonTable.questCache[ok and cleaned or qid]
    if not entry or not entry.rewardTexture then
        if overlay then overlay:Hide() end
        return
    end
    if not overlay then
        overlay = pin.Display:CreateTexture(nil, "OVERLAY")
        overlay:SetAllPoints(pin.Display.Icon)
        overlay:SetMask(PIN_MASK)
        pinIconOverlays[pin] = overlay
    end

    overlay:SetTexture(entry.rewardTexture)
    overlay:Show()
end)

local eventFrame = CreateFrame("Frame")

eventFrame:RegisterEvent("QUEST_DATA_LOAD_RESULT")
eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
eventFrame:RegisterEvent("QUEST_TURNED_IN")
eventFrame:RegisterEvent("TASK_PROGRESS_UPDATE")
eventFrame:RegisterEvent("WORLD_QUEST_COMPLETED_BY_SPELL")

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "QUEST_DATA_LOAD_RESULT" then
        local questID, success = ...
        onQuestDataLoaded(questID, success)

    elseif event == "ZONE_CHANGED_NEW_AREA" then
        AddonTable.scanExpansionZones()

    elseif event == "QUEST_TURNED_IN" then
        local questID = ...
        if AddonTable.questCache[questID] then
            AddonTable.Debug("WQ turned in:", questID)
            AddonTable.questCache[questID] = nil
            scheduleRefresh()
        end

    elseif event == "TASK_PROGRESS_UPDATE" or event == "WORLD_QUEST_COMPLETED_BY_SPELL" then
        local mapID = C_Map.GetBestMapForUnit("player")
        if mapID then AddonTable.scanMap(mapID) end
    end
end)
