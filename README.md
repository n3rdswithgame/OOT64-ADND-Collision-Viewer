# ADND Collision Viewer

Here is the rough source for the collision view I hacked together the [OOT64 All Dungeons No Doors TAS](https://www.youtube.com/watch?v=vtWr7wiS-Hw) ([collision viewer segments](https://www.youtube.com/watch?v=PNXj_QmwNDc)). This code is in a very rough state, but should still work. I've only really used it on bizhawk 1.13.1 with the jabo  video plugin, but **in theory** it should *just work*™ with later versions which don't support jabo.

These 3 lua files have been floating around in people's DM's for better part of 2 and a half years, but at the request of RoseWater I am making it publicly available. 

## Intent

The intent behind these scripts were to make a collision viewer that would be use able for a TAS settings. As such this was designed to have minimal impact on the emulation as possible, only write to RAM what was needed in the form of a display list, and generate it all in LUA instead of C/MIPS to preserve the CPU cyclecount and not fiddle with calls to srand (which periodically use the cpu cycle count as part of the seed).

Every bk2 movie I tried would sync wrt the script running or not, however I cannot guarantee that running the script will not result in a desync.

## Hot to use
* download the repo (git clone or click the green "clone or download" button and download it as a zip), or just download the 3 lua files. 
* Make sure they are all in the same folder.
* In bizhawk, go to Tools->Lua Console
* open `collision.lua`

### Future of this repo

As mentioned earlier, I only uploaded these here as RoseWater request wished for them to be publicly available. I have no plans on updating them or refactoring `collision.lua` to be not jank. For all intents and purposes this project is abandoned. If you want to fork and make this a lot more usable, go ahead. I will even update this readme to point people over there.

MM support has been partially started. All that should be needed are to find a few addresses in `InitMM` in `collision.lua` If you are so inclined.