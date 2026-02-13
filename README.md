# ![logo](https://raw.githubusercontent.com/azerothcore/azerothcore.github.io/master/images/logo-github.png) AzerothCore

# Accountwide Systems Using ALE
Here is my implementation approach to all things Accountwide.  ALE needs to be set up on your server for these scripts to work and each system has a module-like configuration where you can choose to enable/disable independently.  

It is HIGHLY recommended to install these on a fresh server.

### 00_AccountWideUtils.lua
This is a mandatory helper script that contains a few helper functions used across various scripts.  You must have this script installed alongside any of the other systems from this repo, otherwise they will not work properly.

### Achievements
Tired of repeating the same achievements on multiple characters?  This script will allow completed achievements to be synced across all characters on the account.  Once you complete an achievement, the next time you log into a different character, they will be awarded with the achievement as well.  This data will be stored in a new `accountwide_achievements` table.

### Currency
This script will allow currencies to be synced across all characters on your account.  For example, if you have 100 Badge of Justice, all of your characters will have 100. If you spend 30, then all of your characters will now have 70.  This data will be stored in a new `accountwide_currency` table.

### Money
Gone are the days where you need to balance different amounts of gold on each of your characters.

This script essentially allows all of your characters to share a single gold fund. In other words, a joint checking/savings account.  If you gain 100 gold on one character, then all of your characters will get that gold upon the next login. If you spend any gold, then all of your characters will subtract their gold balance.  This data will be stored in a new `accountwide_money` table.

### Mounts
By default, this script allows learned mounts to be shared across all characters on the account, provided they are at least level 11. This level value is configurable using the "WhenPlayerLevel" variable in the config.  This data will be stored in a new `accountwide_mounts` table.

All of the mounts are defined in the "mountSpellIDs" table on Line 22.  Feel free to add/remove any to tailor to your server if needed.

### Pets
This script allows learned pet companions to be shared across all characters on the account.  This data will be stored in a new `accountwide_pets` table.

All of the pets are defined in the "petSpellIDs" table on Line 18.  Feel free to add/remove any to tailor to your server if needed.

### Playtime
This script provides a playtime summary across all characters on your account.  This is similar to the `/played` command, but shows accountwide totals and a per-character breakdown in a cleaner format.

When using the in-game chat command `.playtime` (or any of its aliases), the script will display:
- Total playtime for your current character
- Total combined playtime across all characters on the account
- A per-character breakdown showing each character's share of total playtime

Supported chat commands:

- `.playtime`
- `.accountplaytime`
- `.awplaytime`
- `.played`
- `.awplayed`

### PvP Rank/Stats
This script will sync your PvP Rank/Stats across all of your characters: Honorable Kills, Honor Points, Arena Points. This data will be stored in a new `accountwide_pvp_rank` table.

You will see `RUN_INIT_SEED_ON_STARTUP = true` in the config section of the script.  It is set to `true` by default on purpose.  After you successfully launch the server for the first time with this script, you can then set this value to `false`.  This needs to be `true` only for the **first** run to retroactively seed your existing PvP stats to the accountwide table.  After that you don't need to seed anymore.

### Reputation
Not sure if you are just like me and get tired of farming reputations on multiple characters, but this script allows all of the reputation progress to be shared across all of your characters.

There are some exceptions to the rule though.  In order to not break factions by inadvertently making reputations fully accountwide, factions
will stay true as they do today.  Horde factions will only be shared to horde characters.  Alliance factions will only be shared to alliance characters.
Neutral factions will be shared to both.

### Taxi Paths / Flight Paths

This script synchronizes learned flight paths across all characters on your account that belong to the same faction.
    	
Due to Horde/Alliance restrictions, Horde flight paths will only be shared with other Horde characters, and Alliance flight paths will only be shared with other Alliance characters.

**Important:** This script requires updated ALE C++ bindings to expose taxi node data to Lua.

To use this feature, you must either:

- Use my fork of `mod-ale`: [Aldori15/mod-ale](https://github.com/Aldori15/mod-ale)  
**or**
- Use the official Azerothcore `mod-ale` repo, as long as it includes these commits (or newer):  
  - [Required commit](https://github.com/azerothcore/mod-ale/commit/fe47a5d9c3a2a22f33ea3b1f3ccdc126a0d916dd)
  - [Required commit](https://github.com/azerothcore/mod-ale/commit/bcfe631307cda63514492366f659549ecf050854)


### Titles
Want to flaunt that hard earned title on all of your characters?  This script will synchronize earned character titles to the other characters on your account.  This data will be stored in a new `accountwide_titles` table.



> [!IMPORTANT]
> # Setup / Installation
> - Run the "create_accountwide_tables.sql" file on your Characters database.
> - Copy the "AccountWide" folder into the lua_scripts folder on your server.
> - Configure which module(s) you want to enable at the top of each Lua script.  All of them are turned off by default.
> - Start up the server.

> [!WARNING]
> # If you use AccountReputation:
> - Make sure you use the correct AccountReputation script to avoid weird results.  If you are using base/unmodified AC-Wotlk server without custom races and without a modified Faction.dbc file, then use the `AccountReputation (default AC-Wotlk)` file.  Otherwise if you are using our modified Ashen Order server, then use the `AccountReputation (modified for Ashen Order)` file.  Be sure to delete out the other file that you are not using.  It is HIGHLY recommended to install this on a fresh server.



