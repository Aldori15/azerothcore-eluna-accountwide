-- ----------------------------------------------------------------------------------------------
-- ACCOUNTWIDE UTILS
--
-- This file contains shared utility functions used across each of the account-wide features.
--
-- Hosted by Aldori15 on Github: https://github.com/Aldori15/azerothcore-lua-accountwide
-- ----------------------------------------------------------------------------------------------

if AccountWideUtils then return end -- Prevent double-loading
AccountWideUtils = {}

-- When true, Altbots (other chars on the same account online simultaneously) SKIP the
-- *downward* login sync, but STILL contribute deltas on save (event 25).
if EXCLUDE_ALTBOTS == nil then EXCLUDE_ALTBOTS = true end
-- When true, Altbots are skipped ENTIRELY (no login sync and no save deltas).
-- Most servers should leave this false; usually you want Altbot gameplay to count.
if EXCLUDE_ALTBOTS_FULL == nil then EXCLUDE_ALTBOTS_FULL = false end

local hasPlayerbots = nil
local botAccountCache = {}

function AccountWideUtils.checkCoreVersion()
    if hasPlayerbots == nil then
        local version = GetCoreVersion()
        hasPlayerbots = version and version:lower():find("playerbot") ~= nil
    end
end

-- ==============================================================================================
-- RNDbot detection
-- Note: acore_playerbots.playerbots_account_type currently stores RNDbot accounts.
-- ==============================================================================================

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

-- ==============================================================================================
-- Altbot detection via heuristic:
-- "Altbot" = another character on the same account online at the same time.
-- We designate the 'primary' as the lowest GUID online for that account; all others are Altbots.
-- ==============================================================================================

local function getOnlineGuidsForAccount(accountId)
    local query = CharDBQuery(string.format("SELECT guid FROM characters WHERE account = %d AND online = 1 ORDER BY guid ASC", accountId))
    if not query then return nil end

    local guids = {}
    repeat
        table.insert(guids, query:GetUInt32(0))
    until not query:NextRow()
    return guids
end

function AccountWideUtils.isAltBotCharacter(player)
    AccountWideUtils.checkCoreVersion()
    if not hasPlayerbots then return false end

    local accountId = player:GetAccountId()

    -- RNDbot accounts are handled separately; they are not "Altbots"
    if AccountWideUtils.isPlayerBotAccount(accountId) then return false end

    local guids = getOnlineGuidsForAccount(accountId)
    if not guids or #guids <= 1 then
        return false -- only one character online on this account
    end

    local primaryGuid = guids[1] -- deterministic "primary"
    return player:GetGUIDLow() ~= primaryGuid
end

-- ==============================================================================================
-- Gates used by account-wide scripts
-- ==============================================================================================

function AccountWideUtils.shouldSkipAll(player)
    local accountId = player:GetAccountId()

    -- RNDbots: never process in account-wide systems
    if AccountWideUtils.isPlayerBotAccount(accountId) then return true end

    -- Altbots: optionally skip completely
    if EXCLUDE_ALTBOTS_FULL and AccountWideUtils.isAltBotCharacter(player) then return true end

    return false
end

--  If EXCLUDE_ALTBOTS = true and this is an Altbot, avoid down-sync (prevents tug-of-war).
function AccountWideUtils.shouldDoDownsync(player)
    if EXCLUDE_ALTBOTS and AccountWideUtils.isAltBotCharacter(player) then return false end
    return true
end
