-- -------------------------------------------------------------------------------------------
-- ACCOUNTWIDE MONEY CONFIG
--
-- Hosted by Aldori15 on Github: https://github.com/Aldori15/azerothcore-lua-accountwide
-- -------------------------------------------------------------------------------------------

-- Master on/off for this script
local ENABLE_ACCOUNTWIDE_MONEY = false

local ANNOUNCE_ON_LOGIN = false
local ANNOUNCEMENT = "This server is running the |cFF00B0E8AccountWide Money|r lua script."

-- ===============================
-- Realtime tick (periodic sync)
-- ===============================
-- Global switch for periodic “tick” updates.
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

local GOLD_SOFT_CAP_COPPER  = 210000 * 10000         -- 210k: where we start diverting to virtual bank
local GOLD_WARNING_THRESHOLD = GOLD_SOFT_CAP_COPPER  -- when to show warning

local function ToLuaNumber(value)
    if type(value) == "userdata" then
        return tonumber(tostring(value))
    end

    return tonumber(value) or 0
end

local function MaybeWarnNearGoldCap(player)
    local money = player:GetCoinage() or 0
    if money >= GOLD_WARNING_THRESHOLD then
        local gold = math.floor(money / 10000)
        local silver = math.floor(money / 100) % 100
        local copper = money % 100

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
        VALUES (%d, %d)
        ON DUPLICATE KEY UPDATE money = GREATEST(0, money + VALUES(money))
    ]], accountId, delta)

    CharDBExecute(sql)
end

local function ClampOverflowToAccount(player, accountId)
    local current = player:GetCoinage() or 0
    if current > GOLD_SOFT_CAP_COPPER then
        local overflow = current - GOLD_SOFT_CAP_COPPER

        -- Put the overflow into the virtual bank
        AddDeltaToAccountMoney(accountId, overflow)
        player:ModifyMoney(-overflow)

        return GOLD_SOFT_CAP_COPPER, overflow
    end

    return current, 0
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
            -- Character somehow has more than the account bank: trim down to match bank
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
    -- Never let realtime tick leave a character over the soft cap
    if current > GOLD_SOFT_CAP_COPPER then
        local overflow = current - GOLD_SOFT_CAP_COPPER
        AddDeltaToAccountMoney(accountId, overflow)
        player:ModifyMoney(-overflow)
        current = GOLD_SOFT_CAP_COPPER
    end

    local baseline = lastSyncedMoney[guid]
    if baseline == nil then
        lastSyncedMoney[guid] = current -- first tick, establish baseline
        return
    end

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

    local now = GetMSTime and GetMSTime() or (os.time() * 1000)
    local jp  = justPushedAt[guid] or 0
    if pushed or (now - jp) < 1 then
        -- we either pushed in this tick, or timestamp says "just pushed"
        return
    end

    local accountTotal = GetTotalAccountMoney(accountId)
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

	-- Unfair Taxes Key (Taxation Without Representation Mode)
    if player:HasItem(800086) then return end

    if event == 3 then
        local seeded = RetroactivelySeedAccountMoneyIfMissing(accountId)

        -- Delay to let account seeding settle, then do safe login sync and start the realtime tick
        player:RegisterEvent(function(_, _, _, player)
            AUtils.markPrimaryOnLogin(player)

            if seeded then
                -- If we seeded a new account row, sync again so no relog is needed
                SyncCharacterMoneyOnLogin(player, accountId)
            end

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
        local currentMoney = player:GetCoinage() or 0

        -- Enforce the soft cap and push any overflow to the bank
        if currentMoney > GOLD_SOFT_CAP_COPPER then
            local overflow = currentMoney - GOLD_SOFT_CAP_COPPER
            AddDeltaToAccountMoney(accountId, overflow)
            player:ModifyMoney(-overflow)
            currentMoney = GOLD_SOFT_CAP_COPPER
        end

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

        MaybeWarnNearGoldCap(player)
    end
end

local function CleanUpMoneyOnLogout(event, player)
    local guid = player:GetGUIDLow()
    local accountId = player:GetAccountId()

    local current = player:GetCoinage() or 0
    local baseline = lastSyncedMoney[guid]

    if current > GOLD_SOFT_CAP_COPPER then
        local overflow = current - GOLD_SOFT_CAP_COPPER
        AddDeltaToAccountMoney(accountId, overflow)
        player:ModifyMoney(-overflow)
        current = GOLD_SOFT_CAP_COPPER
    end

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

local function FormatMoney(copper)
    local gold = math.floor(copper / 10000)
    local silver = math.floor((copper % 10000) / 100)
    local copper = copper % 100
    return string.format("%dg %ds %dc", gold, silver, copper)
end

local function HandleAccountBalance(player, command)
    local accountId = player:GetAccountId()

    -- Skip RNDbots completely
    if AUtils.shouldSkipAll and AUtils.shouldSkipAll(player) then return false end

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
        return HandleAccountBalance(player, msg)
    end

    return true
end)

RegisterPlayerEvent(3, AccountMoney) -- PLAYER_EVENT_ON_LOGIN
RegisterPlayerEvent(4, CleanUpMoneyOnLogout) -- PLAYER_EVENT_ON_LOGOUT
RegisterPlayerEvent(25, AccountMoney) -- EVENT_ON_SAVE
