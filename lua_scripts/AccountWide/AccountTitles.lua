-- ----------------------------------------------------------------------------------------------
-- ACCOUNTWIDE TITLES CONFIG 
--
-- Hosted by Aldori15 on Github: https://github.com/Aldori15/azerothcore-lua-accountwide
-- ----------------------------------------------------------------------------------------------

local ENABLE_ACCOUNTWIDE_TITLES = false

local ANNOUNCE_ON_LOGIN = false
local ANNOUNCEMENT = "This server is running the |cFF00B0E8AccountWide Titles |rlua script."

local BATCH_SIZE = 100 -- SQL batching for fewer DB calls

-------------------------------------------------------------------------------------------------
-- END CONFIG
-------------------------------------------------------------------------------------------------

if not ENABLE_ACCOUNTWIDE_TITLES then return end

local AUtils = AccountWideUtils

-- Valid title IDs from your CharTitles.dbc
local VALID_TITLE_IDS = {
    1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21,
    22, 23, 24, 25, 26, 27, 28, 42, 43, 44, 45, 46, 47, 48, 53, 62, 63, 64, 71,
    72, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 89, 90, 91, 92, 93,
    94, 95, 96, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 
    111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 123, 124, 125, 126, 
    127, 128, 129, 130, 131, 132, 133, 134, 135, 137, 138, 139, 140, 141, 142, 143,
    144, 145, 146, 147, 148, 149, 150, 151, 152, 153, 154, 155, 156, 157, 158, 159, 
    160, 161, 163, 164, 165, 166, 167, 168, 169, 170, 171, 172, 173, 174, 175, 176, 
    177, 194, 195, 196, 197, 198, 199, 200, 201, 202, 203, 204, 205, 206, 207, 208,
    209, 210, 211, 212, 213
}

local VALID_TITLE_SET = (function()
    local set = {}
    for i = 1, #VALID_TITLE_IDS do set[VALID_TITLE_IDS[i]] = true end
    return set
end)()

local function insertTitlesBatch(accountId, titleIds)
    if #titleIds == 0 then return end

    local values, count = {}, 0
    for i = 1, #titleIds do
        values[#values+1] = string.format("(%d,%d)", accountId, titleIds[i])
        count = count + 1

        if count == BATCH_SIZE then
            CharDBExecute("INSERT IGNORE INTO accountwide_titles (accountId, titleId) VALUES " .. table.concat(values, ","))
            values, count = {}, 0
        end
    end

    if count > 0 then
        CharDBExecute("INSERT IGNORE INTO accountwide_titles (accountId, titleId) VALUES " .. table.concat(values, ","))
    end
end

local function GrantAccountwideTitlesOnLogin(event, player)
    local accountId = player:GetAccountId()
    -- Skip playerbot accounts
    if AUtils.isPlayerBotAccount(accountId) then return end

    if ANNOUNCE_ON_LOGIN then
        player:SendBroadcastMessage(ANNOUNCEMENT)
    end

    local query = CharDBQuery(string.format("SELECT titleId FROM accountwide_titles WHERE accountId = %d", accountId))
    if query then
        repeat
            local titleId = query:GetUInt32(0)
            if VALID_TITLE_SET[titleId] and not player:HasTitle(titleId) then
                player:SetKnownTitle(titleId)
            end
        until not query:NextRow()
    end
end

local function SyncTitlesOnLogout(event, player)
    local accountId = player:GetAccountId()
    -- Skip playerbot accounts
    if AUtils.isPlayerBotAccount(accountId) then return end

    local newlyEarned = {}
    for i = 1, #VALID_TITLE_IDS do
        local titleId = VALID_TITLE_IDS[i]

        if player:HasTitle(titleId) then
            newlyEarned[#newlyEarned+1] = titleId
        end
    end

    insertTitlesBatch(accountId, newlyEarned)
end

RegisterPlayerEvent(3, GrantAccountwideTitlesOnLogin)  -- EVENT_ON_LOGIN
RegisterPlayerEvent(4, SyncTitlesOnLogout)  -- EVENT_ON_LOGOUT