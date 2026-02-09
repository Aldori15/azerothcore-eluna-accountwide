-- -------------------------------------------------------------------------------------------
-- ACCOUNTWIDE MONEY CONFIG
--
-- Hosted by Aldori15 on Github: https://github.com/Aldori15/azerothcore-lua-accountwide
-- -------------------------------------------------------------------------------------------

local ENABLE_ACCOUNTWIDE_MONEY = false

local ANNOUNCE_ON_LOGIN = false
local ANNOUNCEMENT = "This server is running the |cFF00B0E8AccountWide Money|r lua script."

-- ===============================
-- Realtime tick (periodic sync)
-- ===============================
local ENABLE_REALTIME_TICK = false

-- Only applies when ENABLE_REALTIME_TICK = true.
-- Enable this if you want Altbots to also tick realtime; otherwise Altbots only write on save/logout.
local ENABLE_ALTBOT_REALTIME_TICK = false

local REALTIME_TICK_INTERVAL_MS = 5000
local REALTIME_TICK_JITTER_MS = 500

-- -------------------------------------------------------------------------------------------
-- END CONFIG
-- -------------------------------------------------------------------------------------------

if not ENABLE_ACCOUNTWIDE_MONEY then return end

local AUtils = AccountWideUtils

local lastSyncedMoney = {}
local lastFlushAt = {}
local FLUSH_DEBOUNCE_MS = 2000

local accountDirty = {}
local accountDirtyAt = {}
local DIRTY_MIN_AGE_MS = 300

local GOLD_SOFT_CAP_COPPER  = 210000 * 10000  -- 210k: where we start diverting to virtual bank
local GOLD_WARNING_THRESHOLD = GOLD_SOFT_CAP_COPPER

if ENABLE_REALTIME_TICK and REALTIME_TICK_JITTER_MS > 0 then
    math.randomseed(os.time())
    math.random(); math.random(); math.random()
end

local function ToLuaNumber(value)
    if type(value) == "userdata" then
        return tonumber(tostring(value))
    end

    return tonumber(value) or 0
end

local function GetNowMs()
    return (GetMSTime and GetMSTime()) or (os.time() * 1000)
end

local function MaybeWarnNearGoldCap(player)
    local money = player:GetCoinage() or 0
    if money >= GOLD_WARNING_THRESHOLD then
        player:SendBroadcastMessage(" ")
        player:SendBroadcastMessage(string.format(
            "|cFF00B0E8AccountWide Money Notice:|r You are at the gold soft cap of %dg. " ..
            "Any gold earned above this amount will automatically be stored in your account bank instead.",
            math.floor(GOLD_SOFT_CAP_COPPER / 10000)
        ))
    end
end

local function GetTotalAccountMoney(accountId)
    local query = CharDBQuery(string.format("SELECT money FROM accountwide_money WHERE accountId = %d", accountId))
    if query then
        return ToLuaNumber(query:GetUInt64(0))
    end

    return 0
end

local function AddDeltaToAccountMoney(accountId, delta)
    if delta == 0 then return end

    local sql = string.format([[
        INSERT INTO accountwide_money (accountId, money)
        VALUES (%d, GREATEST(0, %d))
        ON DUPLICATE KEY UPDATE money = GREATEST(0, money + (%d))
    ]], accountId, delta, delta)

    CharDBExecute(sql)
    
    accountDirty[accountId] = true
    accountDirtyAt[accountId] = GetNowMs()
end

local function AccountMoneyRowExists(accountId)
    return CharDBQuery(string.format("SELECT 1 FROM accountwide_money WHERE accountId = %d LIMIT 1", accountId)) ~= nil
end

local function RetroactivelySeedAccountMoneyIfMissing(accountId)
    if AccountMoneyRowExists(accountId) then return false end

    local query = CharDBQuery(string.format("SELECT COALESCE(SUM(money),0) FROM characters WHERE account = %d", accountId))
    local totalAccountMoney = query and ToLuaNumber(query:GetUInt64(0)) or 0

    CharDBExecute(string.format([[
        INSERT INTO accountwide_money (accountId, money)
        VALUES (%d, %d)
    ]], accountId, totalAccountMoney))

    return true -- we seeded
end

