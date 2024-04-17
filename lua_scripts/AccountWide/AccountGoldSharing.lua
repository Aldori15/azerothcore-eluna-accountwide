-- -------------------------------------------------------------------------------------------
-- ACCOUNTWIDE GOLD SHARING CONFIG 
--
-- Hosted by Aldori15 on Github: https://github.com/Aldori15/azerothcore-lua-accountwide
-- -------------------------------------------------------------------------------------------

local ENABLE_GOLD_SHARING = false

local ANNOUNCE_ON_LOGIN = true
local ANNOUNCEMENT = "This server is running the |cFF00B0E8AccountWide Gold Sharing |rmodule."

-- -------------------------------------------------------------------------------------------
-- END CONFIG
-- -------------------------------------------------------------------------------------------

-- Table to store maximum money for each account
local maxMoneyCache = {}

local function StoreMaxMoney(accountId)
    local maxQuery = CharDBQuery("SELECT MAX(money) FROM characters WHERE account = " .. accountId)
    if maxQuery then
        maxMoneyCache[accountId] = maxQuery:GetUInt32(0) or 0
    else
        maxMoneyCache[accountId] = nil -- Set to nil if no maximum money found
    end
end

local function GoldSharing(event, player)
    if not ENABLE_GOLD_SHARING then
        return
    end

    local accountId = player:GetAccountId()
    local startingMoneyCount

    if event == 3 then
        StoreMaxMoney(accountId)

        if ANNOUNCE_ON_LOGIN then
            player:SendBroadcastMessage(ANNOUNCEMENT)
        end
    end

    -- Check if max money is already cached for this account. If not, update the cache
    if not maxMoneyCache[accountId] then
        StoreMaxMoney(accountId)
    end

    local maxCount = maxMoneyCache[accountId]
    local currentCount = player:GetCoinage()

    if event == 3 and (currentCount < maxCount) then
        local difference = maxCount - currentCount
        player:ModifyMoney(difference)
    elseif event == 4 or event == 25 then
    -- Update the money for all characters on the account to the new lower amount if any money was spent
    CharDBExecute("UPDATE characters SET money = " .. currentCount .. " WHERE account = " .. accountId .. " AND money > " .. currentCount)
    end
end

RegisterPlayerEvent(3, GoldSharing) -- PLAYER_EVENT_ON_LOGIN
RegisterPlayerEvent(4, GoldSharing) -- PLAYER_EVENT_ON_LOGOUT
RegisterPlayerEvent(25, GoldSharing) -- EVENT_ON_SAVE