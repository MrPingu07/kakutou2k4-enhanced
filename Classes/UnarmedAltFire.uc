/*
Kakutou 2004!!!
	version 1.0
	Code and animations done by PsychoKick, circa 2002.
	Sounds ripped from Sega's Virtua Fighter PC and edited by PsychoKick.
	Very special thanks to the UT community for sharing the knowledge to make this mod possible.
	Dedicated to all who practice the martial arts, whether in reality or in games.
	UT2004 Code Modifications for Instant Action: Rythmix - Rythmix@gmail.com - www.rythm-nation.net
*/

//The secondary fire is a strong attack with a hell of a kickback and higher recovery time.
//Otherwise it's basically the same as the primary attack.
class UnarmedAltFire extends UnarmedFire;

simulated function SetCurrentAttack()
{
	local float TempRand;

	if (Unarmed(Instigator.Weapon).bFlagFighting)
	{
		while (CurrentAttack == PreviousAttack)
		{
			TempRand = FRand();
    		if (TempRand < 0.25)
			{
    			CurrentAttack='FlagStrong1';
				bKicking=false;
			}
			else if (TempRand < 0.50)
			{
				CurrentAttack='FlagStrong2';
				bKicking=false;
			}
			else if (TempRand < 0.75)
			{
    			CurrentAttack='FlagStrong1';
				bKicking=false;
			}
			else
			{
				CurrentAttack='FlagStrong2';
				bKicking=false;
			}
		}
	}
	else if (Instigator.Physics != PHYS_Falling)
	{
		while (CurrentAttack == PreviousAttack)
		{
			TempRand = FRand();
    		if (TempRand < 0.25)
    		{
    			CurrentAttack='AttackStrong1';
				bKicking=false;
			}
			else if (TempRand < 0.50)
			{
    			CurrentAttack='AttackStrong2';
    			bKicking=false;
			}
			else if (TempRand < 0.75)
			{
				CurrentAttack='AttackStrong3';
				bKicking=true;
			}
			else
			{
				CurrentAttack='AttackStrong4';
				bKicking=true;
			}
		}
	}
	else
	{
		while (CurrentAttack == PreviousAttack)
		{
			TempRand = FRand();
			if (TempRand < 0.50)
			{
				CurrentAttack='AttackStrong3';
				bKicking=true;
			}
			else
			{
				CurrentAttack='AttackStrong4';
				bKicking=true;
			}
		}
	}
}

defaultproperties
{
    WhiffSound=Sound'K2k4Sounds.Unarmed.Whiff2Sound'
    WhackSound=Sound'K2k4Sounds.Unarmed.Whack2Sound'
    Damage=35.00
    Force=90000.00
    OriginalRate=0.90
    FocusRate=0.75
    FireRate=0.90
}
