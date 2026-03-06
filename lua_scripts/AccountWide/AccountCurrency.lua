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
local seededAccountCache = {}

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

local function FetchAccountCurrency(accountId)
    local map = {}
    local query = CharDBQuery(string.format("SELECT currencyId, count FROM accountwide_currency WHERE accountId = %d", accountId))
    if query then
        repeat
            map[query:GetUInt32(0)] = query:GetUInt32(1)
        until not query:NextRow()
    end
    return map
end

-- Record a baseline snapshot of what the player has
local lastSynced = {}
local function RecordLastSynced(player)
    local guid = player:GetGUIDLow()
    local map = {}
    for _, currencyId in ipairs(currencyItemIDs) do
        map[currencyId] = player:GetItemCount(currencyId, true) or 0
    end
    lastSynced[guid] = map
end

local function makeInList(ids)
    if #ids == 0 then return "NULL" end
    return table.concat(ids, ",")
end

local function RetroactivelySeedAccountCurrencyIfMissing(accountId)
    if seededAccountCache[accountId] then return end

    -- If the account has any rows, then it has already been seeded
    local exists = CharDBQuery(string.format("SELECT 1 FROM accountwide_currency WHERE accountId = %d LIMIT 1", accountId))
    if exists then
        seededAccountCache[accountId] = true
        return
    end

    -- Retroactive seeding for all characters that already have currency prior to applying this script
    local inList = makeInList(currencyItemIDs)
    CharDBExecute(string.format([[
        INSERT INTO accountwide_currency (accountId, currencyId, count)
        SELECT %d, ii.itemEntry, COALESCE(SUM(ii.count), 0) AS total
        FROM item_instance ii
        JOIN characters c ON c.guid = ii.owner_guid
        WHERE c.account = %d
        AND ii.itemEntry IN (%s)
        GROUP BY ii.itemEntry
    ]], accountId, accountId, inList))

    seededAccountCache[accountId] = true
end

local function AddDeltasToAccountCurrencyBatch(accountId, deltas)
    if #deltas == 0 then return end

    local values = {}
    local cases = {}

    for i = 1, #deltas do
        local row = deltas[i]
        values[#values + 1] = string.format("(%d, %d, GREATEST(0, %d))", accountId, row.currencyId, row.delta)
        cases[#cases + 1] = string.format("WHEN %d THEN %d", row.currencyId, row.delta)
    end

    local sql = string.format([[
        INSERT INTO accountwide_currency (accountId, currencyId, count)
        VALUES %s
        ON DUPLICATE KEY UPDATE count = GREATEST(0, count + CASE currencyId %s ELSE 0 END)
    ]], table.concat(values, ", "), table.concat(cases, " "))

    CharDBExecute(sql)
end

local function SyncCurrencyOnLogin(player, accountId)
    if #currencyItemIDs == 0 then return end

    local bank = FetchAccountCurrency(accountId)

    for _, currencyId in ipairs(currencyItemIDs) do
        local accountCurrencyCount = bank[currencyId] or 0
        local playerCurrencyCount = player:GetItemCount(currencyId, true)

        if playerCurrencyCount < accountCurrencyCount then
            player:AddItem(currencyId, accountCurrencyCount - playerCurrencyCount)
        elseif playerCurrencyCount > accountCurrencyCount then
            player:RemoveItem(currencyId, playerCurrencyCount - accountCurrencyCount)
        end
    end
end

local function AccountWideCurrency(event, player)
    -- Skip playerbot accounts
    if AUtils.shouldSkipAll and AUtils.shouldSkipAll(player) then return end

    local accountId = player:GetAccountId()

    if event == 3 then
        if ANNOUNCE_ON_LOGIN then
            player:SendBroadcastMessage(ANNOUNCEMENT)
        end

        RetroactivelySeedAccountCurrencyIfMissing(accountId)

        player:RegisterEvent(function(_, _, _, player)
            SyncCurrencyOnLogin(player, accountId)
            RecordLastSynced(player)
        end, 1000, 1) -- Delay of 1sec to ensure that seeding finishes before syncing
    elseif event == 25 then
        if #currencyItemIDs == 0 then return end

        local guid = player:GetGUIDLow()
        if not lastSynced[guid] then
            lastSynced[guid] = {}
        end

        local deltas = {}
        for _, currencyId in ipairs(currencyItemIDs) do
            local current = player:GetItemCount(currencyId, true) or 0

            local baseline = lastSynced[guid][currencyId]
            if baseline == nil then
                lastSynced[guid][currencyId] = current
            else
                local delta = current - baseline
                if delta ~= 0 then
                    deltas[#deltas + 1] = { currencyId = currencyId, delta = delta }
                    lastSynced[guid][currencyId] = current
                end
            end
        end

        AddDeltasToAccountCurrencyBatch(accountId, deltas)
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