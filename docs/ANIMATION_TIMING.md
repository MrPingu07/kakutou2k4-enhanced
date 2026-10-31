# Unarmed animation timing on clients

Status: open investigation. This document records the symptom, the code and
asset facts gathered so far, the working hypothesis, and the recommended test
plan. It is deliberately written before changing gameplay code so the next
build can be judged against a fixed baseline.

## Symptom

As a **remote client** (not the listen/standalone host), the Unarmed attacks
that move the legs play very slowly. Before the kick reads as a combat move the
pawn is already back in its regular pose. Punches and other arm-only actions
appear normal.

In the current code the leg attacks are exactly the "kick" branch:

- Primary: `AttackFast3`, `AttackFast4` (and their `*Rush` variants).
- Secondary: `AttackStrong3`, `AttackStrong4` (and their `*Rush` variants).

`UnarmedFire.SetCurrentAttack()` and `UnarmedAltFire.SetCurrentAttack()` set
`bKicking = true` **only** for those names. Everything else is an arm move.

This matters because the fork uses two different animation paths, and only one
of them is affected by the stock network animation replication path.

## Relevant code paths

### Attack selection and playback

- `Classes/UnarmedFire.uc`
  - `SetCurrentAttack()` chooses `AttackFast1..4` / `FlagFast1..4` randomly and
    sets `bKicking` for 3 and 4.
  - `PlayFiring()` / `ServerPlayFiring()` call
    `K2k4xPawn(Instigator).SetAnimAction(ActionAttack)`.
- `Classes/UnarmedAltFire.uc`
  - Same selection for `AttackStrong1..4`; 3 and 4 are kicks.
- `Classes/K2k4xPawn.uc`
  - `SetAnimAction()`:
    - Kicks: `PlayAnim(NewAction, 1.0, 0.1, 0)` on **channel 0**, sets
      `bWaitForAnim = true`, mutes the channel-1 overlay.
    - Punches/guard/ready: `PlayAnim(NewAction, 1.0, 0.1, 1)` on **channel 1**,
      rooted at `FireRootBone` (`Bip01 Spine`), so the legs keep locomotion.

So the failing category (legs) and the working category (arms) are also a
channel split: legs = full-body kick on channel 0, arms = torso overlay on
channel 1.

### Animation replication

`Classes/K2k4xPawn.uc` default properties contain:

```unrealscript
bReplicateAnimations=True
```

In UT2004 (`Engine/Actor.uc`):

```unrealscript
// Animation replication (can be used to replicate channel 0 anims for dumb proxies)
struct AnimRep
{
    var name AnimSequence;
    var bool bAnimLoop;
    var byte AnimRate;      // note that with compression, max replicated animrate is 4.0
    var byte AnimFrame;
    var byte TweenRate;     // note that with compression, max replicated tweentime is 4 seconds
};
var AnimRep SimAnim;        // only replicated if bReplicateAnimations is true
```

Key consequences:

- `SimAnim`/`AnimRep` carries **channel 0** animation state to remote proxies.
  It has no channel-1 state.
- `AnimRate` and `TweenRate` are **bytes**, i.e. quantised. The comments state
  the compressed ranges are 4.0 and 4 seconds. Any rate outside that range, or
  a mismatch between the rate the server plays and what the client reconstructs,
  changes playback speed on the client.
- Stock `xPawn` does not set `bReplicateAnimations`; this fork inherited
  `bReplicateAnimations=True` from the initial import
  (`4e6f164 Initial import of Kakutou 2004 Enhanced`). No later commit has
  changed the flag or the network animation path.
- The original readme already warns that online play is "very slow moving"
  (`Help/Kakutou2k4_Readme.txt`, line 16), though it attributes it to
  replication generally.

Working hypothesis: the client is not seeing the same effective playback rate
as the server for channel-0 one-shots. The server's `bWaitForAnim`/recovery
timing ends the action on its own schedule and then replicates idle/other
state, while the client's slow kick is still near its first frames. That
matches "the move finishes before the kick can be appreciated".

This does not yet prove whether the byte quantisation itself is wrong or
whether the client is also independently replaying the action through
`AnimAction`/`SetAnimAction`, producing a double-play or a rate reset.

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
  is no obvious PSA-level reason for only kicks to be slow.
- The raw frame count divided by 30 fps gives 0.33 s for fast attacks and
  0.67 s for strong attacks, which is plausible next to the weapon timings
  (`OriginalRate=0.45` / `0.90`). The extra `TrackTime` field is numerically
  equal to the raw frame count, not seconds, which is a quirk of these files
  but is the same for arms and legs.
- Therefore the differentiator is much more likely the **playback path**
  (channel 0 / `SimAnim`) than the animation data itself.

