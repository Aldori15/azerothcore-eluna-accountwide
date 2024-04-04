-- ---------------------------------------------------------------------------------------------
-- -- ACCOUNTWIDE ACHIEVEMENTS CONFIG
-- ---------------------------------------------------------------------------------------------

local ENABLE_ACCOUNTWIDE_ACHIEVEMENTS = false
local ANNOUNCE_ON_LOGIN = true
local ANNOUNCEMENT = "This server is running the |cFF00B0E8AccountWide Achievements |rmodule."

local RESTRICT_FACTION = false  -- Set this to true to only share achievements with characters of the same faction.  For factionless, I'd recommend keeping this set to false.

-- ---------------------------------------------------------------------------------------------
-- -- END CONFIG
-- ---------------------------------------------------------------------------------------------

local function AddAchievements(player, achievements)
    if ENABLE_ACCOUNTWIDE_ACHIEVEMENTS then
        for _, achievementID in ipairs(achievements) do
            player:SetAchievement(achievementID)
        end
    end
end

local function CheckAchievementsOnLogin(event, player)
    if ENABLE_ACCOUNTWIDE_ACHIEVEMENTS then
        if ANNOUNCE_ON_LOGIN then
            player:SendBroadcastMessage(ANNOUNCEMENT)
        end

        local accountId = player:GetAccountId()
        local charQuery = CharDBQuery("SELECT guid, race FROM characters WHERE account = "..accountId)

        if charQuery then
            local achievements = {}
            repeat
                local row = charQuery:GetRow()
                local charGuid = row.guid
                local charRace = row.race

                if not RESTRICT_FACTION or (RESTRICT_FACTION and player:GetTeam() == player:GetTeamByRace(charRace)) then
                    local achQuery = CharDBQuery("SELECT achievement FROM character_achievement WHERE guid = "..charGuid)
                    if achQuery then
                        repeat
                            local achievementRow = achQuery:GetRow()
                            local achievementId = achievementRow.achievement
                            table.insert(achievements, achievementId)
                        until not achQuery:NextRow()
                    end
                end
            until not charQuery:NextRow()
            AddAchievements(player, achievements)
        end
    end
end

RegisterPlayerEvent(3, CheckAchievementsOnLogin) -- PLAYER_EVENT_ON_LOGIN