/*
Kakutou 2004!!!
	version 1.0
	Code and animations done by PsychoKick, circa 2002.
	Sounds ripped from Sega's Virtua Fighter PC and edited by PsychoKick.
	Very special thanks to the UT community for sharing the knowledge to make this mod possible.
	Dedicated to all who practice the martial arts, whether in reality or in games.
	UT2004 Code Modifications for Instant Action: Rythmix - Rythmix@gmail.com - www.rythm-nation.net
*/

//This replaces xPawn. Without this replacement it would be nigh-impossible to properly replicate
//all the animations. I originally wanted to restrict everything to the weapon code, but in the
//end this was the only practical way I could get the effects I wanted.
class K2k4xPawn extends xPawn
	config(User)
    dependsOn(xUtil)
    dependsOn(xPawnSoundGroup)
    dependsOn(xPawnGibGroup);

#exec ANIM IMPORT ANIM=K2k4Anims ANIMFILE=MODELS\K2k4Anims.PSA COMPRESS=0.9 MAXKEYS=9999999
#exec ANIM DIGEST ANIM=K2k4Anims USERAWINFO VERBOSE

#exec ANIM IMPORT ANIM=K2k4Anims1 ANIMFILE=MODELS\K2k4Anims1.PSA COMPRESS=0.9 MAXKEYS=9999999
#exec ANIM DIGEST ANIM=K2k4Anims1 USERAWINFO VERBOSE

#exec ANIM IMPORT ANIM=K2k4FlagAnims ANIMFILE=MODELS\K2k4FlagAnims.PSA COMPRESS=0.9 MAXKEYS=9999999
#exec ANIM DIGEST ANIM=K2k4FlagAnims USERAWINFO VERBOSE

#exec ANIM IMPORT ANIM=K2k4FlagAnims1 ANIMFILE=MODELS\K2k4FlagAnims1.PSA COMPRESS=0.9 MAXKEYS=9999999
#exec ANIM DIGEST ANIM=K2k4FlagAnims1 USERAWINFO VERBOSE

//var float BerRate, BerTween;   //removed for UT2K4 compatibility
var name PrevAnimAction;

// Upper-body animation layering (channel 1).
// Locomotion (walk/run/turn/crouch/jump) plays on channel 0. The martial-arts
// guard/attack animations play on channel 1 with a blend root at the spine so
// they keep owning the torso, arms and head no matter what the legs are doing.
var name K2k4UpperIdle;         // current upper-body idle loop
var bool bK2k4UpperBusy;        // a one-shot upper-body animation is playing
var bool bK2k4UpperActive;      // channel 1 is being driven by this pawn
var bool bK2k4Kicking;          // a full-body kick currently owns channel 0
var bool bK2k4AirFullBody;      // a fast air clip currently owns hips and up
var bool bK2k4Emoting;          // an emote/taunt is playing; channel 1 is free
var float K2k4KickTimeout;      // safety net if AnimEnd never arrives
var bool bK2k4Combat;           // combat stance: ready pose on the torso
var float K2k4CombatTime;       // last time a combat action ran
var float K2k4CombatHold;       // seconds without combat before relaxing
var float K2k4RelaxBlend;       // blend-out time for the return to relaxed

replication
{
	reliable if (bNetDirty && (Role==ROLE_AUTHORITY))
        PrevAnimAction;
}

simulated function AssignInitialPose()
{
	super.AssignInitialPose();

	LinkSkelAnim(MeshAnimation'K2k4Anims');
	LinkSkelAnim(MeshAnimation'K2k4Anims1');
	LinkSkelAnim(MeshAnimation'K2k4FlagAnims');
	LinkSkelAnim(MeshAnimation'K2k4FlagAnims1');

	// Torso root for the martial-arts overlay. Channel 1 therefore only
	// overrides the bones from the lower spine upwards; hips/legs stay free
	// for locomotion. FireRootBone is the stock xPawn torso root.
	AnimBlendParams(1, 1.0, 0.2, 0.2, FireRootBone);
}

