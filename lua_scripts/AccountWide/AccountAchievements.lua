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

local function AddMissingAchievements(player, achievementsSet)
    for achievementID, _ in pairs(achievementsSet) do
        if not player:HasAchieved(achievementID) then
            player:SetAchievement(achievementID)
        end
    end
end

local function ExecAchievementsBatch(accountId, valuesBatch)
    if #valuesBatch == 0 then return end
    local sql = string.format([[
        INSERT IGNORE INTO accountwide_achievements (accountId, achievementId)
        VALUES %s
    ]], table.concat(valuesBatch, ", "))

    CharDBExecute(sql)
end

local function SyncCompletedAchievementsOnLogin(event, player)
    local accountId = player:GetAccountId()
    -- Skip playerbot accounts
    if AUtils.isPlayerBotAccount(accountId) then return end

    if ANNOUNCE_ON_LOGIN then
        player:SendBroadcastMessage(ANNOUNCEMENT)
    end

    local achievements = {}

    do
        local query = CharDBQuery(string.format("SELECT achievementId FROM accountwide_achievements WHERE accountId = %d", accountId))
        if query then
            repeat
                local achievementId = query:GetUInt32(0)
                achievements[achievementId] = true
            until not query:NextRow()
        end
    end

    local achQuery = CharDBQuery(string.format([[
        SELECT ca.achievement
        FROM character_achievement AS ca
        WHERE ca.guid IN (SELECT c.guid FROM characters AS c WHERE c.account = %d)
    ]], accountId))

    -- If we discover new achievements from characters, queue them for a single batched insert
    local batch, count = {}, 0
    local BATCH_SIZE = 500

    if achQuery then
        repeat
            local achievementId = achQuery:GetUInt32(0)
            if not achievements[achievementId] then
                achievements[achievementId] = true
                table.insert(batch, string.format("(%d, %d)", accountId, achievementId))
                count = count + 1
                if count >= BATCH_SIZE then
                    ExecAchievementsBatch(accountId, batch)
                    batch = {}
                    count = 0
                end
            end
        until not achQuery:NextRow()
    end

    if count > 0 then
        ExecAchievementsBatch(accountId, batch)
    end

    -- Ensure the logging-in character has all account-wide achievements
    AddMissingAchievements(player, achievements)
end

if ENABLE_ACCOUNTWIDE_COMPLETED_ACHIEVEMENTS then
    RegisterPlayerEvent(3, SyncCompletedAchievementsOnLogin) -- PLAYER_EVENT_ON_LOGIN
end

-- ====================
--  Criteria Progress
-- ====================

local PROGRESS_BATCH_SIZE = 500

-- Batch insert into character_achievement_progress
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

-- Batch insert into accountwide_criteria_max
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

-- Load all progress for the saving character only
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

-- Load cached account maxima only for criteria that changed
local function LoadAccountMaxForCriteria(accountId, criteriaList)
    if #criteriaList == 0 then return {} end
    local criteriaCSV = table.concat(criteriaList, ",")
    local maxByCriteria = {}
    local query = CharDBQuery(string.format([[
        SELECT criteria, counter, date
          FROM accountwide_criteria_max
         WHERE accountId = %d
           AND criteria IN (%s)
    ]], accountId, criteriaCSV))

    if query then
        repeat
            local criteriaId = query:GetUInt32(0)
            local counterValue = query:GetUInt32(1)
            local progressDate = query:GetUInt32(2)
            maxByCriteria[criteriaId] = { counter = counterValue, date = progressDate }
        until not query:NextRow()
    end
    return maxByCriteria
end

-- Compare saver’s progress vs account maxima, update account cache if increased
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

-- Push only the updated criteria to other characters on the account
local function PropagateDeltasToOtherCharacters(accountId, saverGuid, updatedCriteria)
    if next(updatedCriteria) == nil then return end

    -- Get all other characters on the account
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

    -- Build IN lists
    local criteriaList, criteriaCSV = {}, ""
    for criteriaId, _ in pairs(updatedCriteria) do
        table.insert(criteriaList, criteriaId)
    end
    criteriaCSV = table.concat(criteriaList, ",")
    local guidCSV = table.concat(otherCharacterGuids, ",")

    -- Fetch current values for just these criteria and characters
    local currentProgress = {} -- currentProgress[guid][criteria] = counter
    local query = CharDBQuery(string.format([[
        SELECT guid, criteria, counter
          FROM character_achievement_progress
         WHERE guid IN (%s)
           AND criteria IN (%s)
    ]], guidCSV, criteriaCSV))

    if query then
        repeat
            local guid = query:GetUInt32(0)
            local criteriaId = query:GetUInt32(1)
            local counterValue = query:GetUInt32(2)
            if not currentProgress[guid] then currentProgress[guid] = {} end
            currentProgress[guid][criteriaId] = counterValue
        until not query:NextRow()
    end

    -- Apply updates only if the target value is lower
    local batch, count = {}, 0
    for _, targetGuid in ipairs(otherCharacterGuids) do
        local progressByCriteria = currentProgress[targetGuid] or {}
        for criteriaId, updatedRow in pairs(updatedCriteria) do
            local currentValue = progressByCriteria[criteriaId] or 0
            if currentValue < updatedRow.counter then
                batch[#batch+1] = string.format("(%d,%d,%d,%d)", targetGuid, criteriaId, updatedRow.counter, updatedRow.date)
                count = count + 1
                if count >= PROGRESS_BATCH_SIZE then
                    ExecuteCharacterProgressBatch(batch)
                    batch = {}
                    count = 0
                end
            end
        end
    end
    if count > 0 then ExecuteCharacterProgressBatch(batch) end
end

-- On character create: copy account maxima into the new character
local function SyncCriteriaProgressOnCharacterCreate(event, player)
    local accountId = player:GetAccountId()
    -- Skip playerbot accounts
    if AUtils.isPlayerBotAccount(accountId) then return end
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

-- On logout: check saver’s deltas, update account maxima, then push to others
local function SyncCriteriaProgressOnLogout(event, player)
    local accountId = player:GetAccountId()
    -- Skip playerbot accounts
    if AUtils.isPlayerBotAccount(accountId) then return end
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