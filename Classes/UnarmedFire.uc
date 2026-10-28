/*
Kakutou 2004!!!
	version 1.0
	Code and animations done by PsychoKick, circa 2002.
	Sounds ripped from Sega's Virtua Fighter PC and edited by PsychoKick.
	Very special thanks to the UT community for sharing the knowledge to make this mod possible.
	Dedicated to all who practice the martial arts, whether in reality or in games.
	UT2004 Code Modifications for Instant Action: Rythmix - Rythmix@gmail.com - www.rythm-nation.net
*/

//The basic firing code for Unarmed combat. Note that landing a successful attack will cut down on
//the recovery time, allowing for a faster follow-up attack. Modern day fighting-game lingo would call
//this a combo or combination, but the original Japanese term for this is "Rush", so we shall use this
//term so as not to conflict with the UT2K3 adrenaline combos. This works almost identically to the
//crowbar weapon in Half-Life, so the FPS crowd should be comfortable with it. Maximum rush is 5 hits.
//Also note that successful attacks will raise your ammocount. This ammo represents your skill, or your
//"focus", and acts as a damage bonus to your attacks. Whiffing attacks will drain your focus.
class UnarmedFire extends WeaponFire;

var class<DamageType> DamageType;       // weapon fire damage type (no projectile, so we put this here)

var() sound WhiffSound;
var() sound WhackSound;
var() sound HitWallSound;
var() float Damage, Force, OriginalRate, FocusRate;
//var() int BonusPerHit;
var name PreviousAttack, CurrentAttack, ActionAttack;
var bool bKicking, IsRush;

function DoFireEffect()
{
	local Vector HitLocation, HitNormal, StartTrace, EndTrace, X,Y,Z;
    local Rotator Aim;
	local Actor Other;
    local bool bWhiff;
	local bool bFocus;
	local int HealthBeforeDamage;
	local float ShieldBeforeDamage;

    if ( (Instigator!=None) && (Instigator.Weapon!=None) && (Unarmed(Instigator.Weapon)!=None) )
    {
	    Weapon.GetViewAxes(X,Y,Z);
    	StartTrace = Instigator.Location;
	    Aim = AdjustAim(StartTrace, AimError);

    	if (Unarmed(Instigator.Weapon).bFlagFighting)
		    EndTrace = StartTrace + 225 * vector(Aim);	//300
		else
			EndTrace = StartTrace + 150 * vector(Aim);	//150

    	bWhiff = true;
		Other = Trace(HitLocation, HitNormal, EndTrace, StartTrace, true);

		foreach Level.TraceActors(class'Actor', Other, HitLocation, HitNormal, EndTrace, StartTrace, vect(25.0, 25.0, 25.0) )
		{
	    	if( (Other != none) && (Other != Instigator) &&
				((Pawn(Other)!=None) || ((Mover(Other)!=None) && (Mover(Other).bDamageTriggered)) ) )
	   		{
    			if ( (Pawn(Other)!=None) && (Pawn(Other).Health > 0)
					&& (!Pawn(Other).Controller.SameTeamAs(Instigator.Controller)) )
	    		{
    				HealthBeforeDamage=Pawn(Other).Health;
		  			ShieldBeforeDamage=Pawn(Other).ShieldStrength;
					bFocus = true;
				}
				else
					bFocus = false;

				Other.TakeDamage(Damage + (Instigator.Weapon.AmmoAmount(0) * FocusRate),
							Instigator, HitLocation, Force*(X+vect(0,0,0.5)),
							class'DamTypeUnarmed');

				if (bFocus && (Pawn(Other).Health >= HealthBeforeDamage) && (Pawn(Other).ShieldStrength >= ShieldBeforeDamage))
					bFocus=false;
//Only recieve Focus if damage is inflicted.
  //         	if (bFocus) Instigator.Weapon.AmmoAmount(0)+=BonusPerHit;
   //        	if (bFocus) Instigator.Weapon.AmmoAmount(0)+=Unarmed(Instigator.Weapon).BonusPerHit;
	        	if (bFocus) Instigator.Weapon.AddAmmo(Unarmed(Instigator.Weapon).BonusPerHit, 0);
//        	if (Instigator.Weapon.AmmoAmount(0) > 120)
//				Instigator.Weapon.ConsumeAmmo(Instigator.Weapon.AmmoAmount(0) - 120,0);

				bWhiff = false;
			}
		}

//	if (bWhiff && (Instigator.Weapon.AmmoAmount(0) > 0))
		if (bWhiff)
		{
	//		Instigator.Weapon.AmmoAmount(0) -= Unarmed(Instigator.Weapon).PenaltyPerMiss;
				Instigator.Weapon.ConsumeAmmo( 0, Unarmed(Instigator.Weapon).PenaltyPerMiss);
//			if (Instigator.Weapon.AmmoAmount(0) < 0)
//			    Instigator.Weapon.AddAmmo(- Instigator.Weapon.AmmoAmount(0), 0);
	//			Instigator.Weapon.AmmoAmount(0) = 0;
//				Instigator.Weapon.AddAmmo(0, 0);
		}

		if (!bWhiff)
		{
			FireSound=WhackSound;
			if (Unarmed(Instigator.Weapon).RushCounter < Unarmed(Instigator.Weapon).MaxRush)
			{
				IsRush=true;
				FireRate=OriginalRate/2;
				Unarmed(Instigator.Weapon).RushCounter++;
				Unarmed(Instigator.Weapon).RushTimer=0.7;
			}
			else
			{
				IsRush=false;
				FireRate=OriginalRate;
				Unarmed(Instigator.Weapon).RushCounter=1;
//Kiai on last hit of a rush
				if(K2k4xPawn(Instigator)!=None)
	//	        	Instigator.PlaySound(K2k4xPawn(Instigator).SoundGroupClass.static.GetHitSound(), SLOT_Pain,10.0,,,,false);
	        		Instigator.PlaySound(K2k4xPawn(Instigator).SoundGroupClass.static.GetHitSound(), SLOT_Pain,,,,,false);
			}
		}
		else
		{
			IsRush=false;
			FireSound=WhiffSound;
			FireRate=OriginalRate;
			Unarmed(Instigator.Weapon).RushCounter=1;
		}

		if ( (Instigator.Controller!=None) && (PlayerController(Instigator.Controller)!=None ) && (Instigator.Controller.bIsPlayer) )
			PlayerController(Instigator.Controller).ClientPlaySound(FireSound, true,0.2);

		if ( (K2k4xPawn(Instigator).CurrentCombo != None) &&
			 (K2k4xPawn(Instigator).CurrentCombo.IsA('ComboBerserk')) )
				FireRate = FireRate/2;

		Unarmed(Instigator.Weapon).RecoverTime = FireRate;
	}
}