local function SyncCharacterMoneyOnLogin(player, accountId)
    local accountTotal = GetTotalAccountMoney(accountId)
    local currentMoney = player:GetCoinage() or 0

    -- Enforce the soft cap and push any overflow to the bank
    if currentMoney > GOLD_SOFT_CAP_COPPER then
        local overflow = currentMoney - GOLD_SOFT_CAP_COPPER

        AddDeltaToAccountMoney(accountId, overflow)
        player:ModifyMoney(-overflow)

        currentMoney = GOLD_SOFT_CAP_COPPER
        accountTotal = accountTotal + overflow
    end

    if AUtils.shouldDoDownsync(player) then
        if currentMoney > accountTotal then
            -- Character has more than the account bank: trim down to match bank
            player:ModifyMoney(-(currentMoney - accountTotal))
        elseif accountTotal > currentMoney then
            -- Account bank has more than the character: top up, but never exceed soft cap
            local space = GOLD_SOFT_CAP_COPPER - currentMoney
            if space > 0 then
                local desiredAdd = accountTotal - currentMoney
                local toAdd = math.min(desiredAdd, space)
                if toAdd > 0 then
                    player:ModifyMoney(toAdd)
                    currentMoney = currentMoney + toAdd
                end
            end
        end

        MaybeWarnNearGoldCap(player)
        return
    else
        -- Altbot: do nothing. We will rely on delta pushes only
        return
    end
end

local function FlushMoneyDelta(player, accountId, guid, updateBaseline)
    local now = GetNowMs()

    if lastFlushAt[guid] and (now - lastFlushAt[guid]) < FLUSH_DEBOUNCE_MS then
        if updateBaseline then
            lastSyncedMoney[guid] = player:GetCoinage() or 0
        end
        return
    end
    lastFlushAt[guid] = now

    -- Enforce the soft cap and push any overflow to the bank
    local current = player:GetCoinage() or 0
    if current > GOLD_SOFT_CAP_COPPER then
        local overflow = current - GOLD_SOFT_CAP_COPPER
        AddDeltaToAccountMoney(accountId, overflow)
        player:ModifyMoney(-overflow)
        current = GOLD_SOFT_CAP_COPPER
    end

    local baseline = lastSyncedMoney[guid]
    if baseline == nil then
        if updateBaseline then
            lastSyncedMoney[guid] = current
        end
        return
    end

    local delta = current - baseline
    if delta ~= 0 then
        AddDeltaToAccountMoney(accountId, delta)
    end

    if updateBaseline then
        lastSyncedMoney[guid] = current
    end
end

local function TickRealtimeSync(player)
    if not player or not player:IsInWorld() then return end
    if AUtils.shouldSkipAll and AUtils.shouldSkipAll(player) then return end

    local guid = player:GetGUIDLow()
    local accountId = player:GetAccountId()

    FlushMoneyDelta(player, accountId, guid, true)

    local baseline = lastSyncedMoney[guid]
    if baseline == nil then
        baseline = player:GetCoinage() or 0
        lastSyncedMoney[guid] = baseline
    end

    -- mirror (account -> character) only if we did NOT push this tick
    if not (AUtils.shouldDoDownsync and AUtils.shouldDoDownsync(player)) then return end

    -- dirty gate: if the bank hasn't changed, skip DB downsync
    if not accountDirty[accountId] then return end
    local now = GetNowMs()
    local dirtyAt = accountDirtyAt[accountId] or 0
    if (now - dirtyAt) < DIRTY_MIN_AGE_MS then return end

    local accountTotal = GetTotalAccountMoney(accountId)
    local changed = false
    if accountTotal > baseline then
        -- Account has more than the character: top up, but never exceed soft cap
        local add = accountTotal - baseline
        if add > 0 then
            local space = GOLD_SOFT_CAP_COPPER - baseline
            if space > 0 then
                local toAdd = math.min(add, space)
                if toAdd > 0 then
                    player:ModifyMoney(toAdd)
                    baseline = baseline + toAdd
                    lastSyncedMoney[guid] = baseline
                    changed = true
                end
            end
        end
    elseif baseline > accountTotal then
        -- Character has more than the account: trim down to match
        local sub = baseline - accountTotal
        if sub > 0 then
            player:ModifyMoney(-sub)
            baseline = baseline - sub
            lastSyncedMoney[guid] = baseline
            changed = true
        end
    end

    -- Clear dirty if converged or no change
    local finalBaseline = lastSyncedMoney[guid] or baseline
    if finalBaseline == accountTotal or not changed then
        accountDirty[accountId] = false
    end
