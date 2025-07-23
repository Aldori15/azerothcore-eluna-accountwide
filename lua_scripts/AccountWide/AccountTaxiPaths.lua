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

-- ------------------------------------------------------------------------------------------------
-- END CONFIG
-- ------------------------------------------------------------------------------------------------

if not ENABLE_ACCOUNTWIDE_TAXI_PATHS then return end

local function tableContains(set, value)
    return set[value] ~= nil
end

local function OnPlayerLogin(event, player)
    local accountId = player:GetAccountId()
    local team = player:GetTeam()  -- 0 = Alliance, 1 = Horde
    local tableName = (team == 0) and "accountwide_taxi_alliance" or "accountwide_taxi_horde"

    local query = string.format("SELECT nodeId FROM `%s` WHERE accountId = %d", tableName, accountId)
    local result = CharDBQuery(query)

    if result then
        local knownNodes = player:GetKnownTaxiNodes()
        local knownSet = {}
        for _, nodeId in ipairs(knownNodes) do
            knownSet[nodeId] = true
            if DEBUG_MODE then
                print("[DEBUG] Known Taxi Node:", nodeId)
            end
        end

        local newNodes = {}

        repeat
            local nodeId = result:GetUInt32(0)
            if not tableContains(knownSet, nodeId) then
                table.insert(newNodes, nodeId)
            end
        until not result:NextRow()

        if #newNodes > 0 then
            player:SetKnownTaxiNodes(newNodes)
        end

        if ANNOUNCE_ON_LOGIN then
            player:SendBroadcastMessage(ANNOUNCEMENT)
        end
    end
end

local function OnPlayerLogout(event, player)
    local accountId = player:GetAccountId()
    local team = player:GetTeam()
    local tableName = (team == 0) and "accountwide_taxi_alliance" or "accountwide_taxi_horde"
    local knownNodes = player:GetKnownTaxiNodes()

    for _, nodeId in ipairs(knownNodes) do
        local insertQuery = string.format("INSERT IGNORE INTO `%s` (accountId, nodeId) VALUES (%d, %d)", tableName, accountId, nodeId)
        CharDBExecute(insertQuery)
    end
end

RegisterPlayerEvent(3, OnPlayerLogin)
RegisterPlayerEvent(4, OnPlayerLogout)