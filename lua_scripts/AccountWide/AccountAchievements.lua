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

local function ExecAccountwideAchBatch(accountId, valuesBatch)
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
                    ExecAccountwideAchBatch(accountId, batch)
                    batch = {}
                    count = 0
                end
            end
        until not achQuery:NextRow()
    end

    if count > 0 then
        ExecAccountwideAchBatch(accountId, batch)
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
            table.insert(characterGuids, charQuery:GetUInt32(0))
        until not charQuery:NextRow()
    end

    -- Collect criteria progress for each character
    for _, charGuid in ipairs(characterGuids) do
        local progressQuery = CharDBQuery(string.format("SELECT criteria, counter, date FROM character_achievement_progress WHERE guid = %d", charGuid))
        if progressQuery then
            repeat
                local criteria = progressQuery:GetUInt32(0)
                local counter = progressQuery:GetUInt32(1)
                local date = progressQuery:GetUInt32(2)

                if not criteriaProgress[criteria] or criteriaProgress[criteria].counter < counter then
                    criteriaProgress[criteria] = { counter = counter, date = date }
                elseif criteriaProgress[criteria].counter == counter and criteriaProgress[criteria].date < date then
                    criteriaProgress[criteria].date = date
                end
            until not progressQuery:NextRow()
        end
    end

    return criteriaProgress, characterGuids
end

local function ExecProgressBatch(batchRows)
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
            ExecProgressBatch(batch)
            batch = {}
            count = 0
        end
    end

    if count > 0 then
        ExecProgressBatch(batch)
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

-- Sync criteria progress on login if the character's progress is not up-to-date
local function SyncCriteriaProgressOnLogin(event, player)
    local accountId = player:GetAccountId()
    -- Skip playerbot accounts
    if AUtils.isPlayerBotAccount(accountId) then return end

    local characterGuid = player:GetGUIDLow()
    local accountWideProgress = CollectAccountWideCriteriaProgress(accountId)

    -- Fetch current character's criteria progress
    local charProgress = {}
    local progressQuery = CharDBQuery(string.format("SELECT criteria, counter, date FROM character_achievement_progress WHERE guid = %d", characterGuid))
    if progressQuery then
        repeat
            local criteria = progressQuery:GetUInt32(0)
            local counter = progressQuery:GetUInt32(1)
            local date = progressQuery:GetUInt32(2)
            charProgress[criteria] = { counter = counter, date = date }
        until not progressQuery:NextRow()
    end

    -- Compare against account data and update if there's a mismatch
    for criteria, accountData in pairs(accountWideProgress) do
        local charData = charProgress[criteria]
        if not charData or charData.counter < accountData.counter or (charData.counter == accountData.counter and charData.date < accountData.date) then
            ApplyCriteriaProgressToCharacter(characterGuid, accountWideProgress)
            break
        end
    end
end

local function SyncCriteriaProgressOnSave(event, player)
    local accountId = player:GetAccountId()
    -- Skip playerbot accounts
    if AUtils.isPlayerBotAccount(accountId) then return end
    
    local criteriaProgress, characterGuids = CollectAccountWideCriteriaProgress(accountId)

    -- Apply to all characters on the account
    for _, charGuid in ipairs(characterGuids) do
        ApplyCriteriaProgressToCharacter(charGuid, criteriaProgress)
    end
end

if ENABLE_ACCOUNTWIDE_COMPLETED_ACHIEVEMENTS then
    RegisterPlayerEvent(3, SyncCompletedAchievementsOnLogin) -- PLAYER_EVENT_ON_LOGIN
end

if ENABLE_ACCOUNTWIDE_CRITERIA_PROGRESS then
    RegisterPlayerEvent(1, SyncCriteriaProgressForNewCharacter) -- PLAYER_EVENT_ON_CHARACTER_CREATE
    RegisterPlayerEvent(3, SyncCriteriaProgressOnLogin)      -- PLAYER_EVENT_ON_LOGIN
    RegisterPlayerEvent(25, SyncCriteriaProgressOnSave)     -- PLAYER_EVENT_ON_SAVE
end