-- ------------------------------------------------------------------------------------------------
-- ACCOUNTWIDE TAXI PATHS CONFIG 
--
-- Hosted by Aldori15 on Github: https://github.com/Aldori15/azerothcore-lua-accountwide
--
-- Due to the horde/alliance interactions, taxi paths will only be shared with characters
-- of the SAME faction.  Horde taxi paths will only be shared with other horde characters
-- and Alliance taxi paths will only be shared with other alliance characters on the account.
-- ------------------------------------------------------------------------------------------------

local ENABLE_ACCOUNTWIDE_TAXI_PATHS = false

local ANNOUNCE_ON_LOGIN = false
local ANNOUNCEMENT = "This server is running the |cFF00B0E8AccountWide Taxi Paths |rlua script."

local DEBUG_MODE = false  -- Toggle debug messages
local BATCH_SIZE = 500    -- Safety cap for SQL VALUES batching

-- ------------------------------------------------------------------------------------------------
-- END CONFIG
-- ------------------------------------------------------------------------------------------------

if not ENABLE_ACCOUNTWIDE_TAXI_PATHS then return end

local AUtils = AccountWideUtils

local function toSet(list)
    local set = {}
    for i = 1, #list do set[list[i]] = true end
    return set
end

local function factionTableName(team) -- 0 = Alliance, 1 = Horde
    return (team == 0) and "accountwide_taxi_alliance" or "accountwide_taxi_horde"
end

local function batchInsertIgnore(tableName, accountId, nodeIds)
    if #nodeIds == 0 then return end

    local values, count = {}, 0
    for i = 1, #nodeIds do
        values[#values + 1] = string.format("(%d,%d)", accountId, nodeIds[i])
        count = count + 1

        if count == BATCH_SIZE then
            CharDBExecute(("INSERT IGNORE INTO `%s` (accountId, nodeId) VALUES %s"):format(tableName, table.concat(values, ",")))
            values, count = {}, 0
        end
    end

    if count > 0 then
        CharDBExecute(("INSERT IGNORE INTO `%s` (accountId, nodeId) VALUES %s"):format(tableName, table.concat(values, ",")))
    end
end

local function OnPlayerLogin(event, player)
    local accountId = player:GetAccountId()
    -- Skip playerbot accounts
    if AUtils.isPlayerBotAccount(accountId) then return end

    if ANNOUNCE_ON_LOGIN then
        player:SendBroadcastMessage(ANNOUNCEMENT)
    end

    local tableName = factionTableName(player:GetTeam())
    local nodes = CharDBQuery(("SELECT nodeId FROM `%s` WHERE accountId = %d"):format(tableName, accountId))
    if not nodes then return end

    local knownNodes = player:GetKnownTaxiNodes() or {}
    local playerSet = toSet(knownNodes)

    -- Collect missing nodes to grant this character
    local toGrant = {}
    repeat
        local nodeId = nodes:GetUInt32(0)
        if not playerSet[nodeId] then
            toGrant[#toGrant + 1] = nodeId
        end
    until not nodes:NextRow()

    if #toGrant > 0 then
        if DEBUG_MODE then
            print(string.format("[Taxi]: Granting %d nodes to guid=%d", #toGrant, player:GetGUIDLow()))
        end
        player:SetKnownTaxiNodes(toGrant)
    end
end

local function OnPlayerLogout(event, player)
    local accountId = player:GetAccountId()
    -- Skip playerbot accounts
    if AUtils.isPlayerBotAccount(accountId) then return end

    local tableName = factionTableName(player:GetTeam())
    local knownNodes = player:GetKnownTaxiNodes() or {}

    if #knownNodes > 0 then
        if DEBUG_MODE then
            print(string.format("[Taxi]: Syncing %d nodes for accountId=%d (%s)", #knownNodes, accountId, tableName))
        end
        batchInsertIgnore(tableName, accountId, knownNodes)
    end
end

RegisterPlayerEvent(3, OnPlayerLogin)
RegisterPlayerEvent(4, OnPlayerLogout)