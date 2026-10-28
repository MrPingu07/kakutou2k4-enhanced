/*
Kakutou 2004!!!
	version 1.0
	Code and animations done by PsychoKick, circa 2002.
	Sounds ripped from Sega's Virtua Fighter PC and edited by PsychoKick.
	Very special thanks to the UT community for sharing the knowledge to make this mod possible.
	Dedicated to all who practice the martial arts, whether in reality or in games.
	UT2004 Code Modifications for Instant Action: Rythmix - Rythmix@gmail.com - www.rythm-nation.net
*/

//The Unarmed weapon. Responsible for altering the player's speed and blocking attacks
//dependant on the player's relative movement direction (ie: Forward = faster speed,
//lower guard. Backward = normal speed, higher guard). Note that you can't guard and
//attack at the same time.
class Unarmed extends Weapon
	config(user);

#EXEC OBJ LOAD FILE=InterfaceContent.utx

var int Dir;
var float SpeedBonus;
var() float RecoverTime, RushTimer, LeapTimer;
var() sound GuardSound;
var() int BonusPerHit, BonusPerGuard, PenaltyPerMiss;
var() int RushCounter, MaxRush;
var() bool bAdjustedForComboSpeed, bIsUnarmed, bWasUnarmed, bFlagFighting, bIsLeaping;
var() int BlockMinDegrees, BlockMaxDegrees, LeapBonus;

simulated function Tick( float DeltaTime )
{
//Don't bother mucking around if the game is already over.
    if ((Level.Game!=None) && !Level.Game.bGameEnded)
    {
//Check if weapon has changed, apply appropriate camera modifiers
//This check is something of a kludge, but it works well enough.
		if( (Instigator!=None) &&
			(Instigator.Weapon!=None) &&
			(Instigator.Controller!=None) )
		{
			bWasUnarmed = bIsUnarmed;
			bIsUnarmed = Instigator.Weapon.IsA('Unarmed');

	    	if (bIsUnarmed != bWasUnarmed)
    		{
//Adjust camera & crosshairs according to weapon type — unless the dedicated
//third-person mutator is in charge of the camera, in which case leave it alone.
				if ( (PlayerController(Instigator.Controller)!=None)
					&& !Instigator.Controller.IsA('GTAPlayerController') )
				{
					PlayerController(Instigator.Controller).bBehindView=bIsUnarmed;
					PlayerController(Instigator.Controller).ClientSetBehindView(bIsUnarmed);
				}

//If not martial arts, run adjustments. Otherwise don't, because WeaponTick() will handle it.
				if(bIsUnarmed)
				{
				}
				else
				{
					DoAdjustments(DeltaTime);
				}
			}
		}
	}
}

simulated event WeaponTick(float dt)				//unneeded?
{
//Don't bother mucking around if the game is already over.
    if ( (Level.Game!=None) && !Level.Game.bGameEnded)
//		if( (Instigator!=None) && (Instigator.Weapon!=None) && (PlayerController(Instigator.Controller)!=None) )
		if( (Instigator!=None) && (Instigator.Weapon!=None) && (Instigator.Controller!=None) )
		{
			if ((Instigator.PlayerReplicationInfo!= none) && (Instigator.PlayerReplicationInfo.HasFlag != none))
				bFlagFighting=true;
			else
				bFlagFighting=false;

			DoAdjustments(dt);
//			Instigator.PlayAnim(K2k4xPawn(Instigator).AnimAction);
		}
}

