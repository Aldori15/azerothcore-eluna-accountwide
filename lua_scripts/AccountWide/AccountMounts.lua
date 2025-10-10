-- ---------------------------------------------------------------------------------------------
-- ACCOUNTWIDE MOUNTS CONFIG
--
-- Hosted by Aldori15 on Github: https://github.com/Aldori15/azerothcore-lua-accountwide
------------------------------------------------------------------------------------------------

local ENABLE_ACCOUNTWIDE_MOUNTS = false

local ANNOUNCE_ON_LOGIN = false
local ANNOUNCEMENT = "This server is running the |cFF00B0E8AccountWide Mounts |rlua script."

local MIN_MOUNT_LEVEL = 11  -- Minimum character level before mounts are learned

local RETROACTIVE_NOTIFY = true   -- notify the player when retroactive sync completes
local RETROACTIVE_DELAY_MS = 150  -- small delay after backfill

------------------------------------------------------------------------------------------------
-- END CONFIG
------------------------------------------------------------------------------------------------

if not ENABLE_ACCOUNTWIDE_MOUNTS then return end

local AUtils = AccountWideUtils

local mountSpellIDs = {
    458, -- Brown Horse
    470, -- Black Stallion
    472, -- Pinto
    580, -- Timber Wolf
    3363, -- Nether Drake
    6648, -- Chestnut Mare
    6653, -- Dire Wolf
    6654, -- Brown Wolf
    6777, -- Gray Ram
    6898, -- White Ram
    6899, -- Brown Ram
    8394, -- Striped Frostsaber
    8395, -- Emerald Raptor
    8396, -- Summon Ivory Tallstrider
    10789, -- Spotted Frostsaber
    10793, -- Striped Nightsaber
    10796, -- Turquoise Raptor
    10799, -- Violet Raptor
    10800, -- Summon Brown Tallstrider
    10801, -- Summon Gray Tallstrider
    10802, -- Summon Pink Tallstrider
    10803, -- Summon Purple Tallstrider
    10804, -- Summon Turquoise Tallstrider
    10873, -- Red Mechanostrider
    10969, -- Blue Mechanostrider
    15779, -- White Mechanostrider Mod B
    15780, -- Green Mechanostrider
    15781, -- Steel Mechanostrider
    16055, -- Black Nightsaber
    16056, -- Ancient Frostsaber
    16058, -- Primal Leopard
    16059, -- Tawny Sabercat
    16060, -- Golden Sabercat
    16080, -- Red Wolf
    16081, -- Winter Wolf
    16082, -- Palomino
    16083, -- White Stallion
    16084, -- Mottled Red Raptor
    17229, -- Winterspring Frostsaber
    17450, -- Ivory Raptor
    17453, -- Green Mechanostrider
    17454, -- Unpainted Mechanostrider
    17455, -- Purple Mechanostrider
    17456, -- Red and Blue Mechanostrider
    17459, -- Icy Blue Mechanostrider Mod A
    17460, -- Frost Ram
    17461, -- Black Ram
    17462, -- Red Skeletal Horse
    17463, -- Blue Skeletal Horse
    17464, -- Brown Skeletal Horse
    17465, -- Green Skeletal Warhorse
    17481, -- Rivendare's Deathcharger
    18363, -- Riding Kodo
    18989, -- Gray Kodo
    18990, -- Brown Kodo
    18991, -- Green Kodo
    18992, -- Teal Kodo
    22717, -- Black War Steed
    22718, -- Black War Kodo
    22719, -- Black Battlestrider
    22720, -- Black War Ram
    22721, -- Black War Raptor
    22722, -- Red Skeletal Warhorse
    22723, -- Black War Tiger
    22724, -- Black War Wolf
    23219, -- Swift Mistsaber
    23220, -- Swift Dawnsaber
    23221, -- Swift Frostsaber
    23222, -- Swift Yellow Mechanostrider
    23223, -- Swift White Mechanostrider
    23225, -- Swift Green Mechanostrider
    23227, -- Swift Palomino
    23228, -- Swift White Steed
    23229, -- Swift Brown Steed
    23238, -- Swift Brown Ram
    23239, -- Swift Gray Ram
    23240, -- Swift White Ram
    23241, -- Swift Blue Raptor
    23242, -- Swift Olive Raptor
    23243, -- Swift Orange Raptor
    23246, -- Purple Skeletal Warhorse
    23247, -- Great White Kodo
    23248, -- Great Gray Kodo
    23249, -- Great Brown Kodo
    23250, -- Swift Brown Wolf
    23251, -- Swift Timber Wolf
    23252, -- Swift Gray Wolf
    23338, -- Swift Stormsaber
    23509, -- Frostwolf Howler
    23510, -- Stormpike Battle Charger
    24242, -- Swift Razzashi Raptor
    24252, -- Swift Zulian Tiger
    24576, -- Chromatic Mount
    25675, -- Reindeer
    25858, -- Reindeer
    25859, -- Reindeer
    25863, -- Black Qiraji Battle Tank
    25953, -- Blue Qiraji Battle Tank
    26054, -- Red Qiraji Battle Tank
    26055, -- Yellow Qiraji Battle Tank
    26056, -- Green Qiraji Battle Tank
    26655, -- Black Qiraji Battle Tank
    26656, -- Black Qiraji Battle Tank
    28828, -- Nether Drake
    29059, -- Naxxramas Deathcharger
    30174, -- Riding Turtle
    31700, -- Black Qiraji Battle Tank
    31973, -- Kessel's Elekk
    32235, -- Golden Gryphon
    32239, -- Ebon Gryphon
    32240, -- Snowy Gryphon
    32242, -- Swift Blue Gryphon
    32243, -- Tawny Wind Rider
    32244, -- Blue Wind Rider
    32245, -- Green Wind Rider
    32246, -- Swift Red Wind Rider
    32289, -- Swift Red Gryphon
    32290, -- Swift Green Gryphon
    32292, -- Swift Purple Gryphon
    32295, -- Swift Green Wind Rider
    32296, -- Swift Yellow Wind Rider
    32297, -- Swift Purple Wind Rider
    32345, -- Peep the Phoenix Mount
    32420, -- Old Crappy McWeakSauce
    33630, -- Blue Mechanostrider
    33631, -- Video Mount
    33660, -- Swift Pink Hawkstrider
    34068, -- Summon Dodostrider
    34406, -- Brown Elekk
    34407, -- Great Elite Elekk
    34790, -- Dark War Talbuk
    34795, -- Red Hawkstrider
    34896, -- Cobalt War Talbuk
    34897, -- White War Talbuk
    34898, -- Silver War Talbuk
    34899, -- Tan War Talbuk
    35018, -- Purple Hawkstrider
    35020, -- Blue Hawkstrider
    35022, -- Black Hawkstrider
    35025, -- Swift Green Hawkstrider
    35027, -- Swift Purple Hawkstrider
    35028, -- Swift Warstrider
    35710, -- Gray Elekk
    35711, -- Purple Elekk
    35712, -- Great Green Elekk
    35713, -- Great Blue Elekk
    35714, -- Great Purple Elekk
    36702, -- Fiery Warhorse
    37015, -- Swift Nether Drake
    39315, -- Cobalt Riding Talbuk
    39316, -- Dark Riding Talbuk
    39317, -- Silver Riding Talbuk
    39318, -- Tan Riding Talbuk
    39319, -- White Riding Talbuk
    39450, -- Tallstrider
    39798, -- Green Riding Nether Ray
    39800, -- Red Riding Nether Ray
    39801, -- Purple Riding Nether Ray
    39802, -- Silver Riding Nether Ray
    39803, -- Blue Riding Nether Ray
    39910, -- Riding Clefthoof
    39949, -- Mount (Test Anim)
    40192, -- Ashes of Al'ar
    40212, -- Dragonmaw Nether Drake
    41252, -- Raven Lord
    41513, -- Onyx Netherwing Drake
    41514, -- Azure Netherwing Drake
    41515, -- Cobalt Netherwing Drake
    41516, -- Purple Netherwing Drake
    41517, -- Veridian Netherwing Drake
    41518, -- Violet Netherwing Drake
    42363, -- Dan's Steam Tank Form
    42387, -- Dan's Steam Tank Form (Self)
    42776, -- Spectral Tiger
    42777, -- Swift Spectral Tiger
    42929, -- [DNT] Test Mount
    43688, -- Amani War Bear
    43810, -- Frost Wyrm
    43880, -- Ramstein's Swift Work Ram
    43883, -- Rental Racing Ram
    43899, -- Brewfest Ram
    43900, -- Swift Brewfest Ram
    43927, -- Cenarion War Hippogryph
    44317, -- Merciless Nether Drake
    44655, -- Flying Reindeer
    44744, -- Merciless Nether Drake
    44824, -- Flying Reindeer
    44825, -- Flying Reindeer
    44827, -- Flying Reindeer
    45177, -- Copy of Riding Turtle
    46197, -- X-51 Nether-Rocket
    46199, -- X-51 Nether-Rocket X-TREME
    46628, -- Swift White Hawkstrider
    46980, -- Northrend Nerubian Mount (Test)
    47037, -- Swift War  Elekk
    48023, -- Headless Horseman's Mount
    48024, -- Headless Horseman's Mount
    48025, -- Headless Horseman's Mount
    48027, -- Black War Elekk
    48954, -- Swift Zhevra
    49193, -- Vengeful Nether Drake
    49322, -- Swift Zhevra
    49378, -- Brewfest Riding Kodo
    49379, -- Great Brewfest Kodo
    49908, -- Pink Elekk
    50281, -- Black Warp Stalker
    50869, -- Brewfest Kodo
    50870, -- Brewfest Ram
    51412, -- Big Battle Bear
    51617, -- Headless Horseman's Mount
    51621, -- Headless Horseman's Mount
    51960, -- Frost Wyrm Mount
    54753, -- White Polar Bear
    55164, -- Swift Spectral Gryphon
    55293, -- Amani War Bear
    55531, -- Mechano-hog
    58615, -- Brutal Nether Drake
    58819, -- Swift Brown Steed
    58983, -- Big Blizzard Bear
    58997, -- Big Blizzard Bear
    58999, -- Big Blizzard Bear
    59567, -- Azure Drake
    59568, -- Blue Drake
    59569, -- Bronze Drake
    59570, -- Red Drake
    59571, -- Twilight Drake
    59572, -- Black Polar Bear
    59573, -- Brown Polar Bear
    59650, -- Black Drake
    59785, -- Black War Mammoth
    59788, -- Black War Mammoth
    59791, -- Wooly Mammoth
    59793, -- Wooly Mammoth
    59797, -- Ice Mammoth
    59799, -- Ice Mammoth
    59802, -- Grand Ice Mammoth
    59804, -- Grand Ice Mammoth
    59961, -- Red Proto-Drake
    59976, -- Black Proto-Drake
    59996, -- Blue Proto-Drake
    60002, -- Time-Lost Proto-Drake
    60021, -- Plagued Proto-Drake
    60024, -- Violet Proto-Drake
    60025, -- Albino Drake
    60114, -- Armored Brown Bear
    60116, -- Armored Brown Bear
    60118, -- Black War Bear
    60119, -- Black War Bear
    60136, -- Grand Caravan Mammoth
    60140, -- Grand Caravan Mammoth
    60424, -- Mekgineer's Chopper
    61229, -- Armored Snowy Gryphon
    61230, -- Armored Blue Wind Rider
    61294, -- Green Proto-Drake
    61425, -- Traveler's Tundra Mammoth (Alliance)
    61447, -- Traveler's Tundra Mammoth (Horde)
    61465, -- Grand Black War Mammoth
    61467, -- Grand Black War Mammoth
    61469, -- Grand Ice Mammoth
    61470, -- Grand Ice Mammoth
    61983, -- Dan's Test Mount
    61996, -- Blue Dragonhawk
    61997, -- Red Dragonhawk
    62048, -- Black Dragonhawk Mount
    63232, -- Stormwind Steed
    63635, -- Darkspear Raptor
    63636, -- Ironforge Ram
    63637, -- Darnassian Nightsaber
    63638, -- Gnomeregan Mechanostrider
    63639, -- Exodar Elekk
    63640, -- Orgrimmar Wolf
    63641, -- Thunder Bluff Kodo
    63642, -- Silvermoon Hawkstrider
    63643, -- Forsaken Warhorse
    63796, -- Mimiron's Head
    63844, -- Argent Hippogryph
    63956, -- Ironbound Proto-Drake
    63963, -- Rusted Proto-Drake
    64656, -- Blue Skeletal Warhorse
    64657, -- White Kodo
    64658, -- Black Wolf
    64659, -- Venomhide Ravasaur
    64681, -- Loaned Gryphon
    64731, -- Sea Turtle
    64761, -- Loaned Wind Rider
    64927, -- Deadly Gladiator's Frost Wyrm
    64977, -- Black Skeletal Horse
    64992, -- Big Blizzard Bear [PH]
    64993, -- Big Blizzard Bear [PH]
    65439, -- Furious Gladiator's Frost Wyrm
    65637, -- Great Red Elekk
    65638, -- Swift Moonsaber
    65639, -- Swift Red Hawkstrider
    65640, -- Swift Gray Steed
    65641, -- Great Golden Kodo
    65642, -- Turbostrider
    65643, -- Swift Violet Ram
    65644, -- Swift Purple Raptor
    65645, -- White Skeletal Warhorse
    65646, -- Swift Burgundy Wolf
    65917, -- Magic Rooster
    66087, -- Silver Covenant Hippogryph
    66088, -- Sunreaver Dragonhawk
    66090, -- Quel'dorei Steed
    66091, -- Sunreaver Hawkstrider
    66122, -- Magic Rooster
    66123, -- Magic Rooster
    66124, -- Magic Rooster
    66846, -- Ochre Skeletal Warhorse
    66847, -- Striped Dawnsaber
    67336, -- Relentless Gladiator's Frost Wyrm
    67466, -- Argent Warhorse
    68056, -- Swift Horde Wolf
    68057, -- Swift Alliance Steed
    68187, -- Crusader's White Warhorse
    68188, -- Crusader's Black Warhorse
    68768, -- Little White Stallion
    68769, -- Little Ivory Raptor
    69395, -- Onyxian Drake
    71342, -- Big Love Rocket
    71343, -- Big Love Rocket
    71344, -- Big Love Rocket
    71345, -- Big Love Rocket
    71346, -- Big Love Rocket
    71347, -- Big Love Rocket
    71810, -- Wrathful Gladiator's Frost Wyrm
    72281, -- Invincible
    72282, -- Invincible
    72283, -- Invincible
    72284, -- Invincible
    72286, -- Invincible
    72807, -- Icebound Frostbrood Vanquisher
    72808, -- Bloodbathed Frostbrood Vanquisher
    74854, -- Blazing Hippogryph
    74855, -- Blazing Hippogryph
    74856, -- Blazing Hippogryph
    74918, -- Wooly White Rhino
    75614, -- Celestial Steed
    75617, -- Celestial Steed
    75618, -- Celestial Steed
    75619, -- Celestial Steed
    75620, -- Celestial Steed
    75957, -- X-53 Touring Rocket
    75972, -- X-53 Touring Rocket
    75973, -- X-53 Touring Rocket
    76153, -- Celestial Steed
    76154, -- X-53 Touring Rocket
    10792, -- Spotted Panther
    17458, -- Fluorescent Green Mechanostrider

    -- class mounts
    66906, -- Argent Charger
    66907, -- Argent Warhorse
    13819, -- Warhorse
    23214, -- Charger
    34769, -- Summon Warhorse
    34767, -- Summon Charger
    48778, -- Acherus Deathcharger
    54726, -- Winged Steed of the Ebon Blade
    54727, -- Winged Steed of the Ebon Blade
    54729, -- Winged Steed of the Ebon Blade
    73313, -- Crimson Deathcharger
    23161, -- Dreadsteed
    5784, -- Felsteed

    -- profession mounts
    75387, -- Tiny Mooncloth Carpet
    75596, -- Frosty Flying Carpet
    61451, -- Flying Carpet
    61442, -- Swift Mooncloth Carpet
    61444, -- Swift Shadoweave Carpet
    61446, -- Swift Spellfire Carpet
    61309, -- Magnificent Flying Carpet
    44151, -- Turbo-Charged Flying Machine
    44153, -- Flying Machine

    -- old vanilla faction mounts
    459, -- Gray Wolf
    468, -- White Stallion
    471, -- Palamino
    578, -- Black Wolf
    579, -- Red Wolf
    581, -- Winter Wolf
    6896, -- Black Ram
    6897, -- Blue Ram
    10788, -- Leopard
    10790, -- Tiger
    8980, -- Skeletal Horse
    10787, -- Black Nightsaber
    10795, -- Ivory Raptor
    10798, -- Obsidian Raptor

    -- mounts from items with duration
    42667, -- Flying Broom
    42668, -- Swift Flying Broom
    42680, -- Magic Broom
    42683, -- Swift Magic Broom
    42692, -- Rickety Magic Broom
    47977, -- Magic Broom
    61289, -- Borrowed Broom

    -- Custom exotic mounts
    80055,   -- Primal Flamesaber
    80865,   -- Core Hound
    80875,   -- Lucid Nightmare
    80876,   -- Brown Mystic Courser
    80877,   -- Dark Lucid Nightmare
    80878,   -- Wild Dreamrunner
    80880,   -- White Ethereal Courser
    80881,   -- Black Lucid Nightmare
    80882,   -- Dark Dreaming Courser
    80887,   -- Shimmermist Wanderer
    80888,   -- Dark Wanderer
    80889,   -- Doe Wanderer
    80890,   -- Swift Shimmermist Runner
    80891,   -- Swift Gloomhoof
    80892,   -- Agile Forest Doe
    80899,   -- Prestigious Forestshade Courser
    80900,   -- Prestigious Ivory Gale Courser
    80901,   -- Prestigious Twilight Courser
    80902,   -- Prestigious Emberwood Courser
    80903,   -- Prestigious Midnight War Courser
    100121,  -- Vicious War Fox
    800150,  -- Frostwing Drake (Sapphiron's Icy Reins)
    816056,  -- Gelatinous Stalker
    826655,  -- Armored Red Qiraji Battle Tank
    826656,  -- Armored Yellow Qiraji Battle Tank
    826657,  -- Armored Green Qiraji Battle Tank
    826658,  -- Armored Ivory Qiraji Battle Tank
    826659,  -- Armored Blue Qiraji Battle Tank
    1700157, -- WhimsyshireCloudMount_Angry
    1700158, -- WhimsyshireCloudMount_Frozen
    1700159, -- WhimsyshireCloudMount_Happy
    1700160, -- WhimsyshireCloudMount_Smiling
    1700161, -- WhimsyshireCloudMount_Sad
    1700162, -- WhimsyshireCloudMount_DBZ
    1700000, -- Felsaber
    1700001, -- Slayers Felbroken Shrieker
    1700002, -- Deathlords Vilebrood Vanquisher
    1700003, -- Reins of the Bloodbathed Frostbrood Vanquisher
    1700004, -- Reins of the Icebound Frostbrood Vanquisher
    1700005, -- Reins of the Scourgebound Vanquisher
    1700006, -- Trust of a Dire Wolfhawk
    1700007, -- Trust of a Fierce Wolfhawk
    1700008, -- Huntmasters Loyal Wolfhawk
    1700009, -- Archmages Prismatic Disc Arcane
    1700010, -- Archmages Prismatic Disc Fire
    1700011, -- Archmages Prismatic Disc Frost
    1700012, -- Ban-Lu, Grandmasters Companion
    1700013, -- Highlords Golden Charger
    1700014, -- Highlords Vigilant Charger
    1700015, -- Highlords Vengefull Charger
    1700016, -- Highlords Valorous Charger
    1700017, -- High Priests Lightsworn Seeker Discipline
    1700018, -- High Priests Lightsworn Seeker Holy
    1700019, -- High Priests Lightsworn Seeker Shadow
    1700020, -- Shadowblades Murderous Omen
    1700021, -- Mephitic Reins of Dark Portent
    1700022, -- Midnight Black Reins of Dark Portent
    1700023, -- Bloody Reins of Dark Portent
    1700024, -- Farseers Raging Tempest Elemental
    1700025, -- Farseers Raging Tempest Enhancement
    1700026, -- Farseers Raging Tempest Restoration
    1700027, -- Netherlords Chaotic Wrathsteed
    1700028, -- Hellblazing Reins of the Brimstone Wrathsteed
    1700029, -- Shadowy Reins of the Accursed Wrathsteed
    1700030, -- Battlelords Bloodthirsty War Wyrm Arms
    1700031, -- Battlelords Bloodthirsty War Wyrm Fury
    1700032, -- Battlelords Bloodthirsty War Wyrm Protection
    1700033, -- Reins of the Anduin War Charger
    1700034, -- Luminous Starseeker
    1700035, -- Honeyback Harvester
    1700036, -- Reins of the Dark Honeyback Harvester
    1700037, -- Reins of the Ruby Honeyback Harvester
    1700038, -- Reins of the Blue Bloodgorged Crawg
    1700039, -- Reins of the Dark Bloodgorged Crawg
    1700040, -- Reins of the Green Bloodgorged Crawg
    1700041, -- Reins of the Pale Bloodgorged Crawg
    1700042, -- Mighty Caravan Brutosaur
    1700043, -- Blue Caravan Brutosaur
    1700044, -- Dark Caravan Brutosaur
    1700045, -- Green Caravan Brutosaur
    1700046, -- Red Caravan Brutosaur
    1700047, -- Pale Caravan Brutosaur
    1700048, -- Reins of the Astral Cloud Serpent
    1700049, -- Warforged Nightmare
    1700050, -- Disc of the Flying Cloud
    1700051, -- Disc of the Blue Flying Cloud
    1700052, -- Disc of the Purple Flying Cloud
    1700053, -- Disc of the Red Flying Cloud
    1700054, -- Grimhowls Face Axe
    1700055, -- Dark Phoenix
    1700056, -- Shu-Zen, the Divine Sentinel
    1700057, -- Dawnforge Ram
    1700058, -- Darkforge Ram
    1700059, -- Cloudwing Hippogryph
    1700060, -- Meat Wagon
    1700061, -- Sylverian Dreamer
    1700062, -- Vulpine Familiar
    1700063, -- Obsidian Worldbreaker
    1700064, -- Alabaster Stormtalon
    1700065, -- Alabaster Thunderwing
    1700066, -- Antoran Charhound
    1700067, -- Antoran Gloomhound
    1700068, -- Felsteel Annihilator
    1700069, -- Reins of the Illidari Felstalker
    1700070, -- Primal Felsaber
    1700071, -- Reins of the Llothien Prowler
    1700072, -- Mecha-Mogul Mk2
    1700073, -- Reins of the Dark Fabious Tidestallion
    1700074, -- Reins of the Green Fabious Tidestallion
    1700075, -- Reins of the Purple Fabious Tidestallion
    1700076, -- Reins of the Red Fabious Tidestallion
    1700077, -- Reins of the Pale Fabious Tidestallion
    1700078, -- Horn of the Vicious Black War Wolf
    1700079, -- Horn of the Vicious Green War Wolf
    1700080, -- Horn of the Vicious Orange War Wolf
    1700081, -- Horn of the Vicious Purple War Wolf
    1700082, -- Horn of the Vicious Red War Wolf
    1700083, -- Prestigious Midnight Courser
    1700084, -- Prestigious Forest Courser
    1700085, -- Prestigious Royal Courser
    1700086, -- Prestigious Azure Courser
    1700087, -- Prestigious Ivory Courser
    1700088, -- Prestigious Bronze Courser
    1700089, -- Prestigious Bloodforged Courser
    1700090, -- Xiwyllag ATV blue
    1700091, -- Xiwyllag ATV green
    1700092, -- Xiwyllag ATV
    1700093, -- Xiwyllag ATV red
    1700094, -- Reins of the Infinite Timereaver
    1700095, -- Ironhoof Destroyer
    1700096, -- Armored Irontusk
    1700097, -- Beastlords Warwolf
    1700098, -- Korkron Juggernaut Blue
    1700099, -- Korkron Juggernaut Gray
    1700100, -- Korkron Juggernaut Mint
    1700101, -- Korkron Juggernaut Yellow
    1700102, -- G.M.O.D.
    1700103, -- Cindermane Charger
    1700104, -- Blessed Felcrusher
    1700105, -- Avenging Felcrusher
    1700106, -- Lightforged Felcrusher
    1700107, -- Glorious Felcrusher
    1700108, -- Lightforged Warframe
    1700109, -- Mechacycle Model W Bronze
    1700110, -- Junkheap Drifter
    1700111, -- Mechacycle Model W Silver
    1700112, -- Smoldering Ember Wyrm
    1700113, -- Kaldorei Nightsaber
    1700114, -- Reins of the purple Kaldorei Nightsaber
    1700115, -- Umber Nightsaber
    1700116, -- Sandy Nightsaber
    1700117, -- Reins of the Heavenly Onyx Cloud Serpent
    1700118, -- Reins of the Heavenly Azure Cloud Serpent
    1700119, -- Yulei, Daughter of Jade
    1700120, -- Reins of the Heavenly Crimson Cloud Serpent
    1700121, -- Reins of the Heavenly Golden Cloud Serpent
    1700122, -- Reins of the Voldunai Dunescraper
    1700123, -- Dazaralor Windreaver
    1700124, -- Reins of the Armored Cobalt Pterrordax
    1700125, -- Reins of the Armored Purple Pterrordax
    1700126, -- Reins of the Scarlet Pterrordax
    1700127, -- Reins of the Armored Pale Pterrordax
    1700128, -- Ratstallion
    1700130, -- Priestess Moonsaber
    1700131, -- Ankoan Waveray
    1700132, -- Azshari Bloatray
    1700133, -- Silent Glider
    1700134, -- Unshackled Waveray
    1700135, -- Reins of the Bone Fossilized Raptor
    1700136, -- Reins of the Dark Fossilized Raptor
    1700137, -- Reins of the Fossilized Raptor
    1700138, -- Reins of the Ivory Fossilized Raptor
    1700139, -- The Dreadwake
    1700140, -- Deepcoral Snapdragon
    1700141, -- Royal Snapdragon
    1700142, -- Snapdragon Kelpstalker
    1700143, -- Shackled Urzul Blue
    1700144, -- Shackled Urzul Green
    1700145, -- Shackled Urzul Red
    1700146, -- Shackled Urzul Pale
    1700147, -- Bloodfang Cocoon
    1700149, -- Blue Marsh Hopper
    1700150, -- Green Marsh Hopper
    1700151, -- Yellow Marsh Hopper
    1700152, -- Reins of the Grand Expedition Yak
    1700153, -- Starcursed Voidstrider
    1700154, -- Glacial Tidestorm
    1700155, -- Glacial Tidestorm Purple
    1700156, -- Glacial Tidestorm Green
    1700163, -- Crusaders Direhorn
    1700164, -- Darkmoon Dirigible
    1700165, -- Champions Treadblade
    1700166, -- Reins of the Prestigious War Steed
    1700167, -- Reins of the Blue Vicious War Steed
    1700168, -- Reins of the Copper Vicious War Steed
    1700169, -- Reins of the Red Vicious War Steed
    1700170, -- Reins of the Silver Vicious War Steed
    1700171, -- Patties Cap
    1700172, -- Reins of the Elusive Quickhoof
    1700173, -- Reins of the Springfur Alpaca
    1700174, -- Slightly Damp Pile of Fur
    1700175, -- Patties Cap Yellow
    1700176, -- Malevolent Drone
    1700177, -- Royal Swarmers Reins
    1700178, -- Shadowbarb Drone
    1700179, -- Nyalotha Allseer
    1700180, -- Wonderwing 2.0
    1700181, -- Pale Serpent of NZoth
    1700182, -- Mail Muncher
    1700183, -- Wriggling Parasite
    1700184, -- Caravan Hyena
    1700185, -- Reins of the Wrathion Drake
    1700186, -- Ensorcelled Everwyrm
    1700188, -- Stormwind Skychaser
    1700189, -- Explorer’s Jungle Hopper
    1700190, -- Uncorrupted Voidwing
    1700192, -- Reins of the Silver Bloodgorged Hunter
    1700193, -- Reins of the Black Bloodgorged Hunter
    1700194, -- Reins of the Golden Bloodgorged Hunter
    1700196, -- Magic Broomstick
    1700197, -- Reins of the Brown Riding Camel
    1700198, -- Reins of the Grey Riding Camel
    1700199, -- Reins of the Tan Riding Camel
    1700200, -- Reins of the White Riding Camel
    1700201, -- Explorer’s Dunetrekker
    1700202, -- Snapback Scuttler
    1700203, -- Reins of the Azure Riding Crane
    1700204, -- Reins of the Golden Riding Crane
    1700205, -- Reins of the Regal Riding Crane
    1700206, -- Reins of the Ruby Riding Crane
    1700207, -- Reins of the Pale Riding Crane
    1700208, -- Reins of the Yellow Riding Crane
    1700209, -- Reins of the Phosphorescent Stone Drake
    1700210, -- Sandstone Drake
    1700211, -- Reins of the Vitreous Stone Drake
    1700212, -- Reins of the Volcanic Stone Drake
    1700213, -- Reins of the Drake of the West Wind
    1700214, -- Reins of the Drake of the Four Winds
    1700215, -- Reins of the Drake of the South Wind
    1700216, -- Reins of the Drake of the East Wind
    1700217, -- Pond Nettle Dark
    1700218, -- Pond Nettle Green
    1700219, -- Pond Nettle Red
    1700220, -- Fathom Dweller
    1700221, -- Red Felbat
    1700222, -- Blue Felbat
    1700223, -- Dark Felbat
    1700224, -- Onyx felbat
    1700225, -- Felbat Forsaken
    1700226, -- Brinedeep Bottom-Feeder
    1700227, -- Reins of the Cobalt Primordial Direhorn
    1700228, -- Reins of the Golden Primal Direhorn
    1700229, -- Reins of the Jade Primordial Direhorn
    1700230, -- Reins of the Amber Primordial Direhorn
    1700231, -- Reins of the Palehide Direhorn
    1700232, -- Mechagon Mechanostrider
    1700233, -- Squeakers, the Trickster
    1700234, -- Gilded Prowler
    1700235, -- Vicious War Spider
    1700236, -- Bound Shadehound
    1700237, -- Eternal Phalynx of Courage
    1700238, -- Eternal Phalynx of Humility
    1700239, -- Eternal Phalynx of Loyalty
    1700240, -- Eternal Phalynx of Purity
    1700241, -- Dreamlight Runestag
    1700242, -- Shadeleaf Runestag
    1700243, -- Wakeners Runestag
    1700244, -- Winterborn Runestag
    1700245, -- Enchanted Dreamlight Runestag
    1700246, -- Enchanted Shadeleaf Runestag
    1700247, -- Enchanted Wakeners Runestag
    1700248, -- Enchanted Winterborn Runestag
    1700249, -- Fiendish Hellfire Core
    1700250, -- Lava Infernal Core
    1700251, -- Biting Frostshard Core
    1700252, -- Living Infernal Core
    1700253, -- Cobalt Infernal Core
    1700254, -- Highmountain Elderhorn
    1700255, -- Highmountain Thunderhoof
    1700256, -- Reins of the Black Thunderhoof
    1700257, -- Stonehide Elderhorn
    1700258, -- Reins of the Grove Defiler
    1700259, -- Winged Guardian
    1700261, -- Mawsworn Soulhunter
    1700263, -- Crypt Gargon
    1700264, -- Hopecrusher Gargon
    1700265, -- Inquisition Gargon
    1700266, -- Sinfall Gargon
    1700267, -- Battle Gargon Vrednic
    1700268, -- Desires Battle Gargon
    1700269, -- Gravestone Battle Armor
    1700270, -- Silessas Battle Harness
    1700271, -- Umbral Scythehorn
    1700272, -- Legsplitter War Harness
    1700273, -- Legsplitter Cobalt Harness
    1700274, -- Darkwarren Hardshell
    1700275, -- Pale Acidmaw
    1700276, -- Spinemaw Gladechewer
    1700277, -- Chittering Animite
    1700278, -- Endmire Flyer Tether
    1700279, -- Chittering Pale Animite
    1700280, -- Flametalon of Alysrazor
    1700281, -- Voidtalon of the Dark Star
    1700282, -- Frenzied Feltalon
    1700283, -- Harvesters Dredwing
    1700284, -- Horrid Dredwing
    1700285, -- Rampart Screecher
    1700286, -- Silvertip Dredwing
    1700288, -- Wild Dreamrunner
    1700289, -- Shimmermist Void Runner
    1700290, -- Wild Golden Dreamrunner
    1700291, -- Blisterback Bloodtusk
    1700292, -- Gorespine
    1700293, -- Lurid Bloodtusk
    1700294, -- Lurid Void Bloodtusk
    1700295, -- Chewed Reins of the Callow Flayedwing
    1700296, -- Gruesome Flayedwing
    1700297, -- Marrowfangs Reins
    1700298, -- Reins of the Void Flayedwing
    1700299, -- Amber Ardenmoth
    1700300, -- Duskflutter Ardenmoth
    1700301, -- Silky Shimmermoth
    1700302, -- Vibrant Flutterwing
    1700303, -- Bonesewn Fleshroc
    1700304, -- Predatory Plagueroc
    1700305, -- Reins of the Colossal Slaughterclaw
    1700306, -- Reins of the Hulking Deathroc
    1700307, -- Reins of the cobalt Flametalon
    1700308, -- Reins of the pink Flametalon
    1700309, -- Pureblood Fire Hawk
    1700310, -- Corrupted Fire Hawk
    1700311, -- Pink Fire Hawk
    1700312, -- Felfire Hawk
    1700313, -- Cobalt Fire Hawk
    1700314, -- Cosmic Gladiator’s Soul Eater
    1700315, -- Eternal Gladiator’s Soul Eater
    1700316, -- Sinfull Gladiator’s Soul Eater
    1700317, -- Unchained Gladiator’s Soul Eater
    1700318, -- Warstitched Darkhound
    1700319, -- Sintouched Deathwalker
    1700320, -- Restoration Deathwalker
    1700321, -- Soultwisted Deathwalker
    1700322, -- Ascendants Aquilon
    1700323, -- Bruce
    1700324, -- Armored Blue Dragonhawk
    1700325, -- Enchanted Fey Dragon
    1700326, -- Predatory Bloodgazer
    1700327, -- Spirit of Echero
    1700328, -- Sapphire Riverbeast
    1700329, -- Reins of the Korkron Annihilator
    1700330, -- Orgrimmar Interceptor
    1700331, -- Coalfist Gronnling
    1700332, -- Reins of the Ashhide Mushan Beast
    1700333, -- Arcanists Manasaber
    1700334, -- Ashen Pandaren Phoenix
    1700335, -- Reins of the Stormcrow
    1700336, -- Reins of the Solar Stormcrow
    1700337, -- Arcadian War Turtle
    1700338, -- Vicious War Bear Alliance
    1700339, -- Vicious War Spider Alliance
    1700340, -- Vicious War Turtle Alliance
    1700341, -- Vicious War Bear Horde
    1700342, -- Vicious War Spider Horde
    1700343, -- Waste Marauder
    1700344, -- Reins of the Azure Water Strider
    1700345, -- Vicious War Turtle Horde
    1700346, -- Reins of the Dread Raven
    1700347, -- Tyraels Charger
    1700348, -- Reins of the Gilded Golden Ravasaur
    1700349, -- Reins of the Gilded Pale Ravasaur
    1700350, -- Telix the Stormhorn Beetle
    1700351, -- Reins of the dark Zenet Hatchling
    1700352, -- Reins of the blood Zenet Hatchling
    1700353, -- Reins of the void Zenet Hatchling
    1700354, -- Divine Kiss of Ohnahra
    1700355, -- Reins of the Liberated Slyvern
    1700356, -- Temperamental Skyclaw
    1700357, -- Reins of the Pale Liberated Slyvern
    1700358, -- Reins of the Golden Liberated Slyvern
    1700359, -- Reins of the Sapphire Vorquin
    1700360, -- Reins of the Bronze Vorquin
    1700361, -- Reins of the Obsidian Vorquin
    1700362, -- Reins of the Cobalt Seething Slug
    1700363, -- Reins of the Lava Seething Slug
    1700364, -- Reins of the Blood Seething Slug
    1700365, -- Reins of the Golden Seething Slug
    1700366, -- Reins of the Cobalt Magmashell
    1700367, -- Reins of the Lava Magmashell
    1700368, -- Reins of the Blood Magmashell
    1700369, -- Reins of the Golden Magmashell
    1700370, -- Reins of the Loyal Magmammoth
    1700371, -- Reins of the Lava Magmammoth
    1700372, -- Reins of the Blood Magmammoth
    1700373, -- Reins of the Golden Magmammoth
    1700374, -- Reins of the Cobalt Plainswalker Bearer
    1700375, -- Reins of the Dark Plainswalker Bearer
    1700376, -- Reins of the Pale Plainswalker Bearer
    1700377, -- Reins of the Plainswalker Bearer
    1700378, -- Reins of the Blood Plainswalker Bearer
    1700379, -- Reins of the Noble Bruffalon
    1700380, -- Reins of the Brown Bruffalon
    1700381, -- Reins of the Dark Bruffalon
    1700382, -- Tamed Dark Skitterfly
    1700383, -- Azure Skitterfly
    1700384, -- Verdant Skitterfly
    1700385, -- Tamed Lava Skitterfly
    1700386, -- Tamed Golden Skitterfly
    1700387, -- Reins of the Ancient Azure Salamanther
    1700388, -- Reins of the Ancient Salamanther
    1700389, -- Reins of the Ancient Lava Salamanther
    1700390, -- Reins of the Ancient Pink Salamanther
    1700391, -- Reins of the Ancient Void Salamanther
    1700392, -- Coal Skyskin Hornstrider
    1700393, -- Azure Skyskin Hornstrider
    1700394, -- Emerald Skyskin Hornstrider
    1700395, -- Blood Skyskin Hornstrider
    1700396, -- Pale Skyskin Hornstrider
    1700397, -- Lizis Dark Reins
    1700398, -- Lizis Azure Reins
    1700399, -- Lizis Brown Reins
    1700400, -- Lizis Green Reins
    1700401, -- Lizis Pale Reins
    1700402, -- Dark Nether-Gorged Greatwyrm
    1700403, -- Azure Nether-Gorged Greatwyrm
    1700404, -- Void Nether-Gorged Greatwyrm
    1700405, -- Silver Nether-Gorged Greatwyrm
    1700406, -- Reins of the Armored Azure Valarjar Stormwing
    1700407, -- Reins of the Armored Dark Valarjar Stormwing
    1700408, -- Reins of the Armored Green Valarjar Stormwing
    1700409, -- Reins of the Armored Pale Valarjar Stormwing
    1700410, -- Reins of the Armored Golden Valarjar Stormwing
    1700411, -- Felstorm Dragon
    1700412, -- Uncorrupted Voidwing
}

local MOUNT_ID_SET, uniq_list = {}, {}
do
    local seen = {}
    for _, id in ipairs(mountSpellIDs) do
        if not seen[id] then
            seen[id] = true
            MOUNT_ID_SET[id] = true
            table.insert(uniq_list, id)
        end
    end
end

local function csvInt(tbl)
    local out = {}
    for _, v in ipairs(tbl) do out[#out+1] = tostring(v) end
    return table.concat(out, ",")
end

-- cache once at load:
local MOUNT_ID_CSV = csvInt(uniq_list)

local function InitializeMountTable(accountId)
    -- If this account already has any rows, skip backfill
    local exists = CharDBQuery(string.format("SELECT 1 FROM accountwide_mounts WHERE accountId = %d LIMIT 1", accountId))
    if exists then return end

    local sql = string.format([[
        INSERT IGNORE INTO accountwide_mounts (accountId, mountSpellId)
        SELECT c.account, cs.spell
        FROM characters c
        JOIN character_spell cs ON cs.guid = c.guid
        WHERE c.account = %d AND cs.spell IN (%s)
    ]], accountId, MOUNT_ID_CSV)

    CharDBExecute(sql)
    return true
end

local function OnLearnNewMount(event, player, spellID)
    local accountId = player:GetAccountId()
    -- Skip playerbot accounts
    if AUtils.isPlayerBotAccount(accountId) then return end

    if MOUNT_ID_SET[spellID] then
        CharDBExecute(string.format("INSERT IGNORE INTO accountwide_mounts (accountId, mountSpellId) VALUES (%d, %d)", accountId, spellID))
    end
end

local function LearnOwnedMountsNow(player, accountId)
    local ownedSet = {}
    local owned = CharDBQuery(string.format("SELECT mountSpellId FROM accountwide_mounts WHERE accountId = %d", accountId))
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

local function SyncMountsToPlayer(event, player)
    local accountId = player:GetAccountId()
    -- Skip playerbot accounts
    if AUtils.isPlayerBotAccount(accountId) then return end

    local playerLevel = player:GetLevel()
    if (playerLevel < MIN_MOUNT_LEVEL) then return end
    if player:HasItem(90000, 1) then return end -- Hard Mode Key
    if player:HasItem(800048, 1) then return end -- Slow and Steady Key

    if (ANNOUNCE_ON_LOGIN and event) then
        player:SendBroadcastMessage(ANNOUNCEMENT)
    end

    local didBackfill = InitializeMountTable(accountId)
    if didBackfill then
        if RETROACTIVE_NOTIFY then
            player:SendBroadcastMessage("|cff9CC243[Accountwide Mounts] Retroactive sync complete. Learning account mounts...|r")
        end
        player:RegisterEvent(function(_,_,_,p)
            LearnOwnedMountsNow(p, accountId)
        end, RETROACTIVE_DELAY_MS, 1)
    else
        LearnOwnedMountsNow(player, accountId)
    end
end

local function OnSendLearnedSpell(event, packet, player)
    local accountId = player:GetAccountId()
    -- Skip playerbot accounts
    if AUtils.isPlayerBotAccount(accountId) then return end

    local spellId = packet:ReadULong()
    -- Apprentice Riding   Journeyman Riding   Expert Riding       Artisan Riding
    if spellId == 33388 or spellId == 33391 or spellId == 34090 or spellId == 34091 then
        player:RegisterEvent((function(_,_,_,p) SyncMountsToPlayer(nil, p) end), 100, 1)
    end
end

RegisterPlayerEvent(3, SyncMountsToPlayer) -- PLAYER_EVENT_ON_LOGIN
RegisterPlayerEvent(44, OnLearnNewMount) -- PLAYER_EVENT_ON_LEARN_SPELL
RegisterPacketEvent(299, 7, OnSendLearnedSpell) -- PACKET_EVENT_ON_PACKET_SEND (SMSG_LEARNED_SPELL)
RegisterPacketEvent(300, 7, OnSendLearnedSpell) -- PACKET_EVENT_ON_PACKET_SEND (SMSG_SUPERCEDED_SPELL)