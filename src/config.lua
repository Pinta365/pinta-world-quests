-- Configuration and constants for PintaWorldQuests

local addonName, AddonTable = ...

AddonTable.name = addonName
AddonTable.title = C_AddOns.GetAddOnMetadata(addonName, "Title")
AddonTable.version = C_AddOns.GetAddOnMetadata(addonName, "Version")

-- Default settings
AddonTable.defaultSettings = {
    debug = false,
    listScale = 1.0,            -- List frame scale (0.5–1.5)
    backgroundOpacity = 0.8,    -- List background opacity (0.0–1.0)
    mapPanelSide = "left",      -- In-map panel anchor: "left" or "right"
    compactMode = false,         -- Map overlay: compact (no subtitle) or verbose (slot/category)
    sortMode = "zone",          -- List sort: "zone" (grouped) or "time" (flat by expiry)
    listVisible = false,        -- List frame open/closed
    minimized = false,          -- List frame minimized state
    extendedTooltips = false,   -- Show full objectives + item stats on hover
}

---Print debug message if debug mode is enabled.
---@param ... any Message parts
function AddonTable.Debug(...)
    if PintaWorldQuestsDB and PintaWorldQuestsDB.debug then
        print("|cff888888[PWQ Debug]|r", ...)
    end
end

-- Initialize saved variables
function AddonTable.initSettings()
    PintaWorldQuestsDB = PintaWorldQuestsDB or {}

    for key, value in pairs(AddonTable.defaultSettings) do
        if PintaWorldQuestsDB[key] == nil then
            PintaWorldQuestsDB[key] = value
        end
    end
end
