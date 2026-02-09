-- ---------------------------------------------------------------------------------------------
-- ACCOUNTWIDE MOUNTS CONFIG
--
-- Hosted by Aldori15 on Github: https://github.com/Aldori15/azerothcore-lua-accountwide
------------------------------------------------------------------------------------------------

local ENABLE_ACCOUNTWIDE_MOUNTS = false

local ANNOUNCE_ON_LOGIN = false
local ANNOUNCEMENT = "This server is running the |cFF00B0E8AccountWide Mounts |rlua script."

local MIN_MOUNT_LEVEL = 11  -- Minimum character level before mounts are learned

local RETROACTIVE_NOTIFY = true
local RETROACTIVE_DELAY_MS = 150

------------------------------------------------------------------------------------------------
-- END CONFIG
------------------------------------------------------------------------------------------------

if not ENABLE_ACCOUNTWIDE_MOUNTS then return end

local AUtils = AccountWideUtils

local accountMountCache = {}
local backfillDone = {}

local function csvInt(list)
    local out = {}
    for i = 1, #list do 
        out[i] = tostring(list[i])
    end
    return table.concat(out, ",")
end

-- Build mount spell list dynamically
-- class=15 subclass=5 (mount), spellid_1 is learning spell (483/55884), spellid_2 is the mount spell.
local MOUNT_ID_SET, uniq_list = {}, {}
do
    local query = WorldDBQuery([[
        SELECT DISTINCT spellid_2
          FROM item_template
         WHERE class = 15
           AND subclass = 5
           AND spellid_1 IN (483, 55884)
           AND spellid_2 > 0
    ]])

    if query then
        repeat
            local id = query:GetUInt32(0)
            if id and id > 0 then
                MOUNT_ID_SET[id] = true
                uniq_list[#uniq_list+1] = id
            end
        until not query:NextRow()
    end
end

-- cache once at load:
local MOUNT_ID_CSV = (#uniq_list > 0) and csvInt(uniq_list) or "0"

local function InitializeMountTable(accountId)
    -- If already backfilled this session, skip backfill
    if backfillDone[accountId] then return end

    local exists = CharDBQuery(string.format("SELECT 1 FROM accountwide_mounts WHERE accountId = %d LIMIT 1", accountId))
    if exists then 
        backfillDone[accountId] = true
        return
    end

    local sql = string.format([[
        INSERT IGNORE INTO accountwide_mounts (accountId, mountSpellId)
        SELECT c.account, cs.spell
        FROM characters c
        JOIN character_spell cs ON cs.guid = c.guid
        WHERE c.account = %d AND cs.spell IN (%s)
    ]], accountId, MOUNT_ID_CSV)

    CharDBExecute(sql)
    accountMountCache[accountId] = nil
    backfillDone[accountId] = true
    return true
end

local function OnLearnNewMount(event, player, spellID)
    -- Skip playerbot accounts
    if AUtils.shouldSkipAll and AUtils.shouldSkipAll(player) then return end

    local accountId = player:GetAccountId()

    if MOUNT_ID_SET[spellID] then
        CharDBExecute(string.format("INSERT IGNORE INTO accountwide_mounts (accountId, mountSpellId) VALUES (%d, %d)", accountId, spellID))

        -- Keep cache in sync
        if accountMountCache[accountId] then
            accountMountCache[accountId][spellID] = true
        end
    end
end

local function LearnOwnedMountsNow(player, accountId)
    local ownedSet = accountMountCache[accountId]
    if not ownedSet then
        ownedSet = {}
        local owned = CharDBQuery(string.format("SELECT mountSpellId FROM accountwide_mounts WHERE accountId = %d", accountId))
        if owned then
            repeat
                ownedSet[owned:GetUInt32(0)] = true
            until not owned:NextRow()
        end
        accountMountCache[accountId] = ownedSet
    end

    if next(ownedSet) == nil then return end

    -- Learn only those the account owns (and this character doesn't yet have)
    for spellId in pairs(ownedSet) do
        if not player:HasSpell(spellId) then
            player:LearnSpell(spellId)
        end
    end
end

local function SyncMountsToPlayer(event, player)
    -- Skip playerbot accounts
    if AUtils.shouldSkipAll and AUtils.shouldSkipAll(player) then return end

    local accountId = player:GetAccountId()
    local playerLevel = player:GetLevel()

    if (playerLevel < MIN_MOUNT_LEVEL) then return end
    if player:HasItem(90000, 1) then return end -- Hard Mode Key
    if player:HasItem(800048, 1) then return end -- Slow and Steady Key

    if (ANNOUNCE_ON_LOGIN and event) then
        player:SendBroadcastMessage(ANNOUNCEMENT)
    end

    local didBackfill = InitializeMountTable(accountId)
    if didBackfill then
        if RETROACTIVE_NOTIFY then
            player:SendBroadcastMessage("|cff9CC243[Accountwide Mounts] Retroactive sync complete. Learning account mounts...|r")
        end
        player:RegisterEvent(function(_,_,_,p)
            LearnOwnedMountsNow(p, accountId)
        end, RETROACTIVE_DELAY_MS, 1)
    else
        LearnOwnedMountsNow(player, accountId)
    end
end

local function OnSendLearnedSpell(event, packet, player)
    -- Skip playerbot accounts
    if AUtils.shouldSkipAll and AUtils.shouldSkipAll(player) then return end

    local spellId = packet:ReadULong()
    -- Apprentice Riding   Journeyman Riding   Expert Riding       Artisan Riding
    if spellId == 33388 or spellId == 33391 or spellId == 34090 or spellId == 34091 then
        player:RegisterEvent((function(_,_,_,p) SyncMountsToPlayer(nil, p) end), 100, 1)
    end
end

RegisterPlayerEvent(3, SyncMountsToPlayer) -- PLAYER_EVENT_ON_LOGIN
RegisterPlayerEvent(44, OnLearnNewMount) -- PLAYER_EVENT_ON_LEARN_SPELL
RegisterPacketEvent(299, 7, OnSendLearnedSpell) -- PACKET_EVENT_ON_PACKET_SEND (SMSG_LEARNED_SPELL)
RegisterPacketEvent(300, 7, OnSendLearnedSpell) -- PACKET_EVENT_ON_PACKET_SEND (SMSG_SUPERCEDED_SPELL)