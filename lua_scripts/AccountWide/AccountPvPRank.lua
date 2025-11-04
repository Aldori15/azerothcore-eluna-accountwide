-- ----------------------------------------------------------------------------------------------
-- ACCOUNTWIDE PVP RANK CONFIG 
-- Hosted by Aldori15 on Github: https://github.com/Aldori15/azerothcore-lua-accountwide
-- ----------------------------------------------------------------------------------------------

local ENABLE_ACCOUNTWIDE_PVP_RANK = false

local ANNOUNCE_ON_LOGIN = false
local ANNOUNCEMENT = "This server is running the |cFF00B0E8AccountWide PvP Rank |rlua script."

-- ----------------------------------------------------------------------------------------------
-- Initialize SQL Table (called once at server start)
-- ----------------------------------------------------------------------------------------------

if not ENABLE_ACCOUNTWIDE_PVP_RANK then return end

local AUtils = AccountWideUtils

local function InitializeAccountwidePvPRankTable()
    -- Refresh accountwide totals from current character sums
    CharDBExecute([[
        INSERT INTO `acore_characters`.`accountwide_pvp_rank` (
            accountId, arenaPoints, totalHonorPoints, todayHonorPoints, yesterdayHonorPoints,
            totalKills, todayKills, yesterdayKills
        )
        SELECT
            c.account                     AS accountId,
            SUM(c.arenaPoints)            AS arenaPoints,
            SUM(c.totalHonorPoints)       AS totalHonorPoints,
            MAX(c.todayHonorPoints)       AS todayHonorPoints,
            MAX(c.yesterdayHonorPoints)   AS yesterdayHonorPoints,
            SUM(c.totalKills)             AS totalKills,
            MAX(c.todayKills)             AS todayKills,
            MAX(c.yesterdayKills)         AS yesterdayKills
        FROM `acore_characters`.`characters` c
        JOIN `acore_auth`.`account` a ON a.id = c.account
        WHERE a.username NOT LIKE 'RNDBOT%'
        GROUP BY c.account
        ON DUPLICATE KEY UPDATE
            arenaPoints          = VALUES(arenaPoints),
            totalHonorPoints     = VALUES(totalHonorPoints),
            todayHonorPoints     = VALUES(todayHonorPoints),
            yesterdayHonorPoints = VALUES(yesterdayHonorPoints),
            totalKills           = VALUES(totalKills),
            todayKills           = VALUES(todayKills),
            yesterdayKills       = VALUES(yesterdayKills)
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

-- ----------------------------------------------------------------------------------------------
-- On Player Login: fallback sync to accountwide values
-- ----------------------------------------------------------------------------------------------
local function SyncPvPRankOnLogin(event, player)
    if ANNOUNCE_ON_LOGIN then
        player:SendBroadcastMessage(ANNOUNCEMENT)
    end

    local accountId = player:GetAccountId()
    -- Skip playerbot accounts
    if AUtils.isPlayerBotAccount(accountId) then return end

    local guid = player:GetGUIDLow()

    local query = CharDBQuery(string.format([[
        SELECT
            c.todayKills, c.yesterdayKills,
            aw.arenaPoints, aw.totalHonorPoints, aw.todayHonorPoints, aw.yesterdayHonorPoints,
            aw.totalKills, aw.todayKills, aw.yesterdayKills
        FROM characters c
        LEFT JOIN accountwide_pvp_rank aw ON aw.accountId = %d
        WHERE c.guid = %d
    ]], accountId, guid))

    if not query then return end

    -- If account row missing, create it from current character as seed
    if query:IsNull(2) then
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
            query:GetUInt32(0),
            query:GetUInt32(1)
        ))
        -- After seeding, re-run the normal path next login/save.
        return
    end

    local c_todayKills        = query:GetUInt32(0)
    local c_yesterdayKills    = query:GetUInt32(1)

    local aw_arenaPoints      = query:GetUInt32(2)
    local aw_totalHonorPoints = query:GetUInt32(3)
    local aw_totalKills       = query:GetUInt32(6)
    local aw_todayKills       = query:GetUInt32(7)
    local aw_yesterdayKills   = query:GetUInt32(8)

    if player:GetArenaPoints() ~= aw_arenaPoints then
        player:SetArenaPoints(aw_arenaPoints)
    end
    if player:GetHonorPoints() ~= aw_totalHonorPoints then
        player:SetHonorPoints(aw_totalHonorPoints)
    end
    if player:GetLifetimeKills() ~= aw_totalKills then
        player:SetLifetimeKills(aw_totalKills)
    end

    if c_todayKills ~= aw_todayKills or c_yesterdayKills ~= aw_yesterdayKills then
        CharDBExecute(string.format([[
            UPDATE characters
               SET todayKills = %d, yesterdayKills = %d
             WHERE guid = %d
        ]], aw_todayKills, aw_yesterdayKills, guid))
    end
end

-- ----------------------------------------------------------------------------------------------
-- On Logout: sync character values to accountwide + all other characters
-- ----------------------------------------------------------------------------------------------
local function SyncPvPRankOnLogout(event, player)
    local accountId = player:GetAccountId()
    -- Skip playerbot accounts
    if AUtils.isPlayerBotAccount(accountId) then return end

    local guid = player:GetGUIDLow()

    local arenaPoints  = player:GetArenaPoints()
    local honorPoints  = player:GetHonorPoints()
    local lifetimeKills= player:GetLifetimeKills()

    local query = CharDBQuery("SELECT todayHonorPoints, yesterdayHonorPoints, todayKills, yesterdayKills FROM characters WHERE guid = " .. guid)
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
end

-- ----------------------------------------------------------------------------------------------
-- Register Events
-- ----------------------------------------------------------------------------------------------
InitializeAccountwidePvPRankTable()
RegisterPlayerEvent(3, SyncPvPRankOnLogin)  -- EVENT_ON_LOGIN
RegisterPlayerEvent(4, SyncPvPRankOnLogout)  -- EVENT_ON_LOGOUT