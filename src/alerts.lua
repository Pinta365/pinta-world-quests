-- Expiry alert system for PintaWorldQuests

local addonName, AddonTable = ...

local ALERT_SOUNDS = {
    { label = "Raid Warning",  soundKit = 8959  },
    { label = "Tell",          soundKit = 3081  },
    { label = "Ready Check",   soundKit = 8960  },
    { label = "PvP Queue",     soundKit = 8459  },
    { label = "Warning 1",     soundKit = 12867 },
    { label = "Warning 2",     soundKit = 12889 },
    { label = "Bnet Toast",    soundKit = 18019 },
    { label = "LFG Check",     soundKit = 17317 },
}
AddonTable.ALERT_SOUNDS = ALERT_SOUNDS

local function sweepAlerted()
    local now = GetServerTime()
    for questID, expiresAt in pairs(PintaWorldQuestsDB.alerted) do
        if expiresAt < now then
            PintaWorldQuestsDB.alerted[questID] = nil
        end
    end
end

local function fireAlert(entry)
    local link    = GetQuestLink(entry.questID) or entry.title
    local secs    = entry.expiresAt - GetServerTime()
    local mins    = math.floor(secs / 60)
    local ss      = secs % 60
    local timeStr = string.format("%d:%02d", mins, ss)
    print(string.format("|cff45D388[PWQ]|r |cffFF6B35!!|r %s expires in %s  %s",
        entry.title, timeStr, link))

    local soundLabel = PintaWorldQuestsDB.alertSound
    if soundLabel then
        local channel = PintaWorldQuestsDB.alertChannel or "Master"
        for _, s in ipairs(ALERT_SOUNDS) do
            if s.label == soundLabel and s.soundKit then
                PlaySound(s.soundKit, channel)
                break
            end
        end
    end

    PintaWorldQuestsDB.alerted[entry.questID] = entry.expiresAt
end

local function getFilterZones()
    local root = PintaWorldQuestsDB.expansionFilter or AddonTable.lastKnownRoot
    if not root then return nil, nil end
    return root, AddonTable.EXPANSION_ZONES[root]
end

local function inExpansion(entry, root, zones)
    if entry.mapID == root then return true end
    for _, zoneMapID in ipairs(zones) do
        if entry.mapID == zoneMapID then return true end
    end
    return false
end

local function sweepQuestCache()
    local now = GetServerTime()
    for questID, entry in pairs(AddonTable.questCache) do
        if entry.expiresAt < now then
            AddonTable.questCache[questID] = nil
        end
    end
end

local function checkAlerts()
    if not PintaWorldQuestsDB.alertEnabled then return end
    local threshold = PintaWorldQuestsDB.alertThreshold or 1800
    local scope     = PintaWorldQuestsDB.alertScope or "all"
    local now       = GetServerTime()

    local filterRoot, filterZones
    if scope == "filter" then
        filterRoot, filterZones = getFilterZones()
    end

    for questID, entry in pairs(AddonTable.questCache) do
        local include = true
        if filterZones and not inExpansion(entry, filterRoot, filterZones) then
            include = false
        end
        if include then
            local timeLeft = entry.expiresAt - now
            if timeLeft > 0 and timeLeft <= threshold then
                if PintaWorldQuestsDB.alerted[questID] ~= entry.expiresAt then
                    if not C_QuestLog.IsQuestFlaggedCompleted(questID) then
                        fireAlert(entry)
                    end
                end
            end
        end
    end
end

function AddonTable.initAlerts()
    sweepAlerted()
    C_Timer.NewTicker(10, function()
        sweepQuestCache()
        checkAlerts()
    end)
end
