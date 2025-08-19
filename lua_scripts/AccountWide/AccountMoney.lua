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

local lastSyncedMoney = {}

local function GetTotalAccountMoney(accountId)
    local query = CharDBQuery(string.format("SELECT money FROM accountwide_money WHERE accountId = %d", accountId))
    return query and query:GetUInt32(0) or 0
end

local function AddDeltaToAccountMoney(accountId, delta)
    if delta == 0 then return end

    CharDBExecute(
        "INSERT INTO accountwide_money (accountId, money) VALUES (" ..
            accountId .. ", GREATEST(0, " .. tostring(delta) .. ")) " ..
        "ON DUPLICATE KEY UPDATE money = GREATEST(0, money + (" .. tostring(delta) .. "))"
    )
end

local function AccountMoneyRowExists(accountId)
    return CharDBQuery(string.format("SELECT 1 FROM accountwide_money WHERE accountId = %d LIMIT 1", accountId))
end

-- Retroactively seed this account once by summing all character money
local function RetroactivelySeedAccountMoneyIfMissing(accountId)
    local query = CharDBQuery(string.format("SELECT SUM(money) FROM characters WHERE account = %d", accountId))
    local totalAccountMoney = query and query:GetUInt32(0) or 0

    CharDBExecute(string.format([[
        INSERT INTO accountwide_money (accountId, money)
        VALUES (%d, %d)
        ON DUPLICATE KEY UPDATE money = VALUES(money)
    ]], accountId, totalAccountMoney))
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
        -- If the account has any rows, then it has already been seeded
        if not AccountMoneyRowExists(accountId) then
            RetroactivelySeedAccountMoneyIfMissing(accountId)
        end

        -- Delay the sync to allow accountwide_money to update first before syncing down to the character to ensure there are no discrepancies
        player:RegisterEvent(function(_, _, _, player)
            SyncCharacterMoneyOnLogin(player, accountId)
            lastSyncedMoney[player:GetGUIDLow()] = player:GetCoinage() or 0
        end, 1000, 1)
        
        if ANNOUNCE_ON_LOGIN then
            player:SendBroadcastMessage(ANNOUNCEMENT)
        end
    elseif event == 25 then
        local guid = player:GetGUIDLow()
        local currentMoney = player:GetCoinage() or 0

        -- Fallback if baseline missing (e.g., .reload eluna)
        local baseline = lastSyncedMoney[guid]
        if baseline == nil then
            baseline = GetTotalAccountMoney(accountId) or 0
        end

        local delta = currentMoney - baseline
        if delta ~= 0 then
            AddDeltaToAccountMoney(accountId, delta)
            lastSyncedMoney[guid] = currentMoney
        end
    end
end

local function CleanUpMoneyOnLogout(event, player)
    local guid = player:GetGUIDLow()
    player:RegisterEvent(function()
        lastSyncedMoney[guid] = nil
    end, 1500, 1)
end

RegisterPlayerEvent(3, AccountMoney) -- PLAYER_EVENT_ON_LOGIN
RegisterPlayerEvent(4, CleanUpMoneyOnLogout) -- PLAYER_EVENT_ON_LOGOUT
RegisterPlayerEvent(25, AccountMoney) -- EVENT_ON_SAVE