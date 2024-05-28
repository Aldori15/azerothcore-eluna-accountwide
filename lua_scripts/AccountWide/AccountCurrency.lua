-- ----------------------------------------------------------------------------------------------
-- ACCOUNTWIDE CURRENCY CONFIG 
--
-- Hosted by Aldori15 on Github: https://github.com/Aldori15/azerothcore-lua-accountwide
-- ----------------------------------------------------------------------------------------------

local ENABLE_ACCOUNTWIDE_CURRENCY = false

local ANNOUNCE_ON_LOGIN = true
local ANNOUNCEMENT = "This server is running the |cFF00B0E8AccountWide Currency |rlua script."

-- -- -------------------------------------------------------------------------------------------
-- -- END CONFIG
-- -- -------------------------------------------------------------------------------------------

if not ENABLE_ACCOUNTWIDE_CURRENCY then
    return
end

-- Note: these `item_template` IDs are currently configured for Dinkledork's repack, so your mileage may vary if there are custom currencies, etc.  Just add/remove currencies as necessary.
local currencyItemIDs = {
    12840,  -- Minion's Scourgestone
    12841,  -- Invader's Scourgestone
    12843,  -- Corruptor's Scourgestone
    19182,  -- Darkmoon Faire Prize Ticket
    20558,  -- Warsong Gulch Mark of Honor
    20559,  -- Arathi Basin Mark of Honor
    20560,  -- Alterac Valley Mark of Honor
    22637,  -- Primal Hakkari Idol
    29024,  -- Eye of the Storm Mark of Honor
    29434,  -- Badge of Justice
    37711,  -- Reward Points
    37836,  -- Venture Coin
    40752,  -- Emblem of Heroism
    40753,  -- Emblem of Valor
    41596,  -- Dalaran Jewelcrafter's Token
    42425,  -- Strand of the Ancients Mark of Honor
    43016,  -- Dalaran Cooking Award
    43228,  -- Stone Keeper's Shard
    43307,  -- Arena Points
    43308,  -- Honor Points
    43589,  -- Wintergrasp Mark of Honor
    43949,  -- Lich Rune
    44990,  -- Champion's Seal
    45624,  -- Emblem of Conquest
    47241,  -- Emblem of Triumph
    49426,  -- Emblem of Frost
}

local function AccountWideCurrency(event, player)
    if ANNOUNCE_ON_LOGIN and event == 3 then
        player:SendBroadcastMessage(ANNOUNCEMENT)
    end

    local accountId = player:GetAccountId()

    -- Loop through currency items
    for _, currencyItemID in ipairs(currencyItemIDs) do
        local maxQuery = CharDBQuery("SELECT MAX(count) FROM item_instance WHERE owner_guid IN (SELECT guid FROM characters WHERE account = " .. accountId .. ") AND itemEntry = " .. currencyItemID)
        if maxQuery then
            local maxCount = maxQuery:GetUInt32(0) or 0

            local currentQuery = CharDBQuery("SELECT count FROM item_instance WHERE owner_guid = " .. player:GetGUIDLow() .. " AND itemEntry = " .. currencyItemID)
            if currentQuery then
                local currentCount = currentQuery:GetUInt32(0) or 0

                if event == 3 and currentCount < maxCount then
                    -- If the currency on the current logged in character doesn't match the currency of the other characters on the account, set the difference to match it
                    local difference = maxCount - currentCount
                    player:AddItem(currencyItemID, difference)
                elseif event == 4 or event == 25 then
                    -- Update the count for all characters on the account to the new lower count if any currency was spent
                    CharDBExecute("UPDATE item_instance SET count = " .. currentCount .. " WHERE owner_guid IN (SELECT guid FROM characters WHERE account = " .. accountId .. ") AND itemEntry = " .. currencyItemID .. " AND count > " .. currentCount)
                end
            elseif event == 3 and maxCount ~= 0 then
                -- If the currency is missing from the current character's inventory and it resides on another character, add it
                player:AddItem(currencyItemID, maxCount)
            end
        end
    end
end

RegisterPlayerEvent(3, AccountWideCurrency) -- PLAYER_EVENT_ON_LOGIN
RegisterPlayerEvent(4, AccountWideCurrency) -- PLAYER_EVENT_ON_LOGOUT
RegisterPlayerEvent(25, AccountWideCurrency) -- EVENT_ON_SAVE