This should still be confirmed against the *compiled* `MeshAnimation`
sequences, not only the `.psa` sources. A small diagnostic dump can print the
actual `SequenceName`, `NumFrames` and `Rate` the engine loaded.

## What has already been tried

Recent commits changed layering, idle/relaxed poses, air jumps and weapon
switching, but none changed:

- `bReplicateAnimations`;
- `SimAnim`/`AnimRep` handling;
- the channel used for kicks;
- the `PlayAnim` rate for kicks;
- client-side animation playback.

That is consistent with the symptom surviving those fixes.

## Assessment of the proposed "play every Unarmed animation in order" branch

The proposed mutator (arm sequences first, then leg sequences, each in a fixed
order) is a useful **cataloguing** tool, and better than relying on the random
1-in-4 attack selection. It will answer:

- which sequences play at all;
- whether any *arm* sequence is also visibly broken;
- whether the failure follows the animation name or the body part.

However, on its own it confounds three variables:

1. body part (arms vs legs);
2. animation channel (arms on 1, legs/kicks on 0);
3. replication path (channel 0 is in `SimAnim`, channel 1 is not).

If the test is run on a standalone/listen host it may not reproduce the bug at
all, and if it is run only on a remote client it still will not say *which* of
the three is responsible. It also does not capture the server/client timing
difference, which is the most likely mechanism.

So: keep the deterministic sequence player, but do not make it the first
experiment. Use it after the differential tests below, as the control that
separates "bad asset" from "bad playback path".

## Recommended approach

### 1. Separate local playback from replication first

Run the same build in three setups and record a short clip/log for the same
forced kick (`AttackFast3` and `AttackStrong3`, not random attacks):

| Setup | Kick playback | Interpretation |
|---|---|---|
| Standalone / instant action | normal | asset and script rate are fine |
| Listen server, host view | normal | server-side playback is fine |
| Remote client joining that server | slow | bug is in the client replication path |

If only the remote client fails, stop looking at the PSA/sequence list and
focus on `SimAnim` and `AnimAction`.

### 2. Instrument the actual network animation state

Add a diagnostic switch (default off) to `K2k4xPawn` and/or a small test
mutator that logs, on **both** server and client:

- `Level.TimeSeconds`, `Role`, `RemoteRole`, `bNetOwner`, `Physics`;
- `AnimAction`, `bWaitForAnim`, `bK2k4Kicking`, `bK2k4UpperBusy`;
- `GetAnimParams(0, Seq0, Frame0, Rate0)` and
  `GetAnimParams(1, Seq1, Frame1, Rate1)`;
- `SimAnim.AnimSequence`, `SimAnim.AnimRate`, `SimAnim.AnimFrame`,
  `SimAnim.TweenRate`, `SimAnim.bAnimLoop`;
- a start marker when `SetAnimAction` plays a kick and an end marker in
  `AnimEnd(0)`, with elapsed time.

The `SimAnim.AnimRate` byte is the critical value: compare it with the server's
`Rate0` and with the expected `1.0` multiplier.

### 3. A/B the replication flag

On the diagnostic branch, test:

- **A**: current build, `bReplicateAnimations=True`;
- **B**: `bReplicateAnimations=False` (stock `xPawn` value).

For each, force one kick and one arm punch on a remote client. Two outcomes:

- Kick becomes normal in B -> the problem is `SimAnim`/channel-0 replication.
  The fix is then either to stop replicating channel 0 and drive these clips
  through the replicated `AnimAction` path, or to explicitly set/repair
  `SimAnim` after each `PlayAnim`.
- Kick is still slow in B -> the client is playing the clip through another
  path (likely `SetAnimAction`/`AnimAction`) and the rate passed to `PlayAnim`
  or the client-side timing is wrong.

Keep the air-jump clips in the test matrix: they are also channel 0 and depend
on the same flag. A fix that makes kicks fast but breaks remote air clips is
not acceptable.

### 4. Isolate channel from body part

Temporarily force the *same* sequence (`AttackFast3`) onto channel 0 and then
channel 1 at rate 1.0. If channel 1 is normal and channel 0 is slow, the body
part is irrelevant and the channel/replication path is confirmed. If both are
slow, the sequence/asset or the rate argument is at fault.

Also repeat with an explicit rate (`PlayAnim(Anim, 1.0, 0.1, 0)` vs a known
rate) to see whether the client honours the requested rate or reconstructs a
different one.

### 5. Then run the deterministic sequence catalogue

Once the path is identified, use the proposed mutator to play every Unarmed
sequence in a fixed order:

1. `Ready`, `FlagReady`, `Guard`, `FlagGuard`;
2. `AttackFast1`, `AttackFast2`, then `AttackFast3`, `AttackFast4` and Rush
   variants;
