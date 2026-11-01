# Unarmed animation timing on clients

Status: kick fix confirmed on a remote client. The same class of bug is now
confirmed to affect **jump, dodge and fall** clips, because those also run on
channel 0. Air clips still need the same treatment.
This document records the symptom, root cause, the code changes made, the
remaining verification steps, and permanent context for future maintenance.

## Key discovery (2026-11-01)

**This was never a "kick bug". It is a channel-0 ownership bug that affects
every full-body clip the mod plays on channel 0.**

The evidence:

1. After the kick fix moved kicks to channel 1, the remote client reported
   **zero kick/animation errors in two minutes of spamming attacks** — the
   exact same client, session and map that used to break kicks.
2. In the same session, the client immediately reported that the broken
   behaviour had **"transferred" to jumping, dodging and falling**.
3. Those paths are unchanged by the kick fix, and they all call
   `K2k4PlayAirAnim()` → `PlayAnim(Anim, 1.0, 0.1, 0)` — **channel 0**.

So the kick fix did not introduce the air bug; it removed the loudest symptom
and exposed the general one. Channel 0 is driven by native/stock machinery
(idle restarts, turn-in-place, fall/land, and `SimAnim` replication to
proxies). Any mod clip placed on channel 0 is on ground the engine considers
its own, and on a remote client the engine wins.

Consequence for the fix: the correct pattern is not "special-case kicks". It
is **"full-body mod clips own channel 1 as a global pose, channel 0 keeps
running underneath"**. Kicks already follow this pattern; jump/dodge/fall
need to follow it too.

## Symptom

As a **remote client** (not the listen/standalone host), the Unarmed attacks
that move the legs play very slowly / end prematurely and freeze the character.
Before the kick reads as a combat move the pawn is already back in its regular
pose. Punches and other arm-only actions appear normal.

In the current code the leg attacks are exactly the "kick" branch:

- Primary: `AttackFast3`, `AttackFast4` (and their `*Rush` variants).
- Secondary: `AttackStrong3`, `AttackStrong4` (and their `*Rush` variants).

`UnarmedFire.SetCurrentAttack()` and `UnarmedAltFire.SetCurrentAttack()` set
`bKicking = true` **only** for those names. Everything else is an arm move.

## Root cause

Two compounding problems on **channel 0**:

1. **Kicks played on channel 0.** `SetAnimAction()` played kicks with
   `PlayAnim(NewAction, 1.0, 0.1, 0)` and set `bWaitForAnim = true`. Channel 0
   is the channel the engine's own locomotion machinery uses: standing idle,
   turn-in-place clips (`TurnL`/`TurnR`), fall/land clips. Stock `Pawn`
   `AnimEnd(0)` calls `PlayWaiting()`, which replays `IdleRestAnim` (or
   `IdleWeaponAnim`) every time a channel-0 clip finishes. Native channel-0
   turn clips can also override a kick even with `bWaitForAnim=true`. The
   result: a kick started on channel 0 gets interrupted within ~0.13 s by the
   next idle/turn restart, leaving the legs frozen on the short `Ready` pose.
   Arm attacks play on channel 1, which native locomotion does not touch, so
   they were unaffected.

2. **`IdleRestAnim` set to `Ready`.** `Ready` is a **short torso pose** (1
   frame in the PSA). Using it as `IdleRestAnim` made the engine repeatedly
   restart a static, near-instant channel-0 idle (~every 0.25 s, `ch0=Ready
   f0=-1.00` in the logs), which cuts any channel-0 clip short and leaves the
   legs stuck on a single frame ("freeze").

Diagnostic evidence (standalone control log `/tmp/K2LAB-standalone.txt`):
- `ch0=Ready f0=-1.00` repeated, followed by `ANIMEND ch=0` roughly every 0.25 s.
- Sweep: `AttackFast3` interrupted after 0.13 s by `TurnL`; `AttackStrong3`
  similarly cut short; arm attacks (`AttackFast1/2`, `AttackStrong1/2`) on
  channel 1 completed normally.
- `FlagFast3/4` are upper-body attacks, not kicks; `FlagStrong3/4` do not exist
  in the PSA packages.

**Generalisation:** problem (1) is not specific to kicks. It applies to every
mod clip played on channel 0 with full-body intent. After the kick fix,
jump/dodge/fall (also channel 0) showed the same client-only failure. See
"Key discovery" above.

