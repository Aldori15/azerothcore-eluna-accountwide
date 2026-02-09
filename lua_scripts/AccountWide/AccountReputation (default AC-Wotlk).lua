-- ------------------------------------------------------------------------------------------------
-- ACCOUNTWIDE REPUTATION CONFIG
--
-- Hosted by Aldori15 on Github: https://github.com/Aldori15/azerothcore-lua-accountwide
-- ------------------------------------------------------------------------------------------------

local ENABLE_ACCOUNTWIDE_REPUTATION = false

local ANNOUNCE_ON_LOGIN = false
local ANNOUNCEMENT = "This server is running the |cFF00B0E8AccountWide Reputation |rlua script."

-- PLEASE READ:
-- Retroactive seeding settings (for existing accounts that already have characters with reputation progress):
-- If you are using this script on a brand new server, you can disable with no impact.
-- Otherwise, it's recommended to keep this enabled to retroactively seed existing accounts on their first login.
-- Since the retroactive rep values won't show up on the client until the player logs back in, we will force a logout
-- to ensure the seeded values are applied immediately.
local RETROACTIVE_SEED_ON_LOGIN = true
local SEED_ANNOUNCE_TO_PLAYER = true
local SEED_FORCE_LOGOUT = true
local SEED_LOGOUT_DELAY_SECONDS = 10

-- ------------------------------------------------------------------------------------------------
-- END CONFIG
-- ------------------------------------------------------------------------------------------------

if not ENABLE_ACCOUNTWIDE_REPUTATION then return end

local AUtils = AccountWideUtils

-- Alliance and Horde race and faction definitions
local allianceRaces = {
    [1] = true, [3] = true, [4] = true, [7] = true, [11] = true
}

local hordeRaces = {
    [2] = true, [5] = true, [6] = true, [8] = true, [10] = true
}

local allianceFactions = {
    [47] = true, [54] = true, [69] = true, [72] = true, [469] = true, [471] = true, [509] = true, [589] = true, [730] = true, [890] = true,
    [891] = true, [930] = true, [946] = true, [978] = true, [1037] = true, [1050] = true, [1068] = true, [1094] = true, [1126] = true
}

local hordeFactions = {
    [67] = true, [68] = true, [76] = true, [81] = true, [510] = true, [530] = true, [729] = true, [889] = true, [892] = true, [911] = true,
    [922] = true, [941] = true, [947] = true, [1052] = true, [1064] = true, [1067] = true, [1085] = true, [1124] = true
}

