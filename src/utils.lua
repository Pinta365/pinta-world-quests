-- Shared utilities for PintaWorldQuests

local addonName, AddonTable = ...

---Print debug message if debug mode is enabled.
---@param ... any Message parts
function AddonTable.Debug(...)
    if PintaWorldQuestsDB and PintaWorldQuestsDB.debug then
        print("|cff888888[PWQ Debug]|r", ...)
    end
end

---Format seconds into a coloured time string.
---@param seconds number
---@return string
function AddonTable.formatTimeLeft(seconds)
    if not seconds or seconds <= 0 then
        return "|cffaaaaaa--|r"
    end
    if seconds < 3600 then
        return string.format("|cffff4444%d:%02d|r",
            math.floor(seconds / 60), math.floor(seconds % 60))
    elseif seconds < 10800 then
        return string.format("|cffffff44%dh %dm|r",
            math.floor(seconds / 3600),
            math.floor((seconds % 3600) / 60))
    elseif seconds < 86400 then
        return string.format("%dh", math.floor(seconds / 3600))
    else
        return string.format("%dd", math.floor(seconds / 86400))
    end
end

---Format a copper amount as "Xg Ys Zc".
---@param copper number
---@return string
function AddonTable.formatMoney(copper)
    local parts  = {}
    local gold   = math.floor(copper / 10000)
    local silver = math.floor((copper % 10000) / 100)
    local cop    = copper % 100
    if gold   > 0 then parts[#parts + 1] = gold   .. "g" end
    if silver > 0 then parts[#parts + 1] = silver .. "s" end
    if cop    > 0 or #parts == 0 then parts[#parts + 1] = cop .. "c" end
    return table.concat(parts, " ")
end
