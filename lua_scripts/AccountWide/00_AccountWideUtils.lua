-- ----------------------------------------------------------------------------------------------
-- ACCOUNTWIDE UTILS
--
-- This file contains shared utility functions used across each of the account-wide features.
--
-- Hosted by Aldori15 on Github: https://github.com/Aldori15/azerothcore-lua-accountwide
-- ----------------------------------------------------------------------------------------------

if AccountWideUtils then return end -- Prevent double-loading
AccountWideUtils = {}

local hasPlayerbots = nil
local botAccountCache = {}

function AccountWideUtils.checkCoreVersion()
    if hasPlayerbots == nil then
        local version = GetCoreVersion()
        hasPlayerbots = version and version:lower():find("playerbot") ~= nil
    end
end

function AccountWideUtils.isPlayerBotAccount(accountId)
    AccountWideUtils.checkCoreVersion()
    if not hasPlayerbots then return false end

    local cached = botAccountCache[accountId]
    if cached ~= nil then return cached end

    local result = CharDBQuery(string.format("SELECT 1 FROM acore_playerbots.playerbots_account_type WHERE account_id = %d LIMIT 1", accountId))
    local isBot = result ~= nil
    botAccountCache[accountId] = isBot
    return isBot
end