-- Race specific ReputationBase values are defined in Faction.dbc
-- [race] = { [factionId] = ReputationBase }
local baseReputationValues = {
    -- Alliance
    [1] = { [21] = 500, [47] = 3100, [54] = 3100, [69] = 3100, [70] = -10000, [72] = 4000, [83] = 2999, [86] = 2999, [87] = -6500, [92] = 2000, [93] = 2000, [169] = 500, [369] = 500, [469] = 3300, [470] = 500, [471] = 150, [529] = 200, [549] = 2999, [550] = 2999, [551] = 2999, [576] = -3500, [577] = 500, [910] = -42000, [930] = 3000, [932] = 0, [933] = 0, [934] = 0, [935] = 0, [936] = 0, [942] = 0, [946] = 0, [967] = 0, [970] = -2500, [978] = -1200, [989] = 0, [990] = 0, [1005] = 3000, [1011] = 0, [1012] = 0, [1015] = -42000, [1031] = 0, [1037] = 0, [1038] = 0, [1050] = 0, [1068] = 0, [1073] = 0, [1077] = 0, [1090] = 0, [1091] = 0, [1094] = 0, [1104] = 0, [1105] = 0, [1106] = 0, [1117] = 0, [1118] = 0, [1119] = -42000, [1126] = 0, [1156] = 0  }, -- Human
    [3] = { [21] = 500, [47] = 4000, [54] = 3100, [69] = 3100, [70] = -10000, [72] = 3100, [83] = 2999, [86] = 2999, [87] = -6500, [92] = 2000, [93] = 2000, [169] = 500, [369] = 500, [469] = 3300, [470] = 500, [471] = 500, [529] = 200, [549] = 2999, [550] = 2999, [551] = 2999, [576] = -3500, [577] = 500, [910] = -42000, [930] = 3000, [932] = 0, [933] = 0, [934] = 0, [935] = 0, [936] = 0, [942] = 0, [946] = 0, [967] = 0, [970] = -2500, [978] = -1200, [989] = 0, [990] = 0, [1005] = 3000, [1011] = 0, [1012] = 0, [1015] = -42000, [1031] = 0, [1037] = 0, [1038] = 0, [1050] = 0, [1068] = 0, [1073] = 0, [1077] = 0, [1090] = 0, [1091] = 0, [1094] = 0, [1104] = 0, [1105] = 0, [1106] = 0, [1117] = 0, [1118] = 0, [1119] = -42000, [1126] = 0, [1156] = 0 }, -- Dwarf
    [4] = { [21] = 500, [47] = 3100, [54] = 3100, [69] = 4000, [70] = -10000, [72] = 3100, [83] = 2999, [86] = 2999, [87] = -6500, [92] = 2000, [93] = 2000, [169] = 500, [369] = 500, [469] = 3300, [470] = 500, [471] = 150, [529] = 200, [549] = 2999, [550] = 2999, [551] = 2999, [576] = -3500, [577] = 500, [910] = -42000, [930] = 3000, [932] = 0, [933] = 0, [934] = 0, [935] = 0, [936] = 0, [942] = 0, [946] = 0, [967] = 0, [970] = -2500, [978] = -1200, [989] = 0, [990] = 0, [1005] = 3000, [1011] = 0, [1012] = 0, [1015] = -42000, [1031] = 0, [1037] = 0, [1038] = 0, [1050] = 0, [1068] = 0, [1073] = 0, [1077] = 0, [1090] = 0, [1091] = 0, [1094] = 0, [1104] = 0, [1105] = 0, [1106] = 0, [1117] = 0, [1118] = 0, [1119] = -42000, [1126] = 0, [1156] = 0 }, -- Night Elf
    [7] = { [21] = 500, [47] = 3100, [54] = 4000, [69] = 3100, [70] = -10000, [72] = 3100, [83] = 2999, [86] = 2999, [87] = -6500, [92] = 2000, [93] = 2000, [169] = 500, [369] = 500, [469] = 3300, [470] = 500, [471] = 150, [529] = 200, [549] = 2999, [550] = 2999, [551] = 2999, [576] = -3500, [577] = 500, [910] = -42000, [930] = 3000, [932] = 0, [933] = 0, [934] = 0, [935] = 0, [936] = 0, [942] = 0, [946] = 0, [967] = 0, [970] = -2500, [978] = -1200, [989] = 0, [990] = 0, [1005] = 3000, [1011] = 0, [1012] = 0, [1015] = -42000, [1031] = 0, [1037] = 0, [1038] = 0, [1050] = 0, [1068] = 0, [1073] = 0, [1077] = 0, [1090] = 0, [1091] = 0, [1094] = 0, [1104] = 0, [1105] = 0, [1106] = 0, [1117] = 0, [1118] = 0, [1119] = -42000, [1126] = 0, [1156] = 0 }, -- Gnome
    [11] = { [21] = 500, [47] = 3100, [54] = 3100, [69] = 3100, [70] = -10000, [72] = 3100, [83] = 2999, [86] = 2999, [87] = -6500, [92] = 2000, [93] = 2000, [169] = 500, [369] = 500, [469] = 3300, [470] = 500, [471] = 150, [529] = 200, [549] = 2999, [550] = 2999, [551] = 2999, [576] = -3500, [577] = 500, [910] = -42000, [930] = 4000, [932] = 3500, [933] = 0, [934] = -3500, [935] = 0, [936] = 0, [942] = 0, [946] = 0, [967] = 0, [970] = -2500, [978] = -1200, [989] = 0, [990] = 0, [1005] = 3000, [1011] = 0, [1012] = 0, [1015] = -42000, [1031] = 0, [1037] = 0, [1038] = 0, [1050] = 0, [1068] = 0, [1073] = 0, [1077] = 0, [1090] = 0, [1091] = 0, [1094] = 0, [1104] = 0, [1105] = 0, [1106] = 0, [1117] = 0, [1118] = 0, [1119] = -42000, [1126] = 0, [1156] = 0 }, -- Draenei
    -- Horde
    [2] = { [21] = 500, [67] = 3500, [68] = 500, [70] = -10000, [76] = 4000, [81] = 3100, [83] = 2999, [86] = 2999, [87] = -6500, [92] = 2000, [93] = 2000, [169] = 500, [369] = 500, [470] = 500, [529] = 200, [530] = 3100, [549] = 2999, [550] = 2999, [551] = 2999, [576] = -3500, [577] = 500, [910] = -42000, [911] = 400, [922] = 0, [932] = 0, [933] = 0, [934] = 0, [935] = 0, [936] = 0, [941] = -500, [942] = 0, [947] = 0, [967] = 0, [970] = -2500, [989] = 0, [990] = 0, [1005] = 3000, [1011] = 0, [1012] = 0, [1015] = -42000, [1031] = 0, [1038] = 0, [1052] = 0, [1064] = 0, [1067] = 0, [1073] = 0, [1077] = 0, [1082] = -42000, [1085] = 0, [1090] = 0, [1091] = 0, [1104] = 0, [1105] = 0, [1106] = 0, [1117] = 0, [1118] = 0, [1119] = -42000, [1124] = 0, [1156] = 0 }, -- Orc
    [5] = { [21] = 500, [67] = 3500, [68] = 4000, [70] = -10000, [76] = 500, [81] = 500, [83] = 2999, [86] = 2999, [87] = -6500, [92] = 2000, [93] = 2000, [169] = 500, [369] = 500, [470] = 500, [529] = 200, [530] = 500, [549] = 2999, [550] = 2999, [551] = 2999, [576] = -3500, [577] = 500, [910] = -42000, [911] = 3100, [922] = 0, [932] = 0, [933] = 0, [934] = 0, [935] = 0, [936] = 0, [941] = -500, [942] = 0, [947] = 0, [967] = 0, [970] = -2500, [989] = 0, [990] = 0, [1005] = 3000, [1011] = 0, [1012] = 0, [1015] = -42000, [1031] = 0, [1038] = 0, [1052] = 0, [1064] = 0, [1067] = 0, [1073] = 0, [1077] = 0, [1082] = -42000, [1085] = 0, [1090] = 0, [1091] = 0, [1104] = 0, [1105] = 0, [1106] = 0, [1117] = 0, [1118] = 0, [1119] = -42000, [1124] = 0, [1156] = 0 }, -- Undead
    [6] = { [21] = 500, [67] = 3500, [68] = 500, [70] = -10000, [76] = 3100, [81] = 4000, [83] = 2999, [86] = 2999, [87] = -6500, [92] = 2000, [93] = 2000, [169] = 500, [369] = 500, [470] = 500, [529] = 200, [530] = 3100, [549] = 2999, [550] = 2999, [551] = 2999, [576] = -3500, [577] = 500, [910] = -42000, [911] = 400, [922] = 0, [932] = 0, [933] = 0, [934] = 0, [935] = 0, [936] = 0, [941] = -500, [942] = 0, [947] = 0, [967] = 0, [970] = -2500, [989] = 0, [990] = 0, [1005] = 3000, [1011] = 0, [1012] = 0, [1015] = -42000, [1031] = 0, [1038] = 0, [1052] = 0, [1064] = 0, [1067] = 0, [1073] = 0, [1077] = 0, [1082] = -42000, [1085] = 0, [1090] = 0, [1091] = 0, [1104] = 0, [1105] = 0, [1106] = 0, [1117] = 0, [1118] = 0, [1119] = -42000, [1124] = 0, [1156] = 0 }, -- Tauren
    [8] = { [21] = 500, [67] = 3500, [68] = 500, [70] = -10000, [76] = 3100, [81] = 3100, [83] = 2999, [86] = 2999, [87] = -6500, [92] = 2000, [93] = 2000, [169] = 500, [369] = 500, [470] = 500, [529] = 200, [530] = 4000, [549] = 2999, [550] = 2999, [551] = 2999, [576] = -3500, [577] = 500, [910] = -42000, [911] = 400, [922] = 0, [932] = 0, [933] = 0, [934] = 0, [935] = 0, [936] = 0, [941] = -500, [942] = 0, [947] = 0, [967] = 0, [970] = -2500, [989] = 0, [990] = 0, [1005] = 3000, [1011] = 0, [1012] = 0, [1015] = -42000, [1031] = 0, [1038] = 0, [1052] = 0, [1064] = 0, [1067] = 0, [1073] = 0, [1077] = 0, [1082] = -42000, [1085] = 0, [1090] = 0, [1091] = 0, [1104] = 0, [1105] = 0, [1106] = 0, [1117] = 0, [1118] = 0, [1119] = -42000, [1124] = 0, [1156] = 0 }, -- Troll
    [10] = { [21] = 500, [67] = 3500, [68] = 3100, [70] = -10000, [76] = 500, [81] = 500, [83] = 2999, [86] = 2999, [87] = -6500, [92] = 2000, [93] = 2000, [169] = 500, [369] = 500, [470] = 500, [529] = 200, [530] = 500, [549] = 2999, [550] = 2999, [551] = 2999, [576] = -3500, [577] = 500, [910] = -42000, [911] = 4000, [922] = 0, [932] = -3500, [933] = 0, [934] = 3500, [935] = 0, [936] = 0, [941] = -500, [942] = 0, [947] = 0, [967] = 0, [970] = -2500, [989] = 0, [990] = 0, [1005] = 3000, [1011] = 0, [1012] = 0, [1015] = -42000, [1031] = 0, [1038] = 0, [1052] = 0, [1064] = 0, [1067] = 0, [1073] = 0, [1077] = 0, [1082] = -42000, [1085] = 0, [1090] = 0, [1091] = 0, [1104] = 0, [1105] = 0, [1106] = 0, [1117] = 0, [1118] = 0, [1119] = -42000, [1124] = 0, [1156] = 0 } -- Blood Elf
}

