# ![logo](https://raw.githubusercontent.com/azerothcore/azerothcore.github.io/master/images/logo-github.png) AzerothCore

# Accountwide Systems Using Eluna

### Description

	Since I mainly use a repack instead of compiling with C++, here is my implementation approach
	to things Accountwide with Eluna.  You will need Eluna set up on your server for these scripts to work.

	Here are the Accountwide Lua Scripts that are included in this project:
	- Achievements
	- Currency
 	- GoldSharing
	- Mounts
 	- Pets
	- Reputation

  	Each script has a module-like configuration where you can choose to enable/disable independently.

### Included Module Features:
	** Achievements: **
 		Tired of repeating the same achievements on multiple charcters? This script will allow completed achievements to
   		be synced across all characters on your account.  Once you complete an achievement, the next time you log into a 
     	different character, they will be awarded with the achievement as well.

 
 	** Currency: **
       	This script will allow currencies to be synced across all characters on your account that are eligible to use them.
		For example, if you have 100 Badge of Justice, all of your eligible characters will have 100. If you spend 50, then all
 		of your characters will now have 50.  
  	
		The "currencyItemIDs" variable on Line 16 of the script indicates which currencies are shared. These values are the IDs 
		pulled from `item_template`. Feel free to add more currencies if your server has them. Also feel free to remove currencies
 		if you don't want specific ones to be shared.

 
 	** GoldSharing: **
  		This script essentially allows all of your characters to share a single gold fund. A joint checking/savings account
    	if you will. If you gain 100 gold on one character, then all of your characters will get that gold upon the next login. If you
     	spend any gold, then all of your characters will subtract their gold balance.

 
 	** Mounts: **
  		By default, this script allows unlocked/learned mounts to be shared across all characters on the account, as long as
    	they are at least level 11. This value is configurable using the "WhenPlayerLevel" variable in the config.
      	
       	You also have the ability to prevent sharing mounts of the opposing faction, but I personally would recommend leaving it off.
       	Up to you though.
		
  		All of the mounts are defined in the "mount_listing" variable on Line 26. If your server has any additional mounts that
    	are not listed here, feel free to add them. Also vise versa if there are any mounts you DO NOT want to share, simply
      	comment out or remove them from the list.


       ** Pets: **
       		This script allows unlocked/learned pet companions to be shared across all characters on the account.

  		All of the pets are defined in the "petIDs" variable on Line 19.  If your server has any additional pets that
    	are not listed here, feel free to add them.  Also vise versa if there are any mounts you DO NOT want to share, simply
     	comment out or remove them from the list.

 
 	** Reputation: **
     	Ah yes, probably my favorite script in this list. Not sure if you are just like me and get tired of farming reputations
      	on multiple characters, but with the discussion of Blizzard implementing accountwide Reputation stuff in The War
       	Within, it inspired me to try to achieve similar results here. This script allows all of the reputation progress to be shared
		across all of your characters.


# Setup

- Copy the "AccountWide" folder into the lua_scripts folder on your server.
- Configure which module(s) you want to enable at the top of each Lua script.
- If your server is already running, type ".reload eluna" in the worldserver window.  Otherwise, just start up the server.
