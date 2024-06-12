-- ---------------------------------------------------------------------------------------------
-- ACCOUNTWIDE ACHIEVEMENTS CONFIG
--
-- Hosted by Aldori15 on Github: https://github.com/Aldori15/azerothcore-lua-accountwide
-- ---------------------------------------------------------------------------------------------

local ENABLE_ACCOUNTWIDE_ACHIEVEMENTS = false

local ANNOUNCE_ON_LOGIN = true
local ANNOUNCEMENT = "This server is running the |cFF00B0E8AccountWide Achievements |rlua script."

-- ---------------------------------------------------------------------------------------------
-- -- END CONFIG
-- ---------------------------------------------------------------------------------------------

if not ENABLE_ACCOUNTWIDE_ACHIEVEMENTS then return end

local function AddMissingAchievements(player, achievements)
    for _, achievementID in ipairs(achievements) do
        if not player:HasAchieved(achievementID) then
            player:SetAchievement(achievementID)
        end
    end
end

local function SyncAchievementsOnLogin(event, player)
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

    -- Fetch and update new achievements from character_achievement
    local charQuery = CharDBQuery("SELECT guid FROM characters WHERE account = " .. accountId)
    if charQuery then
        repeat
            local charGuid = charQuery:GetUInt32(0)

            local achQuery = CharDBQuery("SELECT achievement FROM character_achievement WHERE guid = " .. charGuid)
            if achQuery then
                repeat
                    local achievementId = achQuery:GetUInt32(0)
                    if not achievements[achievementId] then
                        CharDBExecute("INSERT IGNORE INTO accountwide_achievements (accountId, achievementId) VALUES (" .. accountId .. ", " .. achievementId .. ")")
                        table.insert(achievements, achievementId)
                    end
                until not achQuery:NextRow()
            end
        until not charQuery:NextRow()
    end

    AddMissingAchievements(player, achievements)
end

RegisterPlayerEvent(3, SyncAchievementsOnLogin) -- PLAYER_EVENT_ON_LOGIN