simulated function Tick(float DeltaTime)
{
	local PlayerController pc;
	local bool bGTA;

	pc = PlayerController(Controller);
	// The dedicated third-person mutator owns the camera whenever it is
	// installed. Detect it by name so Kakutou has no hard package dependency.
	bGTA = (Controller != None) && Controller.IsA('GTAPlayerController');

	// Never advertise a special camera while GTA is driving the view: its
	// PlayerCalcView() is authoritative.
	if (bGTA)
		bSpecialCalcView = false;
	else if (Controller != None)
		bSpecialCalcView = true;

	if (pc != None)
	{
		if ( (Weapon != None) && Weapon.IsA('Unarmed') )
		{
			// GTA draws the stock crosshair and uses it for aiming, so leave
			// it alone. Without GTA keep the original HUD hiding.
			if ( (pc.myHUD != None) && !bGTA )
				pc.myHUD.bCrosshairShow = false;
			else if ( (pc.myHUD != None) && bGTA )
				pc.myHUD.bCrosshairShow = pc.myHUD.default.bCrosshairShow;

			// Arms down until a combat action has happened recently.
			if ( !bK2k4Combat )
			{
				if (IdleWeaponAnim != IdleRestAnim)
					IdleWeaponAnim = IdleRestAnim;
			}
			else if (Unarmed(Weapon).bFlagFighting && (IdleWeaponAnim!='FlagReady') )
				IdleWeaponAnim='FlagReady';
			else if (!Unarmed(Weapon).bFlagFighting && (IdleWeaponAnim!='Ready') )
				IdleWeaponAnim='Ready';
		}
		else if (pc.myHUD != None)
		{
			pc.myHUD.bCrosshairShow = pc.myHUD.default.bCrosshairShow;
		}
	}

	// An air override ends the moment we are back on the ground
	// (or any other non-falling physics state takes over).
	if ( bK2k4AirFullBody && (Physics != PHYS_Falling) )
		K2k4RestoreAirUpperBody();

	K2k4UpdateUpperBody();

	PrevAnimAction = AnimAction;
	super.Tick(DeltaTime);
}

// ---------------------------------------------------------------------------
// Upper-body layering helpers
// ---------------------------------------------------------------------------

simulated function name K2k4DesiredUpperIdle()
{
	if ( !bK2k4Combat )
		return '';
	if ( (Unarmed(Weapon) != None) && Unarmed(Weapon).bFlagFighting )
		return 'FlagReady';
	return 'Ready';
}

simulated function bool K2k4IsKickAction(name A)
{
	return ( (A == 'AttackFast3') || (A == 'AttackFast4')
		  || (A == 'AttackStrong3') || (A == 'AttackStrong4')
		  || (A == 'AttackFast3Rush') || (A == 'AttackFast4Rush')
		  || (A == 'AttackStrong3Rush') || (A == 'AttackStrong4Rush') );
}

simulated function bool K2k4IsUpperAction(name A)
{
	if (K2k4IsKickAction(A))
		return false;

	return ( (A == 'AttackFast1') || (A == 'AttackFast2')
		  || (A == 'AttackStrong1') || (A == 'AttackStrong2')
		  || (A == 'AttackFast1Rush') || (A == 'AttackFast2Rush')
		  || (A == 'AttackStrong1Rush') || (A == 'AttackStrong2Rush')
		  || (A == 'FlagFast1') || (A == 'FlagFast2')
		  || (A == 'FlagFast3') || (A == 'FlagFast4')
		  || (A == 'FlagFast1Rush') || (A == 'FlagFast2Rush')
		  || (A == 'FlagFast3Rush') || (A == 'FlagFast4Rush')
		  || (A == 'FlagStrong1') || (A == 'FlagStrong2')
		  || (A == 'FlagStrong3') || (A == 'FlagStrong4')
		  || (A == 'FlagStrong1Rush') || (A == 'FlagStrong2Rush')
		  || (A == 'FlagStrong3Rush') || (A == 'FlagStrong4Rush')
		  || (A == 'Guard') || (A == 'FlagGuard')
		  || (A == 'Ready') || (A == 'FlagReady') );
}

// ---------------------------------------------------------------------------
// Jump / air-jump animation remap
// ---------------------------------------------------------------------------
// 0 = forward, 1 = back, 2 = left, 3 = right. Unlike the stock
// Get4WayDirection() this is based on the pawn's own facing, not the
// camera, so free-orbit movement (where the body faces its velocity)
// always reads as a forward air move, while aim-mode strafing produces
// the matching side dodge.
simulated function int K2k4GetAirDirection()
{
	local vector FlatVel, Fwd, Right;
	local float FwdDot, RightDot;

	FlatVel = Velocity;
	FlatVel.Z = 0.0;
	if ( VSize(FlatVel) < 20.0 )
		return 0;

	FlatVel = Normal(FlatVel);

	Fwd = vector(Rotation);
	Fwd.Z = 0.0;
	if ( VSize(Fwd) < 0.001 )
		return 0;
	Fwd = Normal(Fwd);

	Right = Normal(vect(0,0,1) cross Fwd);

	FwdDot   = FlatVel dot Fwd;
	RightDot = FlatVel dot Right;

	if ( Abs(FwdDot) >= Abs(RightDot) )
	{
		if ( FwdDot >= 0.0 )
			return 0;
		return 1;
	}

	if ( RightDot >= 0.0 )
		return 3;
	return 2;
}

