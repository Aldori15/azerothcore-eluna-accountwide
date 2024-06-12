-- ------------------------------------------------------------------------------------------------
-- ACCOUNTWIDE TAXI PATHS CONFIG 
--
-- Hosted by Aldori15 on Github: https://github.com/Aldori15/azerothcore-lua-accountwide
--
-- Due to the horde/alliance interactions, taxi paths will only be shared with characters
-- of the SAME faction.  Horde taxi paths will only be shared with other horde characters
-- and Alliance taxi paths will only be shared with other alliance characters on the account.
-- ------------------------------------------------------------------------------------------------

local ENABLE_ACCOUNTWIDE_TAXI_PATHS = false

local ANNOUNCE_ON_LOGIN = true
local ANNOUNCEMENT = "This server is running the |cFF00B0E8AccountWide Taxi Paths |rlua script."

-- -- ---------------------------------------------------------------------------------------------
-- -- END CONFIG
-- -- ---------------------------------------------------------------------------------------------

if not ENABLE_ACCOUNTWIDE_TAXI_PATHS then return end

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
    [20] = true -- Demon Hunter
    -- Add or remove races as needed based on your server. These values come from ChrRaces.dbc
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
    [21] = true -- Demon Hunter
    -- Add or remove races as needed based on your server. These values come from ChrRaces.dbc
}

local function BroadcastLoginAnnouncement(event, player)
    if ANNOUNCE_ON_LOGIN then
        player:SendBroadcastMessage(ANNOUNCEMENT)
    end
end

local function GetKnownTaxiPathsOnAccount(accountId)
    local query = CharDBQuery("SELECT guid, race, taximask FROM characters WHERE account = " .. accountId)
    
    local characters = {}
    local longestKnownTaxiMaskAlliance = ""
    local longestKnownTaxiMaskHorde = ""
    
    if query then
        repeat
            local guid = query:GetUInt32(0)
            local race = query:GetUInt8(1)
            local knownTaxiMask = query:GetString(2)
            
            if allianceRaces[race] and #knownTaxiMask > #longestKnownTaxiMaskAlliance then
                longestKnownTaxiMaskAlliance = knownTaxiMask
            elseif hordeRaces[race] and #knownTaxiMask > #longestKnownTaxiMaskHorde then
                longestKnownTaxiMaskHorde = knownTaxiMask
            end
            
            table.insert(characters, { guid = guid, race = race, knownTaxiMask = knownTaxiMask })
        until not query:NextRow()
    end
    
    return characters, longestKnownTaxiMaskAlliance, longestKnownTaxiMaskHorde
end

local function SynchronizeTaxiPaths(event, player)
    local accountId = player:GetAccountId()
    local charRace = player:GetRace()
    
    local accountCharacters, longestKnownTaxiMaskAlliance, longestKnownTaxiMaskHorde = GetKnownTaxiPathsOnAccount(accountId)

    local longestKnownTaxiMask = ""
    if allianceRaces[charRace] then
        longestKnownTaxiMask = longestKnownTaxiMaskAlliance
    elseif hordeRaces[charRace] then
        longestKnownTaxiMask = longestKnownTaxiMaskHorde
    end
    
    if longestKnownTaxiMask ~= "" then
        for _, character in ipairs(accountCharacters) do
            if allianceRaces[character.race] then
                CharDBQuery("UPDATE characters SET taximask = '" .. longestKnownTaxiMaskAlliance .. "' WHERE guid = " .. character.guid .. " AND taximask <> '" .. longestKnownTaxiMaskAlliance .. "'")
            elseif hordeRaces[character.race] then
                CharDBQuery("UPDATE characters SET taximask = '" .. longestKnownTaxiMaskHorde .. "' WHERE guid = " .. character.guid .. " AND taximask <> '" .. longestKnownTaxiMaskHorde .. "'")
            end
        end
    end
end

RegisterPlayerEvent(3, BroadcastLoginAnnouncement) -- EVENT_ON_LOGIN
RegisterPlayerEvent(4, SynchronizeTaxiPaths) -- EVENT_ON_LOGOUT
RegisterPlayerEvent(25, SynchronizeTaxiPaths) -- EVENT_ON_SAVE