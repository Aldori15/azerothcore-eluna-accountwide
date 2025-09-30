-- -------------------------------------------------------------------------------------------
-- ACCOUNTWIDE MONEY CONFIG
--
-- Hosted by Aldori15 on Github: https://github.com/Aldori15/azerothcore-lua-accountwide
-- -------------------------------------------------------------------------------------------

-- Master on/off for this script
local ENABLE_ACCOUNTWIDE_MONEY = false

-- Optional login announcement
local ANNOUNCE_ON_LOGIN = false
local ANNOUNCEMENT = "This server is running the |cFF00B0E8AccountWide Money|r lua script."

-- =============================================
-- Realtime tick (periodic sync while online)
-- =============================================
-- Global switch for periodic “tick” updates.
-- Primary (or solo) will always tick if this is true.
-- Altbots will only tick if ENABLE_ALTBOT_REALTIME_TICK is also true.
local ENABLE_REALTIME_TICK = false

-- Only applies when ENABLE_REALTIME_TICK = true.
-- Enable this if you want Altbots to also tick realtime; FALSE means Altbots only write on save/logout.
local ENABLE_ALTBOT_REALTIME_TICK = false

local REALTIME_TICK_INTERVAL_MS = 3000 -- every 3 seconds
local REALTIME_TICK_JITTER_MS = 500 -- 0-500ms random jitter so characters don't write at the exact same millisecond

-- -------------------------------------------------------------------------------------------
-- END CONFIG
-- -------------------------------------------------------------------------------------------

if not ENABLE_ACCOUNTWIDE_MONEY then return end

local AUtils = AccountWideUtils

local lastSyncedMoney = {}
local justPushedAt = {}

local function GetTotalAccountMoney(accountId)
    local query = CharDBQuery(string.format("SELECT money FROM accountwide_money WHERE accountId = %d", accountId))
    return query and query:GetUInt32(0) or 0
end

local function AddDeltaToAccountMoney(accountId, delta)
    if delta == 0 then return end

    local sql = string.format([[
        INSERT INTO accountwide_money (accountId, money)
        VALUES (%d, %d)
        ON DUPLICATE KEY UPDATE money = GREATEST(0, money + VALUES(money))
    ]], accountId, delta)

    CharDBExecute(sql)
end

local function AccountMoneyRowExists(accountId)
    return CharDBQuery(string.format("SELECT 1 FROM accountwide_money WHERE accountId = %d LIMIT 1", accountId)) ~= nil
end

-- One-time seeding: sum all character money into the account row.
local function RetroactivelySeedAccountMoneyIfMissing(accountId)
    local query = CharDBQuery(string.format("SELECT COALESCE(SUM(money),0) FROM characters WHERE account = %d", accountId))
    local totalAccountMoney = query and query:GetUInt32(0) or 0
    CharDBExecute(string.format([[
        INSERT INTO accountwide_money (accountId, money)
        VALUES (%d, %d)
        ON DUPLICATE KEY UPDATE money = VALUES(money)
    ]], accountId, totalAccountMoney))
end

--  If character > account, push up the difference.
--  If account > character and this player is allowed to down sync (primary), top up the character.
--  If not allowed to down sync (Altbot), DO NOT change account or char on login. We will only rely on delta changes
local function SyncCharacterMoneyOnLogin(player, accountId)
    local accountTotal = GetTotalAccountMoney(accountId)
    local currentMoney = player:GetCoinage() or 0

    if AUtils.shouldDoDownsync(player) then
        if currentMoney > accountTotal then
            player:ModifyMoney(-(currentMoney - accountTotal))
            return
        elseif accountTotal > currentMoney then
            player:ModifyMoney(accountTotal - currentMoney)
            return
        end
        return
    else
        -- Altbot: do nothing at login. We will rely on delta pushes only
        return
    end
end

