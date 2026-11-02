# Kakutou2k4 Enhanced — Roadmap

## Fixed: slow leg / air animations on clients

Full-body kicks used to play very slowly for remote clients while arm-only
attacks looked normal. The same channel-0 ownership conflict later showed up
on jump, dodge and fall clips. Fixed by playing every full-body mod clip as a
global pose on channel 1 and leaving channel 0 to the engine. The
investigation, evidence and fix are in
[docs/ANIMATION_TIMING.md](docs/ANIMATION_TIMING.md).

## Air-jump animation override

Implemented in `Classes/K2k4xPawn.uc`:

- First jump plays `DoubleJumpAnims[dir]`.
- Every extra jump before landing plays `DodgeAnims[dir]`.
- `dir` comes from `K2k4GetAirDirection()`, which projects `Velocity` onto the
  pawn's own facing (0 = F, 1 = B, 2 = L, 3 = R).
- Clips play as a global pose on channel 1; channel 0 keeps running the stock
  fall/idle/locomotion animation underneath.
- First-jump overrides are gated; extra jumps are not (see below).

Checklist:

- [x] **Only override while Unarmed is equipped.**
  - `K2k4CanOverrideAirAnim()` requires `Unarmed(Weapon) != None`.
  - Every other weapon, bots included, keeps the stock jump and double-jump
    animations.

- [x] **Require running speed for the first jump.**
  - The helper compares the 2D (horizontal) velocity against
    `default.GroundSpeed` (the class default, ignoring temporary
    leap/boost modifiers).
  - Below that threshold the stock first-jump animation plays.

- [x] **Always play the dodge clip on extra jumps.**
  - `PlayDoubleJump()` calls `K2k4PlayAirAnim(..., true)`, bypassing the speed
    term. A slow hop still reads as a direction-relative dodge while Unarmed.

- [x] **Let the air clip own hips and up when the gate passes.**
  - On clip start, `bK2k4AirFullBody` is set and channel 1 becomes a global
    pose (`AnimBlendParams(..., true)`), so the double-jump/dodge drives the
    whole body while channel 0 runs underneath.
  - The guard/idle upper-body loop is restored when the channel-1 clip ends
    (`AnimEnd(1)`), when the pawn lands or leaves `PHYS_Falling` (`Tick`), or
    when another action takes the torso back (`SetAnimAction`).
  - Normal jumps and locomotion keep the existing torso lock.

- [x] ** As a client, Jumping, Double jumping and subsequent are in slow motion WHILE holding a regular, two handed weapon (Anything but Unarmed).**
  - `bReplicateAnimations` is now off, matching stock `xPawn`. It was letting
    the server's channel-0 `SimAnim` updates fight the client's own prediction,
    which slowed jump and double-jump clips for clients holding any non-Unarmed
    weapon. The martial-arts clips live on channel 1 and are simulated locally,
    so they never needed `SimAnim`.

- [x] **Unlike a host, a client cannot see everyone else in their combat-ready 'Ready' animation position. Only as if they were holding an invisible two-handed weapon (Default idle animation of the game).**
  - `bK2k4Combat` and `bK2k4Unarmed` are replicated, and remote proxies replay
    the replicated mod `AnimAction` on channel 1. Other players now enter the
    same `Ready` / `FlagReady` stance on a client as they do on the host, and
    their martial-arts attacks are visible too.
  - Remote proxies have `Weapon == None`, so the overlay gates use
    `K2k4IsUnarmed()` / `K2k4IsFlagFighting()`: a real weapon pointer when
    available, the replicated state otherwise.
  - Only the authority or the owning client ages the stance out; proxies keep
    the replicated state until the server clears it.

Code and package are rebuilt (`0 errors`, one pre-existing warning); the
remote-client pass still needs to confirm both items in game.