## Fix (committed to code, build succeeded)

### `Classes/K2k4xPawn.uc`

1. **Kicks moved to channel 1 as a global pose.**
   - `AnimBlendToAlpha(1, 1.0, 0.05)` — bring channel 1 back to full strength.
   - `AnimBlendParams(1, 1.0, 0.0, 0.05, '', true)` — `bGlobalPose=true` so the
     kick clip animates the whole skeleton including the legs/hips, not just the
     torso.
   - `PlayAnim(NewAction, 1.0, 0.1, 1)` — play on **channel 1** instead of 0.
   - `bWaitForAnim = true` retained so the action holds for the full clip.
   - `bK2k4Kicking` now means "a full-body kick owns channel 1" (comment updated).

2. **`AnimEnd(1)` clears kick state.**
   - Added a `Channel == 1 && bK2k4Kicking` branch (placed before the general
     `bK2k4UpperActive` branch) that clears `bK2k4Kicking` and
     `bWaitForAnim`, then returns the torso to the spine-rooted upper-body idle
     blend via `K2k4LoopUpperIdle()` (or `K2k4ResetUpperBody()` if no weapon).
   - `K2k4ResetUpperBody()` already clears `bK2k4Kicking`, so weapon changes,
     death, and mid-action interruptions remain safe.

3. **`IdleRestAnim` restored to stock.**
   - `IdleRestAnim` is no longer overwritten with `K2k4RelaxIdle()`/`Ready`. It
     is set to `default.IdleRestAnim` (`Idle_Rest`, the stock looping rest
     idle), so channel 0 keeps running underneath kicks and the short `Ready`
     pose no longer restarts channel-0 idle every ~0.25 s.
   - Channel 1 keeps the relaxed upper-body overlay (`K2k4RelaxIdle()` on
     `IdleWeaponAnim`), so the relaxed arms-over-locomotion behaviour is
     preserved.

### `Classes/MutKakutouAnimLab.uc`

1. **`nobots` command** — destroys all bot controllers/pawns and sets
   `Level.Game.NumBots = 0` so bot interference is gone during kick tests.
2. **Persistent netlog/replanim across respawns** — `bK2LabNetLog` and
   `bK2LabReplAnim` store the requested state; a 1 s timer re-applies them to
   every pawn (including newly-respawned ones).
3. **Corrected LEGS sweep list** — removed `FlagFast3/4` (upper-body, not legs)
   and the non-existent `FlagStrong3/4` from the legs sweep; only real kicks
   remain (`AttackFast3/4`, `AttackStrong3/4` and Rush variants).

## Verification plan (not yet complete)

Run a bot-free dedicated-server/client test:
1. `mutate k2lab nobots`
2. `mutate k2lab netlog on`
3. `mutate k2lab kick fast` — expect `AttackFast3` to complete its full ~0.33 s
   on channel 1 (`ch1=AttackFast3 ... ANIMEND ch=1 dt≈0.33`), channel 0 staying
   on a live locomotion clip, and `bK2k4Kicking` cleared in `AnimEnd(1)`.
4. `mutate k2lab kick strong` — same for `AttackStrong3` (~0.67 s).
5. Confirm legs return to a live `Idle_Rest` (`ch0=Idle_Rest f0<1.0`) rather
   than frozen `Ready` (`ch0=Ready f0=-1.00`).

Update this document with the confirmed test result, then commit only after
verification.

## Confirmed results (host/standalone)

Tested on the listen/standalone host with both mutators loaded
(`MutKakutou2k4` + `MutKakutouAnimLab`):

- `mutate k2lab kick fast` → `AttackFast3` plays on **channel 1**
  (`ch1=AttackFast3 f1=-0.10 r1=3.00`) and completes with
  `ANIMEND ch=1 dt=0.41` (full duration, ~0.33s expected). Channel 0 stays on
  `Idle_Rest` (`f0=0.28`), never frozen on `Ready`. No `TurnL` interruption.
- `mutate k2lab kick strong` → `AttackStrong3` plays on **channel 1**
  (`ch1=AttackStrong3 f1=-0.05 r1=1.50`) and completes with
  `ANIMEND ch=1 dt=0.74` (full duration, ~0.67s expected). Channel 0 stays on
  `Idle_Rest` (`f0=0.18`).

