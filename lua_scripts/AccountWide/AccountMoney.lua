-- -------------------------------------------------------------------------------------------
-- ACCOUNTWIDE MONEY CONFIG 
--
-- Hosted by Aldori15 on Github: https://github.com/Aldori15/azerothcore-lua-accountwide
-- -------------------------------------------------------------------------------------------

local ENABLE_ACCOUNTWIDE_MONEY = false

local ANNOUNCE_ON_LOGIN = false
local ANNOUNCEMENT = "This server is running the |cFF00B0E8AccountWide Money |rlua script."

-- -------------------------------------------------------------------------------------------
-- END CONFIG
-- -------------------------------------------------------------------------------------------

local AUtils = AccountWideUtils

if not ENABLE_ACCOUNTWIDE_MONEY then return end

local function GetTotalAccountMoney(accountId)
    local query = CharDBQuery(string.format("SELECT money FROM accountwide_money WHERE accountId = %d", accountId))
    return query and query:GetUInt32(0) or 0
end

-- This function is only called once when the table is empty or has never been populated since creating the table
local function InitializeAccountMoneyOnEmptyTable(accountId)
    local query = CharDBQuery(string.format("SELECT SUM(money) FROM characters WHERE account = %d", accountId))
    local totalAccountMoney = query and query:GetUInt32(0) or 0

    CharDBExecute(string.format("REPLACE INTO accountwide_money (accountId, money) VALUES (%d, %d)", accountId, totalAccountMoney))
end

local function UpdateAccountMoney(accountId, money)
    CharDBExecute(string.format("REPLACE INTO accountwide_money (accountId, money) VALUES (%d, %d)", accountId, money))
end

local function SyncCharacterMoneyOnLogin(player, accountId)
    local totalAccountMoney = GetTotalAccountMoney(accountId)
    local currentMoney = player:GetCoinage()

    -- Calculate the difference and adjust the player's money accordingly
    if totalAccountMoney > currentMoney then
        player:ModifyMoney(totalAccountMoney - currentMoney)
    elseif totalAccountMoney < currentMoney then
        player:ModifyMoney(-(currentMoney - totalAccountMoney))
    end
end

local function AccountMoney(event, player)
    local accountId = player:GetAccountId()

    -- Skip playerbot accounts
    if AUtils.isPlayerBotAccount(accountId) then return end

    if player:HasItem(800086) then  -- Unfair Taxes Key (Taxation Without Representation Mode)
        return
    end

    if event == 3 then
        -- Initialize accountwide_money if the table is empty
        if GetTotalAccountMoney(accountId) == 0 then
            InitializeAccountMoneyOnEmptyTable(accountId)
        end
        -- Delay the sync to allow accountwide_money to update first before syncing down to the character to ensure there are no discrepancies
        player:RegisterEvent(function(_, _, _, player)
            SyncCharacterMoneyOnLogin(player, accountId)
        end, 1000, 1) -- Delay of 1000 milliseconds (1 second)
        
        if ANNOUNCE_ON_LOGIN then
            player:SendBroadcastMessage(ANNOUNCEMENT)
        end
    elseif event == 25 then
        local currentMoney = player:GetCoinage()
        UpdateAccountMoney(accountId, currentMoney)
    end
end

RegisterPlayerEvent(3, AccountMoney) -- PLAYER_EVENT_ON_LOGIN
RegisterPlayerEvent(25, AccountMoney) -- EVENT_ON_SAVE