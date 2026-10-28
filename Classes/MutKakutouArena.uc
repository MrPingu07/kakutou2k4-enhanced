/*
Kakutou 2004!!!
	version 1.0
	Code and animations done by PsychoKick, circa 2002.
	Sounds ripped from Sega's Virtua Fighter PC and edited by PsychoKick.
	Very special thanks to the UT community for sharing the knowledge to make this mod possible.
	Dedicated to all who practice the martial arts, whether in reality or in games.
	UT2004 Code Modifications for Instant Action: Rythmix - Rythmix@gmail.com - www.rythm-nation.net
*/

class MutKakutouArena extends Mutator config (User);

var() config int MinBlock, MaxBlock, HitBonus, GuardBonus, MissPenalty, LeapBonus;

var bool bAllowTranslocator;

function bool CheckReplacement(Actor Other, out byte bSuperRelevant)
{
	if ( Other.IsA('Weapon') )
	{
	        if ( Other.IsA('BallLauncher') )
        	{
			bSuperRelevant = 0;
			return true;
	        }

		if ( Other.IsA('TransLauncher') && bAllowTranslocator )
		{
	        	bSuperRelevant = 0;
		        return true;
	        }

		if ( !Other.IsA('Unarmed') )
		{
			Level.Game.bWeaponStay = false;
			ReplaceWith(Other, "Kakutou2k4.Unarmed");
			return false;
		}

		if ( Other.IsA('Unarmed') )
		{
			Unarmed(Other).BlockMinDegrees = MinBlock;
			Unarmed(Other).BlockMaxDegrees = MaxBlock;
			Unarmed(Other).BonusPerHit = HitBonus;
			Unarmed(Other).BonusPerGuard = GuardBonus;
			Unarmed(Other).PenaltyPerMiss = MissPenalty;
			Unarmed(Other).LeapBonus = LeapBonus;

			bSuperRelevant = 0;
			return true;
		}
	}

	if ( Other.IsA('WeaponPickup') )
		return false;

	if ( Other.IsA('Ammo') )
		return false;

	if ( Other.IsA('xWeaponBase') )
		Other.bHidden = true;

	bSuperRelevant = 0;
	return true;
}

simulated function ModifyPlayer(Pawn Other)
{
	local Pawn OldPawn;
    if ( !Other.IsA('K2k4xPawn') )
    {
        OldPawn=Other;
        Other.Controller.PawnClass = class'K2k4xPawn';
        Level.Game.RestartPlayer(Other.Controller);
//Perhaps you should get rid of OldPawn after NextMutator, not before?
        OldPawn.UnPossessed();
        OldPawn.Destroy();
    }

    if ( NextMutator != None )
        NextMutator.ModifyPlayer(Other);
}

function PlayerChangedClass(Controller aPlayer)
{
    if ( NextMutator != None )
        NextMutator.PlayerChangedClass(aPlayer);
}

defaultproperties
{
    MinBlock=90
    MaxBlock=135
    HitBonus=10
    GuardBonus=3
    MissPenalty=3
    LeapBonus=100
    ConfigMenuClassName="Kakutou2k4.K2k4MutConfig"
    GroupName="KakutouArena2004"
    FriendlyName="Kakutou Arena 2004"
    Description="No Weapons, Martial arts Arena fighting for 2004."
}
