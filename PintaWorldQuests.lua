local addonName, AddonTable = ...

local function onEvent(self, event, ...)
    if event == "ADDON_LOADED" and ... == addonName then
        AddonTable.initSettings()
        AddonTable.initOptionsPanel()
        AddonTable.initUI()
        print("|cff45D388[PWQ]|r v" .. AddonTable.version .. " loaded. Type |cffFFFFFF/pwq|r for commands.")
    elseif event == "PLAYER_ENTERING_WORLD" then
        AddonTable.scanExpansionZones()
        self:RegisterEvent("QUEST_LOG_UPDATE")
    elseif event == "QUEST_LOG_UPDATE" then
        self:UnregisterEvent("QUEST_LOG_UPDATE")
        AddonTable.scanExpansionZones()
    end
end

local frame = CreateFrame("Frame", "PintaWorldQuests")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:SetScript("OnEvent", onEvent)