end

local function StartRealtimeTimer(player)
    if not ENABLE_REALTIME_TICK then return end
    -- Add small random jitter so many players don't tick at the exact same ms
    local delay = REALTIME_TICK_INTERVAL_MS + math.random(0, REALTIME_TICK_JITTER_MS)

    player:RegisterEvent(function(_, _, _, p) TickRealtimeSync(p) end, delay, 0)
end

local function AccountMoney(event, player)
    -- Always skip RNDbots
    if AUtils.shouldSkipAll and AUtils.shouldSkipAll(player) then return end

	-- Unfair Taxes Key (Taxation Without Representation Mode)
    if player:HasItem(800086) then return end

    local accountId = player:GetAccountId()

    if event == 3 then
        RetroactivelySeedAccountMoneyIfMissing(accountId)

        -- Delay to let account seeding settle
        player:RegisterEvent(function(_, _, _, player)
            AUtils.markPrimaryOnLogin(player)
            AUtils.noteLogin(player)

            SyncCharacterMoneyOnLogin(player, accountId)
            lastSyncedMoney[player:GetGUIDLow()] = player:GetCoinage() or 0

            if ENABLE_REALTIME_TICK then
                if AUtils.shouldDoDownsync(player) then
                    StartRealtimeTimer(player)
                elseif ENABLE_ALTBOT_REALTIME_TICK then
                    StartRealtimeTimer(player)
                end
            end
        end, 1000, 1)

        if ANNOUNCE_ON_LOGIN then
            player:SendBroadcastMessage(ANNOUNCEMENT)
        end
    elseif event == 25 then
        local guid = player:GetGUIDLow()

        FlushMoneyDelta(player, accountId, guid, true)
        MaybeWarnNearGoldCap(player)
    end
end

local function CleanUpMoneyOnLogout(event, player)
    local guid = player:GetGUIDLow()
    local accountId = player:GetAccountId()

    if lastSyncedMoney[guid] == nil then
        lastSyncedMoney[guid] = player:GetCoinage() or 0
    end

    AUtils.noteLogout(accountId, guid)
    FlushMoneyDelta(player, accountId, guid, false)
    AUtils.clearPrimaryOnLogout(player)

    player:RegisterEvent(function()
        lastSyncedMoney[guid] = nil
        lastFlushAt[guid] = nil
    end, 500, 1)
end

local function FormatMoney(copper)
    local gold = math.floor(copper / 10000)
    local silver = math.floor((copper % 10000) / 100)
    local copper = copper % 100
    return string.format("%dg %ds %dc", gold, silver, copper)
end

local function HandleAccountBalance(player)
    -- Always skip RNDbots
    if AUtils.shouldSkipAll and AUtils.shouldSkipAll(player) then return false end

    local accountId = player:GetAccountId()
    local accountTotal = GetTotalAccountMoney(accountId) or 0
    local charMoney = player:GetCoinage() or 0

    player:SendBroadcastMessage(" ")
    player:SendBroadcastMessage("|cFF00B0E8AccountWide Money|r")
    player:SendBroadcastMessage("   Account Bank:  |cffffd000" .. FormatMoney(accountTotal) .. "|r")
    player:SendBroadcastMessage("   Character:         |cffffd000" .. FormatMoney(charMoney) .. "|r")

    return false
end

RegisterPlayerEvent(42, function(_, player, msg)
    msg = msg:lower()
    if msg == "accountbalance" or msg == "accountmoney" or msg == "accountbank" then
        return HandleAccountBalance(player)
    end

    return true
end)

RegisterPlayerEvent(3, AccountMoney) -- PLAYER_EVENT_ON_LOGIN
RegisterPlayerEvent(4, CleanUpMoneyOnLogout) -- PLAYER_EVENT_ON_LOGOUT
RegisterPlayerEvent(25, AccountMoney) -- EVENT_ON_SAVE
