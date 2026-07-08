-- ----------------------------------------------------------------------------------------------
-- ACCOUNTWIDE PROFESSIONS CONFIG
-- Hosted by Aldori15 on Github: https://github.com/Aldori15/azerothcore-lua-accountwide
-- ----------------------------------------------------------------------------------------------

local ENABLE_ACCOUNTWIDE_PROFESSIONS = false

-- Primary profession sync limit. Secondary professions do not count toward this limit.
local MAX_PRIMARY_PROFESSIONS = 11
-- Cooking, First Aid, and Fishing. Set false to sync only primary professions.
local INCLUDE_SECONDARY_PROFESSIONS = true
-- Sync profession recipe spells/patterns/plans after the character has the required profession skill.
-- Requires accountwide_profession_recipe_lookup.sql to be imported.
local SYNC_PROFESSION_RECIPES = true

local ANNOUNCE_ON_LOGIN = false
local ANNOUNCEMENT = "This server is running the |cFF00B0E8AccountWide Professions |rlua script."

local RETROACTIVE_NOTIFY = true
local RETROACTIVE_DELAY_MS = 150

-- ----------------------------------------------------------------------------------------------
-- END CONFIG
-- ----------------------------------------------------------------------------------------------

if not ENABLE_ACCOUNTWIDE_PROFESSIONS then return end

local AUtils = AccountWideUtils
if not AUtils then
    print("[AccountWide] Missing 00_AccountWideUtils.lua; disabling AccountWide Professions.")
    return
end

-- ----------------------------------------------------------------------------------------------
-- Profession Skill IDs
-- ----------------------------------------------------------------------------------------------
local PRIMARY_PROFESSION_IDS = {
    164, 165, 171, 182, 186, 197, 202, 333, 393, 755, 773
}

local SECONDARY_PROFESSION_IDS = {
    129, 185, 356
}

local PRIMARY_PROFESSION_SET = {}
for _, skillId in ipairs(PRIMARY_PROFESSION_IDS) do
    PRIMARY_PROFESSION_SET[skillId] = true
end

local SECONDARY_PROFESSION_SET = {}
for _, skillId in ipairs(SECONDARY_PROFESSION_IDS) do
    SECONDARY_PROFESSION_SET[skillId] = true
end

