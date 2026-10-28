/*
Kakutou 2004!!!
	version 1.0
	Code and animations done by PsychoKick, circa 2002.
	Sounds ripped from Sega's Virtua Fighter PC and edited by PsychoKick.
	Very special thanks to the UT community for sharing the knowledge to make this mod possible.
	Dedicated to all who practice the martial arts, whether in reality or in games.
	UT2004 Code Modifications for Instant Action: Rythmix - Rythmix@gmail.com - www.rythm-nation.net
*/

//Pickup type for Unarmed. Pretty much just a placeholder.
class UnarmedPickup extends UTWeaponPickup;

defaultproperties
{
    MaxDesireability=0.39
    InventoryType=Class'Unarmed'
    PickupMessage="Everybody was kung-fu fighting!"
    PickupSound=Sound'PickupSounds.ShieldGunPickup'
    PickupForce="UnarmedPickup"
    DrawType=0
    StaticMesh=StaticMesh'WeaponStaticMesh.ShieldGunPickup'
    DrawScale=0.75
}