// The jump/dodge override only applies to the martial-arts style: unarmed
// and travelling at (or above) the class's default running speed. Slower
// jumps, and every other weapon, keep the stock animations.
simulated function bool K2k4CanOverrideAirAnim()
{
	local vector FlatVel;

	if ( Unarmed(Weapon) == None )
		return false;

	FlatVel = Velocity;
	FlatVel.Z = 0.0;
	return (VSize(FlatVel) >= default.GroundSpeed);
}

simulated function bool K2k4PlayAirAnim(name Anim)
{
	if ( !K2k4CanOverrideAirAnim() )
		return false;

	if ( (Anim == '') || !HasAnim(Anim) )
		return false;

	if ( PlayAnim(Anim, 1.0, 0.1, 0) )
	{
		AnimAction = Anim;
		bWaitForAnim = true;	// hold the one-shot air animation

		// Fast air moves are full-body: they own the hips and everything
		// above for the duration of the clip. The guard overlay comes back
		// when the clip ends or the pawn lands.
		bK2k4AirFullBody = true;
		bK2k4Kicking = false;
		bK2k4UpperBusy = false;
		AnimBlendToAlpha(1, 0.0, 0.1);
		return true;
	}

	return false;
}

// First jump: use the stock double-jump clip instead of the usual takeoff.
function bool DoJump(bool bUpdating)
{
	local bool bWasFalling;

	bWasFalling = (Physics == PHYS_Falling);

	if ( Super.DoJump(bUpdating) )
	{
		// xPawn.DoJump() can itself perform a mid-air jump (bots and
		// direct calls). Do not overwrite that with a takeoff clip.
		if ( !bWasFalling && !bUpdating )
			K2k4PlayAirAnim(DoubleJumpAnims[K2k4GetAirDirection()]);

		return true;
	}

	return false;
}

// Every extra jump before landing: replace the stock double-jump clip
// with the dodge matching the body-relative movement direction.
simulated function PlayDoubleJump()
{
	if ( !K2k4PlayAirAnim(DodgeAnims[K2k4GetAirDirection()]) )
	{
		// Gate failed (slow jump, or not unarmed): give the torso back to
		// the guard overlay before the stock double-jump clip plays.
		K2k4RestoreAirUpperBody();
		Super.PlayDoubleJump();
	}
}

simulated function K2k4ResetUpperBody()
{
	bK2k4UpperActive = false;
	bK2k4UpperBusy = false;
	bK2k4Kicking = false;
	bK2k4AirFullBody = false;
	K2k4UpperIdle = '';
	bK2k4Combat = false;
	AnimBlendToAlpha(1, 0.0, 0.15);
}

// Arms down: channel 1 fades out slowly so the stock idle on channel 0 shows.
simulated function K2k4RelaxUpperBody()
{
	bK2k4UpperActive = false;
	bK2k4UpperBusy = false;
	K2k4UpperIdle = '';
	AnimBlendToAlpha(1, 0.0, K2k4RelaxBlend);
}

// Ends a fast air clip's full-body ownership and hands the torso back to
// the guard overlay (or releases it if the pawn is no longer unarmed).
simulated function K2k4RestoreAirUpperBody()
{
	if ( !bK2k4AirFullBody )
		return;

	bK2k4AirFullBody = false;

	if ( (Unarmed(Weapon) != None) && (Health > 0) && (DrivenVehicle == None) )
		K2k4LoopUpperIdle();
	else
		K2k4ResetUpperBody();
}

simulated function K2k4LoopUpperIdle()
{
	K2k4UpperIdle = K2k4DesiredUpperIdle();
	if ( K2k4UpperIdle == '' )
	{
		K2k4RelaxUpperBody();
		return;
	}
	bK2k4UpperBusy = false;
	bK2k4UpperActive = true;
	AnimBlendToAlpha(1, 1.0, 0.15);
	AnimBlendParams(1, 1.0, 0.0, 0.15, FireRootBone);
	LoopAnim(K2k4UpperIdle, 1.0, 0.15, 1);
}

