-- ------------------------------------------------------------------------------------------------
-- ACCOUNTWIDE REPUTATION CONFIG
--
-- Hosted by Aldori15 on Github: https://github.com/Aldori15/azerothcore-lua-accountwide
-- ------------------------------------------------------------------------------------------------

local ENABLE_ACCOUNTWIDE_REPUTATION = false

local ANNOUNCE_ON_LOGIN = false
local ANNOUNCEMENT = "This server is running the |cFF00B0E8AccountWide Reputation |rlua script."

-- -- ------------------------------------------------------------------------------------------------
-- END CONFIG
-- -- ------------------------------------------------------------------------------------------------

if not ENABLE_ACCOUNTWIDE_REPUTATION then return end

local AUtils = AccountWideUtils

-- Alliance and Horde race and faction definitions
local allianceRaces = {
    [1] = true, [3] = true, [4] = true, [7] = true, [11] = true, [12] = true, [14] = true, [16] = true, [19] = true, [20] = true
}

local hordeRaces = {
    [2] = true, [5] = true, [6] = true, [8] = true, [9] = true, [10] = true, [13] = true, [15] = true, [17] = true, [21] = true
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
    -- Note: Faction 1200 is currently set to a base value of 1 in the dbc, which I believe is incorrect.  I set it to 1 in the script to match the dbc, but
    -- I'm making this note for now to check it later in case the dbc gets corrected and it needs to be changed to match in this script.

    -- Alliance
    [1] = { [21] = 500, [47] = 3100, [54] = 3100, [69] = 3100, [70] = -10000, [72] = 4000, [83] = 2999, [86] = 2999, [87] = -6500, [92] = 2000, [93] = 2000, [169] = 500, [369] = 500, [469] = 3300, [470] = 500, [471] = 150, [529] = 200, [549] = 2999, [550] = 2999, [551] = 2999, [576] = -3500, [577] = 500, [910] = -42000, [930] = 3100, [932] = 0, [933] = 0, [934] = 0, [935] = 0, [936] = 0, [942] = 0, [946] = 0, [967] = 0, [970] = -2500, [978] = -1200, [989] = 0, [990] = 0, [1005] = 3000, [1011] = 0, [1012] = 0, [1015] = -42000, [1031] = 0, [1037] = 0, [1038] = 0, [1050] = 0, [1068] = 0, [1073] = 0, [1077] = 0, [1090] = 3000, [1091] = 0, [1094] = 0, [1104] = 0, [1105] = 0, [1106] = 0, [1117] = 0, [1118] = 0, [1119] = -42000, [1126] = 0, [1156] = 0, [1200] = 1 }, -- Human
    [3] = { [21] = 500, [47] = 4000, [54] = 3100, [69] = 3100, [70] = -10000, [72] = 3100, [83] = 2999, [86] = 2999, [87] = -6500, [92] = 2000, [93] = 2000, [169] = 500, [369] = 500, [469] = 3300, [470] = 500, [471] = 500, [529] = 200, [549] = 2999, [550] = 2999, [551] = 2999, [576] = -3500, [577] = 500, [910] = -42000, [930] = 3100, [932] = 0, [933] = 0, [934] = 0, [935] = 0, [936] = 0, [942] = 0, [946] = 0, [967] = 0, [970] = -2500, [978] = -1200, [989] = 0, [990] = 0, [1005] = 3000, [1011] = 0, [1012] = 0, [1015] = -42000, [1031] = 0, [1037] = 0, [1038] = 0, [1050] = 0, [1068] = 0, [1073] = 0, [1077] = 0, [1090] = 3000, [1091] = 0, [1094] = 0, [1104] = 0, [1105] = 0, [1106] = 0, [1117] = 0, [1118] = 0, [1119] = -42000, [1126] = 0, [1156] = 0, [1200] = 1 }, -- Dwarf
    [4] = { [21] = 500, [47] = 3100, [54] = 3100, [69] = 4000, [70] = -10000, [72] = 3100, [83] = 2999, [86] = 2999, [87] = -6500, [92] = 2000, [93] = 2000, [169] = 500, [369] = 500, [469] = 3300, [470] = 500, [471] = 150, [529] = 200, [549] = 2999, [550] = 2999, [551] = 2999, [576] = -3500, [577] = 500, [910] = -42000, [930] = 3100, [932] = 0, [933] = 0, [934] = 0, [935] = 0, [936] = 0, [942] = 0, [946] = 0, [967] = 0, [970] = -2500, [978] = -1200, [989] = 0, [990] = 0, [1005] = 3000, [1011] = 0, [1012] = 0, [1015] = -42000, [1031] = 0, [1037] = 0, [1038] = 0, [1050] = 0, [1068] = 0, [1073] = 0, [1077] = 0, [1090] = 3000, [1091] = 0, [1094] = 0, [1104] = 0, [1105] = 0, [1106] = 0, [1117] = 0, [1118] = 0, [1119] = -42000, [1126] = 0, [1156] = 0, [1200] = 1 }, -- Night Elf
    [7] = { [21] = 500, [47] = 3100, [54] = 4000, [69] = 3100, [70] = -10000, [72] = 3100, [83] = 2999, [86] = 2999, [87] = -6500, [92] = 2000, [93] = 2000, [169] = 500, [369] = 500, [469] = 3300, [470] = 500, [471] = 150, [529] = 200, [549] = 2999, [550] = 2999, [551] = 2999, [576] = -3500, [577] = 500, [910] = -42000, [930] = 3100, [932] = 0, [933] = 0, [934] = 0, [935] = 0, [936] = 0, [942] = 0, [946] = 0, [967] = 0, [970] = -2500, [978] = -1200, [989] = 0, [990] = 0, [1005] = 3000, [1011] = 0, [1012] = 0, [1015] = -42000, [1031] = 0, [1037] = 0, [1038] = 0, [1050] = 0, [1068] = 0, [1073] = 0, [1077] = 0, [1090] = 3000, [1091] = 0, [1094] = 0, [1104] = 0, [1105] = 0, [1106] = 0, [1117] = 0, [1118] = 0, [1119] = -42000, [1126] = 0, [1156] = 0, [1200] = 1 }, -- Gnome
    [11] = { [21] = 500, [47] = 3100, [54] = 3100, [69] = 3100, [70] = -10000, [72] = 3100, [83] = 2999, [86] = 2999, [87] = -6500, [92] = 2000, [93] = 2000, [169] = 500, [369] = 500, [469] = 3300, [470] = 500, [471] = 150, [529] = 200, [549] = 2999, [550] = 2999, [551] = 2999, [576] = -3500, [577] = 500, [910] = -42000, [930] = 4000, [932] = 3500, [933] = 0, [934] = -3500, [935] = 0, [936] = 0, [942] = 0, [946] = 0, [967] = 0, [970] = -2500, [978] = -1200, [989] = 0, [990] = 0, [1005] = 3000, [1011] = 0, [1012] = 0, [1015] = -42000, [1031] = 0, [1037] = 0, [1038] = 0, [1050] = 0, [1068] = 0, [1073] = 0, [1077] = 0, [1090] = 3000, [1091] = 0, [1094] = 0, [1104] = 0, [1105] = 0, [1106] = 0, [1117] = 0, [1118] = 0, [1119] = -42000, [1126] = 0, [1156] = 0, [1200] = 1 }, -- Draenei
    [12] = { [21] = 500, [47] = 3100, [54] = 3100, [69] = 3100, [70] = -10000, [72] = 3100, [83] = 2999, [86] = 2999, [87] = -6500, [92] = 2000, [93] = 2000, [169] = 500, [369] = 500, [469] = 3300, [470] = 500, [471] = 150, [529] = 200, [549] = 2999, [550] = 2999, [551] = 2999, [576] = -3500, [577] = 500, [910] = -42000, [930] = 3100, [932] = 0, [933] = 0, [934] = 0, [935] = 0, [936] = 0, [942] = 0, [946] = 0, [967] = 0, [970] = -2500, [978] = -1200, [989] = 0, [990] = 0, [1005] = 3000, [1011] = 0, [1012] = 0, [1015] = -42000, [1031] = 0, [1037] = 0, [1038] = 0, [1050] = 0, [1068] = 0, [1073] = 0, [1077] = 0, [1090] = 3000, [1091] = 0, [1094] = 0, [1104] = 0, [1105] = 0, [1106] = 0, [1117] = 0, [1118] = 0, [1119] = -42000, [1126] = 0, [1156] = 0, [1200] = 1 }, -- Void Elf
    [14] = { [21] = 500, [47] = 3100, [54] = 3100, [69] = 3100, [70] = -10000, [72] = 3100, [83] = 2999, [86] = 2999, [87] = -6500, [92] = 2000, [93] = 2000, [169] = 500, [369] = 500, [469] = 3300, [470] = 500, [471] = 150, [529] = 200, [549] = 2999, [550] = 2999, [551] = 2999, [576] = -3500, [577] = 500, [910] = -42000, [930] = 3100, [932] = 0, [933] = 0, [934] = 0, [935] = 0, [936] = 0, [942] = 0, [946] = 0, [967] = 0, [970] = -2500, [978] = -1200, [989] = 0, [990] = 0, [1005] = 3000, [1011] = 0, [1012] = 0, [1015] = -42000, [1031] = 0, [1037] = 0, [1038] = 0, [1050] = 0, [1068] = 0, [1073] = 0, [1077] = 0, [1090] = 3000, [1091] = 0, [1094] = 0, [1104] = 0, [1105] = 0, [1106] = 0, [1117] = 0, [1118] = 0, [1119] = -42000, [1126] = 0, [1156] = 0, [1200] = 1 }, -- High Elf
    [16] = { [21] = 500, [47] = 3100, [54] = 3100, [69] = 3100, [70] = -10000, [72] = 3100, [83] = 2999, [86] = 2999, [87] = -6500, [92] = 2000, [93] = 2000, [169] = 500, [369] = 500, [469] = 3300, [470] = 500, [471] = 150, [529] = 200, [549] = 2999, [550] = 2999, [551] = 2999, [576] = -3500, [577] = 500, [910] = -42000, [930] = 3100, [932] = 0, [933] = 0, [934] = 0, [935] = 0, [936] = 0, [942] = 0, [946] = 0, [967] = 0, [970] = -2500, [978] = -1200, [989] = 0, [990] = 0, [1005] = 3000, [1011] = 0, [1012] = 0, [1015] = -42000, [1031] = 0, [1037] = 0, [1038] = 0, [1050] = 0, [1068] = 0, [1073] = 0, [1077] = 0, [1090] = 3000, [1091] = 0, [1094] = 0, [1104] = 0, [1105] = 0, [1106] = 0, [1117] = 0, [1118] = 0, [1119] = -42000, [1126] = 0, [1156] = 0, [1200] = 1 }, -- Worgen
    [19] = { [21] = 500, [47] = 3100, [54] = 3100, [69] = 3100, [70] = -10000, [72] = 3100, [83] = 2999, [86] = 2999, [87] = -6500, [92] = 2000, [93] = 2000, [169] = 500, [369] = 500, [469] = 3300, [470] = 500, [471] = 150, [529] = 200, [549] = 2999, [550] = 2999, [551] = 2999, [576] = -3500, [577] = 500, [910] = -42000, [930] = 4000, [932] = 3500, [933] = 0, [934] = -3500, [935] = 0, [936] = 0, [942] = 0, [946] = 0, [967] = 0, [970] = -2500, [978] = -1200, [989] = 0, [990] = 0, [1005] = 3000, [1011] = 0, [1012] = 0, [1015] = -42000, [1031] = 0, [1037] = 0, [1038] = 0, [1050] = 0, [1068] = 0, [1073] = 0, [1077] = 0, [1090] = 3000, [1091] = 0, [1094] = 0, [1104] = 0, [1105] = 0, [1106] = 0, [1117] = 0, [1118] = 0, [1119] = -42000, [1126] = 0, [1156] = 0, [1200] = 1 }, -- Lightforged
    [20] = { [21] = 500, [47] = 3100, [54] = 3100, [69] = 4000, [70] = -10000, [72] = 3100, [83] = 2999, [86] = 2999, [87] = -6500, [92] = 2000, [93] = 2000, [169] = 500, [369] = 500, [469] = 3300, [470] = 500, [471] = 150, [529] = 200, [549] = 2999, [550] = 2999, [551] = 2999, [576] = -3500, [577] = 500, [910] = -42000, [930] = 3100, [932] = 0, [933] = 0, [934] = 0, [935] = 0, [936] = 0, [942] = 0, [946] = 0, [967] = 0, [970] = -2500, [978] = -1200, [989] = 0, [990] = 0, [1005] = 3000, [1011] = 0, [1012] = 0, [1015] = -42000, [1031] = 0, [1037] = 0, [1038] = 0, [1050] = 0, [1068] = 0, [1073] = 0, [1077] = 0, [1090] = 3000, [1091] = 0, [1094] = 0, [1104] = 0, [1105] = 0, [1106] = 0, [1117] = 0, [1118] = 0, [1119] = -42000, [1126] = 0, [1156] = 0, [1200] = 1 }, -- Demon Hunter (Alliance)
    -- Horde
    [2] = { [21] = 500, [67] = 3500, [68] = 3100, [70] = -10000, [76] = 4000, [81] = 3100, [83] = 2999, [86] = 2999, [87] = -6500, [92] = 2000, [93] = 2000, [169] = 500, [369] = 500, [470] = 500, [529] = 200, [530] = 3100, [549] = 2999, [550] = 2999, [551] = 2999, [576] = -3500, [577] = 500, [910] = -42000, [911] = 3100, [922] = 0, [932] = 0, [933] = 0, [934] = 0, [935] = 0, [936] = 0, [941] = -500, [942] = 0, [947] = 0, [967] = 0, [970] = -2500, [989] = 0, [990] = 0, [1005] = 3000, [1011] = 0, [1012] = 0, [1015] = -42000, [1031] = 0, [1038] = 0, [1052] = 0, [1064] = 0, [1067] = 0, [1073] = 0, [1077] = 0, [1085] = 0, [1090] = 3000, [1091] = 0, [1104] = 0, [1105] = 0, [1106] = 0, [1117] = 0, [1118] = 0, [1119] = -42000, [1124] = 0, [1156] = 0, [1200] = 1 }, -- Orc
    [5] = { [21] = 500, [67] = 3500, [68] = 4000, [70] = -10000, [76] = 3100, [81] = 3100, [83] = 2999, [86] = 2999, [87] = -6500, [92] = 2000, [93] = 2000, [169] = 500, [369] = 500, [470] = 500, [529] = 200, [530] = 3100, [549] = 2999, [550] = 2999, [551] = 2999, [576] = -3500, [577] = 500, [910] = -42000, [911] = 3100, [922] = 0, [932] = 0, [933] = 0, [934] = 0, [935] = 0, [936] = 0, [941] = -500, [942] = 0, [947] = 0, [967] = 0, [970] = -2500, [989] = 0, [990] = 0, [1005] = 3000, [1011] = 0, [1012] = 0, [1015] = -42000, [1031] = 0, [1038] = 0, [1052] = 0, [1064] = 0, [1067] = 0, [1073] = 0, [1077] = 0, [1085] = 0, [1090] = 3000, [1091] = 0, [1104] = 0, [1105] = 0, [1106] = 0, [1117] = 0, [1118] = 0, [1119] = -42000, [1124] = 0, [1156] = 0, [1200] = 1 }, -- Undead
    [6] = { [21] = 500, [67] = 3500, [68] = 3100, [70] = -10000, [76] = 3100, [81] = 4000, [83] = 2999, [86] = 2999, [87] = -6500, [92] = 2000, [93] = 2000, [169] = 500, [369] = 500, [470] = 500, [529] = 200, [530] = 3100, [549] = 2999, [550] = 2999, [551] = 2999, [576] = -3500, [577] = 500, [910] = -42000, [911] = 3100, [922] = 0, [932] = 0, [933] = 0, [934] = 0, [935] = 0, [936] = 0, [941] = -500, [942] = 0, [947] = 0, [967] = 0, [970] = -2500, [989] = 0, [990] = 0, [1005] = 3000, [1011] = 0, [1012] = 0, [1015] = -42000, [1031] = 0, [1038] = 0, [1052] = 0, [1064] = 0, [1067] = 0, [1073] = 0, [1077] = 0, [1085] = 0, [1090] = 3000, [1091] = 0, [1104] = 0, [1105] = 0, [1106] = 0, [1117] = 0, [1118] = 0, [1119] = -42000, [1124] = 0, [1156] = 0, [1200] = 1 }, -- Tauren
    [8] = { [21] = 500, [67] = 3500, [68] = 3100, [70] = -10000, [76] = 3100, [81] = 3100, [83] = 2999, [86] = 2999, [87] = -6500, [92] = 2000, [93] = 2000, [169] = 500, [369] = 500, [470] = 500, [529] = 200, [530] = 4000, [549] = 2999, [550] = 2999, [551] = 2999, [576] = -3500, [577] = 500, [910] = -42000, [911] = 3100, [922] = 0, [932] = 0, [933] = 0, [934] = 0, [935] = 0, [936] = 0, [941] = -500, [942] = 0, [947] = 0, [967] = 0, [970] = -2500, [989] = 0, [990] = 0, [1005] = 3000, [1011] = 0, [1012] = 0, [1015] = -42000, [1031] = 0, [1038] = 0, [1052] = 0, [1064] = 0, [1067] = 0, [1073] = 0, [1077] = 0, [1085] = 0, [1090] = 3000, [1091] = 0, [1104] = 0, [1105] = 0, [1106] = 0, [1117] = 0, [1118] = 0, [1119] = -42000, [1124] = 0, [1156] = 0, [1200] = 1 }, -- Troll
    [9] = { [21] = 500, [67] = 3500, [68] = 3100, [70] = -10000, [76] = 3100, [81] = 3100, [83] = 2999, [86] = 2999, [87] = -6500, [92] = 2000, [93] = 2000, [169] = 500, [369] = 500, [470] = 500, [529] = 200, [530] = 3100, [549] = 2999, [550] = 2999, [551] = 2999, [576] = -3500, [577] = 500, [910] = -42000, [911] = 3100, [922] = 0, [932] = 0, [933] = 0, [934] = 0, [935] = 0, [936] = 0, [941] = -500, [942] = 0, [947] = 0, [967] = 0, [970] = -2500, [989] = 0, [990] = 0, [1005] = 3000, [1011] = 0, [1012] = 0, [1015] = -42000, [1031] = 0, [1038] = 0, [1052] = 0, [1064] = 0, [1067] = 0, [1073] = 0, [1077] = 0, [1085] = 0, [1090] = 3000, [1091] = 0, [1104] = 0, [1105] = 0, [1106] = 0, [1117] = 0, [1118] = 0, [1119] = -42000, [1124] = 0, [1156] = 0, [1200] = 1 }, -- Goblin
    [10] = { [21] = 500, [67] = 3500, [68] = 3100, [70] = -10000, [76] = 3100, [81] = 3100, [83] = 2999, [86] = 2999, [87] = -6500, [92] = 2000, [93] = 2000, [169] = 500, [369] = 500, [470] = 500, [529] = 200, [530] = 3100, [549] = 2999, [550] = 2999, [551] = 2999, [576] = -3500, [577] = 500, [910] = -42000, [911] = 4000, [922] = 0, [932] = -3500, [933] = 0, [934] = 3500, [935] = 0, [936] = 0, [941] = -500, [942] = 0, [947] = 0, [967] = 0, [970] = -2500, [989] = 0, [990] = 0, [1005] = 3000, [1011] = 0, [1012] = 0, [1015] = -42000, [1031] = 0, [1038] = 0, [1052] = 0, [1064] = 0, [1067] = 0, [1073] = 0, [1077] = 0, [1085] = 0, [1090] = 3000, [1091] = 0, [1104] = 0, [1105] = 0, [1106] = 0, [1117] = 0, [1118] = 0, [1119] = -42000, [1124] = 0, [1156] = 0, [1200] = 1 }, -- Blood Elf
    [13] = { [21] = 500, [67] = 3500, [68] = 3100, [70] = -10000, [76] = 3100, [81] = 3100, [83] = 2999, [86] = 2999, [87] = -6500, [92] = 2000, [93] = 2000, [169] = 500, [369] = 500, [470] = 500, [529] = 200, [530] = 3100, [549] = 2999, [550] = 2999, [551] = 2999, [576] = -3500, [577] = 500, [910] = -42000, [911] = 3100, [922] = 0, [932] = 0, [933] = 0, [934] = 0, [935] = 0, [936] = 0, [941] = -500, [942] = 0, [947] = 0, [967] = 0, [970] = -2500, [989] = 0, [990] = 0, [1005] = 3000, [1011] = 0, [1012] = 0, [1015] = -42000, [1031] = 0, [1038] = 0, [1052] = 0, [1064] = 0, [1067] = 0, [1073] = 0, [1077] = 0, [1085] = 0, [1090] = 3000, [1091] = 0, [1104] = 0, [1105] = 0, [1106] = 0, [1117] = 0, [1118] = 0, [1119] = -42000, [1124] = 0, [1156] = 0, [1200] = 1 }, -- Vulpera
    [15] = { [21] = 500, [67] = 3500, [68] = 3100, [70] = -10000, [76] = 3100, [81] = 3100, [83] = 2999, [86] = 2999, [87] = -6500, [92] = 2000, [93] = 2000, [169] = 500, [369] = 500, [470] = 500, [529] = 200, [530] = 3100, [549] = 2999, [550] = 2999, [551] = 2999, [576] = -3500, [577] = 500, [910] = -42000, [911] = 3100, [922] = 0, [932] = 0, [933] = 0, [934] = 0, [935] = 0, [936] = 0, [941] = -500, [942] = 0, [947] = 0, [967] = 0, [970] = -2500, [989] = 0, [990] = 0, [1005] = 3000, [1011] = 0, [1012] = 0, [1015] = -42000, [1031] = 0, [1038] = 0, [1052] = 0, [1064] = 0, [1067] = 0, [1073] = 0, [1077] = 0, [1085] = 0, [1090] = 3000, [1091] = 0, [1104] = 0, [1105] = 0, [1106] = 0, [1117] = 0, [1118] = 0, [1119] = -42000, [1124] = 0, [1156] = 0, [1200] = 1 }, -- Pandaren (Horde)
    [17] = { [21] = 500, [67] = 3500, [68] = 3100, [70] = -10000, [76] = 3100, [81] = 3100, [83] = 2999, [86] = 2999, [87] = -6500, [92] = 2000, [93] = 2000, [169] = 500, [369] = 500, [470] = 500, [529] = 200, [530] = 3100, [549] = 2999, [550] = 2999, [551] = 2999, [576] = -3500, [577] = 500, [910] = -42000, [911] = 3100, [922] = 0, [932] = 0, [933] = 0, [934] = 0, [935] = 0, [936] = 0, [941] = -500, [942] = 0, [947] = 0, [967] = 0, [970] = -2500, [989] = 0, [990] = 0, [1005] = 3000, [1011] = 0, [1012] = 0, [1015] = -42000, [1031] = 0, [1038] = 0, [1052] = 0, [1064] = 0, [1067] = 0, [1073] = 0, [1077] = 0, [1085] = 0, [1090] = 3000, [1091] = 0, [1104] = 0, [1105] = 0, [1106] = 0, [1117] = 0, [1118] = 0, [1119] = -42000, [1124] = 0, [1156] = 0, [1200] = 1 }, -- Man'ari Eredar
    [21] = { [21] = 500, [67] = 3500, [68] = 3100, [70] = -10000, [76] = 3100, [81] = 3100, [83] = 2999, [86] = 2999, [87] = -6500, [92] = 2000, [93] = 2000, [169] = 500, [369] = 500, [470] = 500, [529] = 200, [530] = 3100, [549] = 2999, [550] = 2999, [551] = 2999, [576] = -3500, [577] = 500, [910] = -42000, [911] = 4000, [922] = 0, [932] = -3500, [933] = 0, [934] = 3500, [935] = 0, [936] = 0, [941] = -500, [942] = 0, [947] = 0, [967] = 0, [970] = -2500, [989] = 0, [990] = 0, [1005] = 3000, [1011] = 0, [1012] = 0, [1015] = -42000, [1031] = 0, [1038] = 0, [1052] = 0, [1064] = 0, [1067] = 0, [1073] = 0, [1077] = 0, [1085] = 0, [1090] = 3000, [1091] = 0, [1104] = 0, [1105] = 0, [1106] = 0, [1117] = 0, [1118] = 0, [1119] = -42000, [1124] = 0, [1156] = 0, [1200] = 1 }  -- Demon Hunter (Horde)
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

-- Batch upsert many rows in one statement
local function execBatchUpsertReputation(rows)
    if #rows == 0 then return end
    local values = {}
    for i = 1, #rows do
        local row = rows[i]
        values[#values+1] = string.format("(%d,%d,%d)", row.guid, row.factionId, row.standing)
    end
    CharDBExecute([[
        INSERT INTO character_reputation (guid, faction, standing)
        VALUES ]] .. table.concat(values, ",") .. [[
        ON DUPLICATE KEY UPDATE standing = VALUES(standing)
    ]])
end

local function SetReputationOnSave(event, player)
    local accountId = player:GetAccountId()
    -- Skip playerbot accounts
    if AUtils.isPlayerBotAccount(accountId) then return end

    local savingGuid = player:GetGUIDLow()
    local savingRace = player:GetRace()
    local savingClass = player:GetClass()

    local accountChars = {}
    do
        local charQuery = CharDBQuery(string.format("SELECT guid, race, class FROM characters WHERE account = %d", accountId))
        if not charQuery then return end
        repeat
            accountChars[#accountChars+1] = {
                guid = charQuery:GetUInt32(0),
                race = charQuery:GetUInt8(1),
                class = charQuery:GetUInt8(2),
            }
        until not charQuery:NextRow()
    end

    if #accountChars == 0 then return end

    local saverFactionIds = {}
    do
        local saverReps = CharDBQuery(string.format("SELECT faction FROM character_reputation WHERE guid = %d", savingGuid))
        if not saverReps then return end
        repeat
            saverFactionIds[#saverFactionIds+1] = saverReps:GetUInt32(0)
        until not saverReps:NextRow()
    end
    if #saverFactionIds == 0 then return end

    local saverFactionIdCSV = toCSV(saverFactionIds)

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

    -- Compute the saving character's CURRENT adjusted standings from memory
    local savingAdjustedByFaction = {}
    for _, factionId in ipairs(saverFactionIds) do
        local rawTotal = player:GetReputation(factionId)
        local baseOffset = GetBaseReputationOffset(savingRace, savingClass, factionId)
        local adjusted = ClampReputation(rawTotal - baseOffset)
        savingAdjustedByFaction[factionId] = adjusted
    end

    -- Decide target adjusted per faction, and batch write to all eligible chars
    local rowsToWrite = {}

    local function propagate(factionId, targetAdjusted, eligiblePredicate)
        local clamped = ClampReputation(targetAdjusted or 0)
        for i = 1, #accountChars do
            local charInfo = accountChars[i]
            if eligiblePredicate(charInfo.race) then
                rowsToWrite[#rowsToWrite+1] = {
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
            -- First time this faction appears on the account: take the saver’s value as-is
            targetAdjusted = savingAdjusted
        elseif saverWasMaxHolder and savingAdjusted < currentMaxAdjusted then
            -- True loss by a current max-holder -> propagate down
            targetAdjusted = savingAdjusted
        else
            -- Gains or non-max-holder saves -> do not lower
            targetAdjusted = math.max(currentMaxAdjusted, savingAdjusted)
        end

        propagate(factionId, targetAdjusted, eligible)
    end

    execBatchUpsertReputation(rowsToWrite)
end

-- Batch upsert many rows in one statement
local function upsertManyForGuid(guid, factionToAdjustedStanding)
    local rows = {}
    for factionId, adjustedStanding in pairs(factionToAdjustedStanding) do
        rows[#rows+1] = string.format("(%d,%d,%d)", guid, factionId, adjustedStanding)
    end
    if #rows == 0 then return end
    CharDBExecute([[
        INSERT INTO character_reputation (guid, faction, standing)
        VALUES ]] .. table.concat(rows, ",") .. [[
        ON DUPLICATE KEY UPDATE standing = VALUES(standing)
    ]])
end

local function SetReputationOnCharacterCreate(event, player)
    local accountId = player:GetAccountId()
    -- Skip playerbot accounts
    if AUtils.isPlayerBotAccount(accountId) then return end

    local newGuid = player:GetGUIDLow()
    local newRace = player:GetRace()

    local newIsAlliance = allianceRaces[newRace] == true
    local newIsHorde = hordeRaces[newRace] == true

    local existingMaxAdjusted = CharDBQuery(string.format([[
        SELECT mr.faction, mr.max_standing, ch.race, ch.class
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

local function BroadcastLoginAnnouncement(event, player)
    if ANNOUNCE_ON_LOGIN then
        player:SendBroadcastMessage(ANNOUNCEMENT)
    end
end

RegisterPlayerEvent(1, SetReputationOnCharacterCreate) -- EVENT_ON_CHARACTER_CREATE
RegisterPlayerEvent(3, BroadcastLoginAnnouncement) -- EVENT_ON_LOGIN
RegisterPlayerEvent(25, SetReputationOnSave) -- EVENT_ON_SAVE