3. `AttackStrong1`, `AttackStrong2`, then `AttackStrong3`, `AttackStrong4` and
   Rush variants;
4. `FlagFast*` / `FlagStrong*`;
5. air clips (`KJump*`, dodge clips) if they are in scope.

Log sequence name, channel, requested rate, actual `GetAnimParams` rate, start
time and `AnimEnd` time for each. That turns "it looked slow" into a table.

## Diagnostic build (implemented)

Branch: `anim-replication-diagnostics`.

The test-only harness is now in place:

- `Classes/MutKakutouAnimLab.uc` - enable with
  `?mutator=Kakutou2k4-Enhanced.MutKakutouAnimLab`.
- `Classes/K2k4xPawn.uc` - adds `bK2k4DebugNetAnim` (replicated to clients)
  and `K2k4LogNetAnim()`, called every 0.25 s and at action start/end.
- `System/Kakutou2k4-Enhanced.u` / `.ucl` - rebuilt with the harness; the
  mutator is exported in the cache.

Console commands (from the **server** console or a client, via `mutate`):

| Command | Purpose |
|---|---|
| `mutate k2lab kick fast` | Force `AttackFast3` through the normal kick path. |
| `mutate k2lab kick strong` | Force `AttackStrong3`. |
| `mutate k2lab play <seq> [rate] [channel]` | Play one sequence directly, bypassing attack selection. |
| `mutate k2lab sweep arms` | Ready/guard and all arm attacks, fixed order. |
| `mutate k2lab sweep legs` | All kick attacks, fixed order. |
| `mutate k2lab sweep all` | Arms first, then legs. |
| `mutate k2lab netlog on/off` | Toggle the `K2LABNET` per-pawn log on server and clients. |
| `mutate k2lab repanim on/off` | A/B switch for `bReplicateAnimations`. |
| `mutate k2lab dump` | Log current channel/`SimAnim` state and `HasAnim` for known sequences. |

`K2LABNET` lines contain the timestamp, `Role`/`RemoteRole`, `bNetOwner`,
physics, `AnimAction`, `bWaitForAnim`, kick/busy flags, both channels
(sequence/frame/rate), and the raw `SimAnim` fields. `K2LAB` lines mark sweep
steps, forced commands and `bReplicateAnimations` changes. All go to
`UT2004.log` on the machine that runs the code, so server and client logs must
be kept side by side.

Recommended run order with this build:

1. Standalone: `sweep all`, capture the client-side log. This is the local
   control.
2. Listen server: host runs `sweep all`, capture the host log; a second client
   joins and repeats, capturing the client log.
3. Compare the `K2LABNET` channel-0 `r0`/`SimAnim.AnimRate` and the
   `ANIMEND`/`ACT-START` deltas. The kick should last roughly 0.33 s locally
   (`AttackFast3`) / 0.67 s (`AttackStrong3`); if the client reports a much
   smaller `r0` or a long frame delta while `SimAnim.AnimRate` differs from the
   server, the replication hypothesis is confirmed.
4. Run `repanim off`, repeat the forced kick on the remote client. If the kick
   becomes normal but remote air clips stop working, the fix must preserve
   channel-0 replication for the air moves.
5. Run `sweep arms` and `sweep legs` on the same client. This is the original
   catalogue idea, now used as confirmation after the path is known.

No gameplay fix is committed until one of those outcomes is observed.

## Context for the next session

- Engine reference sources used: `/home/jdmr/Proyectos/ut2k4tp/reference/`
  (`Engine/Actor.uc`, `Engine/Pawn.uc`, `XGame/xPawn.uc`).
- Local UT2004 install: `/home/jdmr/Juegos/UT2004`; the repo is symlinked as
  `UT2004/Kakutou2k4-Enhanced`. UCC is run through Wine.
- The repo's compiled package is `System/Kakutou2k4-Enhanced.u`; rebuilding
  writes into `System/`.
- `bReplicateAnimations=True` has been present since the initial import and is
  the single strongest difference from stock `xPawn` in this area.

## Decision log

- 2026-10-30: Started this investigation. Confirmed from source and PSA data
  that arms and legs do not differ in animation metadata; identified the
  channel-0 `SimAnim` replication path as the leading hypothesis. Recommended
  differential testing and instrumentation before the deterministic sequence
  catalogue.
- 2026-10-31: Implemented `MutKakutouAnimLab` and the replicated
  `bK2k4DebugNetAnim` logging. Package rebuilt with UCC under Wine:
  `Success - 0 error(s), 1 warning(s)` (`MutKakutou2k4` class-name warning
  only). No runtime test of the mutator commands has been performed yet; the
  next step is to capture a standalone log, then a listen-server/client pair.
