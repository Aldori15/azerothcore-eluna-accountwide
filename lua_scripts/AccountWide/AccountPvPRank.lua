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
local AUtils = AccountWideUtils

local function InitializeAccountwidePvPRankTable()
    local query = CharDBQuery("SELECT guid, account FROM characters")
    if not query then return end

    local accounts = {}

    repeat
        local guid = query:GetUInt32(0)
        local accountId = query:GetUInt32(1)

        if not accounts[accountId] then
            accounts[accountId] = {}
        end

        table.insert(accounts[accountId], guid)
    until not query:NextRow()

    for accountId, guids in pairs(accounts) do
        local check = CharDBQuery("SELECT 1 FROM accountwide_pvp_rank WHERE accountId = " .. accountId)
        if not check then
            local sums = {
                arenaPoints = 0,
                totalHonorPoints = 0,
                todayHonorPoints = 0,
                yesterdayHonorPoints = 0,
                totalKills = 0,
                todayKills = 0,
                yesterdayKills = 0,
            }

            for _, guid in ipairs(guids) do
                local data = CharDBQuery("SELECT arenaPoints, totalHonorPoints, todayHonorPoints, yesterdayHonorPoints, totalKills, todayKills, yesterdayKills FROM characters WHERE guid = " .. guid)
                if data then
                    sums.arenaPoints = sums.arenaPoints + data:GetUInt32(0)
                    sums.totalHonorPoints = sums.totalHonorPoints + data:GetUInt32(1)
                    sums.todayHonorPoints = sums.todayHonorPoints + data:GetUInt32(2)
                    sums.yesterdayHonorPoints = sums.yesterdayHonorPoints + data:GetUInt32(3)
                    sums.totalKills = sums.totalKills + data:GetUInt32(4)
                    sums.todayKills = sums.todayKills + data:GetUInt32(5)
                    sums.yesterdayKills = sums.yesterdayKills + data:GetUInt32(6)
                end
            end

            CharDBExecute(string.format([[
                INSERT INTO accountwide_pvp_rank 
                (accountId, arenaPoints, totalHonorPoints, todayHonorPoints, yesterdayHonorPoints, totalKills, todayKills, yesterdayKills)
                VALUES (%d, %d, %d, %d, %d, %d, %d, %d)
            ]],
                accountId,
                sums.arenaPoints,
                sums.totalHonorPoints,
                sums.todayHonorPoints,
                sums.yesterdayHonorPoints,
                sums.totalKills,
                sums.todayKills,
                sums.yesterdayKills
            ))

            for _, guid in ipairs(guids) do
                CharDBExecute(string.format([[
                    UPDATE characters SET 
                        arenaPoints = %d,
                        totalHonorPoints = %d,
                        todayHonorPoints = %d,
                        yesterdayHonorPoints = %d,
                        totalKills = %d,
                        todayKills = %d,
                        yesterdayKills = %d
                    WHERE guid = %d
                ]],
                    sums.arenaPoints,
                    sums.totalHonorPoints,
                    sums.todayHonorPoints,
                    sums.yesterdayHonorPoints,
                    sums.totalKills,
                    sums.todayKills,
                    sums.yesterdayKills,
                    guid
                ))
            end
        end
    end
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

    local charQuery = CharDBQuery("SELECT todayKills, yesterdayKills FROM characters WHERE guid = " .. guid)
    local acctQuery = CharDBQuery("SELECT arenaPoints, totalHonorPoints, todayHonorPoints, yesterdayHonorPoints, totalKills, todayKills, yesterdayKills FROM accountwide_pvp_rank WHERE accountId = " .. accountId)
    if not charQuery or not acctQuery then return end

    -- Sync via Eluna for live stats
    if player:GetArenaPoints() ~= acctQuery:GetUInt32(0) then
        player:SetArenaPoints(acctQuery:GetUInt32(0))
    end

    if player:GetHonorPoints() ~= acctQuery:GetUInt32(1) then
        player:SetHonorPoints(acctQuery:GetUInt32(1))
    end

    if player:GetLifetimeKills() ~= acctQuery:GetUInt32(4) then
        player:SetLifetimeKills(acctQuery:GetUInt32(4))
    end

    -- Compare kill stats (DB only)
    local todayKills = charQuery:GetUInt32(0)
    local yesterdayKills = charQuery:GetUInt32(1)

    local acctTodayKills = acctQuery:GetUInt32(5)
    local acctYesterdayKills = acctQuery:GetUInt32(6)

    if todayKills ~= acctTodayKills or yesterdayKills ~= acctYesterdayKills then
        CharDBExecute(string.format([[
            UPDATE characters SET
                todayKills = %d,
                yesterdayKills = %d
            WHERE guid = %d
        ]],
            acctTodayKills,
            acctYesterdayKills,
            guid
        ))
    end