Legs return to a live `Idle_Rest` after each kick, not a frozen `Ready` pose.
`bK2k4Kicking` is properly cleared in `AnimEnd(1)`.

### Remote client confirmation

A remote client connected to a `?listen` server (both mutators loaded) and
attacked continuously for two minutes:

> "NOT A SINGLE ANIMATION ERROR IN 2 MINUTES OF SPAMMING AROUND!"

That is the decisive confirmation: the original bug only reproduced on a
remote client, and after moving kicks to channel 1 it no longer reproduces.

### Air clips (open)

In the same client session, jump, dodge and fall animations then showed the
old symptom. These are still played on channel 0:

- `K2k4PlayAirAnim()` → `PlayAnim(Anim, 1.0, 0.1, 0)` (first jump / dodge).
- Stock falling/landing clips are native channel-0 animations.

Client-side netlog has since been captured; see the next section for the
frame-level evidence.

## Client netlog evidence (2026-11-01, listen server + client)

Client-side capture now works: `bK2k4DebugNetAnim=True` was added to
`System/User.ini` under `[Kakutou2k4-Enhanced.K2k4xPawn]`, so the client logs
from startup without needing an in-game command.

Roles in the client log confirm we are looking at the right pawn:

- `role=3 remote=4 owner=True` — the client's **own** pawn
  (`ROLE_AutonomousProxy`, server authoritative).
- `role=2 remote=4 owner=False` — the host's pawn as seen by the client.

### Own pawn: server advances, client stalls

The same dodge, compared side by side:

Server (`UT2004.log`, client pawn, `role=4 remote=3`):

```
ch0=DodgeF f0=0.03 r0=2.31
ch0=DodgeF f0=0.30 r0=2.31
ch0=DodgeF f0=0.60 r0=2.31
ch0=DodgeF f0=0.91 r0=2.31
ANIMEND ch=0 dt=2.06 ... f0=0.92 r0=0.00
```

Client (`K2LABclient.log`, own pawn, `role=3 owner=True`):

```
t=6.10  action=DodgeF  ch0=DodgeF f0=-0.07 r0=2.31  sim=RunF
t=6.19  action=DodgeF  ch0=DodgeF f0=-0.07 r0=2.31  sim=DodgeF (server frame 118)
t=6.45  action=DodgeF  ch0=DodgeF f0=-0.05 r0=2.31  sim=DodgeF (server frame 118)
t=6.72  action=None    ch0=JumpF_Mid ...            sim=DodgeF
```

The client's clip sits at the start (`f0` stuck near 0) and is then replaced
by the native fall pose, while the server's copy runs the full clip. The same
pattern repeats for `DoubleJumpF`. The client is being restarted/overwritten,
not merely ending early.

### Host pawn on the client: two drivers alternate channel 0

For the remote host pawn, channel 0 flips every other sample between the run
loop and the air clip:

```
t=72.55  ch0=JumpL_Takeoff  sim=RunF
t=72.72  ch0=RunF           sim=HitR
t=72.81  ch0=JumpL_Mid      sim=RunF
t=72.98  ch0=RunF           sim=HitR
t=73.08  ch0=JumpL_Mid      sim=RunF
t=73.24  ch0=RunF           sim=HitR
```

Both clips keep their own frame progress, i.e. two writers are playing
different animations on channel 0 in turns. This is the jumping/falling
"flicker/freeze" seen from a client.

### `bReplicateAnimations` A/B (inconclusive / rejected as sole cause)

`mutate k2lab repanim off` was run on the live client session. It stops
`SimAnim` being sent, but the client reported **no immediate visible change**.
The client netlog still shows the own-pawn clip restart pattern afterwards.
Conclusion: `bReplicateAnimations=True` is a real contributing writer (and the
likely cause of the remote-host flicker), but it is **not the sole cause** of
the own-client air failure. Do not rely on that flag alone.

### Conclusion

Channel 0 is contested on the client by more than one driver — native
locomotion/fall simulation, the engine's `AnimEnd(0)` restart path, and
(redundantly) `SimAnim` replication. Our air clips must not be one of the
writers. The proven fix shape is the kick fix: **play the full-body air clip
on channel 1 as a global pose, leave channel 0 to the engine underneath, and
end ownership in `AnimEnd(1)` / on landing.**