simulated function DoAdjustments(float DeltaTime)
{
//Adjust ground speed according to weapon type, movement direction, and current combo
	if ( K2k4xPawn(Instigator).CurrentCombo!=None && K2k4xPawn(Instigator).CurrentCombo.IsA('ComboSpeed') )
	{
		if  (!bAdjustedForComboSpeed)
		{
			Instigator.GroundSpeed = Instigator.Default.GroundSpeed * 1.4;
			bAdjustedForComboSpeed=true;
		}
	}
	else
	{
		bAdjustedForComboSpeed = false;

		if (bIsUnarmed)
		{
			Dir = Instigator.Controller.GetFacingDirection();
			SpeedBonus = (((Abs(32768 - Dir))/32768 ) * 0.3) + 1;
//			SpeedBonus = Abs(32768-Dir) * 0.0000091552734375 + 1;
//			SpeedBonus = (((Abs(32768 - Dir))/32768 ) * 5.0) + 1;
			Instigator.GroundSpeed = Instigator.Default.GroundSpeed * SpeedBonus;
		}
		else if (Instigator.GroundSpeed != Instigator.Default.GroundSpeed)
		{
			Instigator.GroundSpeed = Instigator.Default.GroundSpeed;
		}
	}

    if (!bIsUnarmed)
    	bIsLeaping=false;
	else if ( (LeapTimer>0.0) && (Instigator.Physics == PHYS_FALLING) )
		bIsLeaping=true;
	else if ( bIsLeaping && (Instigator.Physics!=PHYS_FALLING) )
		bIsLeaping=false;

//Adjust jump height according to LeapTimer and current combo
	if ( ((LeapTimer>0.0) && (bIsUnarmed)) || bIsLeaping)
	{
		Instigator.AirControl = Instigator.default.AirControl * 1.5;
		Instigator.JumpZ = Instigator.default.JumpZ * (1.0+(LeapBonus/100.0));
		Instigator.DodgeSpeedFactor = Instigator.default.DodgeSpeedFactor * (1.0+(LeapBonus/100.0));
	}
	else
	{
		if (bAdjustedForComboSpeed)
		{
			Instigator.AirControl = Instigator.default.AirControl * 1.4;
			Instigator.JumpZ = Instigator.default.JumpZ * 1.5;
		}
		else
		{
			Instigator.AirControl = Instigator.default.AirControl;
			Instigator.JumpZ = Instigator.default.JumpZ;
		}

		Instigator.DodgeSpeedFactor = Instigator.default.DodgeSpeedFactor;
	}

//Adjust recovery time and leaptimer according to weapon type
	if (bIsUnarmed)
	{
		if (RecoverTime > 0.0)
			RecoverTime -= DeltaTime;
		if (RecoverTime < 0.0)
			RecoverTime = 0.0;

		if (RushTimer > 0.0)
			RushTimer -= DeltaTime;
		if (RushTimer <= 0.0)
		{
			RushTimer = 0.0;
			RushCounter = 1;
		}

		if(Instigator.bIsCrouched)
		{
			LeapTimer=0.67;
		}
		else
		{
			if (LeapTimer > 0.0) LeapTimer -= DeltaTime;
			if (LeapTimer < 0.0) LeapTimer = 0.0;
		}
	}
	else
	{
		RecoverTime = 0.0;
		RushTimer = 0.0;
		RushCounter = 1;
		LeapTimer=0.0;
	}
}

function AdjustPlayerDamage( out int Damage, Pawn InstigatedBy, Vector HitLocation,
						         out Vector Momentum, class<DamageType> DamageType)
{
	local vector HitNormal;
	local int AdjustedDamage;
//Check for valid block. Superweapons and telefrags cannot be blocked.
	if( (DamageType!=class'DamTypeRedeemer') &&
		(DamageType!=class'DamTypeIonBlast') &&
		(DamageType!=class'DamTypeTeleFrag') &&
		(RecoverTime <= 0.0) &&	(CheckReflect(HitLocation, HitNormal, 0)) )
	{
		if ((DamageType==class'Fell') && (Damage>20))
			AdjustedDamage = Damage/2;
		else AdjustedDamage = 0;

		if (Unarmed(Instigator.Weapon).bFlagFighting)
		{
			K2k4xPawn(Instigator).SetAnimAction('FlagGuard');
		}
		else
		{
			K2k4xPawn(Instigator).SetAnimAction('Guard');
		}

	    Instigator.PlaySound(GuardSound, SLOT_Pain,0.4,,,,false);

//Successful defense gains BonusPerGuard points of focus
		if (DamageType != class'Fell')
		{
            Instigator.Weapon.AddAmmo(BonusPerGuard,0);
		}
	    Damage=AdjustedDamage;
		Momentum=Vect(0,0,0);
	}
}

