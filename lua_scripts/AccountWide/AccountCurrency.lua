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

local AUtils = AccountWideUtils

if not ENABLE_ACCOUNTWIDE_CURRENCY then return end

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

local function InitializeAccountCurrencyOnEmptyTable(accountId)
    local checkQuery = CharDBQuery("SELECT 1 FROM accountwide_currency LIMIT 1")

    if not checkQuery then
        for _, currencyId in ipairs(currencyItemIDs) do
            local itemQuery = CharDBQuery(string.format("SELECT SUM(count) FROM item_instance WHERE itemEntry = %d AND owner_guid IN (SELECT guid FROM characters WHERE account = %d)", currencyId, accountId))
            if itemQuery then
                local count = itemQuery:GetUInt32(0)
                UpdateAccountCurrency(accountId, currencyId, count)
            end
        end
    end
end

local function SyncCurrencyOnLogin(player, accountId)
    for _, currencyId in ipairs(currencyItemIDs) do
        local accountCurrencyCount = FetchAccountCurrency(accountId, currencyId)
        local playerCurrencyCount = player:GetItemCount(currencyId)

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
        InitializeAccountCurrencyOnEmptyTable(accountId)

        player:RegisterEvent(function(_, _, _, player)
            SyncCurrencyOnLogin(player, accountId)
        end, 1000, 1) -- Delay of 1sec to ensure that the InitializeAccountCurrencyOnEmptyTable() function finishes populating the empty table
    elseif event == 25 then
        for _, currencyId in ipairs(currencyItemIDs) do
            local playerCurrencyCount = player:GetItemCount(currencyId)
            local accountCurrencyCount = FetchAccountCurrency(accountId, currencyId)

            if playerCurrencyCount ~= accountCurrencyCount then
                UpdateAccountCurrency(accountId, currencyId, playerCurrencyCount)
            end
        end
    end
end

RegisterPlayerEvent(3, AccountWideCurrency) -- PLAYER_EVENT_ON_LOGIN
RegisterPlayerEvent(25, AccountWideCurrency) -- EVENT_ON_SAVE