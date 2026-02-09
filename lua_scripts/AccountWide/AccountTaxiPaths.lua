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
local BATCH_SIZE = 500

-- ------------------------------------------------------------------------------------------------
-- END CONFIG
-- ------------------------------------------------------------------------------------------------

if not ENABLE_ACCOUNTWIDE_TAXI_PATHS then return end

local AUtils = AccountWideUtils

local accountTaxiCache = { alliance = {}, horde = {} }

local function factionTableName(team) -- 0 = Alliance, 1 = Horde
    return (team == 0) and "accountwide_taxi_alliance" or "accountwide_taxi_horde"
end

local function getFactionKey(team) -- 0 = Alliance, 1 = Horde
    return (team == 0) and "alliance" or "horde"
end

local function getOrLoadAccountSet(accountId, team)
    local key = getFactionKey(team)
    if accountTaxiCache[key][accountId] then
        return accountTaxiCache[key][accountId]
    end

    local tableName = factionTableName(team)
    local set = {}
    local query = CharDBQuery(("SELECT nodeId FROM `%s` WHERE accountId = %d"):format(tableName, accountId))
    if query then
        repeat
            set[query:GetUInt32(0)] = true
        until not query:NextRow()
    end

    accountTaxiCache[key][accountId] = set
    return set
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
    -- Skip playerbot accounts
    if AUtils.shouldSkipAll and AUtils.shouldSkipAll(player) then return end

    if ANNOUNCE_ON_LOGIN then
        player:SendBroadcastMessage(ANNOUNCEMENT)
    end

    local accountId = player:GetAccountId()
    local team = player:GetTeam()

    local accountSet = getOrLoadAccountSet(accountId, team)

    local toGrant = {}
    for nodeId in pairs(accountSet) do
        if not player:HasKnownTaxiNode(nodeId) then
            toGrant[#toGrant + 1] = nodeId
            if DEBUG_MODE then
                print(string.format("[Taxi]: Player %s (guid=%d) missing nodeId=%d, adding to grant list", player:GetName(), player:GetGUIDLow(), nodeId))
            end
        end
    end

    if #toGrant > 0 then
        if DEBUG_MODE then
            print(string.format("[Taxi]: Granting %d nodes to guid=%d", #toGrant, player:GetGUIDLow()))
        end
        player:SetKnownTaxiNodes(toGrant)
    end
end

local function OnPlayerLogout(event, player)
    -- Skip playerbot accounts
    if AUtils.shouldSkipAll and AUtils.shouldSkipAll(player) then return end

    local accountId = player:GetAccountId()
    local team = player:GetTeam()

    local accountSet = getOrLoadAccountSet(accountId, team)

    local knownNodes = player:GetKnownTaxiNodes() or {}
    if #knownNodes == 0 then return end

    local toInsert = {}
    for i = 1, #knownNodes do
        local nodeId = knownNodes[i]
        if nodeId and nodeId > 0 and not accountSet[nodeId] then
            accountSet[nodeId] = true
            toInsert[#toInsert + 1] = nodeId
        end
    end

    if #toInsert > 0 then
        local tableName = factionTableName(team)

        if DEBUG_MODE then
            print(string.format("[Taxi]: Inserting %d new nodes for accountId=%d (%s)", #toInsert, accountId, tableName))
        end

        batchInsertIgnore(tableName, accountId, toInsert)
    end
end

RegisterPlayerEvent(3, OnPlayerLogin)
RegisterPlayerEvent(4, OnPlayerLogout)