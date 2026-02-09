-- ----------------------------------------------------------------------------------------------
-- ACCOUNTWIDE PVP RANK CONFIG 
-- Hosted by Aldori15 on Github: https://github.com/Aldori15/azerothcore-lua-accountwide
-- ----------------------------------------------------------------------------------------------

local ENABLE_ACCOUNTWIDE_PVP_RANK = false

local ANNOUNCE_ON_LOGIN = false
local ANNOUNCEMENT = "This server is running the |cFF00B0E8AccountWide PvP Rank |rlua script."

local RUN_INIT_SEED_ON_STARTUP = true  -- set false after first server run

-- ----------------------------------------------------------------------------------------------
-- Initialize SQL Table (called once at server start)
-- ----------------------------------------------------------------------------------------------

if not ENABLE_ACCOUNTWIDE_PVP_RANK then return end

local AUtils = AccountWideUtils

local function InitializeAccountwidePvPRankTable()
    if not RUN_INIT_SEED_ON_STARTUP then return end

    -- Refresh accountwide totals from current character sums
    CharDBExecute([[
        INSERT IGNORE INTO `acore_characters`.`accountwide_pvp_rank` (
            accountId, arenaPoints, totalHonorPoints, todayHonorPoints, yesterdayHonorPoints,
            totalKills, todayKills, yesterdayKills
        )
        SELECT
            c.account                AS accountId,
            SUM(c.arenaPoints)       AS arenaPoints,
            SUM(c.totalHonorPoints)  AS totalHonorPoints,
            SUM(c.todayHonorPoints)  AS todayHonorPoints,
            SUM(c.yesterdayHonorPoints) AS yesterdayHonorPoints,
            SUM(c.totalKills)        AS totalKills,
            SUM(c.todayKills)        AS todayKills,
            SUM(c.yesterdayKills)    AS yesterdayKills
        FROM `acore_characters`.`characters` c
        JOIN `acore_auth`.`account` a ON a.id = c.account
        WHERE a.username NOT LIKE 'RNDBOT%'
        GROUP BY c.account
    ]])

    -- Mirror to every character on the account
    CharDBExecute([[
        UPDATE `acore_characters`.`characters` c
        JOIN `acore_characters`.`accountwide_pvp_rank` aw ON aw.accountId = c.account
           SET c.arenaPoints      = aw.arenaPoints,
               c.totalHonorPoints = aw.totalHonorPoints,
               c.totalKills       = aw.totalKills
    ]])
end

local function SyncPvPRankOnLogin(event, player)
    -- Skip playerbot accounts
    if AUtils.shouldSkipAll and AUtils.shouldSkipAll(player) then return end

    if ANNOUNCE_ON_LOGIN then
        player:SendBroadcastMessage(ANNOUNCEMENT)
    end

    local accountId = player:GetAccountId()
    local guid = player:GetGUIDLow()

    local query = CharDBQuery(string.format([[
        SELECT
            c.todayHonorPoints, c.yesterdayHonorPoints,
            c.todayKills, c.yesterdayKills,
            aw.arenaPoints, aw.totalHonorPoints, aw.todayHonorPoints, aw.yesterdayHonorPoints,
            aw.totalKills, aw.todayKills, aw.yesterdayKills
        FROM characters c
        LEFT JOIN accountwide_pvp_rank aw ON aw.accountId = c.account
        WHERE c.guid = %d
    ]], guid))

    if not query then return end

    if query:IsNull(4) then
        CharDBExecute(string.format([[
            INSERT INTO accountwide_pvp_rank
                (accountId, arenaPoints, totalHonorPoints, todayHonorPoints, yesterdayHonorPoints, totalKills, todayKills, yesterdayKills)
            VALUES (%d, %d, %d, %d, %d, %d, %d, %d)
        ]],
            accountId,
            player:GetArenaPoints(),
            player:GetHonorPoints(),
            query:GetUInt32(0),
            query:GetUInt32(1),
            player:GetLifetimeKills(),
            query:GetUInt32(2),
            query:GetUInt32(3)
        ))
        -- After seeding, re-run the normal path next login/save
        return
    end

    local c_todayHonor     = query:GetUInt32(0)
    local c_yesterdayHonor = query:GetUInt32(1)
    local c_todayKills     = query:GetUInt32(2)
    local c_yesterdayKills = query:GetUInt32(3)

    local aw_arenaPoints      = query:GetUInt32(4)
    local aw_totalHonorPoints = query:GetUInt32(5)
    local aw_todayHonor       = query:GetUInt32(6)
    local aw_yesterdayHonor   = query:GetUInt32(7)
    local aw_totalKills       = query:GetUInt32(8)
    local aw_todayKills       = query:GetUInt32(9)
    local aw_yesterdayKills   = query:GetUInt32(10)

    if player:GetArenaPoints() ~= aw_arenaPoints then
        player:SetArenaPoints(aw_arenaPoints)
    end
    if player:GetHonorPoints() ~= aw_totalHonorPoints then
        player:SetHonorPoints(aw_totalHonorPoints)
    end
    if player:GetLifetimeKills() ~= aw_totalKills then
        player:SetLifetimeKills(aw_totalKills)
    end

    if c_todayHonor ~= aw_todayHonor or c_yesterdayHonor ~= aw_yesterdayHonor
    or c_todayKills ~= aw_todayKills or c_yesterdayKills ~= aw_yesterdayKills then
        CharDBExecute(string.format([[
            UPDATE characters
            SET todayHonorPoints = %d,
                yesterdayHonorPoints = %d,
                todayKills = %d,
                yesterdayKills = %d
            WHERE guid = %d
        ]], aw_todayHonor, aw_yesterdayHonor, aw_todayKills, aw_yesterdayKills, guid))
    end
