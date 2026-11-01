/*
Kakutou 2004 Enhanced - animation timing lab
Test-only mutator for the slow-client-kick investigation.

Enable it on a listen server / instant action:
    ?mutator=Kakutou2k4-Enhanced.MutKakutouAnimLab

In the console:
    mutate k2lab help
    mutate k2lab kick fast
    mutate k2lab kick strong
    mutate k2lab play AttackFast3 1.0 0
    mutate k2lab sweep arms
    mutate k2lab sweep legs
    mutate k2lab sweep all
    mutate k2lab netlog on
    mutate k2lab netlog off
    mutate k2lab repanim off
    mutate k2lab repanim on
    mutate k2lab dump

All output goes to UT2004.log with the K2LAB / K2LABNET prefixes.
*/

class MutKakutouAnimLab extends Mutator;

var array<name> SweepAnims;
var int SweepIndex;
var bool bSweeping;
var K2k4xPawn SweepPawn;
var string SweepName;

// Persisted animation-debug settings. Re-applied to every pawn on a timer so
// they survive respawns (new pawns default to debug off).
var bool bK2LabNetLog;
var bool bK2LabReplAnim;

function Mutate(string MutateString, PlayerController Sender)
{
	local array<string> P;
	local K2k4xPawn K;
	local name Seq;
	local float Rate;
	local int Channel, i;
	local bool bOn;
	local string StateStr;
	local Controller C;
	local Pawn PawnToKill;
	local int NobotsCount;

	Split(MutateString, " ", P);

	if ( (P.Length < 2) || (Caps(P[0]) != "K2LAB") )
	{
		Super.Mutate(MutateString, Sender);
		return;
	}

	if ( Sender == None )
		return;

	K = K2k4xPawn(Sender.Pawn);

	if ( P[1] ~= "help" )
	{
		Sender.ClientMessage("k2lab kick <fast|strong> | play <seq> [rate] [channel] | sweep <arms|legs|all> | netlog <on|off> | repanim <on|off> | nobots | dump");
		return;
	}

	if ( P[1] ~= "kick" )
	{
		if ( K == None )
		{
			Sender.ClientMessage("k2lab: pawn is not K2k4xPawn");
			return;
		}
		if ( (P.Length >= 3) && (P[2] ~= "strong") )
			K.SetAnimAction('AttackStrong3');
		else
			K.SetAnimAction('AttackFast3');
		K.K2k4LogNetAnim("LAB-KICK");
		return;
	}

	if ( P[1] ~= "nobots" )
	{
		NobotsCount = 0;
		foreach AllActors(class'Controller', C)
		{
			if ( (Bot(C) != None) && !C.bIsPlayer )
			{
				PawnToKill = C.Pawn;
				if ( PawnToKill != None )
					PawnToKill.Destroy();
				C.Destroy();
				NobotsCount++;
			}
		}
		// Ask the game to stop spawning more bots this match.
		if ( Level.Game != None )
			Level.Game.NumBots = 0;

		Sender.ClientMessage("k2lab: removed " $ NobotsCount $ " bots");
		log("K2LAB nobots removed " $ NobotsCount);
		return;
	}

	if ( P[1] ~= "play" )
	{
		if ( (K == None) || (P.Length < 3) )
		{
			Sender.ClientMessage("k2lab play <sequence> [rate] [channel]");
			return;
		}
		Seq = SeqFromString(P[2]);
		if ( Seq == '' )
		{
			Sender.ClientMessage("k2lab: unknown sequence " $ P[2]);
			return;
		}
		Rate = 1.0;
		Channel = 0;
		if ( P.Length >= 4 )
			Rate = float(P[3]);
		if ( P.Length >= 5 )
			Channel = int(P[4]);

		if ( !K.HasAnim(Seq) )
		{
			Sender.ClientMessage("k2lab: no such sequence " $ P[2]);
			return;
		}

		K.PlayAnim(Seq, Rate, 0.1, Channel);
		if ( Channel == 0 )
		{
			K.AnimAction = Seq;
			K.bWaitForAnim = true;
		}
		K.K2k4LogNetAnim("LAB-PLAY "$Seq$" ch="$Channel$" rate="$Rate);
		return;
	}

	if ( P[1] ~= "sweep" )
	{
		if ( K == None )
		{
			Sender.ClientMessage("k2lab: pawn is not K2k4xPawn");
			return;
		}
		StartSweep(K, P, Sender);
		return;
	}

	if ( P[1] ~= "netlog" )
	{
		bOn = true;
		if ( (P.Length >= 3) && ((P[2] ~= "off") || (P[2] ~= "0")) )
			bOn = false;
		bK2LabNetLog = bOn;
		foreach AllActors(class'K2k4xPawn', K)
			K.bK2k4DebugNetAnim = bOn;
		UpdatePersistTimer();
		StateStr = "off";
		if ( bOn )
			StateStr = "on";
		Sender.ClientMessage("k2lab: netlog " $ StateStr);
		log("K2LAB netlog "$StateStr);
		return;
	}

	if ( P[1] ~= "repanim" )
	{
		bOn = true;
		if ( (P.Length >= 3) && ((P[2] ~= "off") || (P[2] ~= "0")) )
			bOn = false;
		bK2LabReplAnim = bOn;
		foreach AllActors(class'K2k4xPawn', K)
			K.bReplicateAnimations = bOn;
		UpdatePersistTimer();
		StateStr = "off";
		if ( bOn )
			StateStr = "on";
		Sender.ClientMessage("k2lab: bReplicateAnimations " $ StateStr);
		log("K2LAB bReplicateAnimations "$StateStr);
		return;
	}

	if ( P[1] ~= "dump" )
	{
		if ( K == None )
		{
			Sender.ClientMessage("k2lab: pawn is not K2k4xPawn");
			return;
		}
		K.K2k4LogNetAnim("LAB-DUMP");
		for ( i = 0; i < SweepAnims.Length; i++ )
			log("K2LAB has "$SweepAnims[i]$" = "$K.HasAnim(SweepAnims[i]));
		return;
	}

	Sender.ClientMessage("k2lab: unknown command");
}

