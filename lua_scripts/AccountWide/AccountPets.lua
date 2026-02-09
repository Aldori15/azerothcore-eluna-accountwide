-- ---------------------------------------------------------------------------------------------
-- ACCOUNTWIDE PETS CONFIG
--
-- Hosted by Aldori15 on Github: https://github.com/Aldori15/azerothcore-lua-accountwide
------------------------------------------------------------------------------------------------

local ENABLE_ACCOUNTWIDE_PETS = false

local ANNOUNCE_ON_LOGIN = false
local ANNOUNCEMENT = "This server is running the |cFF00B0E8AccountWide Pets |rlua script."

local RETROACTIVE_NOTIFY = true
local RETROACTIVE_DELAY_MS = 150

------------------------------------------------------------------------------------------------
-- END CONFIG
------------------------------------------------------------------------------------------------

if not ENABLE_ACCOUNTWIDE_PETS then return end

local AUtils = AccountWideUtils

local accountPetCache = {}
local backfillDone = {}

local function csvInt(list)
    local out = {}
    for i = 1, #list do
        out[i] = tostring(list[i])
    end
    return table.concat(out, ",")
end

-- Build pet spell list dynamically
-- class=15 subclass=2 (pets), spellid_1 is learning spell (483/55884), spellid_2 is the pet spell.
local PET_ID_SET, uniq_pets = {}, {}
do
    local query = WorldDBQuery([[
        SELECT DISTINCT spellid_2
          FROM item_template
         WHERE class = 15
           AND subclass = 2
           AND spellid_1 IN (483, 55884)
           AND spellid_2 > 0
    ]])

    if query then
        repeat
            local id = query:GetUInt32(0)
            if id and id > 0 then
                PET_ID_SET[id] = true
                uniq_pets[#uniq_pets+1] = id
            end
        until not query:NextRow()
    end
end

-- cache once at load:
local PET_ID_CSV = (#uniq_pets > 0) and csvInt(uniq_pets) or "0"

local function InitializePetTable(accountId)
    -- If already backfilled this session, skip backfill
    if backfillDone[accountId] then return end

    local exists = CharDBQuery(string.format("SELECT 1 FROM accountwide_pets WHERE accountId = %d LIMIT 1", accountId))
    if exists then
        backfillDone[accountId] = true
        return
    end

    local sql = string.format([[
        INSERT IGNORE INTO accountwide_pets (accountId, petSpellId)
        SELECT c.account, cs.spell
        FROM characters c
        JOIN character_spell cs ON cs.guid = c.guid
        WHERE c.account = %d AND cs.spell IN (%s)
    ]], accountId, PET_ID_CSV)

    CharDBExecute(sql)
    accountPetCache[accountId] = nil
    backfillDone[accountId] = true
    return true
end

local function OnLearnNewPet(event, player, spellID)
    -- Skip playerbot accounts
    if AUtils.shouldSkipAll and AUtils.shouldSkipAll(player) then return end

    local accountId = player:GetAccountId()

    if PET_ID_SET[spellID] then
        CharDBExecute(string.format("INSERT IGNORE INTO accountwide_pets (accountId, petSpellId) VALUES (%d, %d)", accountId, spellID))

        -- Keep cache in sync
        if accountPetCache[accountId] then
            accountPetCache[accountId][spellID] = true
        end
    end
end

local function LearnOwnedPetsNow(player, accountId)
    local ownedSet = accountPetCache[accountId]
    if not ownedSet then
        ownedSet = {}
        local owned = CharDBQuery(string.format("SELECT petSpellId FROM accountwide_pets WHERE accountId = %d", accountId))
        if owned then
            repeat
                ownedSet[owned:GetUInt32(0)] = true
            until not owned:NextRow()
        end
        accountPetCache[accountId] = ownedSet
    end

    if next(ownedSet) == nil then return end

    -- Learn only those the account owns (and this character doesn't yet have)
    for spellId in pairs(ownedSet) do
        if not player:HasSpell(spellId) then
            player:LearnSpell(spellId)
        end
    end
end

local function SyncPetsToPlayer(event, player)
    -- Skip playerbot accounts
    if AUtils.shouldSkipAll and AUtils.shouldSkipAll(player) then return end

    local accountId = player:GetAccountId()
    
    if (ANNOUNCE_ON_LOGIN and event) then
        player:SendBroadcastMessage(ANNOUNCEMENT)
    end

    local didBackfill = InitializePetTable(accountId)
    if didBackfill then
        if RETROACTIVE_NOTIFY then
            player:SendBroadcastMessage("|cff9CC243[Accountwide Pets] Retroactive sync complete. Learning account pets...|r")
        end

        player:RegisterEvent(function(_,_,_,p)
            LearnOwnedPetsNow(p, accountId)
        end, RETROACTIVE_DELAY_MS, 1)
    else
        LearnOwnedPetsNow(player, accountId)
    end
end

RegisterPlayerEvent(3, SyncPetsToPlayer) -- PLAYER_EVENT_ON_LOGIN
RegisterPlayerEvent(44, OnLearnNewPet) -- PLAYER_EVENT_ON_LEARN_SPELL