end

local function SyncPvPRankOnLogout(event, player)
    -- Skip playerbot accounts
    if AUtils.shouldSkipAll and AUtils.shouldSkipAll(player) then return end

    local accountId = player:GetAccountId()
    local guid = player:GetGUIDLow()

    local arenaPoints   = player:GetArenaPoints()
    local honorPoints   = player:GetHonorPoints()
    local lifetimeKills = player:GetLifetimeKills()

    -- Delay so core has time to flush today's/yesterday's fields to DB
    CreateLuaEvent(function()
        local query = CharDBQuery(string.format("SELECT todayHonorPoints, yesterdayHonorPoints, todayKills, yesterdayKills FROM characters WHERE guid = %d", guid))
        if not query then return end

        local todayHonor      = query:GetUInt32(0)
        local yesterdayHonor  = query:GetUInt32(1)
        local todayKills      = query:GetUInt32(2)
        local yesterdayKills  = query:GetUInt32(3)

        -- Upsert accountwide using this character as the new source of truth
        CharDBExecute(string.format([[
            INSERT INTO accountwide_pvp_rank
                (accountId, arenaPoints, totalHonorPoints, todayHonorPoints, yesterdayHonorPoints, totalKills, todayKills, yesterdayKills)
            VALUES (%d, %d, %d, %d, %d, %d, %d, %d)
            ON DUPLICATE KEY UPDATE
                arenaPoints = VALUES(arenaPoints),
                totalHonorPoints = VALUES(totalHonorPoints),
                todayHonorPoints = VALUES(todayHonorPoints),
                yesterdayHonorPoints = VALUES(yesterdayHonorPoints),
                totalKills = VALUES(totalKills),
                todayKills = VALUES(todayKills),
                yesterdayKills = VALUES(yesterdayKills)
        ]],
            accountId, arenaPoints, honorPoints, todayHonor, yesterdayHonor, lifetimeKills, todayKills, yesterdayKills
        ))

        -- Bulk sync to all characters on the account
        CharDBExecute(string.format([[
            UPDATE characters
            SET arenaPoints = %d,
                totalHonorPoints = %d,
                todayHonorPoints = %d,
                yesterdayHonorPoints = %d,
                totalKills = %d,
                todayKills = %d,
                yesterdayKills = %d
            WHERE account = %d
        ]],
            arenaPoints, honorPoints, todayHonor, yesterdayHonor, lifetimeKills, todayKills, yesterdayKills, accountId
        ))
    end, 1000, 1)
end

InitializeAccountwidePvPRankTable()

RegisterPlayerEvent(3, SyncPvPRankOnLogin)  -- EVENT_ON_LOGIN
RegisterPlayerEvent(4, SyncPvPRankOnLogout)  -- EVENT_ON_LOGOUT