end

-- ----------------------------------------------------------------------------------------------
-- On Save: sync character values to accountwide + all other characters
-- ----------------------------------------------------------------------------------------------
local function SyncPvPRankOnSave(event, player)
    local accountId = player:GetAccountId()
    -- Skip playerbot accounts
    if AUtils.isPlayerBotAccount(accountId) then return end

    local guid = player:GetGUIDLow()

    -- Use Eluna for in-memory values
    local charValues = {
        arenaPoints = player:GetArenaPoints(),
        totalHonorPoints = player:GetHonorPoints(),
        totalKills = player:GetLifetimeKills()
    }

    -- Use SQL for remaining fields
    local query = CharDBQuery("SELECT todayHonorPoints, yesterdayHonorPoints, todayKills, yesterdayKills FROM characters WHERE guid = " .. guid)
    if not query then return end

    charValues.todayHonorPoints = query:GetUInt32(0)
    charValues.yesterdayHonorPoints = query:GetUInt32(1)
    charValues.todayKills = query:GetUInt32(2)
    charValues.yesterdayKills = query:GetUInt32(3)

    -- Compare to accountwide
    local acctQuery = CharDBQuery("SELECT arenaPoints, totalHonorPoints, todayHonorPoints, yesterdayHonorPoints, totalKills, todayKills, yesterdayKills FROM accountwide_pvp_rank WHERE accountId = " .. accountId)
    if not acctQuery then return end

    local acctValues = {
        arenaPoints = acctQuery:GetUInt32(0),
        totalHonorPoints = acctQuery:GetUInt32(1),
        todayHonorPoints = acctQuery:GetUInt32(2),
        yesterdayHonorPoints = acctQuery:GetUInt32(3),
        totalKills = acctQuery:GetUInt32(4),
        todayKills = acctQuery:GetUInt32(5),
        yesterdayKills = acctQuery:GetUInt32(6)
    }

    local changed = false
    for k, v in pairs(charValues) do
        if v ~= acctValues[k] then
            changed = true
            break
        end
    end

    if not changed then return end

    -- Update accountwide
    CharDBExecute(string.format([[
        UPDATE accountwide_pvp_rank SET
            arenaPoints = %d,
            totalHonorPoints = %d,
            todayHonorPoints = %d,
            yesterdayHonorPoints = %d,
            totalKills = %d,
            todayKills = %d,
            yesterdayKills = %d
        WHERE accountId = %d
    ]],
        charValues.arenaPoints,
        charValues.totalHonorPoints,
        charValues.todayHonorPoints,
        charValues.yesterdayHonorPoints,
        charValues.totalKills,
        charValues.todayKills,
        charValues.yesterdayKills,
        accountId
    ))

    -- Sync to all other characters
    local otherChars = CharDBQuery("SELECT guid FROM characters WHERE account = " .. accountId)
    if otherChars then
        repeat
            local otherGuid = otherChars:GetUInt32(0)
            if otherGuid ~= guid then
                CharDBExecute(string.format([[
                    UPDATE characters SET
                        arenaPoints = %d,
                        totalHonorPoints = %d,
                        todayHonorPoints = %d,
                        yesterdayHonorPoints = %d,
                        totalKills = %d,
                        todayKills = %d,
                        yesterdayKills = %d
                    WHERE guid = %d
                ]],
                    charValues.arenaPoints,
                    charValues.totalHonorPoints,
                    charValues.todayHonorPoints,
                    charValues.yesterdayHonorPoints,
                    charValues.totalKills,
                    charValues.todayKills,
                    charValues.yesterdayKills,
                    otherGuid
                ))
            end
        until not otherChars:NextRow()
    end
end

-- ----------------------------------------------------------------------------------------------
-- Register Events
-- ----------------------------------------------------------------------------------------------
if ENABLE_ACCOUNTWIDE_PVP_RANK then
    InitializeAccountwidePvPRankTable()
    RegisterPlayerEvent(3, SyncPvPRankOnLogin)  -- EVENT_ON_LOGIN
    RegisterPlayerEvent(25, SyncPvPRankOnSave)      -- EVENT_ON_SAVE
end
