/*
Kakutou 2004!!!
	version 1.0
	Code and animations done by PsychoKick, circa 2002.
	Sounds ripped from Sega's Virtua Fighter PC and edited by PsychoKick.
	Very special thanks to the UT community for sharing the knowledge to make this mod possible.
	Dedicated to all who practice the martial arts, whether in reality or in games.
	UT2004 Code Modifications for Instant Action: Rythmix - Rythmix@gmail.com - www.rythm-nation.net
*/

//The mutator responsible for replacing the xPawn with K2k4xPawn. Note that
//the K2k4xPawn automatically comes with Unarmed instead of the Shieldgun, so
//the mutator does not need to explicitly replace the Shieldgun
class MutKakutou2k4 extends Mutator config (User);

var() config int MinBlock, MaxBlock, HitBonus, GuardBonus, MissPenalty, LeapBonus;

////////////////////////////////////////////////////////////////////////
/*This method assigns the new derived pawn class to the PawnClass property
of the controller, which could either be a player or a bot.  You call
Level.Game.RestartPlayer on that particular Controller because when
ModifyPlayer is called, the player class is already created. If you
leave that line out, everyone will still be the original Pawn class
until they die.*/

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

/*A final footnote: Due to a bug in the Mutator class,
the "nextMutator" in the chain is not properly handled in PlayerChangedClass,
so if you use the above method to override your pawns in a Mutator, make an
additional change by overriding PlayerChangedClass, like so:
*/

function PlayerChangedClass(Controller aPlayer)
{
    if ( NextMutator != None )
        NextMutator.PlayerChangedClass(aPlayer);
}

function bool CheckReplacement(Actor Other, out byte bSuperRelevant)
{
	if ( Other.IsA('Unarmed') )
	{
		Unarmed(Other).BlockMinDegrees = MinBlock;
		Unarmed(Other).BlockMaxDegrees = MaxBlock;
		Unarmed(Other).BonusPerHit = HitBonus;
		Unarmed(Other).BonusPerGuard = GuardBonus;
		Unarmed(Other).PenaltyPerMiss = MissPenalty;
		Unarmed(Other).LeapBonus = LeapBonus;
	}

	bSuperRelevant = 0;
	return true;
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
    GroupName="Kakutou2004"
    FriendlyName="Kakutou 2004"
    Description="Players spawn with martial art skills instead of the ShieldGun."
}
