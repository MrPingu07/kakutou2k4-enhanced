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
var bool bK2k4Kicking;          // a full-body kick currently owns channel 1
var bool bK2k4AirFullBody;      // a fast air clip currently owns hips and up
var bool bK2k4Emoting;          // an emote/taunt is playing; channel 1 is free
var float K2k4KickTimeout;      // safety net if AnimEnd never arrives
var bool bK2k4Combat;           // combat stance: ready pose on the torso
var bool bK2k4Unarmed;          // replicated: Unarmed equipped (remote-proxy safe)
var float K2k4CombatTime;       // last time a combat action ran
var float K2k4CombatHold;       // seconds without combat before relaxing
var float K2k4RelaxBlend;       // blend-out time for the return to relaxed
var config name K2k4RelaxIdleAnim;	// relaxed standing base pose (falls back to IdleRestAnim)
var config rotator K2k4ArmDownL;	// upper-arm offset that lowers the left arm (User.ini)
var config rotator K2k4ArmDownR;	// upper-arm offset that lowers the right arm (User.ini)
var config rotator K2k4ForearmL;	// forearm offset that straightens the left elbow (User.ini)
var config rotator K2k4ForearmR;	// forearm offset that straightens the right elbow (User.ini)
var config rotator K2k4WristL;		// hand offset for the left wrist (Bip01 L Finger0, User.ini)
var config rotator K2k4WristR;		// hand offset for the right wrist (Bip01 R Hand, User.ini)
var config float K2k4AirJumpBoostFraction;	// extra-jump speed nudge, fraction of GroundSpeed (User.ini)
var config bool bK2k4DebugAnim;	// log channel/idle changes to UT2004.log (User.ini)
var config bool bK2k4DebugNetAnim;	// log client/server animation state (User.ini)
var name K2k4DbgSeq0, K2k4DbgSeq1, K2k4DbgIdle;
var float K2k4ArmAlpha;			// how much of the arm-down offset is applied (0..1)
var bool bK2k4ArmOn;			// the arm bones currently carry an offset
var float K2k4NetDbgTime;		// next periodic network-animation log line
var float K2k4ActionStart;		// Level.TimeSeconds when the last action began
var name K2k4LastRemoteAction;	// last AnimAction replayed on a remote proxy

replication
{
	reliable if (bNetDirty && (Role==ROLE_AUTHORITY))
        PrevAnimAction, bK2k4DebugNetAnim, bK2k4Combat, bK2k4Unarmed;
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

	// The server is the only machine that can see every pawn's Weapon
	// pointer. Remote proxies usually have Weapon == None, so they use this
	// replicated flag instead of Unarmed(Weapon).
	if (Role == ROLE_Authority)
	{
		if ( bK2k4Unarmed != (Unarmed(Weapon) != None) )
			bK2k4Unarmed = (Unarmed(Weapon) != None);
	}

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
		if ( K2k4IsUnarmed() )
		{
			// GTA draws the stock crosshair and uses it for aiming, so leave
			// it alone. Without GTA keep the original HUD hiding.
			if ( (pc.myHUD != None) && !bGTA )
				pc.myHUD.bCrosshairShow = false;
			else if ( (pc.myHUD != None) && bGTA )
				pc.myHUD.bCrosshairShow = pc.myHUD.default.bCrosshairShow;

			// Arms down until a combat action has happened recently. The
			// relaxed upper-body pose lives on channel 1; channel 0 must
			// keep the stock looping rest idle. Ready is a short torso
			// pose, so using it as IdleRestAnim freezes the legs and makes
			// the engine cancel channel-0 clips (kicks) every idle retry.
			if (IdleRestAnim != default.IdleRestAnim)
				IdleRestAnim = default.IdleRestAnim;
			if ( !bK2k4Combat )
			{
				if (IdleWeaponAnim != K2k4RelaxIdle())
					IdleWeaponAnim = K2k4RelaxIdle();
			}
			else if (K2k4IsFlagFighting() && (IdleWeaponAnim!='FlagReady') )
				IdleWeaponAnim='FlagReady';
			else if (!K2k4IsFlagFighting() && (IdleWeaponAnim!='Ready') )
				IdleWeaponAnim='Ready';
		}
		else if (pc.myHUD != None)
		{
			pc.myHUD.bCrosshairShow = pc.myHUD.default.bCrosshairShow;
		}
		if ( !K2k4IsUnarmed() )
			IdleRestAnim = default.IdleRestAnim;
	}

	// An air override ends the moment we are back on the ground
	// (or any other non-falling physics state takes over).
	if ( bK2k4AirFullBody && (Physics != PHYS_Falling) )
		K2k4RestoreAirUpperBody();

	K2k4SyncRemoteAction();
	K2k4UpdateUpperBody();
	K2k4UpdateArmDown(DeltaTime);
	if ( bK2k4DebugAnim && (pc != None) )
		K2k4DebugAnim();
	if ( bK2k4DebugNetAnim && (Level.TimeSeconds >= K2k4NetDbgTime) )
	{
		K2k4LogNetAnim("TICK");
		K2k4NetDbgTime = Level.TimeSeconds + 0.25;
	}

	PrevAnimAction = AnimAction;
	super.Tick(DeltaTime);
}

