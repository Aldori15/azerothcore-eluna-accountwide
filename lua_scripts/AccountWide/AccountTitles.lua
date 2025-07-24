-- ----------------------------------------------------------------------------------------------
-- ACCOUNTWIDE TITLES CONFIG 
--
-- Hosted by Aldori15 on Github: https://github.com/Aldori15/azerothcore-lua-accountwide
-- ----------------------------------------------------------------------------------------------

local ENABLE_ACCOUNTWIDE_TITLES = false

local ANNOUNCE_ON_LOGIN = false
local ANNOUNCEMENT = "This server is running the |cFF00B0E8AccountWide Titles |rlua script."

-- -- -------------------------------------------------------------------------------------------
-- END CONFIG
-- -- -------------------------------------------------------------------------------------------

local AUtils = AccountWideUtils

if not ENABLE_ACCOUNTWIDE_TITLES then return end

local function UpdateAccountwideTitles(accountId, titleId)
    CharDBExecute(string.format("INSERT IGNORE INTO accountwide_titles (accountId, titleId) VALUES (%d, %d)", accountId, titleId))
end

local function GrantAccountwideTitlesOnLogin(event, player)
    local accountId = player:GetAccountId()

    -- Skip playerbot accounts
    if AUtils.isPlayerBotAccount(accountId) then return end

    local query = CharDBQuery(string.format("SELECT titleId FROM accountwide_titles WHERE accountId = %d", accountId))
    if query then
        repeat
            local titleId = query:GetUInt32(0)
            if not player:HasTitle(titleId) then
                player:SetKnownTitle(titleId)
            end
        until not query:NextRow()
    end

    if ANNOUNCE_ON_LOGIN then
        player:SendBroadcastMessage(ANNOUNCEMENT)
    end
end

local function SyncTitlesOnSave(event, player)
    local accountId = player:GetAccountId()

    -- Skip playerbot accounts
    if AUtils.isPlayerBotAccount(accountId) then return end

    for titleId = 1, 220 do -- Assuming a maximum of 220 titles (increase this if your CharTitles.dbc file has more than 220 IDs)
        if player:HasTitle(titleId) then
            UpdateAccountwideTitles(accountId, titleId)
        end
    end
end

RegisterPlayerEvent(3, GrantAccountwideTitlesOnLogin)  -- EVENT_ON_LOGIN
RegisterPlayerEvent(25, SyncTitlesOnSave)  -- EVENT_ON_SAVE