simulated function K2k4UpdateUpperBody()
{
	local name Desired;

	// Channel 1 is only ours while holding the martial-arts weapon, alive,
	// and not riding something.
	if ( (Health <= 0) || (Unarmed(Weapon) == None) || (DrivenVehicle != None) )
	{
		if (bK2k4UpperActive || bK2k4Kicking || bK2k4AirFullBody)
			K2k4ResetUpperBody();
		return;
	}

	// A fast air clip owns the whole body while airborne. Keep channel 1
	// muted until the clip ends (AnimEnd) or the pawn lands (Tick).
	if ( bK2k4AirFullBody )
	{
		if ( Physics == PHYS_Falling )
			return;
		K2k4RestoreAirUpperBody();
		return;
	}

	// Combat stance stays up while a combat action runs, then drops back to
	// relaxed K2k4CombatHold seconds after the last one.
	if ( bK2k4Combat )
	{
		if ( (bK2k4UpperBusy && IsAnimating(1)) || bK2k4Kicking || bK2k4Emoting )
			K2k4CombatTime = Level.TimeSeconds;
		else if ( Level.TimeSeconds - K2k4CombatTime > K2k4CombatHold )
			bK2k4Combat = false;
	}

	// An emote/taunt owns the body: keep channel 1 free so stock can play it
	// full-body or on channel 1 without the guard overlay fighting it. Once
	// the emote stops animating, hand the torso back to the overlay.
	if ( bK2k4Emoting )
	{
		if ( IsAnimating(0) || IsAnimating(1) )
			return;	// emote still playing; channel 1 stays free
		bK2k4Emoting = false;
		if ( (Unarmed(Weapon) != None) && (Health > 0) && (DrivenVehicle == None) )
			K2k4LoopUpperIdle();
		else
			K2k4ResetUpperBody();
		return;
	}

	// Arms down until the next combat action.
	if ( !bK2k4Combat )
	{
		if ( bK2k4UpperActive )
			K2k4RelaxUpperBody();
		return;
	}

	// Safety net in case a kick's AnimEnd never fires.
	if ( bK2k4Kicking && (Level.TimeSeconds > K2k4KickTimeout) )
	{
		bK2k4Kicking = false;
		bWaitForAnim = false;
		K2k4LoopUpperIdle();
	}

	if (bK2k4Kicking)
		return;

	// A one-shot attack ended without us seeing AnimEnd (interrupted etc.).
	if ( bK2k4UpperBusy && !IsAnimating(1) )
		bK2k4UpperBusy = false;

	if (bK2k4UpperBusy)
		return;

	Desired = K2k4DesiredUpperIdle();
	bK2k4UpperActive = true;
	AnimBlendParams(1, 1.0, 0.0, 0.15, FireRootBone);

	if ( !IsAnimating(1) || (K2k4UpperIdle != Desired) )
		K2k4LoopUpperIdle();
}

simulated function AnimEnd(int Channel)
{
	// Fast air clip just finished: the hips-up ownership ends here.
	if ( bK2k4AirFullBody && (Channel == 0) )
	{
		K2k4RestoreAirUpperBody();
		super.AnimEnd(Channel);
		return;
	}

	// A one-shot punch/guard overlay finished while the air clip owns the
	// torso. Do not let it re-enable channel 1 mid-air.
	if ( bK2k4AirFullBody && (Channel == 1) )
	{
		bK2k4UpperBusy = false;
		super.AnimEnd(Channel);
		return;
	}

	if ( (Channel == 1) && bK2k4UpperActive )
	{
		if ( (Unarmed(Weapon) != None) && (Health > 0) && (DrivenVehicle == None) )
		{
			// Our overlay finished (or stock tried to blend it out): return to
			// the martial-arts idle loop instead of releasing the torso.
			K2k4LoopUpperIdle();
			return;
		}
		// Weapon changed / died mid-animation: release the channel.
		K2k4ResetUpperBody();
	}

	if ( (Channel == 0) && bK2k4Kicking )
	{
		bK2k4Kicking = false;
		bWaitForAnim = false;
		if ( (Unarmed(Weapon) != None) && (Health > 0) && (DrivenVehicle == None) )
			K2k4LoopUpperIdle();
		else
			K2k4ResetUpperBody();
	}

	super.AnimEnd(Channel);
}