// ---------------------------------------------------------------------------
// Remote proxy animation state
// ---------------------------------------------------------------------------

// Remote proxies usually have Weapon == None because inventory is owner-only,
// so Unarmed(Weapon) is not usable there. The server replicates bK2k4Unarmed
// for exactly this case; a real local Weapon pointer always wins when present.
simulated function bool K2k4IsUnarmed()
{
	if ( Unarmed(Weapon) != None )
		return true;
	// The server and the owning client know the real weapon; a remote proxy
	// trusts the replicated flag even if it carries a stale Weapon pointer.
	if ( (Role == ROLE_Authority) || IsLocallyControlled() )
		return false;
	return bK2k4Unarmed;
}

simulated function bool K2k4IsFlagFighting()
{
	if ( Unarmed(Weapon) != None )
		return Unarmed(Weapon).bFlagFighting;
	return (PlayerReplicationInfo != None) && (PlayerReplicationInfo.HasFlag != None);
}

// Only the machine that owns the real simulation ages the combat stance out.
// A remote proxy keeps the replicated bK2k4Combat value until the server sends
// the timeout, so other players stay in the ready pose on every client.
simulated function bool K2k4RunsCombatTimer()
{
	return (Role == ROLE_Authority) || IsLocallyControlled();
}

// Remote proxies receive AnimAction, but stock does not replay it for us.
// Combat actions live on channel 1, so without this a proxy would never show
// them and would also never enter the combat stance. Replay only the actions
// this class owns; stock, air and emote names keep their normal paths.
simulated function K2k4SyncRemoteAction()
{
	if ( (Role == ROLE_Authority) || IsLocallyControlled() )
		return;

	if ( AnimAction == K2k4LastRemoteAction )
		return;

	K2k4LastRemoteAction = AnimAction;
	if ( (AnimAction == '') || !K2k4IsUnarmed() )
		return;

	if ( !K2k4IsKickAction(AnimAction) && !K2k4IsUpperAction(AnimAction) )
		return;

	SetAnimAction(AnimAction);
}

// ---------------------------------------------------------------------------
// Upper-body layering helpers
// ---------------------------------------------------------------------------

// Relaxed standing base pose. The arms are lowered on top of it by
// K2k4UpdateArmDown().
simulated function name K2k4RelaxIdle()
{
	if ( (K2k4RelaxIdleAnim != '') && HasAnim(K2k4RelaxIdleAnim) )
		return K2k4RelaxIdleAnim;
	return default.IdleRestAnim;
}

// Relaxed upper body over walking, running, turning, crouching and swimming.
// Jumps, falls, dodges, emotes and kicks keep the stock or combat behaviour.
simulated function bool K2k4RelaxOverlay()
{
	if ( bK2k4Emoting || bK2k4AirFullBody || bK2k4Kicking || bWaitForAnim )
		return false;
	return ( (Physics == PHYS_Walking) || (Physics == PHYS_Swimming) || (Physics == PHYS_Falling) );
}