// UnrealScript cannot cast a string to a name at runtime, so the lab only
// accepts the sequences shipped in the Kakutou animation packages.
function name SeqFromString(string S)
{
	if ( S ~= "Ready" ) return 'Ready';
	if ( S ~= "Guard" ) return 'Guard';
	if ( S ~= "FlagReady" ) return 'FlagReady';
	if ( S ~= "FlagGuard" ) return 'FlagGuard';
	if ( S ~= "AttackFast1" ) return 'AttackFast1';
	if ( S ~= "AttackFast2" ) return 'AttackFast2';
	if ( S ~= "AttackFast3" ) return 'AttackFast3';
	if ( S ~= "AttackFast4" ) return 'AttackFast4';
	if ( S ~= "AttackFast1Rush" ) return 'AttackFast1Rush';
	if ( S ~= "AttackFast2Rush" ) return 'AttackFast2Rush';
	if ( S ~= "AttackFast3Rush" ) return 'AttackFast3Rush';
	if ( S ~= "AttackFast4Rush" ) return 'AttackFast4Rush';
	if ( S ~= "AttackStrong1" ) return 'AttackStrong1';
	if ( S ~= "AttackStrong2" ) return 'AttackStrong2';
	if ( S ~= "AttackStrong3" ) return 'AttackStrong3';
	if ( S ~= "AttackStrong4" ) return 'AttackStrong4';
	if ( S ~= "AttackStrong1Rush" ) return 'AttackStrong1Rush';
	if ( S ~= "AttackStrong2Rush" ) return 'AttackStrong2Rush';
	if ( S ~= "AttackStrong3Rush" ) return 'AttackStrong3Rush';
	if ( S ~= "AttackStrong4Rush" ) return 'AttackStrong4Rush';
	if ( S ~= "FlagFast1" ) return 'FlagFast1';
	if ( S ~= "FlagFast2" ) return 'FlagFast2';
	if ( S ~= "FlagFast3" ) return 'FlagFast3';
	if ( S ~= "FlagFast4" ) return 'FlagFast4';
	if ( S ~= "FlagFast1Rush" ) return 'FlagFast1Rush';
	if ( S ~= "FlagFast2Rush" ) return 'FlagFast2Rush';
	if ( S ~= "FlagFast3Rush" ) return 'FlagFast3Rush';
	if ( S ~= "FlagFast4Rush" ) return 'FlagFast4Rush';
	if ( S ~= "FlagStrong1" ) return 'FlagStrong1';
	if ( S ~= "FlagStrong2" ) return 'FlagStrong2';
	if ( S ~= "FlagStrong3" ) return 'FlagStrong3';
	if ( S ~= "FlagStrong4" ) return 'FlagStrong4';
	if ( S ~= "FlagStrong1Rush" ) return 'FlagStrong1Rush';
	if ( S ~= "FlagStrong2Rush" ) return 'FlagStrong2Rush';
	if ( S ~= "FlagStrong3Rush" ) return 'FlagStrong3Rush';
	if ( S ~= "FlagStrong4Rush" ) return 'FlagStrong4Rush';
	if ( S ~= "KRunF" ) return 'KRunF';
	if ( S ~= "KRunB" ) return 'KRunB';
	if ( S ~= "KRunL" ) return 'KRunL';
	if ( S ~= "KRunR" ) return 'KRunR';
	if ( S ~= "KJumpTakeoff" ) return 'KJumpTakeoff';
	if ( S ~= "KJumpMid" ) return 'KJumpMid';
	if ( S ~= "KJumpLand" ) return 'KJumpLand';
	return '';
}