local function GetBaseReputationOffset(race, class, factionId)
    -- Special handling for Faction 1098 (Knights of the Ebon Blade)
    if factionId == 1098 then
        if class == 6 then -- Death Knight
            return 3200
        else
            return 0
        end
    end

    -- Default behavior for other factions (race-based reputation)
    local baseReputation = baseReputationValues[race]
    if baseReputation and baseReputation[factionId] then
        return baseReputation[factionId]
    end
    
    return 0
end

local function ClampReputation(value)
    -- Clamp highest and lowest possible adjusted standing to prevent overflows
    return math.max(-46000, math.min(84000, value))
end

local function toCSV(intList)
    local out = {}
    for i = 1, #intList do out[i] = tostring(intList[i]) end
    return table.concat(out, ",")
end

-- Split large upserts into chunks to avoid overly long SQL statements
local function execBatchUpsertReputationChunked(rows, chunkSize)
    if #rows == 0 then return end
    chunkSize = chunkSize or 500

    local i = 1
    while i <= #rows do
        local j = math.min(i + chunkSize - 1, #rows)
        local values = {}

        for k = i, j do
            local row = rows[k]
            values[#values + 1] = string.format("(%d,%d,%d)", row.guid, row.factionId, row.standing)
        end

        CharDBExecute([[
            INSERT INTO character_reputation (guid, faction, standing)
            VALUES ]] .. table.concat(values, ",") .. [[
            ON DUPLICATE KEY UPDATE standing = VALUES(standing)
        ]])

        i = j + 1
    end
end

local function HasAccountBeenSeeded(accountId)
    local seeded = CharDBQuery(string.format("SELECT seeded FROM accountwide_reputation_seed WHERE accountId = %d", accountId))
    if not seeded then return false end
    return seeded:GetUInt8(0) == 1
end

local function MarkAccountSeeded(accountId)
    CharDBExecute(string.format([[
        INSERT INTO accountwide_reputation_seed (accountId, seeded)
        VALUES (%d, 1)
        ON DUPLICATE KEY UPDATE seeded = 1, seeded_at = CURRENT_TIMESTAMP
    ]], accountId))
end

local PENDING_SEED_ROWS_BY_ACCOUNT = {}
local PENDING_SEED_IN_PROGRESS = {}
local SEED_COUNTDOWN_EVENTID_BY_GUID = {}

local ACCOUNT_CHARS_CACHE = {}
local SAVER_FACTIONS_CACHE = {}

local function InvalidateAccountCharsCache(accountId)
    ACCOUNT_CHARS_CACHE[accountId] = nil
end

local function GetAccountCharsCached(accountId)
    local now = os.time()
    local cached = ACCOUNT_CHARS_CACHE[accountId]
    if cached and (now - cached.ts) <= 30 then
        return cached.chars
    end

    local chars = {}
    local query = CharDBQuery(string.format("SELECT guid, race, class FROM characters WHERE account = %d", accountId))
    if not query then
        ACCOUNT_CHARS_CACHE[accountId] = { ts = now, chars = chars }
        return chars
    end

    repeat
        chars[#chars + 1] = {
            guid = query:GetUInt32(0),
            race = query:GetUInt8(1),
            class = query:GetUInt8(2),
        }
    until not query:NextRow()

    ACCOUNT_CHARS_CACHE[accountId] = { ts = now, chars = chars }
    return chars
end

local function GetSaverFactionIdsCached(guid, savingIsAlliance, savingIsHorde)
    local now = os.time()
    local cached = SAVER_FACTIONS_CACHE[guid]
    if cached and (now - cached.ts) <= 60 then
        return cached.ids, cached.csv
    end

    local saverFactionIds = {}
    local saverReps = CharDBQuery(string.format("SELECT faction FROM character_reputation WHERE guid = %d", guid))
    if not saverReps then
        return nil, nil
    end

    repeat
        local factionId = saverReps:GetUInt32(0)

        local isAllianceFaction = allianceFactions[factionId] == true
        local isHordeFaction = hordeFactions[factionId] == true
        local isNeutralFaction = (not isAllianceFaction and not isHordeFaction)

        if isNeutralFaction
            or (savingIsAlliance and isAllianceFaction)
            or (savingIsHorde and isHordeFaction)
        then
            saverFactionIds[#saverFactionIds + 1] = factionId
        end
    until not saverReps:NextRow()

    if #saverFactionIds == 0 then
        return nil, nil
    end

    local csv = toCSV(saverFactionIds)
    SAVER_FACTIONS_CACHE[guid] = { ts = now, ids = saverFactionIds, csv = csv }
    return saverFactionIds, csv
end

local function ApplyPendingSeedForAccount(accountId)
    local rows = PENDING_SEED_ROWS_BY_ACCOUNT[accountId]
    if not rows or #rows == 0 then
        PENDING_SEED_ROWS_BY_ACCOUNT[accountId] = nil
        PENDING_SEED_IN_PROGRESS[accountId] = nil
        return
    end

    execBatchUpsertReputationChunked(rows, 500)
    MarkAccountSeeded(accountId)

    PENDING_SEED_ROWS_BY_ACCOUNT[accountId] = nil
    PENDING_SEED_IN_PROGRESS[accountId] = nil
end

local function StartSeedLogoutCountdown(player, accountId)
    if not SEED_FORCE_LOGOUT then
        ApplyPendingSeedForAccount(accountId)
        return
    end

    local seconds = tonumber(SEED_LOGOUT_DELAY_SECONDS) or 5
    if seconds < 1 then seconds = 1 end

    local function doLogout(eventId, delay, calls, plr)
        if not plr then return end

        local guid = plr:GetGUIDLow()
        local event = SEED_COUNTDOWN_EVENTID_BY_GUID[guid]
        if event then
            plr:RemoveEventById(event)
            SEED_COUNTDOWN_EVENTID_BY_GUID[guid] = nil
        end

        plr:SendBroadcastMessage("|cFF00B0E8[AccountWide]|r Applying reputation seed now. Logging out...")

        -- Delay to apply seed AFTER player is disconnected (so core save can't overwrite it).
        CreateLuaEvent(function()
            ApplyPendingSeedForAccount(accountId)
        end, 2000, 1)

        -- I would like to use LogoutPlayer here but currently it crashes the worldserver. Once this is fixed in ALE, i'll switch to that instead:
        -- https://github.com/azerothcore/mod-ale/issues/359
        -- plr:LogoutPlayer(false)
        plr:KickPlayer()
    end

    local function tick(eventId, delay, calls, plr)
        if not plr then return end

        local remaining = calls - 1
        if remaining <= 0 then
            plr:RegisterEvent(doLogout, 1, 1)
            return
        end

        plr:SendBroadcastMessage(string.format(
            "|cFF00B0E8[AccountWide]|r Reputation seeded. You will be logged out in %d second%s to apply changes.",
            remaining, (remaining == 1 and "" or "s")
        ))
    end

    local evtId = player:RegisterEvent(tick, 1000, seconds + 1)
    SEED_COUNTDOWN_EVENTID_BY_GUID[player:GetGUIDLow()] = evtId
end

local function IsAllianceRace(race) return allianceRaces[race] == true end
local function IsHordeRace(race) return hordeRaces[race] == true end

local function IsAllianceFaction(factionId) return allianceFactions[factionId] == true end
local function IsHordeFaction(factionId) return hordeFactions[factionId] == true end
local function IsNeutralFaction(factionId) return (not IsAllianceFaction(factionId)) and (not IsHordeFaction(factionId)) end

-- Retroactive seeding:
local function SeedAccountReputationIfNeeded(player)
    if not RETROACTIVE_SEED_ON_LOGIN then return end
    if AUtils.shouldSkipAll and AUtils.shouldSkipAll(player) then return end

    local accountId = player:GetAccountId()
    if HasAccountBeenSeeded(accountId) then return end

    local accountChars = GetAccountCharsCached(accountId)
    if not accountChars or #accountChars == 0 then
        MarkAccountSeeded(accountId)
        return
    end

    local maxAlliance = {}
    local maxHorde = {}
    local maxNeutral = {}

    do
        local repQuery = CharDBQuery(string.format([[
            SELECT cr.faction, cr.standing, ch.race
            FROM character_reputation cr
            JOIN characters ch ON ch.guid = cr.guid
            WHERE ch.account = %d
            AND cr.standing <> 0
        ]], accountId))

        if not repQuery then
            -- mark seeded so we don't recheck every login
            MarkAccountSeeded(accountId)
            return
        end

        repeat
            local factionId = repQuery:GetUInt32(0)
            local delta = ClampReputation(repQuery:GetInt32(1))
            local holderRace = repQuery:GetUInt8(2)

            if IsNeutralFaction(factionId) then
                local cur = maxNeutral[factionId]
                if cur == nil or delta > cur then
                    maxNeutral[factionId] = delta
                end

            elseif IsAllianceFaction(factionId) and IsAllianceRace(holderRace) then
                local cur = maxAlliance[factionId]
                if cur == nil or delta > cur then
                    maxAlliance[factionId] = delta
                end

            elseif IsHordeFaction(factionId) and IsHordeRace(holderRace) then
                local cur = maxHorde[factionId]
                if cur == nil or delta > cur then
                    maxHorde[factionId] = delta
                end
            end

        until not repQuery:NextRow()
    end

    local hasAny = false
    for _ in pairs(maxAlliance) do hasAny = true break end
    if not hasAny then for _ in pairs(maxHorde) do hasAny = true break end end
    if not hasAny then for _ in pairs(maxNeutral) do hasAny = true break end end

    if not hasAny then
        -- If there is nothing to seed, mark seeded so we don't recheck every login
        MarkAccountSeeded(accountId)
        return
    end

    local rowsToWrite = {}

    for i = 1, #accountChars do
        local char = accountChars[i]
        local isAlliance = IsAllianceRace(char.race)
        local isHorde = IsHordeRace(char.race)

        -- neutrals -> everyone
        for factionId, delta in pairs(maxNeutral) do
            rowsToWrite[#rowsToWrite + 1] = {
                guid = char.guid,
                factionId = factionId,
                standing = ClampReputation(delta),
            }
        end

        if isAlliance then
            for factionId, delta in pairs(maxAlliance) do
                rowsToWrite[#rowsToWrite + 1] = {
                    guid = char.guid,
                    factionId = factionId,
                    standing = ClampReputation(delta),
                }
            end
        elseif isHorde then
            for factionId, delta in pairs(maxHorde) do
                rowsToWrite[#rowsToWrite + 1] = {
                    guid = char.guid,
                    factionId = factionId,
                    standing = ClampReputation(delta),
                }
            end
        end
    end

    PENDING_SEED_ROWS_BY_ACCOUNT[accountId] = rowsToWrite
    PENDING_SEED_IN_PROGRESS[accountId] = true

    if SEED_ANNOUNCE_TO_PLAYER then
        if SEED_FORCE_LOGOUT then
            player:SendBroadcastMessage("|cFF00B0E8[AccountWide]|r Reputation seeded for your account. You will be logged out soon to apply changes.")
        else
            player:SendBroadcastMessage("|cFF00B0E8[AccountWide]|r Reputation seeded for your account. Relog to apply changes.")
        end
    end

    StartSeedLogoutCountdown(player, accountId)
end

local function SetReputationOnSave(event, player)
    -- Skip playerbot accounts
    if AUtils.shouldSkipAll and AUtils.shouldSkipAll(player) then return end

    local accountId = player:GetAccountId()
    if PENDING_SEED_IN_PROGRESS[accountId] then return end

    local savingGuid = player:GetGUIDLow()
    local savingRace = player:GetRace()
    local savingClass = player:GetClass()

    local accountChars = GetAccountCharsCached(accountId)
    if not accountChars or #accountChars == 0 then return end

    local savingIsAlliance = allianceRaces[savingRace] == true
    local savingIsHorde = hordeRaces[savingRace] == true

    local saverFactionIds, saverFactionIdCSV = GetSaverFactionIdsCached(savingGuid, savingIsAlliance, savingIsHorde)
    if not saverFactionIds or #saverFactionIds == 0 then return end

    local maxAdjustedAllianceByFaction = {}
    local maxAdjustedHordeByFaction = {}
    local maxAdjustedNeutralByFaction = {}

    local maxHolderGuidsAlliance = {}
    local maxHolderGuidsHorde = {}
    local maxHolderGuidsNeutral = {}

    do
        local accountRepQuery = CharDBQuery(string.format([[
            SELECT cr.guid, cr.faction, cr.standing, ch.race
              FROM character_reputation cr
              JOIN characters ch ON ch.guid = cr.guid
             WHERE ch.account = %d
               AND cr.faction IN (%s)
        ]], accountId, saverFactionIdCSV))

        if accountRepQuery then
            repeat
                local guid = accountRepQuery:GetUInt32(0)
                local factionId = accountRepQuery:GetUInt32(1)
                local adjustedStanding = accountRepQuery:GetInt32(2)
                local holderRace = accountRepQuery:GetUInt8(3)

                local isAllianceFaction = allianceFactions[factionId] == true
                local isHordeFaction = hordeFactions[factionId] == true
                local isNeutralFaction = (not isAllianceFaction and not isHordeFaction)

                if isNeutralFaction then
                    local current = maxAdjustedNeutralByFaction[factionId]
                    if current == nil or adjustedStanding > current then
                        maxAdjustedNeutralByFaction[factionId] = adjustedStanding
                        maxHolderGuidsNeutral[factionId] = { [guid] = true }
                    elseif adjustedStanding == current then
                        maxHolderGuidsNeutral[factionId][guid] = true
                    end

                elseif isAllianceFaction and allianceRaces[holderRace] then
                    local current = maxAdjustedAllianceByFaction[factionId]
                    if current == nil or adjustedStanding > current then
                        maxAdjustedAllianceByFaction[factionId] = adjustedStanding
                        maxHolderGuidsAlliance[factionId] = { [guid] = true }
                    elseif adjustedStanding == current then
                        maxHolderGuidsAlliance[factionId][guid] = true
                    end

                elseif isHordeFaction and hordeRaces[holderRace] then
                    local current = maxAdjustedHordeByFaction[factionId]
                    if current == nil or adjustedStanding > current then
                        maxAdjustedHordeByFaction[factionId] = adjustedStanding
                        maxHolderGuidsHorde[factionId] = { [guid] = true }
                    elseif adjustedStanding == current then
                        maxHolderGuidsHorde[factionId][guid] = true
                    end
                end
            until not accountRepQuery:NextRow()
        end
    end

    -- Compute the saving character's current adjusted standings from memory
    local savingAdjustedByFaction = {}
    for _, factionId in ipairs(saverFactionIds) do
        local rawTotal = player:GetReputation(factionId)
        local baseOffset = GetBaseReputationOffset(savingRace, savingClass, factionId)
        local adjusted = ClampReputation(rawTotal - baseOffset)
        savingAdjustedByFaction[factionId] = adjusted
    end

    local rowsToWrite = {}

    local function propagate(factionId, targetAdjusted, eligiblePredicate)
        local clamped = ClampReputation(targetAdjusted or 0)
        for i = 1, #accountChars do
            local charInfo = accountChars[i]
            if eligiblePredicate(charInfo.race) then
                rowsToWrite[#rowsToWrite + 1] = {
                    guid = charInfo.guid,
                    factionId = factionId,
                    standing = clamped
                }
            end
        end
    end

    for _, factionId in ipairs(saverFactionIds) do
        local isAllianceFaction = allianceFactions[factionId] == true
        local isHordeFaction = hordeFactions[factionId] == true
        local isNeutralFaction = (not isAllianceFaction and not isHordeFaction)

        local savingAdjusted = savingAdjustedByFaction[factionId] or 0

        local rawMax, maxHolderGuids, eligible

        if isNeutralFaction then
            rawMax = maxAdjustedNeutralByFaction[factionId]
            maxHolderGuids = maxHolderGuidsNeutral[factionId] or {}
            eligible = function(_) return true end
        elseif isAllianceFaction then
            rawMax = maxAdjustedAllianceByFaction[factionId]
            maxHolderGuids = maxHolderGuidsAlliance[factionId] or {}
            eligible = function(race) return allianceRaces[race] == true end
        else
            rawMax = maxAdjustedHordeByFaction[factionId]
            maxHolderGuids = maxHolderGuidsHorde[factionId] or {}
            eligible = function(race) return hordeRaces[race] == true end
        end

        local hasExisting = (rawMax ~= nil)
        local currentMaxAdjusted = rawMax or 0
        local saverWasMaxHolder = maxHolderGuids[savingGuid] == true
        local targetAdjusted

        if not hasExisting then
            targetAdjusted = savingAdjusted
        elseif saverWasMaxHolder and savingAdjusted < currentMaxAdjusted then
            targetAdjusted = savingAdjusted
        else
            targetAdjusted = math.max(currentMaxAdjusted, savingAdjusted)
        end

        propagate(factionId, targetAdjusted, eligible)
    end

    if #rowsToWrite == 0 then return end
    execBatchUpsertReputationChunked(rowsToWrite, 500)
end

local function upsertManyForGuid(guid, factionToAdjustedStanding)
    local rows = {}
    for factionId, adjustedStanding in pairs(factionToAdjustedStanding) do
        rows[#rows + 1] = string.format("(%d,%d,%d)", guid, factionId, adjustedStanding)
    end
    if #rows == 0 then return end
    CharDBExecute([[
        INSERT INTO character_reputation (guid, faction, standing)
        VALUES ]] .. table.concat(rows, ",") .. [[
        ON DUPLICATE KEY UPDATE standing = VALUES(standing)
    ]])
end

local function SetReputationOnCharacterCreate(event, player)
    -- Skip playerbot accounts
    if AUtils.shouldSkipAll and AUtils.shouldSkipAll(player) then return end

    local accountId = player:GetAccountId()
    InvalidateAccountCharsCache(accountId)
    local newGuid = player:GetGUIDLow()
    local newRace = player:GetRace()

    local newIsAlliance = allianceRaces[newRace] == true
    local newIsHorde = hordeRaces[newRace] == true

    local existingMaxAdjusted = CharDBQuery(string.format([[
        SELECT mr.faction, mr.max_standing, ch.race
        FROM (
            SELECT cr.faction, MAX(cr.standing) AS max_standing
            FROM character_reputation cr
            JOIN characters ch ON ch.guid = cr.guid
            WHERE ch.account = %d
            GROUP BY cr.faction
        ) mr
        JOIN character_reputation cr2
          ON cr2.faction = mr.faction AND cr2.standing = mr.max_standing
        JOIN characters ch
          ON ch.guid = cr2.guid
    ]], accountId))

    local adjustedProgressByFaction = {}

    if existingMaxAdjusted then
        repeat
            local factionId = existingMaxAdjusted:GetUInt32(0)
            local maxAdjustedDelta = existingMaxAdjusted:GetInt32(1)
            local holderRace = existingMaxAdjusted:GetUInt8(2)

            local holderIsAlliance = allianceRaces[holderRace] == true
            local holderIsHorde = hordeRaces[holderRace] == true
            local isNeutralFaction = (not allianceFactions[factionId]) and (not hordeFactions[factionId])

            -- Only adopt progress from same-side factions or neutrals
            if isNeutralFaction or (newIsAlliance and holderIsAlliance) or (newIsHorde and holderIsHorde) then
                adjustedProgressByFaction[factionId] = maxAdjustedDelta
            end
        until not existingMaxAdjusted:NextRow()
    end

    -- Build all rows for the new character in memory
    local rowsForNew = {}

    if newIsAlliance then
        for factionId, _ in pairs(allianceFactions) do
            local adjusted = adjustedProgressByFaction[factionId] or 0
            rowsForNew[factionId] = ClampReputation(adjusted)
        end
    elseif newIsHorde then
        for factionId, _ in pairs(hordeFactions) do
            local adjusted = adjustedProgressByFaction[factionId] or 0
            rowsForNew[factionId] = ClampReputation(adjusted)
        end
    end

    -- Neutral factions
    for factionId, adjusted in pairs(adjustedProgressByFaction) do
        local isNeutral = (not allianceFactions[factionId]) and (not hordeFactions[factionId])
        if isNeutral then
            rowsForNew[factionId] = ClampReputation(adjusted)
        end
    end

    upsertManyForGuid(newGuid, rowsForNew)
end

local function OnLogin(event, player)
    SeedAccountReputationIfNeeded(player)

    if ANNOUNCE_ON_LOGIN then
        player:SendBroadcastMessage(ANNOUNCEMENT)
    end
end

RegisterPlayerEvent(1, SetReputationOnCharacterCreate) -- EVENT_ON_CHARACTER_CREATE
RegisterPlayerEvent(3, OnLogin) -- EVENT_ON_LOGIN
RegisterPlayerEvent(25, SetReputationOnSave) -- EVENT_ON_SAVE