-- ---------------------------------------------------------------------------------------------
-- ACCOUNTWIDE ACHIEVEMENTS CONFIG
--
-- Hosted by Aldori15 on Github: https://github.com/Aldori15/azerothcore-lua-accountwide
-- ---------------------------------------------------------------------------------------------

local ENABLE_ACCOUNTWIDE_COMPLETED_ACHIEVEMENTS = false
local ENABLE_ACCOUNTWIDE_CRITERIA_PROGRESS = false

local ANNOUNCE_ON_LOGIN = false
local ANNOUNCEMENT = "This server is running the |cFF00B0E8AccountWide Achievements |rlua script."

-- ---------------------------------------------------------------------------------------------
-- END CONFIG
-- ---------------------------------------------------------------------------------------------

local AUtils = AccountWideUtils

local completedAchievementsCache = {}
local completedAchievementsLoaded = {}
local completedAchievementsSeedAttempted = {}

local function GetCompletedAchievementsForAccount(accountId)
    if completedAchievementsLoaded[accountId] then
        return completedAchievementsCache[accountId]
    end

    local achievements = {}
    local query = CharDBQuery(string.format("SELECT achievementId FROM accountwide_achievements WHERE accountId = %d", accountId))

    if query then
        repeat
            local achievementId = query:GetUInt32(0)
            achievements[achievementId] = true
        until not query:NextRow()
    end

    completedAchievementsCache[accountId] = achievements
    completedAchievementsLoaded[accountId] = true
    return achievements
end

local function MarkCompletedAchievementCached(accountId, achievementId)
    if not completedAchievementsLoaded[accountId] then return end
    local achievements = completedAchievementsCache[accountId]
    if not achievements then return end
    achievements[achievementId] = true
end

local function AddMissingAchievements(player, achievementsSet)
    for achievementID, _ in pairs(achievementsSet) do
        if not player:HasAchieved(achievementID) then
            player:SetAchievement(achievementID)
        end
    end
end

local function SyncCompletedAchievementsOnLogin(event, player)
    -- Skip playerbot accounts
    if AUtils.shouldSkipAll and AUtils.shouldSkipAll(player) then return end

    local accountId = player:GetAccountId()

    if ANNOUNCE_ON_LOGIN then
        player:SendBroadcastMessage(ANNOUNCEMENT)
    end

    local achievements = GetCompletedAchievementsForAccount(accountId)

    local isAnchor = (AUtils.shouldDoDownsync and AUtils.shouldDoDownsync(player)) or false
    if isAnchor then
        -- if this account has no rows yet, read directly from character achievements
        if next(achievements) == nil and not completedAchievementsSeedAttempted[accountId] then
            completedAchievementsSeedAttempted[accountId] = true

            -- Seed accountwide table once for this account.
            CharDBExecute(string.format([[
                INSERT IGNORE INTO accountwide_achievements (accountId, achievementId)
                SELECT DISTINCT %d, ca.achievement
                FROM character_achievement AS ca
                JOIN characters AS c ON c.guid = ca.guid
                WHERE c.account = %d
            ]], accountId, accountId))

            local query = CharDBQuery(string.format([[
                SELECT DISTINCT ca.achievement
                FROM character_achievement AS ca
                JOIN characters AS c ON c.guid = ca.guid
                WHERE c.account = %d
            ]], accountId))

            if query then
                repeat
                    achievements[query:GetUInt32(0)] = true
                until not query:NextRow()
            end
        end
    end

    -- Ensure the logging in character has all accountwide achievements
    AddMissingAchievements(player, achievements)
end

local function SyncCompletedAchievementOnEarn(event, player, achievement)
    -- Skip playerbot accounts
    if AUtils.shouldSkipAll and AUtils.shouldSkipAll(player) then return end
    if not achievement then return end

    local achievementId = achievement:GetId()
    if not achievementId then return end

    local accountId = player:GetAccountId()
    CharDBExecute(string.format([[
        INSERT IGNORE INTO accountwide_achievements (accountId, achievementId)
        VALUES (%d, %d)
    ]], accountId, achievementId))
    MarkCompletedAchievementCached(accountId, achievementId)
end