function StartSweep(K2k4xPawn K, array<string> P, PlayerController Sender)
{
	local string Kind;

	SweepAnims.Length = 0;
	Kind = "all";
	if ( P.Length >= 3 )
		Kind = Caps(P[2]);

	if ( (Kind == "ALL") || (Kind == "ARMS") )
	{
		AddSweepAnim('Ready');
		AddSweepAnim('Guard');
		AddSweepAnim('FlagReady');
		AddSweepAnim('FlagGuard');
		AddSweepAnim('AttackFast1');
		AddSweepAnim('AttackFast2');
		AddSweepAnim('AttackFast1Rush');
		AddSweepAnim('AttackFast2Rush');
		AddSweepAnim('AttackStrong1');
		AddSweepAnim('AttackStrong2');
		AddSweepAnim('AttackStrong1Rush');
		AddSweepAnim('AttackStrong2Rush');
		AddSweepAnim('FlagFast1');
		AddSweepAnim('FlagFast2');
		AddSweepAnim('FlagStrong1');
		AddSweepAnim('FlagStrong2');
	}

	if ( (Kind == "ALL") || (Kind == "LEGS") )
	{
		AddSweepAnim('AttackFast3');
		AddSweepAnim('AttackFast4');
		AddSweepAnim('AttackFast3Rush');
		AddSweepAnim('AttackFast4Rush');
		AddSweepAnim('AttackStrong3');
		AddSweepAnim('AttackStrong4');
		AddSweepAnim('AttackStrong3Rush');
		AddSweepAnim('AttackStrong4Rush');
	}

	if ( SweepAnims.Length == 0 )
	{
		Sender.ClientMessage("k2lab sweep <arms|legs|all>");
		return;
	}

	SweepPawn = K;
	SweepIndex = 0;
	SweepName = Kind;
	bSweeping = true;
	K.bK2k4Combat = true;
	K.bK2k4UpperBusy = false;
	K.bWaitForAnim = false;
	log("K2LAB sweep start kind="$Kind$" count="$SweepAnims.Length);
	SetTimer(1.5, true);
	SweepStep();
}

function AddSweepAnim(name A)
{
	SweepAnims.Length = SweepAnims.Length + 1;
	SweepAnims[SweepAnims.Length - 1] = A;
}

function SweepStep()
{
	if ( !bSweeping || (SweepPawn == None) || (SweepIndex >= SweepAnims.Length) )
	{
		StopSweep();
		return;
	}

	log("K2LAB sweep "$SweepName$" ["$SweepIndex$"/"$SweepAnims.Length$"] "$SweepAnims[SweepIndex]);
	SweepPawn.SetAnimAction(SweepAnims[SweepIndex]);
	SweepIndex++;
}

function Timer()
{
	if ( bSweeping )
	{
		SweepStep();
		return;
	}
	// Re-apply persisted netlog/replanim settings so they survive respawns.
	ApplyPersistedAnimSettings();
}

function StopSweep()
{
	bSweeping = false;
	UpdatePersistTimer();
	log("K2LAB sweep done "$SweepName);
	SweepPawn = None;
}

// Apply the persisted netlog/replanim flags to every pawn, catching any that
// were spawned after the command was issued (e.g. after a respawn).
function ApplyPersistedAnimSettings()
{
	local K2k4xPawn K;

	foreach AllActors(class'K2k4xPawn', K)
	{
		if ( K.bK2k4DebugNetAnim != bK2LabNetLog )
			K.bK2k4DebugNetAnim = bK2LabNetLog;
		if ( K.bReplicateAnimations != bK2LabReplAnim )
			K.bReplicateAnimations = bK2LabReplAnim;
	}
}

// Start or stop the persistence timer based on whether any persisted setting
// is active. The sweep uses its own 1.5 s timer; this is only for idle
// re-application between sweeps.
function UpdatePersistTimer()
{
	if ( bK2LabNetLog || bK2LabReplAnim )
		SetTimer(1.0, true);
	else if ( !bSweeping )
		SetTimer(0.0, false);
}

defaultproperties
{
	FriendlyName="Kakutou Animation Lab (test only)"
	Description="Forces Unarmed animations and logs channel/SimAnim timing. Test builds only."
}
