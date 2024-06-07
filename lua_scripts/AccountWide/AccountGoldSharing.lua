-- -------------------------------------------------------------------------------------------
-- ACCOUNTWIDE GOLD SHARING CONFIG 
--
-- Hosted by Aldori15 on Github: https://github.com/Aldori15/azerothcore-lua-accountwide
-- -------------------------------------------------------------------------------------------

local ENABLE_GOLD_SHARING = false

local ANNOUNCE_ON_LOGIN = true
local ANNOUNCEMENT = "This server is running the |cFF00B0E8AccountWide Gold Sharing |rlua script."

-- -------------------------------------------------------------------------------------------
-- END CONFIG
-- -------------------------------------------------------------------------------------------

if not ENABLE_GOLD_SHARING then return end

local function GetTotalAccountGold(accountId)
    local query = CharDBQuery("SELECT gold FROM accountwide_gold WHERE accountId = " .. accountId)
    return query and query:GetUInt32(0) or 0
end

-- This function is only called once when the table is empty or has never been populated since creating the table
local function InitializeAccountGoldOnEmptyTable(accountId)
    local query = CharDBQuery("SELECT SUM(money) FROM characters WHERE account = " .. accountId)
    local totalAccountGold = query and query:GetUInt32(0) or 0
    CharDBExecute("REPLACE INTO accountwide_gold (accountId, gold) VALUES (" .. accountId .. ", " .. totalAccountGold .. ")")
end

local function UpdateAccountGold(accountId, gold)
    CharDBExecute("REPLACE INTO accountwide_gold (accountId, gold) VALUES (" .. accountId .. ", " .. gold .. ")")
end

local function SyncCharacterGoldOnLogin(player, accountId)
    local totalAccountGold = GetTotalAccountGold(accountId)
    local currentGold = player:GetCoinage()

    -- Calculate the difference and adjust the player's gold accordingly
    if totalAccountGold > currentGold then
        player:ModifyMoney(totalAccountGold - currentGold)
    elseif totalAccountGold < currentGold then
        player:ModifyMoney(-(currentGold - totalAccountGold))
    end
end

local function GoldSharing(event, player)
    local accountId = player:GetAccountId()

    if event == 3 then
        -- Initialize account gold if not already initialized. Once initialized, it should never need to do it again
        if GetTotalAccountGold(accountId) == 0 then
            InitializeAccountGoldOnEmptyTable(accountId)
        end
        -- Delay the sync to allow accountwide_gold to update first before syncing down to the character to ensure there are no discrepancies 
        player:RegisterEvent(function(_, _, _, player)
            SyncCharacterGoldOnLogin(player, accountId)
        end, 1000, 1) -- Delay of 1000 milliseconds (1 second) to ensure that the InitializeAccountGoldOnEmptyTable() function finishes populating the empty table
        
        if ANNOUNCE_ON_LOGIN then
            player:SendBroadcastMessage(ANNOUNCEMENT)
        end
    elseif event == 4 or event == 25 then
        local currentGold = player:GetCoinage()
        UpdateAccountGold(accountId, currentGold)
    end
end

RegisterPlayerEvent(3, GoldSharing) -- PLAYER_EVENT_ON_LOGIN
RegisterPlayerEvent(4, GoldSharing) -- PLAYER_EVENT_ON_LOGOUT
RegisterPlayerEvent(25, GoldSharing) -- EVENT_ON_SAVE