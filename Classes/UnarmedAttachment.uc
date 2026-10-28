/*
Kakutou 2004!!!
	version 1.0
	Code and animations done by PsychoKick, circa 2002.
	Sounds ripped from Sega's Virtua Fighter PC and edited by PsychoKick.
	Very special thanks to the UT community for sharing the knowledge to make this mod possible.
	Dedicated to all who practice the martial arts, whether in reality or in games.
	UT2004 Code Modifications for Instant Action: Rythmix - Rythmix@gmail.com - www.rythm-nation.net
*/

//Attachment type for Unarmed combat. The empty ThirdPersonEffects() is to prevent the normal
//weapon firing animation from playing and overriding any martial arts animations.
class UnarmedAttachment extends xWeaponAttachment;

simulated event ThirdPersonEffects()
{
}

defaultproperties
{
    DrawType=0
    /* Mesh=SkeletalMesh'Weapons.BallLauncher_3rd'*/
}
