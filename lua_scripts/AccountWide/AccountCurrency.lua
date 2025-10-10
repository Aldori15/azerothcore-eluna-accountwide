-- ----------------------------------------------------------------------------------------------
-- ACCOUNTWIDE CURRENCY CONFIG 
--
-- Hosted by Aldori15 on Github: https://github.com/Aldori15/azerothcore-lua-accountwide
-- ----------------------------------------------------------------------------------------------

local ENABLE_ACCOUNTWIDE_CURRENCY = false

local ANNOUNCE_ON_LOGIN = false
local ANNOUNCEMENT = "This server is running the |cFF00B0E8AccountWide Currency |rlua script."

-- -------------------------------------------------------------------------------------------
-- END CONFIG
-- -------------------------------------------------------------------------------------------

if not ENABLE_ACCOUNTWIDE_CURRENCY then return end

local AUtils = AccountWideUtils

local function FetchCurrencyItemIDs()
    local itemIDs = {}
    local query = WorldDBQuery("SELECT entry FROM item_template WHERE BagFamily = 8192")

    if query then
        repeat
            local itemID = query:GetUInt32(0)
            table.insert(itemIDs, itemID)
        until not query:NextRow()
    end

    return itemIDs
end

-- Dynamically populate currency items and store them in memory
local currencyItemIDs = FetchCurrencyItemIDs()

local function FetchAccountCurrency(accountId, currencyId)
    local query = CharDBQuery(string.format("SELECT count FROM accountwide_currency WHERE accountId = %d AND currencyId = %d", accountId, currencyId))
    return query and query:GetUInt32(0) or 0
end

local function UpdateAccountCurrency(accountId, currencyId, newCount)
    CharDBExecute(string.format("INSERT INTO accountwide_currency (accountId, currencyId, count) VALUES (%d, %d, %d) ON DUPLICATE KEY UPDATE count = %d", accountId, currencyId, newCount, newCount))
end

-- Record a baseline snapshot of what the player has right after login sync
local lastSynced = {}  -- lastSynced[guidLow] = { [currencyId] = count }
local function RecordLastSynced(player)
    local guid = player:GetGUIDLow()
    local map = {}
    for _, currencyId in ipairs(currencyItemIDs) do
        map[currencyId] = player:GetItemCount(currencyId, true) or 0
    end
    lastSynced[guid] = map
end

-- Apply a delta (positive or negative) to the account row
local function AddDeltaToAccountCurrency(accountId, currencyId, delta)
    if delta == 0 then return end
    local sql = string.format([[
        INSERT INTO accountwide_currency (accountId, currencyId, count)
        VALUES (%d, %d, %d)
        ON DUPLICATE KEY UPDATE count = GREATEST(0, count + VALUES(count))
    ]], accountId, currencyId, delta)
    CharDBExecute(sql)
end

local function makeInList(ids)
    if #ids == 0 then return "NULL" end
    return table.concat(ids, ",")
end

local function RetroactivelySeedAccountCurrencyIfMissing(accountId)
    -- If the account has any rows, then it has already been seeded
    local exists = CharDBQuery(string.format("SELECT 1 FROM accountwide_currency WHERE accountId = %d LIMIT 1", accountId))
    if exists then return end

    -- Retroactive seeding for all characters that already have currency prior to applying this script
    local inList = makeInList(currencyItemIDs)
    local sumQuery = CharDBQuery(string.format([[
        SELECT ii.itemEntry, COALESCE(SUM(ii.count), 0) AS total
        FROM item_instance ii
        JOIN characters c ON c.guid = ii.owner_guid
        WHERE c.account = %d
        AND ii.itemEntry IN (%s)
        GROUP BY ii.itemEntry
    ]], accountId, inList))

    if sumQuery then
        repeat
            local currencyId = sumQuery:GetUInt32(0)
            local total = sumQuery:GetUInt32(1)
            if total > 0 then
                UpdateAccountCurrency(accountId, currencyId, total)
            end
        until not sumQuery:NextRow()
    end
end

local function SyncCurrencyOnLogin(player, accountId)
    if #currencyItemIDs == 0 then return end

    for _, currencyId in ipairs(currencyItemIDs) do
        local accountCurrencyCount = FetchAccountCurrency(accountId, currencyId)
        local playerCurrencyCount = player:GetItemCount(currencyId, true)

        if playerCurrencyCount < accountCurrencyCount then
            player:AddItem(currencyId, accountCurrencyCount - playerCurrencyCount)
        elseif playerCurrencyCount > accountCurrencyCount then
            player:RemoveItem(currencyId, playerCurrencyCount - accountCurrencyCount)
        end
    end
end

local function AccountWideCurrency(event, player)
    local accountId = player:GetAccountId()

    -- Skip playerbot accounts
    if AUtils.isPlayerBotAccount(accountId) then return end

    if event == 3 then
        if ANNOUNCE_ON_LOGIN then
            player:SendBroadcastMessage(ANNOUNCEMENT)
        end

        RetroactivelySeedAccountCurrencyIfMissing(accountId)

        player:RegisterEvent(function(_, _, _, player)
            SyncCurrencyOnLogin(player, accountId)
            RecordLastSynced(player)
        end, 1000, 1) -- Delay of 1sec to ensure that the Initialize function finishes seeding
    elseif event == 25 then
        if #currencyItemIDs == 0 then return end

        local guid = player:GetGUIDLow()
        if not lastSynced[guid] then
            lastSynced[guid] = {}
        end

        for _, currencyId in ipairs(currencyItemIDs) do
            local current = player:GetItemCount(currencyId, true) or 0

            local baseline = lastSynced[guid][currencyId]
            if baseline == nil then
                baseline = FetchAccountCurrency(accountId, currencyId) or 0
            end

            local delta = current - baseline
            if delta ~= 0 then
                AddDeltaToAccountCurrency(accountId, currencyId, delta)
                lastSynced[guid][currencyId] = current  -- update baseline
            end
        end        
    end
end

local function CleanUpSyncOnLogout(event, player)
    local guid = player:GetGUIDLow()
    player:RegisterEvent(function(_, _, _, p)
        lastSynced[guid] = nil
    end, 1500, 1)
end

RegisterPlayerEvent(3, AccountWideCurrency) -- PLAYER_EVENT_ON_LOGIN
RegisterPlayerEvent(4, CleanUpSyncOnLogout) -- PLAYER_EVENT_ON_LOGOUT
RegisterPlayerEvent(25, AccountWideCurrency) -- EVENT_ON_SAVE