if ENABLE_ACCOUNTWIDE_COMPLETED_ACHIEVEMENTS then
    RegisterPlayerEvent(3, SyncCompletedAchievementsOnLogin) -- PLAYER_EVENT_ON_LOGIN
    RegisterPlayerEvent(45, SyncCompletedAchievementOnEarn) -- PLAYER_EVENT_ON_ACHIEVEMENT_COMPLETE
end

-- ====================
--  Criteria Progress
-- ====================

local PROGRESS_BATCH_SIZE = 500

local function ExecuteCharacterProgressBatch(batchRows)
    if #batchRows == 0 then return end
    CharDBExecute([[
        INSERT INTO character_achievement_progress (guid, criteria, counter, date)
        VALUES ]] .. table.concat(batchRows, ", ") .. [[
        ON DUPLICATE KEY UPDATE
            counter = IF(VALUES(counter) > counter, VALUES(counter), counter),
            date = IF(VALUES(counter) > counter, VALUES(date), GREATEST(date, VALUES(date)))
    ]])
end

local function ExecuteCharacterProgressBatchIfCounterHigher(batchRows)
    if #batchRows == 0 then return end
    CharDBExecute([[
        INSERT INTO character_achievement_progress (guid, criteria, counter, date)
        VALUES ]] .. table.concat(batchRows, ", ") .. [[
        ON DUPLICATE KEY UPDATE
            counter = IF(VALUES(counter) > counter, VALUES(counter), counter),
            date = IF(VALUES(counter) > counter, VALUES(date), date)
    ]])
end

local function ExecuteAccountMaxBatch(batchRows)
    if #batchRows == 0 then return end
    CharDBExecute([[
        INSERT INTO accountwide_criteria_max (accountId, criteria, counter, date)
        VALUES ]] .. table.concat(batchRows, ", ") .. [[
        ON DUPLICATE KEY UPDATE
            counter = IF(VALUES(counter) > counter, VALUES(counter), counter),
            date = IF(VALUES(counter) > counter, VALUES(date), GREATEST(date, VALUES(date)))
    ]])
end

local function LoadCharacterCriteriaProgress(characterGuid)
    local progressByCriteria = {}
    local query = CharDBQuery(string.format([[
        SELECT criteria, counter, date
          FROM character_achievement_progress
         WHERE guid = %d
    ]], characterGuid))

    if query then
        repeat
            local criteriaId = query:GetUInt32(0)
            local counterValue = query:GetUInt32(1)
            local progressDate = query:GetUInt32(2)
            progressByCriteria[criteriaId] = { counter = counterValue, date = progressDate }
        until not query:NextRow()
    end
    return progressByCriteria
end