Next step: apply that to `K2k4PlayAirAnim()` and verify on a remote client.

## Asset facts (PSA metadata)

The PSA files were parsed directly. All attack sequences in the Unarmed sets
have the same shape:

| Sequence examples | Raw frames | PSA `AnimRate` | PSA `TrackTime` |
|---|---:|---:|---:|
| `AttackFast1/2/3/4`, `FlagFast1..4` | 10 | 30.0 | 10.0 |
| `AttackFast*Rush`, `FlagFast*Rush` | 5 | 30.0 | 5.0 |
| `AttackStrong1/2/3/4`, `FlagStrong1..4` | 20 | 30.0 | 20.0 |
| `AttackStrong*Rush`, `FlagStrong*Rush` | 10 | 30.0 | 10.0 |
| `Ready`, `FlagReady` | 1 | 30.0 | 1.0 |
| `Guard`, `FlagGuard` | 3 | 30.0 | 3.0 |

Observations:

- Arm and leg attack sequences are **identical in rate/frame metadata**. There
  is no obvious PSA-level reason for only kicks to be broken.
- `Ready` is a 1-frame pose — confirming it is unsuitable as a looping
  `IdleRestAnim`.
- The differentiator is the **playback path** (channel 0 vs channel 1), not the
  animation data.

## Animation replication (secondary context)

`Classes/K2k4xPawn.uc` default properties contain:

```unrealscript
bReplicateAnimations=True
```

In UT2004 (`Engine/Actor.uc`), `SimAnim`/`AnimRep` carries **channel 0** animation
state to remote proxies and has no channel-1 state. `AnimRate`/`TweenRate` are
bytes (quantised to 4.0 / 4 s). Stock `xPawn` does not set this flag; this fork
inherited `bReplicateAnimations=True` from the initial import
(`4e6f164 Initial import of Kakutou 2004 Enhanced`).

The channel-0 conflict explains the arm/leg asymmetry without relying on
`bReplicateAnimations`, but the flag remains a secondary factor for remote
clients and is still A/B-testable via `mutate k2lab repanim on/off`.

## Diagnostic build (implemented)

Branch: `anim-replication-diagnostics`.

Test-only harness:

- `Classes/MutKakutouAnimLab.uc` — enable with
  `?mutator=Kakutou2k4-Enhanced.MutKakutouAnimLab`.
- `Classes/K2k4xPawn.uc` — adds `bK2k4DebugNetAnim` and `K2k4LogNetAnim()`,
  called every 0.25 s and at action start/end.
- `System/Kakutou2k4-Enhanced.u` / `.ucl` — rebuilt with the harness; the
  mutator is exported in the cache.

Console commands (via `mutate k2lab ...`):

| Command | Purpose |
|---|---|
| `mutate k2lab kick fast` | Force `AttackFast3` through the normal kick path. |
| `mutate k2lab kick strong` | Force `AttackStrong3`. |
| `mutate k2lab play <seq> [rate] [channel]` | Play one sequence directly. |
| `mutate k2lab sweep arms` | Ready/guard and all arm attacks, fixed order. |
| `mutate k2lab sweep legs` | All kick attacks, fixed order. |
| `mutate k2lab sweep all` | Arms first, then legs. |
| `mutate k2lab netlog on/off` | Toggle the `K2LABNET` per-pawn log. |
| `mutate k2lab repanim on/off` | A/B switch for `bReplicateAnimations`. |
| `mutate k2lab nobots` | Remove all bots; set `NumBots = 0`. |
| `mutate k2lab dump` | Log channel/`SimAnim` state and `HasAnim`. |

`K2LABNET` lines contain timestamp, `Role`/`RemoteRole`, `bNetOwner`, physics,
`AnimAction`, `bWaitForAnim`, kick/busy flags, both channels (sequence/frame/
rate), and the raw `SimAnim` fields. All go to `UT2004.log` on the machine that
runs the code, so server and client logs must be kept side by side.

## Relevant files

- `Classes/K2k4xPawn.uc` — kick path, channel layering, `AnimEnd`, idle/rest
  assignment (`IdleRestAnim`).
- `Classes/MutKakutouAnimLab.uc` — test mutator; `nobots`, persistent netlog,
  corrected sweep lists.