function PlayFiring()
{
	//local float AdjustedRate, AdjustedTween;   //removed for UT2K4 compatibility
//Don't do anything if you're in the middle of an attack, or else you'll muck up the animation
	if (Unarmed(Instigator.Weapon).RecoverTime >= FireRate)
	{
		//removed for UT2K4 compatibility
		//if ( (K2k4xPawn(Instigator).CurrentCombo != None) &&
		//	 (K2k4xPawn(Instigator).CurrentCombo.IsA('ComboBerserk')) )
		//{
		//	AdjustedRate = 2.0;
		//	AdjustedTween = 0.0;
		//}
		//else
		//{
		//	AdjustedRate = 1.0;
		//	AdjustedTween = 0.1;
		//}

		SetCurrentAttack();
		SetActionAttack();

		K2k4xPawn(Instigator).bWaitForAnim=bKicking; //
//The following order is very important! Play the animation AFTER setting the AnimAction
//or else you'll repeat attack animations.
		K2k4xPawn(Instigator).SetAnimAction(ActionAttack); //

		PreviousAttack = CurrentAttack; //

//	    Weapon.PlayOwnedSound(FireSound,SLOT_Interact,TransientSoundVolume,,,,false);
	    Weapon.PlayOwnedSound(FireSound,SLOT_Interact);
		ClientPlayForceFeedback(FireForce);  // jdf
	}
}

