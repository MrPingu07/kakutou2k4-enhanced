/*
Kakutou 2004!!!
	version 1.0
	Code and animations done by PsychoKick, circa 2002.
	Sounds ripped from Sega's Virtua Fighter PC and edited by PsychoKick.
	Very special thanks to the UT community for sharing the knowledge to make this mod possible.
	Dedicated to all who practice the martial arts, whether in reality or in games.
	UT2004 Code Modifications for Instant Action: Rythmix - Rythmix@gmail.com - www.rythm-nation.net
*/

//Damage type class for unarmed combat.
class DamTypeUnarmed extends WeaponDamageType
	abstract;

defaultproperties
{
    WeaponClass=Class'Unarmed'
    DeathString="%o got his ass kicked by %k."
    FemaleSuicide="%o's suicide was without honor."
    MaleSuicide="%o's suicide was without honor."
    bDetonatesGoop=True
    bCausesBlood=False
    bKUseOwnDeathVel=True
    GibModifier=0.00
    KDeathVel=225.00
    KDeathUpKick=150.00
}
