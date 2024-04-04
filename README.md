# ![logo](https://raw.githubusercontent.com/azerothcore/azerothcore.github.io/master/images/logo-github.png) AzerothCore

# Accountwide Systems Using Eluna

### Description

	Since I mainly use a repack instead of compiling with C++, here is my implementation approach
	to things Accountwide with Eluna.  You will need Eluna set up on your server for these scripts to work.

	Here are the Accountwide Lua Scripts that are included in this project:
	- Achievements
	- Currency
	- Mounts
	- Reputation

  	Each script has a module-like configuration where you can choose to enable/disable independently.


# Setup

- Copy the "AccountWide" folder into the lua_scripts folder on your server.
- Configure which module(s) you want to enable at the top of each Lua script.
- If your server is already running, type ".reload eluna" in the worldserver window.  Otherwise, just start up the server.
