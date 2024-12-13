-- ---------------------------------------------------------------------------------------------
-- ACCOUNTWIDE ACHIEVEMENTS CONFIG
--
-- Hosted by Aldori15 on Github: https://github.com/Aldori15/azerothcore-lua-accountwide
-- ---------------------------------------------------------------------------------------------

local ENABLE_ACCOUNTWIDE_ACHIEVEMENTS = true
local ENABLE_ACCOUNTWIDE_CRITERIA_PROGRESS = true

local ANNOUNCE_ON_LOGIN = true
local ANNOUNCEMENT = "This server is running the |cFF00B0E8AccountWide Achievements |rlua script."

-- ---------------------------------------------------------------------------------------------
-- -- END CONFIG
-- ---------------------------------------------------------------------------------------------

local function AddMissingAchievements(player, achievements)
    for _, achievementID in ipairs(achievements) do
        if not player:HasAchieved(achievementID) then
            player:SetAchievement(achievementID)
        end
    end
end

local function SyncCompletedAchievementsOnLogin(event, player)
    if ANNOUNCE_ON_LOGIN then
        player:SendBroadcastMessage(ANNOUNCEMENT)
    end

    local accountId = player:GetAccountId()

    -- Fetch achievements from accountwide_achievements
    local query = CharDBQuery("SELECT achievementId FROM accountwide_achievements WHERE accountId = " .. accountId)
    local achievements = {}
    if query then
        repeat
            local achievementId = query:GetUInt32(0)
            table.insert(achievements, achievementId)
        until not query:NextRow()
    end

    AddMissingAchievements(player, achievements)
end

local function CollectAccountWideCriteriaProgress(accountId)
    local criteriaProgress = {}
    local characterGuids = {}

    -- Collect all character GUIDs for the account
    local charQuery = CharDBQuery("SELECT guid FROM characters WHERE account = " .. accountId)
    if charQuery then
        repeat
            table.insert(characterGuids, charQuery:GetUInt32(0))
        until not charQuery:NextRow()
    end

    -- Collect criteria progress for each character
    for _, charGuid in ipairs(characterGuids) do
        local progressQuery = CharDBQuery("SELECT criteria, counter, date FROM character_achievement_progress WHERE guid = " .. charGuid)
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

local function ApplyCriteriaProgressToCharacter(targetGuid, criteriaProgress)
    for criteria, data in pairs(criteriaProgress) do
        CharDBExecute(string.format([[
            INSERT INTO character_achievement_progress (guid, criteria, counter, date)
            VALUES (%d, %d, %d, %d)
            ON DUPLICATE KEY UPDATE counter = %d, date = %d
        ]], targetGuid, criteria, data.counter, data.date, data.counter, data.date))
    end
end

local function SyncCriteriaProgressForNewCharacter(event, player)
    local accountId = player:GetAccountId()
    local newCharacterGuid = player:GetGUIDLow()
    local criteriaProgress = CollectAccountWideCriteriaProgress(accountId)

    ApplyCriteriaProgressToCharacter(newCharacterGuid, criteriaProgress)
end

-- Sync criteria progress on login if the character's progress is not up-to-date
local function SyncCriteriaProgressOnLogin(event, player)
    local accountId = player:GetAccountId()
    local characterGuid = player:GetGUIDLow()
    local accountWideProgress = CollectAccountWideCriteriaProgress(accountId)

    -- Fetch current character's criteria progress
    local charProgress = {}
    local progressQuery = CharDBQuery("SELECT criteria, counter, date FROM character_achievement_progress WHERE guid = " .. characterGuid)
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

local function SyncCriteriaProgressOnLogout(event, player)
    local accountId = player:GetAccountId()
    local criteriaProgress, characterGuids = CollectAccountWideCriteriaProgress(accountId)

    -- Apply to all characters on the account
    for _, charGuid in ipairs(characterGuids) do
        ApplyCriteriaProgressToCharacter(charGuid, criteriaProgress)
    end
end

if ENABLE_ACCOUNTWIDE_ACHIEVEMENTS then
    RegisterPlayerEvent(3, SyncCompletedAchievementsOnLogin) -- PLAYER_EVENT_ON_LOGIN
end

if ENABLE_ACCOUNTWIDE_CRITERIA_PROGRESS then
    RegisterPlayerEvent(1, SyncCriteriaProgressForNewCharacter) -- PLAYER_EVENT_ON_CHARACTER_CREATE
    RegisterPlayerEvent(3, SyncCriteriaProgressOnLogin)      -- PLAYER_EVENT_ON_LOGIN
    RegisterPlayerEvent(4, SyncCriteriaProgressOnLogout)     -- PLAYER_EVENT_ON_LOGOUT
end