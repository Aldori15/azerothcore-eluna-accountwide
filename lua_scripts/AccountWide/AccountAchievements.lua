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

local function CollectAccountWideCriteriaProgress(accountId)
    local criteriaProgress = {}
    local characterGuids = {}

    -- Collect all character GUIDs for the account
    local charQuery = CharDBQuery(string.format("SELECT guid FROM characters WHERE account = %d", accountId))
    if charQuery then
        repeat
            local guid = charQuery:GetUInt32(0)
            table.insert(characterGuids, guid)
        until not charQuery:NextRow()
    end

    local progressQuery = CharDBQuery(string.format([[
        SELECT guid, criteria, counter, date
        FROM character_achievement_progress
        WHERE guid IN (SELECT guid FROM characters WHERE account = %d)
    ]], accountId))

    if progressQuery then
        repeat
            local guid = progressQuery:GetUInt32(0)
            local criteria = progressQuery:GetUInt32(1)
            local counter = progressQuery:GetUInt32(2)
            local date = progressQuery:GetUInt32(3)

            local existing = criteriaProgress[criteria]
            if not existing or existing.counter < counter then
                criteriaProgress[criteria] = { counter = counter, date = date }
            elseif existing.counter == counter and existing.date < date then
                criteriaProgress[criteria].date = date
            end
        until not progressQuery:NextRow()
    end

    return criteriaProgress, characterGuids
end

local function ExecCriteriaProgressBatch(batchRows)
    if #batchRows == 0 then return end
    local query = [[
        INSERT INTO character_achievement_progress (guid, criteria, counter, date)
        VALUES %s
        ON DUPLICATE KEY UPDATE
            counter = VALUES(counter),
            date    = VALUES(date)
    ]]
    local sql = string.format(query, table.concat(batchRows, ", "))
    CharDBExecute(sql)
end

local function ApplyCriteriaProgressToCharacter(targetGuid, criteriaProgress)
    local batch, count = {}, 0
    local PROGRESS_BATCH_SIZE = 500

    for criteria, data in pairs(criteriaProgress) do
        local counter = tonumber(data.counter) or 0
        local date = tonumber(data.date) or 0

        table.insert(batch, string.format("(%d, %d, %d, %d)", targetGuid, criteria, counter, date))
        count = count + 1

        if count >= PROGRESS_BATCH_SIZE then
            ExecCriteriaProgressBatch(batch)
            batch = {}
            count = 0
        end
    end

    if count > 0 then
        ExecCriteriaProgressBatch(batch)
    end
end

local function SyncCriteriaProgressForNewCharacter(event, player)
    local accountId = player:GetAccountId()
    -- Skip playerbot accounts
    if AUtils.isPlayerBotAccount(accountId) then return end

    local newCharacterGuid = player:GetGUIDLow()
    local criteriaProgress = CollectAccountWideCriteriaProgress(accountId)

    ApplyCriteriaProgressToCharacter(newCharacterGuid, criteriaProgress)
end

local function SyncCriteriaProgressOnSave(event, player)
    local accountId = player:GetAccountId()
    local currentGuid = player:GetGUIDLow()
    -- Skip playerbot accounts
    if AUtils.isPlayerBotAccount(accountId) then return end

    -- Delay to let character data finish saving to DB before syncing to other characters
    CreateLuaEvent(function()
        local criteriaProgress, characterGuids = CollectAccountWideCriteriaProgress(accountId)

        -- Apply to all characters on the account
        for _, guid in ipairs(characterGuids) do
            if guid ~= currentGuid then
                ApplyCriteriaProgressToCharacter(guid, criteriaProgress)
            end
        end
    end, 1000, 1)
end

if ENABLE_ACCOUNTWIDE_COMPLETED_ACHIEVEMENTS then
    RegisterPlayerEvent(3, SyncCompletedAchievementsOnLogin) -- PLAYER_EVENT_ON_LOGIN
end

if ENABLE_ACCOUNTWIDE_CRITERIA_PROGRESS then
    RegisterPlayerEvent(1, SyncCriteriaProgressForNewCharacter) -- PLAYER_EVENT_ON_CHARACTER_CREATE
    RegisterPlayerEvent(25, SyncCriteriaProgressOnSave)     -- PLAYER_EVENT_ON_SAVE
end