function bool CheckReflect( Vector HitLocation, out Vector RefNormal, int AmmoDrain )
{
    local vector HitDir;
    local vector FaceDir;
	local float DefenseValue;
	local float MinBlockValue, MaxBlockValue;
	local int MinBlockArc, MaxBlockArc;

    FaceDir = vector(Instigator.Controller.Rotation);
    HitDir = Normal(Instigator.Location - HitLocation + Vect(0,0,8));

    RefNormal = FaceDir;

//DefenseValue of -1.0 offers 0 protection, while 1.0 offers 360 protection
//Abs(32768 - Dir) of 0 equals backward movement, while 32768 equals forward.
/*
+1.00	360'
+0.00	180'
 -0.25	135'
 -0.50	090'
 -0.75	045'
-1.00	000'
*/
//	DefenseValue = (Abs(32768-Dir) / 32768) * (-0.26) - 0.37;
//	DefenseValue = (Abs(32768-Dir) / 32768) * (-0.30) + (-0.25);
//	MinBlockArc = 90;
//	MaxBlockArc = 135;

	MinBlockArc = BlockMinDegrees;
	MaxBlockArc = BlockMaxDegrees;
	MinBlockValue = (MinBlockArc-180)/180;//-0.55;
	MaxBlockValue = (MaxBlockArc-180)/180;//-0.25;
	DefenseValue = (Abs(32768-Dir) / 32768) *  (MinBlockValue - MaxBlockValue) + MaxBlockValue;
    if ( FaceDir dot HitDir < DefenseValue )
        return true;
    return false;
}

simulated function BringUp(optional Weapon PrevWeapon)
{
   local int Mode;

    if (ClientState == WS_Hidden)
    {
        PlayOwnedSound(SelectSound, SLOT_Interact,,,,, false);
		ClientPlayForceFeedback(SelectForce);  // jdf
        ClientState = WS_BringUp;
        SetTimer(0.3, false);
    }
    for (Mode = 0; Mode < NUM_FIRE_MODES; Mode++)
	{
		FireMode[Mode].bIsFiring = false;
		FireMode[Mode].HoldTime = 0.0;
		FireMode[Mode].bServerDelayStartFire = false;
		FireMode[Mode].bServerDelayStopFire = false;
	}
}

simulated function bool PutDown()
{
    local int Mode;

    if (ClientState == WS_BringUp || ClientState == WS_ReadyToFire)
    {
        if (!Instigator.PendingWeapon.bForceSwitch)
        {
            for (Mode = 0; Mode < NUM_FIRE_MODES; Mode++)
            {
                if (FireMode[Mode].bFireOnRelease && FireMode[Mode].bIsFiring)
                    return false;
            }
        }

        if (Instigator.IsLocallyControlled())
        {
            for (Mode = 0; Mode < NUM_FIRE_MODES; Mode++)
            {
                if (FireMode[Mode].bIsFiring)
                    ClientStopFire(Mode);
            }
        }
        ClientState = WS_PutDown;

        SetTimer(0.3, false);
    }
    for (Mode = 0; Mode < NUM_FIRE_MODES; Mode++)
    {
		FireMode[Mode].bServerDelayStartFire = false;
		FireMode[Mode].bServerDelayStopFire = false;
	}
    Instigator.AmbientSound = None;
    return true; // return false if preventing weapon switch
}

simulated function OutOfAmmo()
{
}
//    Mesh=SkeletalMesh'Weapons.ShieldGun_1st'
defaultproperties
{
    GuardSound=Sound'K2k4Sounds.Unarmed.GuardSound'
    BonusPerHit=10
    BonusPerGuard=3
    PenaltyPerMiss=3
    RushCounter=1
    MaxRush=5
    bWasUnarmed=True
    BlockMinDegrees=90
    BlockMaxDegrees=135
    LeapBonus=100
    FireModeClass(0)=Class'UnarmedFire'
    FireModeClass(1)=Class'UnarmedAltFire'
    PutDownAnim=PutDown
    SelectSound=Sound'WeaponSounds.Misc.shieldgun_change'
    SelectForce="ShieldGun_change"
    AIRating=0.39
    CurrentRating=0.39
    // Keep Unarmed ahead of other weapons in inventory group 1 (the
    // ShieldGun slot), even if another mutator or pickup adds one there, so
    // the slot key and auto-switch always land on Unarmed.
    Priority=50
    // Stock weapons all use GroupOffset 0. Giving Unarmed offset 1 keeps a
    // second group-1 weapon (a ShieldGun or Impact Hammer picked up during
    // play) reachable with the previous/next weapon keys instead of being
    // stranded in the same group. Both values are class defaults, so the
    // server and the HUD agree without needing replication.
    GroupOffset=1
    bMeleeWeapon=True
    bCanThrow=False
    PickupClass=Class'UnarmedPickup'
    AttachmentClass=Class'UnarmedAttachment'
    IconMaterial=Texture'InterfaceContent.HUD.SkinA'
    IconCoords=(X1=200,Y1=281,X2=321,Y2=371)
    ItemName="Unarmed"
    DrawType=0
    UV2Texture=Shader'XGameShaders.WeaponShaders.WeaponEnvShader'
}
