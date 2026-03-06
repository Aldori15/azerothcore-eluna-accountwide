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
local pvpSnapshotByAccount = {}

local function BuildPvPRankPayload(arenaPoints, totalHonorPoints, todayHonorPoints, yesterdayHonorPoints, totalKills, todayKills, yesterdayKills)
    return {
        arenaPoints = arenaPoints,
        totalHonorPoints = totalHonorPoints,
        todayHonorPoints = todayHonorPoints,
        yesterdayHonorPoints = yesterdayHonorPoints,
        totalKills = totalKills,
        todayKills = todayKills,
        yesterdayKills = yesterdayKills
    }
end

local function IsSamePvPRankPayload(a, b)
    if not a or not b then return false end
    return a.arenaPoints == b.arenaPoints
       and a.totalHonorPoints == b.totalHonorPoints
       and a.todayHonorPoints == b.todayHonorPoints
       and a.yesterdayHonorPoints == b.yesterdayHonorPoints
       and a.totalKills == b.totalKills
       and a.todayKills == b.todayKills
       and a.yesterdayKills == b.yesterdayKills
end

local function TryGetDailyPvPFromPlayer(player)
    local hasDailyMethods =
        type(player.GetTodayHonorPoints) == "function" and
        type(player.GetYesterdayHonorPoints) == "function" and
        type(player.GetTodayKills) == "function" and
        type(player.GetYesterdayKills) == "function"

    if not hasDailyMethods then
        return nil, nil, nil, nil
    end

    return
        (player:GetTodayHonorPoints() or 0),
        (player:GetYesterdayHonorPoints() or 0),
        (player:GetTodayKills() or 0),
        (player:GetYesterdayKills() or 0)
end

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
            c.arenaPoints, c.totalHonorPoints, c.todayHonorPoints, c.yesterdayHonorPoints,
            c.totalKills, c.todayKills, c.yesterdayKills,
            aw.arenaPoints, aw.totalHonorPoints, aw.todayHonorPoints, aw.yesterdayHonorPoints,
            aw.totalKills, aw.todayKills, aw.yesterdayKills
        FROM characters c
        LEFT JOIN accountwide_pvp_rank aw ON aw.accountId = c.account
        WHERE c.guid = %d
    ]], guid))

    if not query then return end

    local c_todayHonor = query:GetUInt32(2)
    local c_yesterdayHonor = query:GetUInt32(3)
    local c_todayKills = query:GetUInt32(5)
    local c_yesterdayKills = query:GetUInt32(6)

    local awPayload

    if query:IsNull(7) then
        local seedQuery = CharDBQuery(string.format([[
            SELECT
                COALESCE(SUM(arenaPoints), 0),
                COALESCE(SUM(totalHonorPoints), 0),
                COALESCE(SUM(totalKills), 0)
            FROM characters
            WHERE account = %d
        ]], accountId))

        if seedQuery then
            -- Keep long-lived totals account-wide, but seed day-bound counters
            -- from the logging-in character to match runtime sync semantics.
            awPayload = BuildPvPRankPayload(
                seedQuery:GetUInt32(0),
                seedQuery:GetUInt32(1),
                query:GetUInt32(2),
                query:GetUInt32(3),
                seedQuery:GetUInt32(2),
                query:GetUInt32(5),
                query:GetUInt32(6)
            )
        else
            -- Fallback to this character's persisted DB values if aggregate query fails.
            awPayload = BuildPvPRankPayload(
                query:GetUInt32(0),
                query:GetUInt32(1),
                query:GetUInt32(2),
                query:GetUInt32(3),
                query:GetUInt32(4),
                query:GetUInt32(5),
                query:GetUInt32(6)
            )
        end

        CharDBExecute(string.format([[
            INSERT INTO accountwide_pvp_rank
                (accountId, arenaPoints, totalHonorPoints, todayHonorPoints, yesterdayHonorPoints, totalKills, todayKills, yesterdayKills)
            VALUES (%d, %d, %d, %d, %d, %d, %d, %d)
        ]],
            accountId,
            awPayload.arenaPoints,
            awPayload.totalHonorPoints,
            awPayload.todayHonorPoints,
            awPayload.yesterdayHonorPoints,
            awPayload.totalKills,
            awPayload.todayKills,
            awPayload.yesterdayKills
        ))
    else
        awPayload = BuildPvPRankPayload(
            query:GetUInt32(7),
            query:GetUInt32(8),
            query:GetUInt32(9),
            query:GetUInt32(10),
            query:GetUInt32(11),
            query:GetUInt32(12),
            query:GetUInt32(13)
        )
    end

    pvpSnapshotByAccount[accountId] = awPayload

    local aw_arenaPoints = awPayload.arenaPoints
    local aw_totalHonorPoints = awPayload.totalHonorPoints
    local aw_todayHonor = awPayload.todayHonorPoints
    local aw_yesterdayHonor = awPayload.yesterdayHonorPoints
    local aw_totalKills = awPayload.totalKills
    local aw_todayKills = awPayload.todayKills
    local aw_yesterdayKills = awPayload.yesterdayKills

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

    local arenaPoints = player:GetArenaPoints()
    local honorPoints = player:GetHonorPoints()
    local lifetimeKills = player:GetLifetimeKills()
    local todayHonor, yesterdayHonor, todayKills, yesterdayKills = TryGetDailyPvPFromPlayer(player)

    -- Keep delayed execution behavior for compatibility with existing flow.
    CreateLuaEvent(function()
        if todayHonor == nil then
            local query = CharDBQuery(string.format("SELECT todayHonorPoints, yesterdayHonorPoints, todayKills, yesterdayKills FROM characters WHERE guid = %d", guid))
            if not query then return end

            todayHonor = query:GetUInt32(0)
            yesterdayHonor = query:GetUInt32(1)
            todayKills = query:GetUInt32(2)
            yesterdayKills = query:GetUInt32(3)
        end

        local newPayload = BuildPvPRankPayload(
            arenaPoints,
            honorPoints,
            todayHonor,
            yesterdayHonor,
            lifetimeKills,
            todayKills,
            yesterdayKills
        )

        if IsSamePvPRankPayload(pvpSnapshotByAccount[accountId], newPayload) then
            return
        end

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
              AND (
                    arenaPoints <> %d
                 OR totalHonorPoints <> %d
                 OR todayHonorPoints <> %d
                 OR yesterdayHonorPoints <> %d
                 OR totalKills <> %d
                 OR todayKills <> %d
                 OR yesterdayKills <> %d
              )
        ]],
            arenaPoints, honorPoints, todayHonor, yesterdayHonor, lifetimeKills, todayKills, yesterdayKills,
            accountId,
            arenaPoints, honorPoints, todayHonor, yesterdayHonor, lifetimeKills, todayKills, yesterdayKills
        ))

        pvpSnapshotByAccount[accountId] = newPayload
    end, 1000, 1)
end

InitializeAccountwidePvPRankTable()

RegisterPlayerEvent(3, SyncPvPRankOnLogin)  -- EVENT_ON_LOGIN
RegisterPlayerEvent(4, SyncPvPRankOnLogout)  -- EVENT_ON_LOGOUT
