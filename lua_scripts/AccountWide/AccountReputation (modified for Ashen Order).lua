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

local AUtils = AccountWideUtils

if not ENABLE_ACCOUNTWIDE_REPUTATION then return end

-- Alliance and Horde race and faction definitions
local allianceRaces = {
    [1] = true, [3] = true, [4] = true, [7] = true, [11] = true, [12] = true, [14] = true, [16] = true, [19] = true, [20] = true
}

local hordeRaces = {
    [2] = true, [5] = true, [6] = true, [8] = true, [9] = true, [10] = true, [13] = true, [15] = true, [17] = true, [21] = true
}

local allianceFactions = {
    [47] = true, [54] = true, [69] = true, [72] = true, [469] = true, [471] = true, [509] = true, [589] = true, [730] = true, [890] = true,
    [891] = true, [930] = true, [946] = true, [978] = true, [1037] = true, [1050] = true, [1068] = true, [1090] = true, [1094] = true, [1126] = true
}

local hordeFactions = {
    [67] = true, [68] = true, [76] = true, [81] = true, [510] = true, [530] = true, [729] = true, [889] = true, [892] = true, [911] = true,
    [922] = true, [941] = true, [947] = true, [1052] = true, [1064] = true, [1067] = true, [1085] = true, [1090] = true, [1124] = true
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
    -- Clamp the standing between -42000 and 42000 to prevent overflows
    return math.max(-42000, math.min(42000, value))
end

local function UpdateReputationForFaction(factionId, rawReputation, accountId, factionChecker)
    local characterGuidsQuery = CharDBQuery(string.format("SELECT guid, race, class FROM characters WHERE account = %d", accountId))

    if not characterGuidsQuery then
        return -- No characters found for this account
    end

    repeat
        local characterGuid = characterGuidsQuery:GetUInt32(0)
        local race = characterGuidsQuery:GetUInt8(1)
        local class = characterGuidsQuery:GetUInt8(2)

		if factionChecker[race] or (not allianceFactions[factionId] and not hordeFactions[factionId]) then
            -- Calculate the adjusted standing for each character using their own race's and class's base reputation offset
            local baseReputationOffset = GetBaseReputationOffset(race, class, factionId)
            local adjustedStanding = ClampReputation(rawReputation - baseReputationOffset)
            CharDBExecute(string.format("UPDATE character_reputation SET standing = %d WHERE guid = %d AND faction = %d", adjustedStanding, characterGuid, factionId))
        end
    until not characterGuidsQuery:NextRow()
end

local function SetReputationOnSave(event, player)
    local accountId = player:GetAccountId()
    -- Skip playerbot accounts
    if AUtils.isPlayerBotAccount(accountId) then return end

    local characterGuid = player:GetGUIDLow()
    local race = player:GetRace()
    local isAlliance = allianceRaces[race]
    local isHorde = hordeRaces[race]

    local factionIDsQuery = CharDBQuery(string.format("SELECT faction FROM character_reputation WHERE guid = %d", characterGuid))
    if not factionIDsQuery then
        return -- No faction IDs found for this character
    end

    repeat
        local factionId = factionIDsQuery:GetUInt32(0)
        local rawReputation = player:GetReputation(factionId)  -- Get the raw reputation from the player in-game before any conversion

        -- Now pass the rawReputation to the update function, allowing it to calculate the correct adjusted standing per character
        if isAlliance and allianceFactions[factionId] then
            UpdateReputationForFaction(factionId, rawReputation, accountId, allianceRaces)
        elseif isHorde and hordeFactions[factionId] then
            UpdateReputationForFaction(factionId, rawReputation, accountId, hordeRaces)
        elseif not allianceFactions[factionId] and not hordeFactions[factionId] then
            -- Neutral faction, apply to all characters
            UpdateReputationForFaction(factionId, rawReputation, accountId, allianceRaces)
            UpdateReputationForFaction(factionId, rawReputation, accountId, hordeRaces)
        end
    until not factionIDsQuery:NextRow()
end

local function SetReputationOnCharacterCreate(event, player)
    local accountId = player:GetAccountId()
    -- Skip playerbot accounts
    if AUtils.isPlayerBotAccount(accountId) then return end

    local newCharacterGuidQuery = CharDBQuery(string.format("SELECT guid, race, class FROM characters WHERE account = %d ORDER BY guid DESC LIMIT 1", accountId))
    if not newCharacterGuidQuery then
        return -- No new character found
    end

    local newCharacterGuid = newCharacterGuidQuery:GetUInt32(0)
    local newRace = newCharacterGuidQuery:GetUInt8(1)
    local newClass = newCharacterGuidQuery:GetUInt8(2)

    local isAlliance = allianceRaces[newRace]
    local isHorde = hordeRaces[newRace]
    local existingReputations = {}

    local existingReputationQuery = CharDBQuery(string.format([[SELECT faction, MAX(standing) as standing FROM character_reputation WHERE guid IN (SELECT guid FROM characters WHERE account = %d) GROUP BY faction]], accountId))

    if existingReputationQuery then
        repeat
            local factionId = existingReputationQuery:GetUInt32(0)
            local standing = existingReputationQuery:GetInt32(1)

            -- Get the race of the character that has this faction reputation
            local existingCharacterGuidQuery = CharDBQuery(string.format("SELECT guid FROM character_reputation WHERE faction = %d AND standing = %d LIMIT 1", factionId, standing))
            if existingCharacterGuidQuery then
                local existingCharacterGuid = existingCharacterGuidQuery:GetUInt32(0)
                local existingRaceQuery = CharDBQuery(string.format("SELECT race, class FROM characters WHERE guid = %d", existingCharacterGuid))
                if existingRaceQuery then
                    local existingRace = existingRaceQuery:GetUInt8(0)
                    local existingClass = existingRaceQuery:GetUInt8(1)

                    local existingRaceIsAlliance = allianceRaces[existingRace]
                    local existingRaceIsHorde = hordeRaces[existingRace]

                    -- Only consider reputations from the same faction or neutral faction
                    if (isAlliance and existingRaceIsAlliance) or (isHorde and existingRaceIsHorde) or
                       (not allianceFactions[factionId] and not hordeFactions[factionId]) then
                        local rawReputation = standing + GetBaseReputationOffset(existingRace, existingClass, factionId)
                        existingReputations[factionId] = rawReputation
                    end
                end
            end
        until not existingReputationQuery:NextRow()
    end

    -- Sync reputation data for the new character based on alliance, horde and neutral factions
    for factionId, _ in pairs(allianceFactions) do
        if isAlliance then
            local baseReputationOffset = GetBaseReputationOffset(newRace, newClass, factionId)
            local rawReputation = existingReputations[factionId] or baseReputationOffset
            local adjustedStanding = ClampReputation(rawReputation - baseReputationOffset)
            CharDBExecute(string.format("INSERT INTO character_reputation (guid, faction, standing) VALUES (%d, %d, %d) ON DUPLICATE KEY UPDATE standing = %d", newCharacterGuid, factionId, adjustedStanding, adjustedStanding))
        end
    end

    for factionId, _ in pairs(hordeFactions) do
        if isHorde then
            local baseReputationOffset = GetBaseReputationOffset(newRace, newClass, factionId)
            local rawReputation = existingReputations[factionId] or baseReputationOffset
            local adjustedStanding = ClampReputation(rawReputation - baseReputationOffset)
            CharDBExecute(string.format("INSERT INTO character_reputation (guid, faction, standing) VALUES (%d, %d, %d) ON DUPLICATE KEY UPDATE standing = %d", newCharacterGuid, factionId, adjustedStanding, adjustedStanding))
        end
    end

    for factionId in pairs(existingReputations) do
        if not allianceFactions[factionId] and not hordeFactions[factionId] then
            local baseReputationOffset = GetBaseReputationOffset(newRace, newClass, factionId)
            local rawReputation = existingReputations[factionId] or baseReputationOffset
            local adjustedStanding = ClampReputation(rawReputation - baseReputationOffset)
            CharDBExecute(string.format("INSERT INTO character_reputation (guid, faction, standing) VALUES (%d, %d, %d) ON DUPLICATE KEY UPDATE standing = %d", newCharacterGuid, factionId, adjustedStanding, adjustedStanding))
        end
    end
end

local function BroadcastLoginAnnouncement(event, player)
    if ANNOUNCE_ON_LOGIN then
        player:SendBroadcastMessage(ANNOUNCEMENT)
    end
end

RegisterPlayerEvent(1, SetReputationOnCharacterCreate) -- EVENT_ON_CHARACTER_CREATE
RegisterPlayerEvent(3, BroadcastLoginAnnouncement) -- EVENT_ON_LOGIN
RegisterPlayerEvent(25, SetReputationOnSave) -- EVENT_ON_SAVE
