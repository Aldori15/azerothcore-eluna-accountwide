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
local botCache = {}

function AccountWideUtils.checkCoreVersion()
    -- Detect whether we're on Playerbot branch
    if hasPlayerbots == nil then
        local coreVersion = GetCoreVersion()
        hasPlayerbots = coreVersion and coreVersion:lower():find("playerbot") ~= nil
    end
end

function AccountWideUtils.isPlayerBotAccount(accountId)
    AccountWideUtils.checkCoreVersion()

    if not hasPlayerbots then return false end

    local cached = botCache[accountId]
    if cached ~= nil then return cached end

    local result = AuthDBQuery(string.format("SELECT username FROM account WHERE id = %d", accountId))
    if result then
        local username = result:GetString(0)
        local isBot = username:sub(1, 6) == "RNDBOT"
        botCache[accountId] = isBot
        return isBot
    end

    botCache[accountId] = false
    return false
end
