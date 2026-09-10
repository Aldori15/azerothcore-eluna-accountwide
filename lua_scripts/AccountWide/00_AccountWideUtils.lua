-- ----------------------------------------------------------------------------------------------
-- ACCOUNTWIDE UTILS
--
-- This file contains shared helper functions used across each of the accountwide features
-- for making them compatible with Playerbots.
--
-- Hosted by Aldori15 on Github: https://github.com/Aldori15/azerothcore-eluna-accountwide
-- ----------------------------------------------------------------------------------------------

if AccountWideUtils then return end -- Prevent double-loading
AccountWideUtils = {}

local EXCLUDE_ALTBOTS_FROM_DOWNSYNC = true
local EXCLUDE_ALTBOTS_COMPLETELY = false

-- Playerbot methods are only registered by ALE when MOD_PLAYERBOTS is available
local HAS_PLAYERBOTS = type(GetPlayerbotsMgr) == "function"


-- ==============================================================================================
-- Playerbot classification
-- ==============================================================================================

-- Server generated RandomBot / RNDBot.
local function isRandomBot(player)
    if not HAS_PLAYERBOTS then return false end
    return player:IsRandomBot()
end

-- Server generated bot from the AddClass account pool.
local function isAddClassBot(player)
    if not HAS_PLAYERBOTS then return false end
    return player:IsAddclassBot()
end

-- Bot-controlled character whose master is client based (a regular player or SelfBot).
-- Playerbots also classifies AddClass bots as AltBots.
local function isAltBotCharacter(player)
    if not HAS_PLAYERBOTS then return false end
    return player:IsAltBot()
end


-- ==============================================================================================
-- Gates used by Accountwide scripts
-- ==============================================================================================

function AccountWideUtils.shouldSkipAll(player)
    if not HAS_PLAYERBOTS then return false end

    -- RNDBots: server generated
    -- never process in accountwide systems
    if isRandomBot(player) then return true end

    -- AddClass bots: server generated
    -- never process in accountwide systems
    if isAddClassBot(player) then return true end

    -- AltBots: optionally skip completely
    if EXCLUDE_ALTBOTS_COMPLETELY and isAltBotCharacter(player) then return true end

    return false
end

function AccountWideUtils.shouldDoDownsync(player)
    if not HAS_PLAYERBOTS then return true end

    -- RNDBots and AddClass bots should never perform AccountWide downsync
    if isRandomBot(player) or isAddClassBot(player) then return false end

    -- AltBots may contribute changes, but when EXCLUDE_ALTBOTS_FROM_DOWNSYNC is enabled,
    -- they are not allowed to push account state back down onto themselves.
    if EXCLUDE_ALTBOTS_FROM_DOWNSYNC and isAltBotCharacter(player) then return false end

    return true
end


-- ==============================================================================================
-- General helpers
-- ==============================================================================================

function AccountWideUtils.csv(list, emptyValue)
    if not list or #list == 0 then return emptyValue or "0" end
    return table.concat(list, ",")
end

function AccountWideUtils.csvInt(list, emptyValue)
    if not list or #list == 0 then return emptyValue or "0" end

    local out = {}
    for i = 1, #list do
        out[i] = tostring(list[i])
    end
    return table.concat(out, ",")
end

function AccountWideUtils.chunkList(list, chunkSize)
    local chunks = {}
    if not list or #list == 0 then return chunks end

    local i = 1
    while i <= #list do
        local chunk = {}
        for j = i, math.min(i + chunkSize - 1, #list) do
            chunk[#chunk + 1] = list[j]
        end
        chunks[#chunks + 1] = chunk
        i = i + chunkSize
    end
    return chunks
end

function AccountWideUtils.insertValuesInBatches(insertPrefix, rowValues, batchSize)
    if not rowValues or #rowValues == 0 then return end

    batchSize = tonumber(batchSize) or 500
    if batchSize < 1 then batchSize = 500 end

    for _, chunk in ipairs(AccountWideUtils.chunkList(rowValues, batchSize)) do
        CharDBExecute(insertPrefix .. table.concat(chunk, ","))
    end
end
