# ![logo](https://raw.githubusercontent.com/azerothcore/azerothcore.github.io/master/images/logo-github.png) AzerothCore

# Accountwide Systems Using Eluna

### Description

	Since I mainly use a repack instead of compiling with C++, here is my implementation approach to
	all things Accountwide using Eluna.  You will need Eluna set up on your server for these scripts to work.

	Here are the Accountwide Lua Scripts that are included in this project:
	- Achievements
	- Currency
 	- Money
	- Mounts
 	- Pets
	- Reputation
 	- TaxiPaths
  	- Titles

  	Each script has a module-like configuration where you can choose to enable/disable independently.

### Included Module Features:
	Achievements:
 		Tired of repeating the same achievements on multiple charcters? This script will allow completed achievements to
   		be synced across all characters on your account.  Once you complete an achievement, the next time you log into a 
     	different character, they will be awarded with the achievement as well.

 
 	Currency:
       	This script will allow currencies to be synced across all characters on your account that are eligible to use them.
		For example, if you have 100 Badge of Justice, all of your characters will have 100. If you spend 50, then all
 		of your characters will now have 50.
  	
		The "currencyItemIDs" variable on Line 17 of the script indicates which currencies are shared. These are the
		IDs pulled from `CurrencyTypes.dbc`. Feel free to add/remove any to tailor to your server if needed.

 
 	Money:
  		Gone are the days where you need to balance different amounts of gold on each of your characters.
    
    		This script essentially allows all of your characters to share a single gold fund. 
      	In other words, a joint checking/savings account.  If you gain 100 gold on one character, 
       	then all of your characters will get that gold upon the next login. If you spend any gold, 
	then all of your characters will subtract their gold balance.

 
 	Mounts:
  		By default, this script allows learned mounts to be shared across all characters on the account, provided
    	they are at least level 11. This value is configurable using the "WhenPlayerLevel" variable in the config.
		
  		All of the mounts are defined in the "mountSpellIDs" variable on Line 22.  Feel free to add/remove any
    	to tailor to your server if needed.


	Pets:
       	This script allows learned pet companions to be shared across all characters on the account.

  		All of the pets are defined in the "petSpellIDs" variable on Line 18.  Feel free to add/remove any 
    	to tailor to your server if needed.

 
 	Reputation:
     	Not sure if you are just like me and get tired of farming reputations on multiple characters. This script
      	allows all of the reputation progress to be shared across all of your characters.


  	TaxiPaths:
   		This script will synchronize learned taxi paths across all characters on your account within the same faction.
    	
     	Due to horde/alliance interactions, horde taxi paths will only be shared with other horde characters and 
     	alliance taxi paths will only be shared with other alliance characters on the same account.


	Titles:
       	Want to flaunt that hard earned title on all of your characters?  This script will synchronize earned 
       	character titles to the other characters on your account.


# Setup

- Run the "create_accountwide_tables.sql" file on your Characters database.
- Copy the "AccountWide" folder into the lua_scripts folder on your server.
- Configure which module(s) you want to enable at the top of each Lua script.  All of them are turned off by default.
- Start up the server.
