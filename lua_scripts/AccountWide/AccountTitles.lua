-- ----------------------------------------------------------------------------------------------
-- ACCOUNTWIDE TITLES CONFIG 
--
-- Hosted by Aldori15 on Github: https://github.com/Aldori15/azerothcore-lua-accountwide
-- ----------------------------------------------------------------------------------------------

local ENABLE_ACCOUNTWIDE_TITLES = false

local ANNOUNCE_ON_LOGIN = true
local ANNOUNCEMENT = "This server is running the |cFF00B0E8AccountWide Titles |rlua script."

-- -- -------------------------------------------------------------------------------------------
-- -- END CONFIG
-- -- -------------------------------------------------------------------------------------------

if not ENABLE_ACCOUNTWIDE_TITLES then 
    return
end

local function BroadcastLoginAnnouncement(event, player)
    if ANNOUNCE_ON_LOGIN then
        player:SendBroadcastMessage(ANNOUNCEMENT)
    end
end

local function GetKnownTitlesOnAccount(accountId)
    local query = CharDBQuery("SELECT guid, knownTitles FROM characters WHERE account = " .. accountId)
    
    local characters = {}
    local longestKnownTitles = ""
    
    if query then
        repeat            
            local guid = query:GetUInt32(0)
            local knownTitles = query:GetString(1)
            
            if #knownTitles > #longestKnownTitles then
                longestKnownTitles = knownTitles
            end
            
            table.insert(characters, { guid = guid, knownTitles = knownTitles })
        until not query:NextRow()
    end
    
    return characters, longestKnownTitles
end

local function SynchronizeTitles(event, player)
    local accountId = player:GetAccountId()
    local accountCharacters, longestKnownTitles = GetKnownTitlesOnAccount(accountId)
    
    -- Ensure there is a longestKnownTitles string on the account to synchronize
    if longestKnownTitles ~= "" then
        -- Update characters where knownTitles length is less than the longest knownTitles length
        for _, character in ipairs(accountCharacters) do
            if #character.knownTitles < #longestKnownTitles then
                local updateQuery = CharDBQuery("UPDATE characters SET knownTitles = '" .. longestKnownTitles .. "' WHERE guid = " .. character.guid .. " AND knownTitles <> '" .. longestKnownTitles .. "'")
            end
        end
    end
end

RegisterPlayerEvent(3, BroadcastLoginAnnouncement)   -- EVENT_ON_LOGIN
RegisterPlayerEvent(4, SynchronizeTitles)   -- EVENT_ON_LOGOUT
RegisterPlayerEvent(25, SynchronizeTitles)  -- EVENT_ON_SAVE