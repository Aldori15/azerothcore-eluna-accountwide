-- ----------------------------------------------------------------------------------------------
-- ACCOUNTWIDE UTILS
--
-- This file contains shared helper functions used across each of the accountwide features
-- for making them compatible with Playerbots.
--
-- Hosted by Aldori15 on Github: https://github.com/Aldori15/azerothcore-lua-accountwide
-- ----------------------------------------------------------------------------------------------

if AccountWideUtils then return end -- Prevent double-loading
AccountWideUtils = {}

if EXCLUDE_ALTBOTS == nil then EXCLUDE_ALTBOTS = true end
if EXCLUDE_ALTBOTS_FULL == nil then EXCLUDE_ALTBOTS_FULL = false end

local hasPlayerbots = nil
local botAccountCache = {}
local primaryByAccount = {}

local onlineByAccount = {}
local onlineCount = {}

-- ==============================================================================================
-- Playerbots module detection
-- We don't need to run any of this if the server doesn't have playerbots.
-- ==============================================================================================
function AccountWideUtils.checkPlayerbotsModule()
    if hasPlayerbots ~= nil then return end

    if type(GetConfigValue) == "function" then
        -- Try reading the playerbots.conf file
        local value = GetConfigValue("AiPlayerbot.Enabled")

        if value ~= nil and value ~= "" then
            hasPlayerbots = (tonumber(value) or 0) ~= 0
            return
        end

        -- playerbots.conf not found -> assume no Playerbots module
        hasPlayerbots = false
        return
    end

    -- Fallback method for older Eluna/ALE builds that don't have GetConfigValue
    if type(GetCoreVersion) == "function" then
        local version = GetCoreVersion()
        hasPlayerbots = version and version:lower():find("playerbot") ~= nil
        return
    end
end

-- ==============================================================================================
-- RNDbot detection
-- ==============================================================================================
function AccountWideUtils.isPlayerBotAccount(accountId)
    AccountWideUtils.checkPlayerbotsModule()
    if not hasPlayerbots then return false end

    local cached = botAccountCache[accountId]
    if cached ~= nil then return cached end

    local result = CharDBQuery(string.format("SELECT 1 FROM acore_playerbots.playerbots_account_type WHERE account_id = %d LIMIT 1", accountId))
    local isBot = result ~= nil
    botAccountCache[accountId] = isBot
    return isBot
end

-- ==============================================================================================
-- Altbot detection
-- "Altbot" = another character on the same account online at the same time.
-- ==============================================================================================
local function getOnlineGuidsForAccount(accountId)
    local set = onlineByAccount[accountId]
    if not set then return {} end

    local guids = {}
    for guid,_ in pairs(set) do
        guids[#guids + 1] = guid
    end
    table.sort(guids)
    return guids
end

function AccountWideUtils.isAltBotCharacter(player)
    AccountWideUtils.checkPlayerbotsModule()
    if not hasPlayerbots then return false end

    local accountId = player:GetAccountId()
    if AccountWideUtils.isPlayerBotAccount(accountId) then return false end

    local guids = getOnlineGuidsForAccount(accountId)
    if #guids <= 1 then return false end  -- solo online => never an Altbot

    local anchor = primaryByAccount[accountId]
    if not anchor then
        -- If no anchor yet, treat first online as anchor
        anchor = guids[1]
        primaryByAccount[accountId] = anchor
    end
    return player:GetGUIDLow() ~= anchor
end

function AccountWideUtils.markPrimaryOnLogin(player)
    local accountId = player:GetAccountId()
    if not primaryByAccount[accountId] then
        primaryByAccount[accountId] = player:GetGUIDLow()
    end
end

function AccountWideUtils.clearPrimaryOnLogout(player)
    local accountId = player:GetAccountId()
    if primaryByAccount[accountId] == player:GetGUIDLow() then
        primaryByAccount[accountId] = nil
    end
end

function AccountWideUtils.noteLogin(player)
    local accountId = player:GetAccountId()
    local guid = player:GetGUIDLow()

    local set = onlineByAccount[accountId]
    if not set then
        set = {}
        onlineByAccount[accountId] = set
        onlineCount[accountId] = 0
    end

    if not set[guid] then
        set[guid] = true
        onlineCount[accountId] = (onlineCount[accountId] or 0) + 1
    end

    if not primaryByAccount[accountId] then
        primaryByAccount[accountId] = guid
    end
end

function AccountWideUtils.noteLogout(accountId, guid)
    local set = onlineByAccount[accountId]
    if not set or not set[guid] then return end

    set[guid] = nil
    onlineCount[accountId] = (onlineCount[accountId] or 1) - 1

    if onlineCount[accountId] <= 0 then
        onlineByAccount[accountId] = nil
        onlineCount[accountId] = nil
        primaryByAccount[accountId] = nil
        return
    end

    -- If the anchor logged out, pick a new anchor deterministically (lowest guid)
    if primaryByAccount[accountId] == guid then
        local lowest
        for g,_ in pairs(set) do
            if not lowest or g < lowest then lowest = g end
        end
        primaryByAccount[accountId] = lowest
    end
end

-- ==============================================================================================
-- Gates used by Accountwide scripts
-- ==============================================================================================
function AccountWideUtils.shouldSkipAll(player)
    local accountId = player:GetAccountId()

    -- RNDbots: never process in accountwide systems
    if AccountWideUtils.isPlayerBotAccount(accountId) then return true end

    -- Altbots: optionally skip completely
    if EXCLUDE_ALTBOTS_FULL and AccountWideUtils.isAltBotCharacter(player) then return true end

    return false
end

function AccountWideUtils.shouldDoDownsync(player)
    local accountId = player:GetAccountId()
    local count = onlineCount[accountId] or 0

    -- Solo online -> always allow
    if count <= 1 then return true end

    -- Otherwise, only the anchored primary can down-sync
    if EXCLUDE_ALTBOTS then
        local anchor = primaryByAccount[accountId]
        if not anchor then
            anchor = player:GetGUIDLow()
            primaryByAccount[accountId] = anchor
        end
        return player:GetGUIDLow() == anchor
    end

    return true
end
