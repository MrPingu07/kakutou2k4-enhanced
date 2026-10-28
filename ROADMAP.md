# Kakutou2k4 Enhanced — Roadmap

## Air-jump animation override

Implemented in `Classes/K2k4xPawn.uc`:

- First jump plays `DoubleJumpAnims[dir]`.
- Every extra jump before landing plays `DodgeAnims[dir]`.
- `dir` comes from `K2k4GetAirDirection()`, which projects `Velocity` onto the
  pawn's own facing (0 = F, 1 = B, 2 = L, 3 = R).
- Clips play on channel 0.
- Overrides are gated (see below); without the gate the stock jump animations
  play and the torso overlay is untouched.

Checklist:

- [x] **Only override while Unarmed is equipped.**
  - `K2k4CanOverrideAirAnim()` requires `Unarmed(Weapon) != None`.
  - Every other weapon, bots included, keeps the stock jump and double-jump
    animations.

- [x] **Require running speed.**
  - The same helper compares the 2D (horizontal) velocity against
    `default.GroundSpeed` (the class default, ignoring temporary
    leap/boost modifiers).
  - Below that threshold the stock jump animation plays.

- [x] **Let the air clip own hips and up when the gate passes.**
  - On clip start, `bK2k4AirFullBody` is set and channel 1 is blended out
    (`AnimBlendToAlpha(1, 0.0, 0.1)`), so the double-jump/dodge drives the
    whole body.
  - The guard/idle upper-body loop is restored when the channel-0 clip ends
    (`AnimEnd`), when the pawn lands or leaves `PHYS_Falling` (`Tick`), or when
    another action takes the torso back (`SetAnimAction`).
  - Normal jumps and locomotion keep the existing torso lock.