function ServerPlayFiring()
{
	//local float AdjustedRate, AdjustedTween;   //removed for UT2K4 compatibility
//Don't do anything if you're in the middle of an attack, or else you'll muck up the animation more than it already is.
	if (Unarmed(Instigator.Weapon).RecoverTime >= FireRate)
	{
		//removed for UT2K4 compatibility
		//if ( (K2k4xPawn(Instigator).CurrentCombo != None) &&
		//	 (K2k4xPawn(Instigator).CurrentCombo.IsA('ComboBerserk')) )
		//{
		//	AdjustedRate = 2.0;
		//	AdjustedTween = 0.0;
		//}
		//else
		//{
		//	AdjustedRate = 1.0;
		//	AdjustedTween = 0.1;
		//}

		SetCurrentAttack();
		SetActionAttack();

		K2k4xPawn(Instigator).bWaitForAnim=bKicking;
//The following order is very important! Play the animation AFTER setting the AnimAction
//or else you'll repeat attack animations.
		K2k4xPawn(Instigator).SetAnimAction(ActionAttack);
		//Instigator.PlayAnim(ActionAttack, AdjustedRate,AdjustedTween);//,0);   //removed for UT2K4 compatibility

		PreviousAttack = CurrentAttack;

//	    Weapon.PlayOwnedSound(FireSound,SLOT_Interact,TransientSoundVolume,,,,false);
	    Weapon.PlayOwnedSound(FireSound,SLOT_Interact);
		ClientPlayForceFeedback(FireForce);  // jdf
	}
}

simulated function SetActionAttack()
{
	if (IsRush)
//		((K2k4xPawn(Instigator).CurrentCombo != None) &&
//		(K2k4xPawn(Instigator).CurrentCombo.IsA('ComboBerserk'))) )
	{
		switch (CurrentAttack)
		{
			case 'AttackFast1': ActionAttack='AttackFast1Rush'; break;
			case 'AttackFast2': ActionAttack='AttackFast2Rush'; break;
			case 'AttackFast3': ActionAttack='AttackFast3Rush'; break;
			case 'AttackFast4': ActionAttack='AttackFast4Rush'; break;
			case 'AttackStrong1': ActionAttack='AttackStrong1Rush'; break;
			case 'AttackStrong2': ActionAttack='AttackStrong2Rush'; break;
			case 'AttackStrong3': ActionAttack='AttackStrong3Rush'; break;
			case 'AttackStrong4': ActionAttack='AttackStrong4Rush'; break;
			case 'FlagFast1': ActionAttack='FlagFast1Rush'; break;
			case 'FlagFast2': ActionAttack='FlagFast2Rush'; break;
			case 'FlagFast3': ActionAttack='FlagFast3Rush'; break;
			case 'FlagFast4': ActionAttack='FlagFast4Rush'; break;
			case 'FlagStrong1': ActionAttack='FlagStrong1Rush'; break;
			case 'FlagStrong2': ActionAttack='FlagStrong2Rush'; break;
			case 'FlagStrong3': ActionAttack='FlagStrong3Rush'; break;
			case 'FlagStrong4': ActionAttack='FlagStrong4Rush'; break;
		}
	}
	else ActionAttack=CurrentAttack;
}

//This function randomly chooses what animation to play. It also prevents the same
//animation from playing twice in a row.
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
    			CurrentAttack='FlagFast1';
				bKicking=false;
			}
			else if (TempRand < 0.50)
			{
				CurrentAttack='FlagFast2';
				bKicking=false;
			}
			else if (TempRand < 0.75)
			{
    			CurrentAttack='FlagFast3';
				bKicking=false;
			}
			else
			{
				CurrentAttack='FlagFast4';
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
    			CurrentAttack='AttackFast1';
				bKicking=false;
			}
			else if (TempRand < 0.50)
			{
    			CurrentAttack='AttackFast2';
				bKicking=false;
			}
			else if (TempRand < 0.75)
			{
				CurrentAttack='AttackFast3';
				bKicking=true;
			}
			else
			{
				CurrentAttack='AttackFast4';
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
				CurrentAttack='AttackFast3';
				bKicking=true;
			}
			else
			{
				CurrentAttack='AttackFast4';
				bKicking=true;
			}
		}
	}
}

function PlayFireEnd()
{
//	if ( Instigator.Controller.IsA('PlayerController') )
//		PlayerController(Instigator.Controller).ClientMessage("FireEnd");
}

function float MaxRange()
{
	return 300;
}

defaultproperties
{
    WhiffSound=Sound'K2k4Sounds.Unarmed.WhiffSound'
    WhackSound=Sound'K2k4Sounds.Unarmed.WhackSound'
    HitWallSound=Sound'K2k4Sounds.Unarmed.GuardSound'
    Damage=15.00
    Force=25000.00
    OriginalRate=0.45
    FocusRate=0.50
    FireRate=0.45
    AmmoClass=Class'UnarmedAmmo'
    aimerror=1000.00
}