- `docs/ANIMATION_TIMING.md` — this document.
- `/tmp/K2LAB-standalone.txt` — standalone control log showing static `Ready`
  idle and `TurnL` interruption (pre-fix baseline).
- `/tmp/K2LAB-server.txt` — server log from the pre-fix diagnostic run.
- `/tmp/K2LAB-client-game.txt` — client log; local pawn logging stops at respawn.
- `System/Kakutou2k4-Enhanced.u` / `.ucl` — rebuilt package containing the fix.
- `Models/K2k4Anims.psa`, `Models/K2k4Anims1.psa` — Unarmed attack sequences.
- `Classes/UnarmedFire.uc`, `Classes/UnarmedAltFire.uc` — attack selection;
  `AttackFast3/4` and `AttackStrong3/4` are kicks.
- `/home/jdmr/Proyectos/ut2k4tp/reference/Engine/Actor.uc` — `AnimRep`/`SimAnim`,
  `AnimBlendParams`, `AnimBlendToAlpha`, `GetAnimParams`, `PlayAnim`/`LoopAnim`.
- `/home/jdmr/Proyectos/ut2k4tp/reference/XGame/xPawn.uc` — stock
  `SetAnimAction`, `AnimEnd`, idle behaviour.

## Environment

- Engine reference sources: `/home/jdmr/Proyectos/ut2k4tp/reference/`
- Local UT2004 install: `/home/jdmr/Juegos/UT2004`; repo is symlinked as
  `UT2004/Kakutou2k4-Enhanced`. UCC is run through Wine.
- Repo: `/home/jdmr/Proyectos/kakutou2k4-enhanced`; branch
  `anim-replication-diagnostics`.
- Build command: `cd /home/jdmr/Juegos/UT2004/System && rm -f
  Kakutou2k4-Enhanced.u Kakutou2k4-Enhanced.ucl && WINEDEBUG=-all DISPLAY= wine
  UCC.exe make` → copy `.u`/`.ucl` back to repo `System/`.

## Decision log

- 2026-10-30: Started investigation. Identified channel-0 `SimAnim` as leading
  hypothesis; built diagnostic harness.
- 2026-10-31: Diagnostic run confirmed channel-0 idle restarts (`Ready` every
  ~0.25 s) and `TurnL` interrupting kicks after 0.13 s; arm attacks on channel 1
  complete normally.
- 2026-11-01: Implemented the fix — kicks on channel 1 with `bGlobalPose`,
  `AnimEnd(1)` clears kick state, `IdleRestAnim` restored to
  `default.IdleRestAnim`. Build succeeded (0 errors, 1 pre-existing warning).
  **Host test confirmed:** `AttackFast3` completes `ANIMEND ch=1 dt=0.41`,
  `AttackStrong3` completes `ANIMEND ch=1 dt=0.74`, channel 0 stays on live
  `Idle_Rest` throughout, no frozen `Ready`.
- 2026-11-01: **Remote-client test confirmed the kick fix** — listen server +
  remote client, two minutes of continuous attacking, no animation errors.
- 2026-11-01: **Discovery recorded:** the bug is channel-0 ownership, not
  kick-specific. Jump/dodge/fall clips are on channel 0 and show the same
  client-only symptom. Next: move air clips to channel 1 as a global pose
  (mirroring kicks) and verify on a remote client before committing.
- 2026-11-01: Client-side `K2LABNET` capture enabled via `User.ini`
  (`bK2k4DebugNetAnim=True`). Confirmed frame-level split: the server's copy of
  `DodgeF` advances `0.03 → 0.91 → 0.92` while the client's own copy stalls at
  `f0 ≈ 0` and is replaced by the native fall pose. Remote host pawn visibly
  alternates channel 0 between `RunF` and `JumpL_Mid` — two writers.
- 2026-11-01: `mutate k2lab repanim off` produced **no immediate visible
  change** on the client. `bReplicateAnimations=True` is a contributing writer
  (remote-host flicker) but not the sole cause of the own-client air failure.
  Do not rely on that flag alone.
- 2026-11-01: Decision — fix air clips the same way as kicks: play
  `K2k4PlayAirAnim()` on channel 1 with `bGlobalPose`, leave channel 0 to the
  engine, end ownership in `AnimEnd(1)` or on landing. Verify on a remote
  client before committing.
