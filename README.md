# Kakutou 2004 — Enhanced

Community continuation of **Kakutou 2004**, the unarmed martial-arts mutator
for Unreal Tournament 2004. This fork preserves the original gameplay, models,
animations and sounds, and modernizes the animation layer and third-person
camera compatibility.

## What this fork adds

- **Torso-only animation layering.** Punches, guard and ready poses play on
  animation channel 1, rooted at `Bip01 Spine`, so the legs keep walking,
  running, crouching, turning and jumping underneath. Kicks remain full-body.
- **Air-jump animation remap.** The first jump plays a double-jump clip; every
  extra jump before landing plays a dodge clip chosen from the body-relative
  movement direction (forward/back/left/right).
- **Gameplay gates.** The remap only runs while `Unarmed` is equipped and the
  pawn is moving at or above its default running speed. Slower jumps and other
  weapons keep the stock animations.
- **Full-body air moves.** When the gate passes, the air clip temporarily owns
  hips and up; the guard overlay is restored when the clip ends, the pawn
  lands, or another action takes over.
- **Third-person camera awareness.** When `GTAThirdPerson` is installed, its
  `GTAPlayerController` owns the view and Kakutou defers to it. The camera mod
  is not bundled here.
- **Guaranteed spawn weapon.** After the rest of the mutator chain sets up its
  loadout, Kakutou checks for `Unarmed` and grants it if missing, so weapon or
  loadout mutators that replace the ShieldGun slot (UT99-style loadouts, for
  example) can no longer lock the martial-arts weapon out. If `Unarmed` is
  already present, the check does nothing.

See [ROADMAP.md](ROADMAP.md) for the current state and planned work.

## Gameplay

Players spawn with the `Unarmed` weapon instead of the ShieldGun, with
strikes, kicks, blocking and combos. Crouching just before a jump or dodge
increases leap height and distance. See
[Help/Kakutou2k4_Readme.txt](Help/Kakutou2k4_Readme.txt) for the original
gameplay documentation.

## Installation

1. Copy `System/Kakutou2k4.u`, `System/Kakutou2k4.int` and
   `System/Kakutou2k4.ucl` into `UT2004/System/`.
2. Copy `Sounds/K2k4Sounds.uax` into `UT2004/Sounds/`.
3. Optionally copy `Help/Kakutou2k4_Readme.txt` into `UT2004/Help/`.
4. Select **Kakutou 2004** (or **Kakutou Arena 2004**) from the in-game
   mutator list.

## Building from source

The mod is UnrealScript; all classes live in `Classes/`.

1. Install the UT2004 Editor/UCC tools.
2. Put `K2k4Sounds.uax` in `UT2004/Sounds/` so the package can resolve its
   sounds during compilation.
3. Make the repository visible to the editor as package `Kakutou2k4` (for
   example, a `UT2004/Kakutou2k4` directory link containing `Classes/` and
   `Models/`, plus `EditPackages=Kakutou2k4` in `UT2004.ini`).
4. Run `ucc make` from `UT2004/System/`. The compiled `Kakutou2k4.u` is
   written to `System/`.

`System/Kakutou2k4.u` in this repository is the current verified build.

## Credits

- **PsychoKick** — original Kakutou 2004 code, animations and sounds
  (circa 2002).
- **Circa** — credited by the original project.
- **Rythmix** — UT2004 Instant Action port and code modifications.
- **MrPingu07 and contributors** — enhanced animation layering, air-jump
  remap, GTAThirdPerson compatibility and ongoing maintenance.

The original readme asks that existing developer names stay in the files and
that the readme itself stay intact. Both have been preserved.

## License

The enhancements in this repository are released under the [MIT
License](LICENSE).

The original mod — including its UnrealScript code, animations and sounds —
remains the work of its original authors. It is included here for
preservation, and no new rights are claimed over that original work. The
original readme's credit and preservation requests take precedence for those
portions.

`GTAThirdPerson` is a separate project and is not included in this
repository.