simulated function name K2k4DesiredUpperIdle()
{
	if ( !bK2k4Combat )
	{
		if ( K2k4RelaxOverlay() )
			return K2k4RelaxIdle();
		return '';
	}
	if ( K2k4IsFlagFighting() )
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

// The jump/dodge override only applies to the martial-arts style: unarmed.
// Takeoffs additionally require travelling at (or above) the class's default
// running speed; slower takeoffs and every other weapon keep the stock
// animations. Double-jumps pass bAllowSlow so the directional dodge clip
// still plays when the pawn has not reached running speed yet.
simulated function bool K2k4CanOverrideAirAnim(optional bool bAllowSlow)
{
	local vector FlatVel;

	if ( !K2k4IsUnarmed() )
		return false;

	if ( bAllowSlow )
		return true;

	FlatVel = Velocity;
	FlatVel.Z = 0.0;
	return (VSize(FlatVel) >= default.GroundSpeed);
}

simulated function bool K2k4PlayAirAnim(name Anim, optional bool bAllowSlow)
{
	if ( !K2k4CanOverrideAirAnim(bAllowSlow) )
		return false;

	if ( (Anim == '') || !HasAnim(Anim) )
		return false;

	// Air clips are full-body, but they must not own channel 0: the engine's
	// native locomotion/fall code writes channel 0 and calls AnimEnd(0) when
	// it finishes, which restarts and freezes the clip on remote clients.
	// Play it as a global pose on channel 1 instead, so it still moves the
	// whole skeleton while channel 0 runs its own fall/idle animation.
	AnimBlendToAlpha(1, 1.0, 0.05);
	AnimBlendParams(1, 1.0, 0.0, 0.05, '', true);
	if ( !PlayAnim(Anim, 1.0, 0.1, 1) )
	{
		// Keep the channel in its normal spine-rooted state if playback fails.
		AnimBlendParams(1, 1.0, 0.0, 0.15, FireRootBone, false);
		return false;
	}

	AnimAction = Anim;
	bWaitForAnim = false;	// let stock channel 0 keep running underneath
	bK2k4AirFullBody = true;
	bK2k4Kicking = false;
	bK2k4UpperBusy = false;
	return true;
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
		else if ( bWasFalling )
			K2k4AirJumpBoost();

		return true;
	}

	return false;
}

// Each extra (mid-air) jump nudges the pawn forward by a small fraction of its
// current ground speed, along its horizontal travel (or facing if standing
// still). It is an impulse only: no timer, nothing held after the jump.
// The boost is part of the martial-arts style, so it only applies while
// Unarmed is equipped; any other weapon keeps the stock air jump.
simulated function K2k4AirJumpBoost()
{
	local vector Dir;

	if ( !K2k4IsUnarmed() )
		return;

	if ( K2k4AirJumpBoostFraction <= 0.0 )
		return;

	Dir = Velocity;
	Dir.Z = 0.0;
	if ( VSize(Dir) < 1.0 )
	{
		Dir = vector(Rotation);
		Dir.Z = 0.0;
	}
	if ( VSize(Dir) < 0.001 )
		return;

	Velocity += Normal(Dir) * (GroundSpeed * K2k4AirJumpBoostFraction);
}