local function ChunkList(list, chunkSize)
    local chunks = {}
    local i = 1
    while i <= #list do
        local chunk = {}
        for j = i, math.min(i + chunkSize - 1, #list) do
            chunk[#chunk+1] = list[j]
        end
        chunks[#chunks+1] = chunk
        i = i + chunkSize
    end
    return chunks
end

local function LoadAccountMaxForCriteria(accountId, criteriaList)
    if #criteriaList == 0 then return {} end

    local maxByCriteria = {}
    for _, chunk in ipairs(ChunkList(criteriaList, 800)) do
        local csv = table.concat(chunk, ",")
        local query = CharDBQuery(string.format([[
            SELECT criteria, counter, date
              FROM accountwide_criteria_max
             WHERE accountId = %d
               AND criteria IN (%s)
        ]], accountId, csv))

        if query then
            repeat
                local criteriaId = query:GetUInt32(0)
                local counterValue = query:GetUInt32(1)
                local progressDate = query:GetUInt32(2)
                maxByCriteria[criteriaId] = { counter = counterValue, date = progressDate }
            until not query:NextRow()
        end
    end

    return maxByCriteria
end

-- Compare saver’s progress vs account, update account cache if increased
local function ComputeDeltasAndUpdateAccountMax(accountId, saverProgress)
    local criteriaList = {}
    for criteriaId, _ in pairs(saverProgress) do
        table.insert(criteriaList, criteriaId)
    end
    if #criteriaList == 0 then return {} end

    local currentMaxByCriteria = LoadAccountMaxForCriteria(accountId, criteriaList)
    local updatedCriteria = {}
    local batch, count = {}, 0

    for criteriaId, progress in pairs(saverProgress) do
        local shouldUpdate = false
        local current = currentMaxByCriteria[criteriaId]

        if not current then
            shouldUpdate = true
        elseif progress.counter > current.counter then
            shouldUpdate = true
        elseif progress.counter == current.counter and progress.date > current.date then
            shouldUpdate = true
        end

        if shouldUpdate then
            updatedCriteria[criteriaId] = { counter = progress.counter, date = progress.date }
            batch[#batch+1] = string.format("(%d,%d,%d,%d)", accountId, criteriaId, progress.counter, progress.date)
            count = count + 1

            if count >= PROGRESS_BATCH_SIZE then
                ExecuteAccountMaxBatch(batch)
                batch = {}
                count = 0
            end
        end
    end

    if count > 0 then ExecuteAccountMaxBatch(batch) end
    return updatedCriteria
end

local function PropagateDeltasToOtherCharacters(accountId, saverGuid, updatedCriteria)
    if next(updatedCriteria) == nil then return end

    local otherCharacterGuids = {}
    local characterQuery = CharDBQuery(string.format("SELECT guid FROM characters WHERE account = %d", accountId))
    if characterQuery then
        repeat
            local guid = characterQuery:GetUInt32(0)
            if guid ~= saverGuid then
                otherCharacterGuids[#otherCharacterGuids+1] = guid
            end
        until not characterQuery:NextRow()
    end
    if #otherCharacterGuids == 0 then return end

    -- Upsert directly and let SQL only apply when incoming counter is higher.
    local batch, count = {}, 0
    for _, targetGuid in ipairs(otherCharacterGuids) do
        for criteriaId, updatedRow in pairs(updatedCriteria) do
            batch[#batch+1] = string.format("(%d,%d,%d,%d)", targetGuid, criteriaId, updatedRow.counter, updatedRow.date)
            count = count + 1
            if count >= PROGRESS_BATCH_SIZE then
                ExecuteCharacterProgressBatchIfCounterHigher(batch)
                batch = {}
                count = 0
            end
        end
    end
    if count > 0 then ExecuteCharacterProgressBatchIfCounterHigher(batch) end
end

local function SyncCriteriaProgressOnCharacterCreate(event, player)
    -- Skip playerbot accounts
    if AUtils.shouldSkipAll and AUtils.shouldSkipAll(player) then return end

    local accountId = player:GetAccountId()
    local newCharacterGuid = player:GetGUIDLow()

    local query = CharDBQuery(string.format([[
        SELECT criteria, counter, date
          FROM accountwide_criteria_max
         WHERE accountId = %d
    ]], accountId))

    if not query then return end

    local batch, count = {}, 0
    repeat
        local criteriaId = query:GetUInt32(0)
        local counterValue = query:GetUInt32(1)
        local progressDate = query:GetUInt32(2)
        batch[#batch+1] = string.format("(%d,%d,%d,%d)", newCharacterGuid, criteriaId, counterValue, progressDate)
        count = count + 1
        if count >= PROGRESS_BATCH_SIZE then
            ExecuteCharacterProgressBatch(batch)
            batch = {}
            count = 0
        end
    until not query:NextRow()
    if count > 0 then ExecuteCharacterProgressBatch(batch) end
end

local function SyncCriteriaProgressOnLogout(event, player)
    -- Skip playerbot accounts
    if AUtils.shouldSkipAll and AUtils.shouldSkipAll(player) then return end

    local accountId = player:GetAccountId()
    local saverGuid = player:GetGUIDLow()

    -- slight delay to let the core flush the saver’s own rows first
    CreateLuaEvent(function()
        local saverProgress = LoadCharacterCriteriaProgress(saverGuid)
        local updatedCriteria = ComputeDeltasAndUpdateAccountMax(accountId, saverProgress)
        PropagateDeltasToOtherCharacters(accountId, saverGuid, updatedCriteria)
    end, 1000, 1)
end

if ENABLE_ACCOUNTWIDE_CRITERIA_PROGRESS then
    RegisterPlayerEvent(1, SyncCriteriaProgressOnCharacterCreate) -- PLAYER_EVENT_ON_CHARACTER_CREATE
    RegisterPlayerEvent(4, SyncCriteriaProgressOnLogout) -- PLAYER_EVENT_ON_LOGOUT
end