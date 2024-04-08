-- ---------------------------------------------------------------------------------------------
-- -- ACCOUNTWIDE ACHIEVEMENTS CONFIG
-- ---------------------------------------------------------------------------------------------

local ENABLE_ACCOUNTWIDE_ACHIEVEMENTS = true
local ANNOUNCE_ON_LOGIN = true
local ANNOUNCEMENT = "This server is running the |cFF00B0E8AccountWide Achievements |rmodule."

local RESTRICT_FACTION = false  -- Set this to true to only share achievements with characters of the same faction.

-- ---------------------------------------------------------------------------------------------
-- -- END CONFIG
-- ---------------------------------------------------------------------------------------------

local function AddMissingAchievements(player, achievements)
    if ENABLE_ACCOUNTWIDE_ACHIEVEMENTS then
        for _, achievementID in ipairs(achievements) do
            player:SetAchievement(achievementID)
        end
    end
end

local function SyncAchievementsOnLogin(event, player)
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

                -- Define races belonging to each faction
                local allianceRaces = {
                    [1] = true,  -- Human
                    [3] = true,  -- Dwarf
                    [4] = true,  -- Night Elf
                    [7] = true,  -- Gnome
                    [11] = true, -- Draenei
                    [12] = true, -- Void Elf
                    [14] = true, -- High Elf
                    [16] = true, -- Worgen
                    [19] = true, -- Lightforged
                    [20] = true, -- Demon Hunter
                }
                local hordeRaces = {
                    [2] = true,  -- Orc
                    [5] = true,  -- Undead
                    [6] = true,  -- Tauren
                    [8] = true,  -- Troll
                    [9] = true,  -- Goblin
                    [10] = true, -- Blood Elf
                    [13] = true, -- Vulpera
                    [15] = true, -- Pandaren
                    [17] = true, -- Man'ari Eredar
                    [21] = true, -- Demon Hunter
                }

                -- Determine if the player's race belongs to Alliance or Horde
                local playerIsAlliance = allianceRaces[charRace]
                local playerIsHorde = hordeRaces[charRace]

                -- Compare with the faction of the player
                if not RESTRICT_FACTION or 
                   (RESTRICT_FACTION and ((player:GetTeam() == 0 and playerIsAlliance) or (player:GetTeam() == 1 and playerIsHorde))) then
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
            AddMissingAchievements(player, achievements)
        end
    end
end

RegisterPlayerEvent(3, SyncAchievementsOnLogin) -- PLAYER_EVENT_ON_LOGIN