// Every extra jump before landing: replace the stock double-jump clip
// with the dodge matching the body-relative movement direction.
simulated function PlayDoubleJump()
{
	// Double-jumps always use the directional dodge clip when unarmed, even
	// below running speed (a slow hop still reads as a dodge).
	if ( !K2k4PlayAirAnim(DodgeAnims[K2k4GetAirDirection()], true) )
	{
		// Gate failed (not unarmed): give the torso back to the guard overlay
		// before the stock double-jump clip plays.
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
	// Keep the replicated stance on remote proxies: the server sends the real
	// clear, and the pawn may simply not have its weapon replicated yet.
	if ( K2k4RunsCombatTimer() )
		bK2k4Combat = false;
	AnimBlendToAlpha(1, 0.0, 0.15);
}

// Logs channel 0/1 sequence and idle-anim changes, only when they change.
simulated function K2k4DebugAnim()
{
	local name S0, S1;
	local float F, R;

	GetAnimParams(0, S0, F, R);
	GetAnimParams(1, S1, F, R);
	if ( (S0 != K2k4DbgSeq0) || (S1 != K2k4DbgSeq1) || (IdleWeaponAnim != K2k4DbgIdle) )
	{
		log("K2k4DBG t="$Level.TimeSeconds$" ch0="$S0$" ch1="$S1$" idle="$IdleWeaponAnim$" action="$AnimAction$" wait="$bWaitForAnim$" idleflag="$bIsIdle$" phys="$Physics$" combat="$bK2k4Combat$" unarmed="$(K2k4IsUnarmed()));
		K2k4DbgSeq0 = S0;
		K2k4DbgSeq1 = S1;
		K2k4DbgIdle = IdleWeaponAnim;
	}
}

// Network-animation diagnostics for the slow-kick investigation. Logs the
// server and client view of the same pawn: the channels we drive ourselves and
// the stock SimAnim record that carries channel 0 to remote proxies.
simulated function K2k4LogNetAnim(string Tag)
{
	local name S0, S1;
	local float F0, R0, F1, R1;

	GetAnimParams(0, S0, F0, R0);
	GetAnimParams(1, S1, F1, R1);
	log("K2LABNET tag="$Tag
		$" t="$Level.TimeSeconds
		$" role="$Role$" remote="$RemoteRole$" owner="$bNetOwner
		$" phys="$Physics
		$" action="$AnimAction$" wait="$bWaitForAnim
		$" kick="$bK2k4Kicking$" busy="$bK2k4UpperBusy
		$" unarmedflag="$bK2k4Unarmed$" unarmed="$K2k4IsUnarmed()
		$" combat="$bK2k4Combat$" local="$IsLocallyControlled()
		$" weapon="$Weapon
		$" ch0="$S0$" f0="$F0$" r0="$R0
		$" ch1="$S1$" f1="$F1$" r1="$R1
		$" sim="$SimAnim.AnimSequence
		$" srate="$SimAnim.AnimRate
		$" sframe="$SimAnim.AnimFrame
		$" stween="$SimAnim.TweenRate
		$" sloop="$SimAnim.bAnimLoop);
}

// Arms down: rotate the upper arms on top of the relaxed base pose. The offset
// fades in while relaxed and out quickly when a combat action starts.
simulated function K2k4UpdateArmDown(float DeltaTime)
{
	local float Target, Step;

	Target = 0.0;
	if ( (Health > 0) && K2k4IsUnarmed() && (DrivenVehicle == None)
		&& !bK2k4Combat && K2k4RelaxOverlay() )
		Target = 1.0;

	if ( Target > K2k4ArmAlpha )
		Step = DeltaTime / FMax(K2k4RelaxBlend, 0.01);
	else
		Step = DeltaTime / 0.15;

	if ( Target > K2k4ArmAlpha )
		K2k4ArmAlpha = FMin(Target, K2k4ArmAlpha + Step);
	else
		K2k4ArmAlpha = FMax(Target, K2k4ArmAlpha - Step);

	if ( K2k4ArmAlpha > 0.0 )
	{
		SetBoneRotation('Bip01 L UpperArm', K2k4ArmDownL, 0, K2k4ArmAlpha);
		SetBoneRotation('Bip01 R UpperArm', K2k4ArmDownR, 0, K2k4ArmAlpha);
		SetBoneRotation('Bip01 L Forearm', K2k4ForearmL, 0, K2k4ArmAlpha);
		SetBoneRotation('Bip01 R Forearm', K2k4ForearmR, 0, K2k4ArmAlpha);
		SetBoneRotation('Bip01 L Finger0', K2k4WristL, 0, K2k4ArmAlpha);
		SetBoneRotation('Bip01 R Hand', K2k4WristR, 0, K2k4ArmAlpha);
		bK2k4ArmOn = true;
	}
	else if ( bK2k4ArmOn )
	{
		SetBoneRotation('Bip01 L UpperArm', rot(0,0,0), 0, 0.0);
		SetBoneRotation('Bip01 R UpperArm', rot(0,0,0), 0, 0.0);
		SetBoneRotation('Bip01 L Forearm', rot(0,0,0), 0, 0.0);
		SetBoneRotation('Bip01 R Forearm', rot(0,0,0), 0, 0.0);
		SetBoneRotation('Bip01 L Finger0', rot(0,0,0), 0, 0.0);
		SetBoneRotation('Bip01 R Hand', rot(0,0,0), 0, 0.0);
		bK2k4ArmOn = false;
	}
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

	if ( K2k4IsUnarmed() && (Health > 0) && (DrivenVehicle == None) )
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
	if ( (Health <= 0) || !K2k4IsUnarmed() || (DrivenVehicle != None) )
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
		else if ( K2k4RunsCombatTimer()
			&& (Level.TimeSeconds - K2k4CombatTime > K2k4CombatHold) )
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
		if ( K2k4IsUnarmed() && (Health > 0) && (DrivenVehicle == None) )
			K2k4LoopUpperIdle();
		else
			K2k4ResetUpperBody();
		return;
	}

	// Arms down until the next combat action, except over locomotion where the
	// relaxed base carries the upper body.
	if ( !bK2k4Combat && !K2k4RelaxOverlay() )
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
	if ( bK2k4DebugNetAnim )
		K2k4LogNetAnim("ANIMEND ch="$Channel$" dt="$(Level.TimeSeconds - K2k4ActionStart));

	// Fast air clip just finished on channel 1: the hips-up ownership ends
	// here. Channel 0 (native fall/idle/locomotion) is left alone.
	if ( bK2k4AirFullBody && (Channel == 1) )
	{
		K2k4RestoreAirUpperBody();
		super.AnimEnd(Channel);
		return;
	}

	// While the air clip owns the body, channel-0 native clips finish
	// underneath. Do not let AnimEnd(0) hand the torso back mid-air.
	if ( bK2k4AirFullBody && (Channel == 0) )
	{
		super.AnimEnd(Channel);
		return;
	}

	// A global-pose kick on channel 1 just finished: clear the kick state
	// and return the torso to the spine-rooted upper-body idle blend.
	if ( (Channel == 1) && bK2k4Kicking )
	{
		bK2k4Kicking = false;
		bWaitForAnim = false;
		if ( K2k4IsUnarmed() && (Health > 0) && (DrivenVehicle == None) )
			K2k4LoopUpperIdle();
		else
			K2k4ResetUpperBody();
		super.AnimEnd(Channel);
		return;
	}

	if ( (Channel == 1) && bK2k4UpperActive )
	{
		if ( K2k4IsUnarmed() && (Health > 0) && (DrivenVehicle == None) )
		{
			// Our overlay finished (or stock tried to blend it out): return to
			// the martial-arts idle loop instead of releasing the torso.
			K2k4LoopUpperIdle();
			return;
		}
		// Weapon changed / died mid-animation: release the channel.
		K2k4ResetUpperBody();
	}

	super.AnimEnd(Channel);
}