local PROFESSION_IDS = {}
for _, skillId in ipairs(PRIMARY_PROFESSION_IDS) do
    PROFESSION_IDS[#PROFESSION_IDS + 1] = skillId
end

if INCLUDE_SECONDARY_PROFESSIONS then
    for _, skillId in ipairs(SECONDARY_PROFESSION_IDS) do
        PROFESSION_IDS[#PROFESSION_IDS + 1] = skillId
    end
end

table.sort(PROFESSION_IDS)

local PROFESSION_ID_CSV = AUtils.csv(PROFESSION_IDS)

local maxPrimaryProfessionCache

local function GetMaxPrimaryProfessions()
    if maxPrimaryProfessionCache then return maxPrimaryProfessionCache end

    local maxPrimary = tonumber(MAX_PRIMARY_PROFESSIONS) or #PRIMARY_PROFESSION_IDS

    maxPrimary = math.floor(maxPrimary)
    if maxPrimary < 0 then
        maxPrimary = 0
    elseif maxPrimary > #PRIMARY_PROFESSION_IDS then
        maxPrimary = #PRIMARY_PROFESSION_IDS
    end

    maxPrimaryProfessionCache = maxPrimary
    return maxPrimaryProfessionCache
end

local function ApplyPrimaryProfessionLimit(professions)
    local maxPrimary = GetMaxPrimaryProfessions()
    if maxPrimary >= #PRIMARY_PROFESSION_IDS then return professions end

    local primaryRows = {}
    local filtered = {}

    for skillId, row in pairs(professions) do
        if PRIMARY_PROFESSION_SET[skillId] then
            primaryRows[#primaryRows + 1] = {
                skillId = skillId,
                currentVal = row.currentVal,
                maxVal = row.maxVal,
                row = row
            }
        elseif SECONDARY_PROFESSION_SET[skillId] then
            filtered[skillId] = row
        end
    end

    table.sort(primaryRows, function(a, b)
        if a.currentVal ~= b.currentVal then return a.currentVal > b.currentVal end
        if a.maxVal ~= b.maxVal then return a.maxVal > b.maxVal end
        return a.skillId < b.skillId
    end)

    for i = 1, math.min(maxPrimary, #primaryRows) do
        local entry = primaryRows[i]
        filtered[entry.skillId] = entry.row
    end

    return filtered
end

-- ----------------------------------------------------------------------------------------------
-- Mapping of Rank-Up Spells per Profession
-- Used to teach all required rank spells on login sync
-- ----------------------------------------------------------------------------------------------
local PROFESSION_RANK_SPELLS = {
    [129] = {3273, 3274, 7924, 10846, 27028, 45542},               -- First Aid
    [164] = {2018, 3100, 3538, 9785, 29844, 51300},                -- Blacksmithing
    [165] = {2108, 3104, 3811, 10662, 32549, 51302},               -- Leatherworking
    [171] = {2259, 3101, 3464, 11611, 28596, 51304},               -- Alchemy
    [182] = {2366, 2368, 3570, 11993, 28695, 50300},               -- Herbalism
    [185] = {2550, 3102, 3413, 18260, 33359, 51296},               -- Cooking
    [186] = {2575, 2576, 3564, 10248, 29354, 50310},               -- Mining
    [197] = {3908, 3909, 3910, 12180, 26790, 51309},               -- Tailoring
    [202] = {4036, 4037, 4038, 12656, 30350, 51306},               -- Engineering
    [333] = {7411, 7412, 7413, 13920, 28029, 51313},               -- Enchanting
    [356] = {7620, 7731, 7732, 18248, 33095, 51294, 62734, 63275}, -- Fishing
    [393] = {8613, 8617, 8618, 10768, 32678, 50305},               -- Skinning
    [755] = {25229, 25230, 28894, 28895, 28897, 51311},            -- Jewelcrafting
    [773] = {45357, 45358, 45359, 45360, 45361, 45363}             -- Inscription
}

-- Flatten all rank spells for lookup
local ALL_PROF_RANK_SPELLS = {}
for _, list in pairs(PROFESSION_RANK_SPELLS) do
    for _, spellId in ipairs(list) do
        ALL_PROF_RANK_SPELLS[spellId] = true
    end
end

local function GetBestRankSpell(skillId, maxValue)
    local spells = PROFESSION_RANK_SPELLS[skillId]
    if not spells then return nil end

    local index = 1
    if maxValue > 375 then
        index = 6
    elseif maxValue > 300 then
        index = 5
    elseif maxValue > 225 then
        index = 4
    elseif maxValue > 150 then
        index = 3
    elseif maxValue > 75 then
        index = 2
    end

    return spells[index]
end

local function GetSkillStep(maxValue)
    if maxValue > 375 then
        return 6
    elseif maxValue > 300 then
        return 5
    elseif maxValue > 225 then
        return 4
    elseif maxValue > 150 then
        return 3
    elseif maxValue > 75 then
        return 2
    end

    return 1
end

local function GetStoredSkillValue(player, skillId)
    if player.GetPureSkillValue then
        return player:GetPureSkillValue(skillId) or 0
    end

    return player:GetSkillValue(skillId) or 0
end

local function GetStoredMaxSkillValue(player, skillId)
    if player.GetPureMaxSkillValue then
        return player:GetPureMaxSkillValue(skillId) or 0
    end

    return player:GetMaxSkillValue(skillId) or 0
end

local function IsDownsyncAllowed(player)
    return not AUtils.shouldDoDownsync or AUtils.shouldDoDownsync(player)
end

local professionRecipeSpellSet = {}
local professionRecipeSpellChunks = {}

local function LoadProfessionRecipeSpellLookup()
    if not SYNC_PROFESSION_RECIPES then return end

    local ids = {}
    local query = CharDBQuery([[
        SELECT professionId, spellId, minSkillLineRank, raceMask, classMask
          FROM accountwide_profession_recipe_lookup
         WHERE professionId IN (]] .. PROFESSION_ID_CSV .. [[)
    ]])

    if query then
        repeat
            local professionId = query:GetUInt32(0)
            local spellId = query:GetUInt32(1)
            if not ALL_PROF_RANK_SPELLS[spellId] and not professionRecipeSpellSet[spellId] then
                professionRecipeSpellSet[spellId] = {
                    professionId = professionId,
                    minSkillLineRank = query:GetUInt32(2),
                    raceMask = query:GetUInt32(3),
                    classMask = query:GetUInt32(4)
                }
                ids[#ids + 1] = spellId
            end
        until not query:NextRow()
    end

    table.sort(ids)
    professionRecipeSpellChunks = AUtils.chunkList(ids, 500)

    if #ids == 0 then
        print("[AccountWide] Profession recipe lookup is empty. Import accountwide_profession_recipe_lookup.sql for recipe sync.")
    end
end

LoadProfessionRecipeSpellLookup()

local seededAccountCache = {}
local accountProfessionCache = {}
local accountRecipeCache = {}
local professionSyncInProgress = {}

local function ClearAccountCache(accountId)
    accountProfessionCache[accountId] = nil
    accountRecipeCache[accountId] = nil
end

local function LoadAccountProfessions(accountId)
    local cached = accountProfessionCache[accountId]
    if cached then return cached end

    local professions = {}
    local query = CharDBQuery(string.format([[
        SELECT professionId, currentVal, maxVal
          FROM accountwide_professions
         WHERE accountId = %d
           AND professionId IN (%s)
    ]], accountId, PROFESSION_ID_CSV))

    if query then
        repeat
            local skillId = query:GetUInt32(0)
            professions[skillId] = {
                currentVal = query:GetUInt32(1),
                maxVal = query:GetUInt32(2)
            }
        until not query:NextRow()
    end

    professions = ApplyPrimaryProfessionLimit(professions)
    accountProfessionCache[accountId] = professions
    return professions
end

local function LoadAccountRecipes(accountId)
    if not SYNC_PROFESSION_RECIPES then return {} end

    local cached = accountRecipeCache[accountId]
    if cached then return cached end

    local professions = LoadAccountProfessions(accountId)
    local recipes = {}
    local query = CharDBQuery(string.format([[
        SELECT ar.spellId, rl.professionId, rl.minSkillLineRank, rl.raceMask, rl.classMask
          FROM accountwide_profession_recipes AS ar
          JOIN accountwide_profession_recipe_lookup AS rl ON rl.spellId = ar.spellId
         WHERE ar.accountId = %d
           AND rl.professionId IN (%s)
    ]], accountId, PROFESSION_ID_CSV))
    if query then
        repeat
            local spellId = query:GetUInt32(0)
            local professionId = query:GetUInt32(1)
            if professions[professionId] then
                recipes[spellId] = {
                    professionId = professionId,
                    minSkillLineRank = query:GetUInt32(2),
                    raceMask = query:GetUInt32(3),
                    classMask = query:GetUInt32(4)
                }
            end
        until not query:NextRow()
    end

    accountRecipeCache[accountId] = recipes
    return recipes
end

-- ----------------------------------------------------------------------------------------------
-- Retroactive Account Seed
-- ----------------------------------------------------------------------------------------------
local function SeedAccountProfessionsIfNeeded(accountId)
    if seededAccountCache[accountId] then return false end

    local skillsSeeded = false
    local recipesSeeded = false
    local seedQuery = CharDBQuery(string.format([[
        SELECT skillsSeeded, recipesSeeded
          FROM accountwide_professions_seed
         WHERE accountId = %d
    ]], accountId))

    if seedQuery then
        skillsSeeded = seedQuery:GetUInt32(0) ~= 0
        recipesSeeded = seedQuery:GetUInt32(1) ~= 0
    end

    local didSeed = false

    if not skillsSeeded then
        CharDBExecute(string.format([[
            INSERT INTO accountwide_professions (accountId, professionId, currentVal, maxVal)
            SELECT %d, cs.skill, MAX(cs.value), MAX(cs.max)
              FROM character_skills AS cs
              JOIN characters AS c ON c.guid = cs.guid
             WHERE c.account = %d
               AND cs.skill IN (%s)
             GROUP BY cs.skill
            ON DUPLICATE KEY UPDATE
                currentVal = GREATEST(currentVal, VALUES(currentVal)),
                maxVal = GREATEST(maxVal, VALUES(maxVal))
        ]], accountId, accountId, PROFESSION_ID_CSV))

        skillsSeeded = true
        didSeed = true
    end

    if SYNC_PROFESSION_RECIPES and not recipesSeeded and #professionRecipeSpellChunks > 0 then
        for _, chunk in ipairs(professionRecipeSpellChunks) do
            CharDBExecute(string.format([[
                INSERT IGNORE INTO accountwide_profession_recipes (accountId, spellId)
                SELECT DISTINCT %d, cs.spell
                 FROM character_spell AS cs
                  JOIN characters AS c ON c.guid = cs.guid
                 WHERE c.account = %d
                   AND cs.spell IN (%s)
            ]], accountId, accountId, AUtils.csv(chunk)))
        end

        recipesSeeded = true
        didSeed = true
    end

    CharDBExecute(string.format([[
        INSERT INTO accountwide_professions_seed (accountId, skillsSeeded, recipesSeeded)
        VALUES (%d, %d, %d)
        ON DUPLICATE KEY UPDATE
            skillsSeeded = GREATEST(skillsSeeded, VALUES(skillsSeeded)),
            recipesSeeded = GREATEST(recipesSeeded, VALUES(recipesSeeded))
    ]], accountId, skillsSeeded and 1 or 0, recipesSeeded and 1 or 0))

    seededAccountCache[accountId] = true
    if didSeed then ClearAccountCache(accountId) end
    return didSeed
end

-- ----------------------------------------------------------------------------------------------
-- Downsync
-- ----------------------------------------------------------------------------------------------
local function LearnBestRankSpell(player, skillId, maxVal)
    local spellId = GetBestRankSpell(skillId, maxVal)
    if spellId and not player:HasSpell(spellId) then
        player:LearnSpell(spellId)
    end
end

local function SyncAccountProfessionsToPlayer(player, accountId)
    local professions = LoadAccountProfessions(accountId)
    if next(professions) == nil then return end

    local guid = player:GetGUIDLow()
    professionSyncInProgress[guid] = true

    local ok = pcall(function()
        for skillId, row in pairs(professions) do
            LearnBestRankSpell(player, skillId, row.maxVal)

            if not player:HasSkill(skillId)
                or GetStoredSkillValue(player, skillId) < row.currentVal
                or GetStoredMaxSkillValue(player, skillId) < row.maxVal then
                -- needs this PR to be approved:  https://github.com/azerothcore/mod-ale/pull/391
                player:SetSkill(skillId, GetSkillStep(row.maxVal), row.currentVal, row.maxVal)
                -- if the PR is not approved, then use this as a workaround:
                -- player:SetSkill(skillId, row.maxVal, GetSkillStep(row.maxVal), row.currentVal)
            end
        end
    end)

    professionSyncInProgress[guid] = nil
    if not ok then return end
end

-- ----------------------------------------------------------------------------------------------
-- Recipes
-- ----------------------------------------------------------------------------------------------
local function SyncAccountRecipesToPlayer(player, accountId)
    if not SYNC_PROFESSION_RECIPES then return end

    local recipes = LoadAccountRecipes(accountId)
    if next(recipes) == nil then return end

    local guid = player:GetGUIDLow()
    professionSyncInProgress[guid] = true

    local ok = pcall(function()
        local playerRaceMask = player:GetRaceMask()
        local playerClassMask = player:GetClassMask()

        for spellId, recipe in pairs(recipes) do
            local hasRequiredSkill = player:HasSkill(recipe.professionId)
                and player:GetSkillValue(recipe.professionId) >= recipe.minSkillLineRank
            local raceAllowed = recipe.raceMask == 0 or bit_and(recipe.raceMask, playerRaceMask) > 0
            local classAllowed = recipe.classMask == 0 or bit_and(recipe.classMask, playerClassMask) > 0

            if hasRequiredSkill and raceAllowed and classAllowed and not player:HasSpell(spellId) then
                player:LearnSpell(spellId)
            end
        end
    end)

    professionSyncInProgress[guid] = nil
    if not ok then return end
end

local function StoreLearnedProfessionRecipe(event, player, spellId)
    if AUtils.shouldSkipAll and AUtils.shouldSkipAll(player) then return end
    if not SYNC_PROFESSION_RECIPES then return end
    if not professionRecipeSpellSet[spellId] then return end
    if professionSyncInProgress[player:GetGUIDLow()] then return end

    local accountId = player:GetAccountId()
    CharDBExecute(string.format("INSERT IGNORE INTO accountwide_profession_recipes (accountId, spellId) VALUES (%d, %d)", accountId, spellId))

    local cached = accountRecipeCache[accountId]
    if cached then
        local recipe = professionRecipeSpellSet[spellId]
        local professions = accountProfessionCache[accountId]
        if not professions or professions[recipe.professionId] then
            cached[spellId] = recipe
        end
    end
end

-- ----------------------------------------------------------------------------------------------
-- Upsync
-- ----------------------------------------------------------------------------------------------
local function StorePlayerProfessionSkills(player)
    local accountId = player:GetAccountId()
    local values = {}

    for _, skillId in ipairs(PROFESSION_IDS) do
        if player:HasSkill(skillId) then
            local currentVal = GetStoredSkillValue(player, skillId)
            local maxVal = GetStoredMaxSkillValue(player, skillId)
            if currentVal > 0 and maxVal > 0 then
                values[#values + 1] = string.format("(%d,%d,%d,%d)", accountId, skillId, currentVal, maxVal)

                local cached = accountProfessionCache[accountId]
                if cached then
                    local row = cached[skillId]
                    if not row then
                        cached[skillId] = { currentVal = currentVal, maxVal = maxVal }
                    else
                        row.currentVal = math.max(row.currentVal, currentVal)
                        row.maxVal = math.max(row.maxVal, maxVal)
                    end
                end
            end
        end
    end

    if #values == 0 then return end

    CharDBExecute(string.format([[
        INSERT INTO accountwide_professions (accountId, professionId, currentVal, maxVal)
        VALUES %s
        ON DUPLICATE KEY UPDATE
            currentVal = GREATEST(currentVal, VALUES(currentVal)),
            maxVal = GREATEST(maxVal, VALUES(maxVal))
    ]], table.concat(values, ",")))

    if accountProfessionCache[accountId] then
        accountProfessionCache[accountId] = ApplyPrimaryProfessionLimit(accountProfessionCache[accountId])
        accountRecipeCache[accountId] = nil
    end
end

local function SyncProfessionsOnSave(event, player)
    if AUtils.shouldSkipAll and AUtils.shouldSkipAll(player) then return end
    StorePlayerProfessionSkills(player)
end

local function SyncProfessionsOnLogin(event, player)
    if AUtils.shouldSkipAll and AUtils.shouldSkipAll(player) then return end
    if not IsDownsyncAllowed(player) then return end

    local accountId = player:GetAccountId()

    if ANNOUNCE_ON_LOGIN then
        player:SendBroadcastMessage(ANNOUNCEMENT)
    end

    local didSeed = SeedAccountProfessionsIfNeeded(accountId)
    local function syncNow(_, _, _, p)
        SyncAccountProfessionsToPlayer(p, accountId)
        SyncAccountRecipesToPlayer(p, accountId)
    end

    if didSeed then
        if RETROACTIVE_NOTIFY then
            player:SendBroadcastMessage("|cff9CC243[Accountwide Professions] Retroactive sync complete. Learning account professions...|r")
        end
        player:RegisterEvent(syncNow, RETROACTIVE_DELAY_MS, 1)
    else
        syncNow(nil, nil, nil, player)
    end
end

-- ----------------------------------------------------------------------------------------------
-- Register Events
-- ----------------------------------------------------------------------------------------------
RegisterPlayerEvent(3, SyncProfessionsOnLogin)        -- PLAYER_EVENT_ON_LOGIN
RegisterPlayerEvent(25, SyncProfessionsOnSave)        -- PLAYER_EVENT_ON_SAVE
RegisterPlayerEvent(44, StoreLearnedProfessionRecipe) -- PLAYER_EVENT_ON_LEARN_SPELL
