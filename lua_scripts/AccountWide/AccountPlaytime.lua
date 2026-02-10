-- -------------------------------------------------------------------------------------------
-- ACCOUNTWIDE PLAYTIME CONFIG
--
-- Hosted by Aldori15 on Github: https://github.com/Aldori15/azerothcore-lua-accountwide
-- -------------------------------------------------------------------------------------------

local ENABLE_ACCOUNTWIDE_PLAYTIME = false

local ANNOUNCE_ON_LOGIN = false
local ANNOUNCEMENT = "This server is running the |cFF00B0E8AccountWide Playtime |rlua script."

local SHOW_SECONDS = true  -- Show seconds in the formatted playtime output

-- -------------------------------------------------------------------------------------------
-- END CONFIG
-- -------------------------------------------------------------------------------------------

if not ENABLE_ACCOUNTWIDE_PLAYTIME then return end

local AUtils = AccountWideUtils

local color = {
    HEADER  = "|cFF00B0E8",  -- Cyan
    LABEL   = "|cffa0a0a0",  -- Gray
    NAME    = "|cff66ccff",  -- Light Blue
    TIME    = "|cffffff00",  -- Gold/Yellow
    PERCENT = "|cff00ff66",  -- Green
    RESET   = "|r",
}

local commands = {
    playtime = true,
    accountplaytime = true,
    awplaytime = true,
    played = true,
    awplayed = true,
}

local function FormatSeconds(totalSeconds)
    totalSeconds = tonumber(totalSeconds) or 0
    if totalSeconds < 0 then totalSeconds = 0 end

    local days = math.floor(totalSeconds / 86400)
    local rem = totalSeconds % 86400
    local hours = math.floor(rem / 3600)
    rem = rem % 3600
    local minutes = math.floor(rem / 60)
    local seconds = rem % 60

    local parts = {}

    if days > 0 then table.insert(parts, string.format("%dd", days)) end
    if hours > 0 or days > 0 then table.insert(parts, string.format("%dh", hours)) end
    if minutes > 0 or hours > 0 or days > 0 then table.insert(parts, string.format("%dm", minutes)) end

    if SHOW_SECONDS then
        -- If we're under 1 minute total, show seconds so it's not "0m"
        if totalSeconds < 60 then
            parts = { string.format("%ds", seconds) }
        else
            table.insert(parts, string.format("%ds", seconds))
        end
    else
        -- If omitting seconds, still show something meaningful under 1 minute
        if totalSeconds < 60 then
            parts = { string.format("%ds", seconds) }
        end
    end

    return table.concat(parts, " ")
end

local function HandleAccountPlaytime(player)
    -- Always skip RNDBots / AltBots
    if AUtils.shouldSkipAll and AUtils.shouldSkipAll(player) then return false end

    local accountId = player:GetAccountId()
    local guidLow = player:GetGUIDLow()

    local query = CharDBQuery(string.format("SELECT guid, name, totaltime FROM characters WHERE account = %d", accountId))
    if not query then return false end

    local accountTotal = 0
    local thisCharTotal = 0
    local breakdown = {}

    repeat
        local guid = query:GetUInt32(0)
        local name = query:GetString(1)
        local seconds = tonumber(query:GetUInt32(2))

        accountTotal = accountTotal + seconds

        if guid == guidLow then
            thisCharTotal = seconds
        end

        table.insert(breakdown, { name = name, seconds = seconds })
    until not query:NextRow()

    -- Sort by most played
    table.sort(breakdown, function(a, b) return a.seconds > b.seconds end)

    -- Output message
    player:SendBroadcastMessage(" ")
    player:SendBroadcastMessage(color.HEADER .. "AccountWide Playtime" .. color.RESET)
    player:SendBroadcastMessage(color.LABEL .. "Character:" .. color.RESET .. " " .. color.TIME .. FormatSeconds(thisCharTotal) .. color.RESET)
    player:SendBroadcastMessage(color.LABEL .. "Account:  " .. color.RESET .. " " .. color.TIME .. FormatSeconds(accountTotal) .. color.RESET)

    player:SendBroadcastMessage(" ")
    player:SendBroadcastMessage(color.LABEL .. "Breakdown:" .. color.RESET)

    for _, row in ipairs(breakdown) do
        local pct = 0
        if accountTotal > 0 then
            pct = (row.seconds / accountTotal) * 100
        end

        local line =
            "   " .. color.NAME .. row.name .. color.RESET .. " " ..
            color.LABEL .. "(" ..
            color.TIME .. FormatSeconds(row.seconds) .. color.RESET ..
            color.LABEL .. ", " ..
            color.PERCENT .. string.format("%.1f%%", pct) .. color.RESET ..
            color.LABEL .. ")" .. color.RESET

        player:SendBroadcastMessage(line)
    end

    return false
end

RegisterPlayerEvent(42, function(_, player, msg)
    msg = (msg or ""):lower()
    if commands[msg] then
        return HandleAccountPlaytime(player)
    end

    return true
end)

local function BroadcastLoginAnnouncement(event, player)
    if ANNOUNCE_ON_LOGIN then
        player:SendBroadcastMessage(ANNOUNCEMENT)
    end
end

RegisterPlayerEvent(3, BroadcastLoginAnnouncement) -- EVENT_ON_LOGIN