//Process unarmed animations first before processing the normal animations.
//simulated event SetAnimAction(name NewAction)
simulated function SetAnimAction(name NewAction)	//function seems to play smoother animation than event. Don't know why.
{
	local name EmoteSeq;

    K2k4ActionStart = Level.TimeSeconds;
    AnimAction = NewAction;
    bK2k4Emoting = false;	// any new action ends an emote's channel-1 exemption
    if ( bK2k4DebugNetAnim )
        K2k4LogNetAnim("ACT-START "$NewAction);

    // A new action takes the torso back from a fast air clip.
    if (bK2k4AirFullBody)
        K2k4RestoreAirUpperBody();

    // Not fighting unarmed: leave everything to stock xPawn.
    if (!K2k4IsUnarmed())
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

    // Kicks are full-body moves, but they must not own channel 0: the
    // engine's locomotion code plays idle, turn-in-place and fall clips on
    // channel 0 and calls AnimEnd(0) when they finish, which cancels a kick
    // mid-swing. Instead play the kick as a global pose on channel 1 so it
    // still animates the legs, while channel 0 keeps running underneath.
    if (K2k4IsKickAction(NewAction))
    {
        bK2k4Kicking = true;
        bK2k4UpperBusy = false;
        bK2k4UpperActive = true;
        K2k4KickTimeout = Level.TimeSeconds + 2.0;
        AnimBlendToAlpha(1, 1.0, 0.05);
        AnimBlendParams(1, 1.0, 0.0, 0.05, '', true);
        PlayAnim(NewAction, 1.0, 0.1, 1);
        bWaitForAnim = true;		//Animate the entire body for kick attacks
        if ( bK2k4DebugNetAnim )
            K2k4LogNetAnim("ACT-KICK "$NewAction);
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
        if ( bK2k4DebugNetAnim )
            K2k4LogNetAnim("ACT-UPPER "$NewAction);
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
    // Stock xPawn leaves this off. Turning it on made the server's SimAnim
    // (channel 0) fight the client's own prediction, which showed up as slow
    // jump/double-jump animations whenever a regular weapon was held and as
    // flicker on other players. Channel 1 is simulated on each machine.
    bReplicateAnimations=False
    K2k4CombatHold=2.0
    K2k4RelaxBlend=1.0
    K2k4RelaxIdleAnim="Ready"
    K2k4AirJumpBoostFraction=0.025
    K2k4ArmDownL=(Pitch=0,Yaw=0,Roll=0)
    K2k4ArmDownR=(Pitch=0,Yaw=0,Roll=0)
}