//Process unarmed animations first before processing the normal animations.
//simulated event SetAnimAction(name NewAction)
simulated function SetAnimAction(name NewAction)	//function seems to play smoother animation than event. Don't know why.
{
	local name EmoteSeq;

    AnimAction = NewAction;
    bK2k4Emoting = false;	// any new action ends an emote's channel-1 exemption

    // A new action takes the torso back from a fast air clip.
    if (bK2k4AirFullBody)
        K2k4RestoreAirUpperBody();

    // Not fighting unarmed: leave everything to stock xPawn.
    if (Unarmed(Weapon) == None)
    {
        if (bK2k4UpperActive || bK2k4Kicking)
            K2k4ResetUpperBody();
        super.SetAnimAction(NewAction);
        return;
    }

    // The ready pose only shows while in combat stance.
    if ( (NewAction == 'Ready') || (NewAction == 'FlagReady') )
    {
        if ( !bK2k4Combat )
            return;
    }
    else if ( K2k4IsKickAction(NewAction) || K2k4IsUpperAction(NewAction) )
    {
        bK2k4Combat = true;
        K2k4CombatTime = Level.TimeSeconds;
    }

    // Kicks are full-body moves: play them on channel 0 and mute the
    // upper-body overlay for their duration.
    if (K2k4IsKickAction(NewAction))
    {
        bK2k4Kicking = true;
        bK2k4UpperBusy = false;
        bK2k4UpperActive = true;
        K2k4KickTimeout = Level.TimeSeconds + 2.0;
        AnimBlendToAlpha(1, 0.0, 0.05);
        PlayAnim(NewAction, 1.0, 0.1, 0);
        bWaitForAnim = true;		//Animate the entire body for kick attacks
        return;
    }

    // Punches / guard / ready are torso-only: channel 1 keeps locomotion
    // (channel 0) completely intact below the spine.
    if (K2k4IsUpperAction(NewAction))
    {
        bK2k4Kicking = false;
        bWaitForAnim = false;
        bK2k4UpperActive = true;
        AnimBlendToAlpha(1, 1.0, 0.1);
        AnimBlendParams(1, 1.0, 0.0, 0.15, FireRootBone);

        if ( (NewAction == 'Ready') || (NewAction == 'FlagReady') )
        {
            K2k4UpperIdle = NewAction;
            bK2k4UpperBusy = false;
            LoopAnim(NewAction, 1.0, 0.15, 1);
        }
        else
        {
            bK2k4UpperBusy = true;
            PlayAnim(NewAction, 1.0, 0.1, 1);
        }
        return;
    }

    // Emotes / taunts: free channel 1 so stock can play the emote full-body
    // or on channel 1 without the guard overlay fighting it. Stock's own
    // SetAnimAction will re-enable channel 1 if it plays the emote there.
    EmoteSeq = NewAction;
    if ( FindValidTaunt( EmoteSeq ) )
    {
        bK2k4Emoting = true;
        bK2k4UpperActive = false;
        AnimBlendToAlpha(1, 0.0, 0.05);	// mute channel 1 for full-body emotes
        super.SetAnimAction(NewAction);	// stock plays the emote
        return;
    }

    // Some other action (weapon switch, ...): stock handles it. The
    // next Tick re-establishes the martial-arts upper body.
    super.SetAnimAction(NewAction);
}


simulated function bool SpecialCalcView(out actor ViewActor, out vector CameraLocation, out rotator CameraRotation )
{
	local PlayerController pc;

    if ((Level.Game!=None) && Level.Game.bGameEnded)
		return false;

	pc = PlayerController(Controller);

	if (pc == none)
		return false;

	// Let the dedicated third-person camera win the view outright.
	if (pc.IsA('GTAPlayerController'))
		return false;

	CameraLocation = self.Location;

	if( pc.bBehindView ) //up and behind
	{
		pc.CalcBehindView(CameraLocation, CameraRotation, pc.CameraDist * self.default.CollisionRadius);
		if (Weapon.IsA('Unarmed'))
			CameraLocation.Z+=62;
	}
	else
		pc.CalcFirstPersonView( CameraLocation, CameraRotation );
	return true;
}

// Kakutou owns the ShieldGun slot (inventory group 1). Some loadout mutators
// (UT2341, for example) put their own melee weapon there by rewriting
// RequiredEquipment during CheckReplacement. Force Unarmed back in after they
// have had their turn and before any default inventory is created, so the two
// weapons can never share the slot.
simulated function AddDefaultInventory()
{
    RequiredEquipment[1] = string(class'Unarmed');
    Super.AddDefaultInventory();
}

defaultproperties
{
    RequiredEquipment(1)="Kakutou2k4-Enhanced.Unarmed"
    bSpecialCalcView=True
    bReplicateAnimations=True
    K2k4CombatHold=2.0
    K2k4RelaxBlend=1.0
}
