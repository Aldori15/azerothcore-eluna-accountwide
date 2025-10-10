-- ---------------------------------------------------------------------------------------------
-- ACCOUNTWIDE PETS CONFIG
--
-- Hosted by Aldori15 on Github: https://github.com/Aldori15/azerothcore-lua-accountwide
------------------------------------------------------------------------------------------------

local ENABLE_ACCOUNTWIDE_PETS = false

local ANNOUNCE_ON_LOGIN = false
local ANNOUNCEMENT = "This server is running the |cFF00B0E8AccountWide Pets |rlua script."

local RETROACTIVE_NOTIFY = true   -- notify the player when retroactive sync completes
local RETROACTIVE_DELAY_MS = 150  -- small delay after backfill

------------------------------------------------------------------------------------------------
-- END CONFIG
------------------------------------------------------------------------------------------------

if not ENABLE_ACCOUNTWIDE_PETS then return end

local AUtils = AccountWideUtils

local petSpellIDs = {
    4055,  -- Mechanical Squirrel
    10673,  -- Bombay Cat
    10674,  -- Cornish Rex Cat
    10675,  -- Black Tabby Cat
    10676,  -- Orange Tabby Cat
    10677,  -- Siamese Cat
    10678,  -- Silver Tabby Cat
    10679,  -- White Kitten
    10680,  -- Cockatiel
    10682,  -- Hyacinth Macaw
    10683,  -- Green Wing Macaw
    10684,  -- Senegal
    10685,  -- Abcona Chicken
    10688,  -- Cockroach
    10695,  -- Dark Whelpling
    10696,  -- Azure Whelpling
    10697,  -- Crimson Whelpling
    10698,  -- Emerald Whelpling
    10703,  -- Wood Frog
    10704,  -- Tree Frog
    10706,  -- Hawk Owl
    10707,  -- Great Horned Owl
    10709,  -- Brown Prairie Dog
    10711,  -- Snowshoe Rabbit
    10713,  -- Albino Snake
    10714,  -- Black Kingsnake
    10716,  -- Brown Snake
    10717,  -- Crimson Snake
    12243,  -- Mechanical Chicken
    13548,  -- Westfall Chicken
    15048,  -- Pet Bombling
    15049,  -- Lil' Smoky
    15067,  -- Sprite Darter Hatchling
    15648,  -- Corrupted Kitten
    15999,  -- Worg Pup
    16450,  -- Smolderweb Hatchling
    17707,  -- Panda Cub
    17708,  -- Mini Diablo
    17709,  -- Zergling
    19772,  -- Lifelike Toad
    23429,  -- Loggerhead Snapjaw
    23811,  -- Jubling
    23530,  -- Tiny Red Dragon
    23531,  -- Tiny Green Dragon
    24988,  -- Lurky
    25018,  -- Murki
    25162,  -- Disgusting Oozeling
    25849,  -- Baby Shark
    26010,  -- Tranquil Mechanical Yeti
    26045,  -- Tiny Snowman
    26529,  -- Winter Reindeer
    26533,  -- Father Winter's Helper
    26541,  -- Winter's Little Helper
    27241,  -- Gurky
    27570,  -- Peddlefeet
    28487,  -- Terky
    28505,  -- Poley
    28738,  -- Speedy
    28739,  -- Mr. Wiggles
    28740,  -- Whiskers the Rat
    28871,  -- Spirit of Summer
    30152,  -- White Tiger Cub
    30156,  -- Hippogryph Hatchling
    32298,  -- Netherwhelp
    33050,  -- Magical Crawdad
    35156,  -- Mana Wyrmling
    35239,  -- Brown Rabbit
    35907,  -- Blue Moth
    35909,  -- Red Moth
    35910,  -- Yellow Moth
    35911,  -- White Moth
    36027,  -- Golden Dragonhawk Hatchling
    36028,  -- Red Dragonhawk Hatchling
    36029,  -- Silver Dragonhawk Hatchling
    36031,  -- Blue Dragonhawk Hatchling
    36034,  -- Firefly
    39181,  -- Miniwing
    39709,  -- Wolpertinger
    40405,  -- Lucky
    40549,  -- Bananas
    40613,  -- Willy
    40614,  -- Egbert
    40634,  -- Peanut
    40990,  -- Stinker
    42609,  -- Sinister Squashling
    43697,  -- Toothy
    43698,  -- Muckbreath
    43918,  -- Mojo
    44369,  -- Pint-Sized Pink Pachyderm
    45082,  -- Tiny Sporebat
    45125,  -- Rocket Chicken
    45127,  -- Dragon Kite
    45174,  -- Golden Pig
    45175,  -- Silver Pig
    45890,  -- Scorchling
    46425,  -- Snarly
    46426,  -- Chuck
    46599,  -- Phoenix Hatchling
    48406,  -- Spirit of Competition
    48408,  -- Essence of Competition
    49964,  -- Ethereal Soul-Trader
    51716,  -- Nether Ray Fry
    51851,  -- Vampiric Batling
    52615,  -- Frosty
    53082,  -- Mini Tyrael
    53316,  -- Ghostly Skull
    54187,  -- Clockwork Rocket Bot
    55068,  -- Mr. Chilly
    59250,  -- Giant Sewer Rat
    61348,  -- Tickbird Hatchling
    61349,  -- White Tickbird Hatchling
    61350,  -- Proto-Drake Whelp
    61351,  -- Cobra Hatchling
    61357,  -- Pengu
    61472,  -- Kirin Tor Familiar
    61725,  -- Spring Rabbit
    61773,  -- Plump Turkey
    61855,  -- Baby Blizzard Bear
    61991,  -- Little Fawn
    62491,  -- Teldrassil Sproutling
    62508,  -- Dun Morogh Cub
    62510,  -- Tirisfal Batling
    62513,  -- Durotar Scorpion
    62514,  -- Alarming Clockbot
    62516,  -- Elwynn Lamb
    62542,  -- Mulgore Hatchling
    62561,  -- Strand Crawler
    62562,  -- Ammen Vale Lashling
    62564,  -- Enchanted Broom
    62609,  -- Argent Squire
    62674,  -- Mechanopeep
    62746,  -- Argent Gruntling
    63318,  -- Murkimus the Gladiator
    63712,  -- Sen'jin Fetish
    64351,  -- XS-001 Constructor Bot
    65358,  -- Calico Cat
    65381,  -- Curious Oracle Hatchling
    65382,  -- Curious Wolvar Pup
    65682,  -- Warbot
    66030,  -- Grunty
    66096,  -- Shimmering Wyrmling
    66520,  -- Jade Tiger
    67413,  -- Darting Hatchling
    67414,  -- Deviate Hatchling
    67415,  -- Gundrak Hatchling
    67416,  -- Leaping Hatchling
    67417,  -- Obsidian Hatchling
    67418,  -- Ravasaur Hatchling
    67419,  -- Razormaw Hatchling
    67420,  -- Razzashi Hatchling
    67527,  -- Onyx Panther
    68810,  -- Spectral Tiger Cub
    68767,  -- Tuskarr Kite
    69002,  -- Onyxian Whelpling
    69452,  -- Core Hound Pup
    69535,  -- Gryphon Hatchling
    69536,  -- Wind Rider Cub
    69539,  -- Zipao Tiger
    69541,  -- Pandaren Monk
    69677,  -- Lil' K.T.
    70613,  -- Perky Pug
    71840,  -- Toxic Wasteling
    74932,  -- Frigid Frostling
    75134,  -- Blue Clockwork Rocket Bot
    75613,  -- Celestial Dragon
    75906,  -- Lil' XT
    75936,  -- Murkimus the Gladiator
    78381,  -- Mini Thor

    795023,  -- Blinky
    1001005, -- Mini Mindslayer
    1001006, -- Anubisith Idol
    1001007, -- Giant Bone Spider
    1001008, -- Fungal Abomination
    1001009, -- Stitched Pup
    1001010, -- Harbinger of Flame
    1001011, -- Corefire Imp
    1001012, -- Ashstone Core
    1001013, -- Untamed Hatchling
    1001014, -- Chrominius
    1001015, -- Death Talon Whelpguard
    1001016, -- Viscidus Globule
    1001017, -- Lil' Ragnaros
    1001029, -- Mr. Bigglesworth
}

