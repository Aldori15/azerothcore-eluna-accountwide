-- ----------------------------------------------------------------------------------------------
-- ACCOUNTWIDE CURRENCY CONFIG 
--
-- Hosted by Aldori15 on Github: https://github.com/Aldori15/azerothcore-lua-accountwide
-- ----------------------------------------------------------------------------------------------

local ENABLE_ACCOUNTWIDE_CURRENCY = false

local ANNOUNCE_ON_LOGIN = true
local ANNOUNCEMENT = "This server is running the |cFF00B0E8AccountWide Currency |rlua script."

-- -- -------------------------------------------------------------------------------------------
-- END CONFIG
-- -- -------------------------------------------------------------------------------------------

if not ENABLE_ACCOUNTWIDE_CURRENCY then return end

-- Note: these ItemIDs are currently configured in CurrencyTypes.dbc for Dinkledork's Ashen Order repack, so your mileage may vary with custom currencies, etc.  Just add/remove any as necessary.
local currencyItemIDs = {
    12840,   -- Minion's Scourgestone
    12841,   -- Invader's Scourgestone
    12843,   -- Corruptor's Scourgestone
    19182,   -- Darkmoon Faire Prize Ticket
    20558,   -- Warsong Gulch Mark of Honor
    20559,   -- Arathi Basin Mark of Honor
    20560,   -- Alterac Valley Mark of Honor
    21229,   -- Qiraji Lord's Insignia
    22637,   -- Primal Hakkari Idol
    29024,   -- Eye of the Storm Mark of Honor
    29434,   -- Badge of Justice
    37711,   -- Reward Points
    37836,   -- Venture Coin
    40752,   -- Emblem of Heroism
    40753,   -- Emblem of Valor
    41596,   -- Dalaran Jewelcrafter's Token
    42425,   -- Strand of the Ancients Mark of Honor
    43016,   -- Dalaran Cooking Award
    43228,   -- Stone Keeper's Shard
    43307,   -- Arena Points
    43308,   -- Honor Points
    43589,   -- Wintergrasp Mark of Honor
    43949,   -- Lich Rune
    44990,   -- Champion's Seal
    45624,   -- Emblem of Conquest
    47241,   -- Emblem of Triumph
    49426,   -- Emblem of Frost
    829434,  -- Badge of Glory
    829435,  -- Badge of Courage
    1000010, -- Quest Reward Tokens
}

local function FetchAccountCurrency(accountId, currencyId)
    local query = CharDBQuery(string.format("SELECT count FROM accountwide_currency WHERE accountId = %d AND currencyId = %d", accountId, currencyId))
    return query and query:GetUInt32(0) or 0
end

local function UpdateAccountCurrency(accountId, currencyId, newCount)
    CharDBExecute(string.format("INSERT INTO accountwide_currency (accountId, currencyId, count) VALUES (%d, %d, %d) ON DUPLICATE KEY UPDATE count = %d", accountId, currencyId, newCount, newCount))
end

-- Purpose of this function is to populate the accountwide_currency table if it is empty, usually when the table is first created and the first character login.
-- Once the table has been populated, this function should always return out early since checkQuery will have records and the function will not proceed.
-- If the table is empty, then it will check item_instance for a sum of currencies on the account and use those to populate the table.
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

    if event == 3 then
        if ANNOUNCE_ON_LOGIN then
            player:SendBroadcastMessage(ANNOUNCEMENT)
        end
        InitializeAccountCurrencyOnEmptyTable(accountId)

        player:RegisterEvent(function(_, _, _, player)
            SyncCurrencyOnLogin(player, accountId)
        end, 1000, 1) -- Delay of 1000 milliseconds (1 second) to ensure that the InitializeAccountCurrencyOnEmptyTable() function finishes populating the empty table
    elseif event == 4 or event == 25 then
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
RegisterPlayerEvent(4, AccountWideCurrency) -- PLAYER_EVENT_ON_LOGOUT
RegisterPlayerEvent(25, AccountWideCurrency) -- EVENT_ON_SAVE