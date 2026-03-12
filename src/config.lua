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
    skinQuestPins = true,       -- Replace quest pin icons on the map with reward icons
    alertEnabled   = false,     -- Master on/off for expiry alerts
    alertThreshold = 1800,      -- Seconds before expiry to fire alert (1800 = 30 min)
    alertSound     = "Raid Warning", -- Sound label to play on alert; nil = no sound
    alertChannel   = "Master",  -- Audio channel for alert sound
    alertScope     = "filter",  -- "all" = every cached WQ; "filter" = current expansion only
    alerted        = {},        -- { [questID] = expiresAt } — persists across reloads
    rewardFilter        = {},   -- { [categoryKey] = true } — true = hidden
    mapOverlayMovable   = false, -- Whether the map overlay can be dragged to a custom position
    mapOverlayPositions = {},   -- { [mapID] = {x, y} } saved TOPLEFT offsets per map
}

-- Initialize saved variables
function AddonTable.initSettings()
    PintaWorldQuestsDB = PintaWorldQuestsDB or {}

    for key, value in pairs(AddonTable.defaultSettings) do
        if PintaWorldQuestsDB[key] == nil then
            PintaWorldQuestsDB[key] = value
        end
    end
end
