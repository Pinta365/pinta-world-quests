-- Slash commands for PintaWorldQuests

local addonName, AddonTable = ...

StaticPopupDialogs["PINTAWQ_RESET_CONFIRM"] = {
    text = "Reset all Pinta World Quests settings to defaults and reload the UI?",
    button1 = "Reset",
    button2 = "Cancel",
    OnAccept = function()
        if AddonTable.mainFrame then
            AddonTable.mainFrame:SetUserPlaced(false)
        end
        wipe(PintaWorldQuestsDB)
        ReloadUI()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
}

function AddonTable.initCommands()
    local function printHelp()
        local c = "|cff45D388[PWQ]|r"
        print(c, "Commands:")
        print(c, "|cffFFFFFF/pwq toggle|r \226\128\148 show or hide the quest list")
        print(c, "|cffFFFFFF/pwq clearalerts|r \226\128\148 clear alert history (re-fires all pending alerts)")
        print(c, "|cffFFFFFF/pwq reset|r \226\128\148 reset all settings to defaults")
    end

SlashCmdList["PINTAWQ"] = function(msg)
        local cmd = msg:match("^%s*(%S*)%s*$") or ""
        if cmd == "toggle" then
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
        elseif cmd == "clearalerts" then
            wipe(PintaWorldQuestsDB.alerted)
            print("|cff45D388[PWQ]|r Alert history cleared.")
        elseif cmd == "reset" then
            StaticPopup_Show("PINTAWQ_RESET_CONFIRM")
        else
            printHelp()
        end
    end
    SLASH_PINTAWQ1 = "/pwq"
end
