-- ---------------------------------------------------------------------------------------------
-- ACCOUNTWIDE PETS CONFIG
--
-- Hosted by Aldori15 on Github: https://github.com/Aldori15/azerothcore-lua-accountwide
------------------------------------------------------------------------------------------------

local ENABLE_ACCOUNTWIDE_PETS = false

local ANNOUNCE_ON_LOGIN = true
local ANNOUNCEMENT = "This server is running the |cFF00B0E8AccountWide Pets |rmodule."

------------------------------------------------------------------------------------------------
-- END CONFIG
------------------------------------------------------------------------------------------------

if (not ENABLE_ACCOUNTWIDE_PETS) then return end

-- These are the spell IDs, not item IDs
local petIDs = {
    10713,  -- Albino Snake
    62562,  -- Ammen Vale Lashling
    10685,  -- Abcona Chicken
    62746,  -- Argent Gruntling
    62609,  -- Argent Squire
    10696,  -- Azure Whelpling
    61855,  -- Baby Blizzard Bear
    40549,  -- Bananas
    10714,  -- Black Kingsnake
    10675,  -- Black Tabby Cat
    75134,  -- Blue Clockwork Rocket Bot
    36031,  -- Blue Dragonhawk Hatchling
    35907,  -- Blue Moth
    10673,  -- Bombay Cat
    10709,  -- Brown Prairie Dog
    35239,  -- Brown Rabbit
    10716,  -- Brown Snake
    65358,  -- Calico Cat
    75613,  -- Celestial Dragon
    46426,  -- Chuck
    54187,  -- Clockwork Rocket Bot
    61351,  -- Cobra Hatchling
    10680,  -- Cockatiel
    10688,  -- Cockroach
    69452,  -- Core Hound Pup
    10674,  -- Cornish Rex Cat
    10717,  -- Crimson Snake
    10697,  -- Crimson Whelpling
    65381,  -- Curious Oracle Hatchling
    65382,  -- Curious Wolvar Pup
    10695,  -- Dark Whelpling
    67413,  -- Darting Hatchling
    67414,  -- Deviate Hatchling
    25162,  -- Disgusting Oozeling
    45127,  -- Dragon Kite
    62508,  -- Dun Morogh Cub
    62513,  -- Durotar Scorpion
    40614,  -- Egbert
    62516,  -- Elwynn Lamb
    10698,  -- Emerald Whelpling
    62564,  -- Enchanted Broom
    48408,  -- Essence of Competition
    49964,  -- Ethereal Soul-Trader
    26533,  -- Father Winter's Helper
    36034,  -- Firefly
    74932,  -- Frigid Frostling
    52615,  -- Frosty
    53316,  -- Ghostly Skull
    59250,  -- Giant Sewer Rat
    36027,  -- Golden Dragonhawk Hatchling
    45174,  -- Golden Pig
    10707,  -- Great Horned Owl
    10683,  -- Green Wing Macaw
    66030,  -- Grunty
    69535,  -- Gryphon Hatchling
    67415,  -- Gundrak Hatchling
    27241,  -- Gurky
    10706,  -- Hawk Owl
    30156,  -- Hippogryph Hatchling
    10682,  -- Hyacinth Macaw
    66520,  -- Jade Tiger
    23811,  -- Jubling
    61472,  -- Kirin Tor Familiar
    67416,  -- Leaping Hatchling
    19772,  -- Lifelike Toad
    69677,  -- Lil' K.T.
    15049,  -- Lil' Smoky
    75906,  -- Lil' XT
    61991,  -- Little Fawn
    40405,  -- Lucky
    24988,  -- Lurky
    33050,  -- Magical Crawdad
    35156,  -- Mana Wyrmling
    12243,  -- Mechanical Chicken
    4055,  -- Mechanical Squirrel
    62674,  -- Mechanopeep
    17708,  -- Mini Diablo
    78381,  -- Mini Thor
    53082,  -- Mini Tyrael
    39181,  -- Miniwing
    43918,  -- Mojo
    55068,  -- Mr. Chilly
    28739,  -- Mr. Wiggles
    43698,  -- Muckbreath
    62542,  -- Mulgore Hatchling
    25018,  -- Murki
    63318,  -- Murkimus the Gladiator
    75936,  -- Murkimus the Gladiator
    -- 24696,  -- Murky
    51716,  -- Nether Ray Fry
    32298,  -- Netherwhelp
    67417,  -- Obsidian Hatchling
    67527,  -- Onyx Panther
    69002,  -- Onyxian Whelpling
    10676,  -- Orange Tabby Cat
    17707,  -- Panda Cub
    69541,  -- Pandaren Monk
    40634,  -- Peanut
    27570,  -- Peddlefeet
    61357,  -- Pengu
    70613,  -- Perky Pug
    15048,  -- Pet Bombling
    46599,  -- Phoenix Hatchling
    44369,  -- Pint-Sized Pink Pachyderm
    61773,  -- Plump Turkey
    28505,  -- Poley
    61350,  -- Proto-Drake Whelp
    67418,  -- Ravasaur Hatchling
    67419,  -- Razormaw Hatchling
    67420,  -- Razzashi Hatchling
    36028,  -- Red Dragonhawk Hatchling
    35909,  -- Red Moth
    45125,  -- Rocket Chicken
    45890,  -- Scorchling
    63712,  -- Sen'jin Fetish
    10684,  -- Senegal
    66096,  -- Shimmering Wyrmling
    10677,  -- Siamese Cat
    36029,  -- Silver Dragonhawk Hatchling
    45175,  -- Silver Pig
    10678,  -- Silver Tabby Cat
    42609,  -- Sinister Squashling
    16450,  -- Smolderweb Hatchling
    46425,  -- Snarly
    10711,  -- Snowshoe Rabbit
    68810,  -- Spectral Tiger Cub
    28738,  -- Speedy
    48406,  -- Spirit of Competition
    28871,  -- Spirit of Summer
    61725,  -- Spring Rabbit
    15067,  -- Sprite Darter Hatchling
    40990,  -- Stinker
    62561,  -- Strand Crawler
    62491,  -- Teldrassil Sproutling
    28487,  -- Terky
    61348,  -- Tickbird Hatchling
    23531,  -- Tiny Green Dragon
    23530,  -- Tiny Red Dragon
    26045,  -- Tiny Snowman
    45082,  -- Tiny Sporebat
    62510,  -- Tirisfal Batling
    43697,  -- Toothy
    71840,  -- Toxic Wasteling
    26010,  -- Tranquil Mechanical Yeti
    10704,  -- Tree Frog
    68767,  -- Tuskarr Kite
    51851,  -- Vampiric Batling
    65682,  -- Warbot
    13548,  -- Westfall Chicken
    28740,  -- Whiskers the Rat
    10679,  -- White Kitten
    35911,  -- White Moth
    61349,  -- White Tickbird Hatchling
    30152,  -- White Tiger Cub
    40613,  -- Willy
    69536,  -- Wind Rider Cub
    26529,  -- Winter Reindeer
    26541,  -- Winter's Little Helper
    39709,  -- Wolpertinger
    10703,  -- Wood Frog
    15999,  -- Worg Pup
    35910,  -- Yellow Moth
    17709,  -- Zergling
    69539,  -- Zipao Tiger

    -- Dinkledork custom imports
    795023,  -- Blinky
}

local function CheckPetsOnLogin(event, player)
    if (ANNOUNCE_ON_LOGIN) then
        player:SendBroadcastMessage(ANNOUNCEMENT)
    end

    local accountId = player:GetAccountId()

    local charGuids = {}
    local charQuery = CharDBQuery("SELECT guid FROM characters WHERE account = "..accountId)
    if (charQuery) then
        repeat
            table.insert(charGuids, charQuery:GetUInt32(0))
        until not charQuery:NextRow()
    end

    for _, petID in ipairs(petIDs) do
        -- Check if any character on the account has the pet spell
        local spellQuery = CharDBQuery("SELECT DISTINCT spell FROM character_spell WHERE guid IN("..table.concat(charGuids, ",")..") AND spell = "..petID)
        if (spellQuery) then
            -- If the pet spell is found, check if the player knows it, if not, learn it
            if (not player:HasSpell(petID)) then
                player:LearnSpell(petID)
            end
        end
    end
end

RegisterPlayerEvent(3, CheckPetsOnLogin)