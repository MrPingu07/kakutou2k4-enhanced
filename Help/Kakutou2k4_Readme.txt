Kakutou 2004!!!
	version 1.01
	Code and animations done by PsychoKick, circa 2002.
	Sounds ripped from Sega's Virtua Fighter PC and edited by PsychoKick.
	Very special thanks to the UT community for sharing the knowledge to make this mod possible.
	Dedicated to all who practice the martial arts, whether in reality or in games.
	UT2004 Code Modifications for Instant Action: Rythmix - Rythmix@gmail.com - www.rythm-nation.net
        UT2004 Multiplayer Cleanup: PsychoKick

******** version 1.01 changes & notes ******************************************
- Multiplayer is now fully functional
- Miscellaneous cleanup to remove obsolete code
********************************************************************************

******** version 1.0 changes & notes *******************************************
This mutator is not 100% complete yet on UT2004. It works 100% in Instant Action for UT2004, but online it is very slow moving. I don't know how to fix it but I assume it has something to do with Replication which Im not good with. I invite anyone who knows how to fix it to give it a try. It wasn't hard to convert the UT2003 to UT2004 version for instant action, so Im sure it won't be too hard to convert the online part of it either. So please! Give it a shot.
********************************************************************************

Working forum thread for this project:
http://www.ataricommunity.com/forums/showthread.php?s=&threadid=424219

Please leave any existing developer names in the files and only add yours with a description of what you added. Please leave PsychoKick, Circa, and Rythmix in there and Please leave this read me file intact.

Included is the Kakutou2k4-Project.zip with all the project classes and models. The only thing that you need to note is that to compile it, you will first have to have the K2k4Sounds.uax file in the UT2004/Sounds directory so it can find the sounds it needs to compile.

-----INTRODUCTION-----
What is this?

"Kakutou" is the Japanese word for "fistfight" or "brawl". "Kakutou Raging Carnival 120%!!!" was an unarmed combat modification for Unreal Tournament 2003. "Kakutou 2004" is an update to the original KakutouRC120p to work with UT2004 - modified by Rythmix. As before, Kakutou 2004 starts players off with unarmed martial arts combat instead of the normal ShieldGun, played from a third person perspective with custom animations, complete with a simple combination and blocking system.

-----INSTALLATION-----
How do I get this to work?

Just unzip the file with full paths into your UT2004 directory. If you want to install the files manually, then "Kakutou2k4.int", "Kakutou2k4.ucl", and "Kakutou2k4.u" go into the System folder, "K2k4Sounds.uax" goes into the Sounds folder, and This file goes into the Help folder. The mutator should then be selectable from the in-game mutator menu.


-----BASIC GAMEPLAY-----
How do I kick @$$?

Attacking:
Primary fire is a fast attack of 15 damage points, while Secondary fire is a strong attack of 35 damage points. Strong attacks will also knock back your targets, but are much slower with longer recovery time. If you have the flag in a CTF game, you will use it like a spear and gain a bit of extra range.

Blocking:
To block, you must not be attacking or recovering, and must be facing whatever it is you want to block. The width of your block is dependant on your movement. If you are advancing, your blocking width will be lower and you will be easier to hit. Retreating increases your blocking width and makes guarding much easier. Superweapons (ie: Redeemer, satellite Ion Blast) cannot be blocked, and falling damage can only be partially blocked.

Movement:
Your movement speed is dependant on what direction you are moving in. Advancing will give you a 30% speed bonus, strafing less, and retreating none.


-----ADVANCED GAMEPLAY-----
How do I kick even more @$$?

Focus:
Notice that unarmed combat has an AmmoCount. This represents your martial arts skill, or "Focus". Every time you successfully deal damage, you will gain Focus. Every time you attack without hitting anything, you will lose Focus. A percentage of your Focus count is added a bonus to your attacks (50% bonus for Fast attacks, 75% for Strong), so a skilled fighter can inflict some really serious damage. The maximum possible Focus at 120.

Rush:
Successfully hitting a target will cut down on the recovery time of your attack, allowing a faster follow-up attack. Typical fighting game lingo refers to this as a combo, but since UT2003 uses that word for something entirely different, we shall refer to it by the original Japanese arcade term "Rush". The maximum Rush length is 5 hits. Gamers familiar with Half-Life's crowbar will be instantly familiar with this.

Leaping:
If you crouch right before before jumping or dodging, then your jump height/dodge length will be increased. This also affects double jumps and wall dodges, so you can cover significant distance and altitude.


-----MUTATOR CONFIGURATION-----
What settings can I mess around with?

You can reset certain aspects of Kakutou2k4. The settings are as follows:

Min Block - This is your minimum blocking arc (ie: when advancing). Default is 90 degrees.
Max Block - This is the maximum blocking arc (ie: when retreating). Default is 135 degrees.
Hit Bonus - The amount of focus gained with each successful hit. Default is 10 points.
Block Bonus - The amount of focus gained with each successful block. Default is 3 points.
Miss Penalty - The amount of focus lost with each missed strike. Default is 3 points.
Leap % Bonus - The bonus added to a leap or dodge when you crouch. Default is 100%.


-----Online Play-----
-If you wish to try Kakutou2k4 online or in multiplayer, please remember to add the line "ServerPackages=Kakutou2k4" to the [Engine.GameEngine] section inside your UT2004.INI file.



	-PsychoKick
	 wyoon@panix.com
	 psychokick@flyingserpent.com
	
	-Rythmix
	 Rythmix@gmail.com
	 www.rythm-nation.net