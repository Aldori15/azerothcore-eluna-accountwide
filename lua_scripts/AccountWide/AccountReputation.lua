-- ------------------------------------------------------------------------------------------------
-- ACCOUNTWIDE REPUTATION CONFIG 
--
-- Hosted by Aldori15 on Github: https://github.com/Aldori15/azerothcore-lua-accountwide
-- ------------------------------------------------------------------------------------------------

local ENABLE_ACCOUNTWIDE_REPUTATION = false

local ANNOUNCE_ON_LOGIN = true
local ANNOUNCEMENT = "This server is running the |cFF00B0E8AccountWide Reputation |rlua script."

-- -- ------------------------------------------------------------------------------------------------
-- -- END CONFIG
-- -- ------------------------------------------------------------------------------------------------

if not ENABLE_ACCOUNTWIDE_REPUTATION then
    return
end

local function SetReputation(event, player)
    local accountId = player:GetAccountId()
    local characterGuidsQuery = CharDBQuery("SELECT guid FROM characters WHERE account = " .. accountId)

    if not characterGuidsQuery then
        return -- No characters found for this account
    end

    repeat
        local characterGuid = characterGuidsQuery:GetUInt32(0)

        local factionIDsQuery
        if event == 1 then
            factionIDsQuery = CharDBQuery("SELECT DISTINCT faction FROM character_reputation WHERE guid IN (SELECT guid FROM characters WHERE account = " .. accountId .. ")")
        elseif event == 4 or event == 25 then
            factionIDsQuery = CharDBQuery("SELECT DISTINCT faction FROM character_reputation WHERE guid = " .. characterGuid)
        end

        if not factionIDsQuery then
            return -- No faction IDs found for this account
        end

        local factionIDs = {}
        repeat
            local factionId = factionIDsQuery:GetUInt32(0)
            table.insert(factionIDs, factionId)
        until not factionIDsQuery:NextRow()

        local highestReputation = {}
        for _, factionId in ipairs(factionIDs) do
            local query = CharDBQuery("SELECT MAX(standing) FROM character_reputation WHERE faction = " .. factionId .. " AND guid IN (SELECT guid FROM characters WHERE account = " .. accountId .. ")")
            local reputation = query and query:GetUInt32(0) or 0
            highestReputation[factionId] = reputation
        end

        if event == 1 then
            for factionId, reputation in pairs(highestReputation) do
                CharDBQuery("INSERT INTO character_reputation (guid, faction, standing) VALUES (" .. characterGuid .. ", " .. factionId .. ", " .. reputation .. ") ON DUPLICATE KEY UPDATE standing = " .. reputation)
            end
        elseif event == 4 or event == 25 then
            for factionId, reputation in pairs(highestReputation) do
                CharDBQuery("UPDATE character_reputation SET standing = " .. reputation .. " WHERE guid = " .. characterGuid .. " AND faction = " .. factionId)
            end
        end
    until not characterGuidsQuery:NextRow()
end

local function BroadcastLoginAnnouncement(event, player)
    if ANNOUNCE_ON_LOGIN then
        player:SendBroadcastMessage(ANNOUNCEMENT)
    end
end

RegisterPlayerEvent(1, SetReputation) -- EVENT_ON_CHARACTER_CREATE
RegisterPlayerEvent(3, BroadcastLoginAnnouncement) -- EVENT_ON_LOGIN
RegisterPlayerEvent(4, SetReputation) -- EVENT_ON_LOGOUT
RegisterPlayerEvent(25, SetReputation) -- EVENT_ON_SAVE