local PET_ID_SET, uniq_pets = {}, {}
do
    local seen = {}
    for _, id in ipairs(petSpellIDs) do
        if not seen[id] then
            seen[id] = true
            PET_ID_SET[id] = true
            table.insert(uniq_pets, id)
        end
    end
end

local function csvInt(tbl)
    local out = {}
    for _, v in ipairs(tbl) do out[#out+1] = tostring(v) end
    return table.concat(out, ",")
end

-- cache once at load:
local PET_ID_CSV = csvInt(uniq_pets)

local function InitializePetTable(accountId)
    -- If this account already has any rows, skip backfill
    local exists = CharDBQuery(string.format("SELECT 1 FROM accountwide_pets WHERE accountId = %d LIMIT 1", accountId))
    if exists then return end

    local sql = string.format([[
        INSERT IGNORE INTO accountwide_pets (accountId, petSpellId)
        SELECT c.account, cs.spell
        FROM characters c
        JOIN character_spell cs ON cs.guid = c.guid
        WHERE c.account = %d AND cs.spell IN (%s)
    ]], accountId, PET_ID_CSV)

    CharDBExecute(sql)
    return true
end

local function OnLearnNewPet(event, player, spellID)
    local accountId = player:GetAccountId()
    -- Skip playerbot accounts
    if AUtils.isPlayerBotAccount(accountId) then return end

    if PET_ID_SET[spellID] then
        CharDBExecute(string.format("INSERT IGNORE INTO accountwide_pets (accountId, petSpellId) VALUES (%d, %d)", accountId, spellID))
    end
end

local function LearnOwnedPetsNow(player, accountId)
    local ownedSet = {}
    local owned = CharDBQuery(string.format("SELECT petSpellId FROM accountwide_pets WHERE accountId = %d", accountId))
    if owned then
        repeat
            ownedSet[owned:GetUInt32(0)] = true
        until not owned:NextRow()
    end

    if next(ownedSet) == nil then return end

    -- Learn only those the account owns (and this character doesn't yet have)
    for spellId in pairs(ownedSet) do
        if not player:HasSpell(spellId) then
            player:LearnSpell(spellId)
        end
    end
end

local function SyncPetsToPlayer(event, player)
    local accountId = player:GetAccountId()
    -- Skip playerbot accounts
    if AUtils.isPlayerBotAccount(accountId) then return end
    
    if (ANNOUNCE_ON_LOGIN and event) then
        player:SendBroadcastMessage(ANNOUNCEMENT)
    end

    local didBackfill = InitializePetTable(accountId)
    if didBackfill then
        if RETROACTIVE_NOTIFY then
            player:SendBroadcastMessage("|cff9CC243[Accountwide Pets] Retroactive sync complete. Learning account pets...|r")
        end

        player:RegisterEvent(function(_,_,_,p)
            LearnOwnedPetsNow(p, accountId)
        end, RETROACTIVE_DELAY_MS, 1)
    else
        LearnOwnedPetsNow(player, accountId)
    end
end

RegisterPlayerEvent(3, SyncPetsToPlayer) -- PLAYER_EVENT_ON_LOGIN 
RegisterPlayerEvent(44, OnLearnNewPet) -- PLAYER_EVENT_ON_LEARN_SPELL 