local function TickRealtimeSync(player)
    if not player or not player:IsInWorld() then return end

    local guid = player:GetGUIDLow()
    local accountId = player:GetAccountId()

    if AUtils.shouldSkipAll and AUtils.shouldSkipAll(player) then return end

    local current = player:GetCoinage() or 0
    local baseline = lastSyncedMoney[guid]
    if baseline == nil then
        lastSyncedMoney[guid] = current -- first tick, establish baseline
        return
    end

    -- push delta (character -> account)
    local delta = current - baseline
    local pushed = false
    if delta ~= 0 then
        AddDeltaToAccountMoney(accountId, delta)
        baseline = current
        lastSyncedMoney[guid] = baseline
        pushed = true
        if GetMSTime then justPushedAt[guid] = GetMSTime() else justPushedAt[guid] = os.time() * 1000 end
    end

    -- mirror (account -> character) only if we did NOT push this tick
    if not (AUtils.shouldDoDownsync and AUtils.shouldDoDownsync(player)) then return end

    -- If we just pushed this tick, skip mirror to avoid “bounce”
    local now = GetMSTime and GetMSTime() or (os.time() * 1000)
    local jp  = justPushedAt[guid] or 0
    if pushed or (now - jp) < 1 then
        -- we either pushed in this tick, or timestamp says "just pushed"
        return
    end

    local accountTotal = GetTotalAccountMoney(accountId)
    if accountTotal > baseline then
        local add = accountTotal - baseline
        if add > 0 then
            player:ModifyMoney(add)
            baseline = baseline + add
            lastSyncedMoney[guid] = baseline
        end
    elseif baseline > accountTotal then
        local sub = baseline - accountTotal
        if sub > 0 then
            player:ModifyMoney(-sub)
            baseline = baseline - sub
            lastSyncedMoney[guid] = baseline
        end
    end
end

local function StartRealtimeTimer(player)
    if not ENABLE_REALTIME_TICK then return end
    -- Add small random jitter so many players don't tick at the exact same ms
    local delay = REALTIME_TICK_INTERVAL_MS + math.random(0, REALTIME_TICK_JITTER_MS)

    player:RegisterEvent(function(_, _, _, p) TickRealtimeSync(p) end, delay, 0)
end

local function AccountMoney(event, player)
    local accountId = player:GetAccountId()

    -- Always skip RNDbots; Altbots still push deltas but avoid down-syncs via shouldDoDownsync
    if AUtils.shouldSkipAll and AUtils.shouldSkipAll(player) then return end

	-- Skip if player has Unfair Taxes Key (Taxation Without Representation Mode)
    if player:HasItem(800086) then return end

    if event == 3 then
        if not AccountMoneyRowExists(accountId) then
            RetroactivelySeedAccountMoneyIfMissing(accountId)
        end

        -- Delay to let account seeding settle, then do safe login sync and start the realtime tick
        player:RegisterEvent(function(_, _, _, player)
            AUtils.markPrimaryOnLogin(player)
            SyncCharacterMoneyOnLogin(player, accountId)
            lastSyncedMoney[player:GetGUIDLow()] = player:GetCoinage() or 0

            if ENABLE_REALTIME_TICK then
                if AUtils.shouldDoDownsync(player) then
                    -- Primary (or solo)
                    StartRealtimeTimer(player)
                elseif ENABLE_ALTBOT_REALTIME_TICK then
                    -- Altbots: only if explicitly enabled
                    StartRealtimeTimer(player)
                end
            end
        end, 1000, 1)

        if ANNOUNCE_ON_LOGIN then
            player:SendBroadcastMessage(ANNOUNCEMENT)
        end
    elseif event == 25 then
        local guid = player:GetGUIDLow()
        local currentMoney = player:GetCoinage() or 0

        local baseline = lastSyncedMoney[guid]
        if baseline == nil then
            lastSyncedMoney[guid] = currentMoney
            return
        end

        local delta = currentMoney - baseline
        if delta ~= 0 then
            AddDeltaToAccountMoney(accountId, delta)
            lastSyncedMoney[guid] = currentMoney
        end
    end
end

local function CleanUpMoneyOnLogout(event, player)
    local guid = player:GetGUIDLow()
    local accountId = player:GetAccountId()

    -- FINAL FLUSH: capture any last delta before the player object goes away
    local current = player:GetCoinage() or 0
    local baseline = lastSyncedMoney[guid]

    if baseline == nil then
        baseline = current
    else
        local delta = current - baseline
        if delta ~= 0 then
            AddDeltaToAccountMoney(accountId, delta)
        end
    end

    player:RegisterEvent(function()
        lastSyncedMoney[guid] = nil
        AUtils.clearPrimaryOnLogout(player)
    end, 500, 1)
end

RegisterPlayerEvent(3, AccountMoney) -- PLAYER_EVENT_ON_LOGIN
RegisterPlayerEvent(4, CleanUpMoneyOnLogout) -- PLAYER_EVENT_ON_LOGOUT
RegisterPlayerEvent(25, AccountMoney) -- EVENT_ON_SAVE
