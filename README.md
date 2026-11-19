# Michigan Lunker Rush

> Scout the water, cast true, and don't snap the line.

A portrait 2D arcade fishing game for Android set on Michigan lakes. Deploy a
scout drone to reveal fish silhouettes, tap-drag to cast, and fight panfish,
largemouth bass, and northern pike in a rhythmic tension-bar reeling minigame —
without snapping your 15 lb braid. Landed fish earn coins to spend in the
Workbench on 3D-printed lures for larger boss fish, while the weather changes
how the fish bite.

## Features

- Portrait tap-and-drag aiming and casting — distance and power follow drag length
- Scout drone button that reveals fish silhouettes for 5 seconds, then cools down
- Tension-bar reeling minigame: rhythmic tapping reels in; too much tension snaps
  the 15 lb braid, too little lets the fish escape
- Three catchable species — panfish, largemouth bass, and northern pike — each
  with distinct size, fight strength, speed, and coin value
- Boss fish per lake, landable only with upgraded lures and careful tension control
- Weather system (sunny, cloudy, rain) that changes bite rate and aggression —
  pike get more aggressive in the rain
- Three Michigan lake environments with different fish mixes, depth, visuals,
  and difficulty
- Coins earned per landed fish, saved locally and spent in the Workbench
- Workbench 3D-printing: unlock the Texas-rigged worm, topwater frog, and
  squarebill crankbait, each suited to larger, heavier fish

## Screens

Main Menu · Lake Select · Fishing (main gameplay) · Catch Summary ·
Workbench (3D-print lures) · Fish Log / Collection · Pause / Settings

## How to run

Requires **Godot 4.x** (tested with 4.3+).

1. Open Godot and import this project (`project.godot`).
2. Press **F5** (or the Play button) to run the main fishing scene
   (`scenes/fishing.tscn`) on desktop.
3. For touch testing, use Godot's **Remote Deploy** to an Android device, or
   export with the Android export preset (see below).

## Android export

1. In Godot: **Project → Export… → Add → Android**.
2. Install the Android export templates and set up the Android SDK
   (Godot docs: "Exporting for Android").
3. Set the package name (e.g. `com.workinmanstrokes.lunkerrush`), a
   portrait orientation is already configured in `project.godot`.
4. Export an APK/AAB and install it on a phone to test touch casting.

## Controls

- **Tap-drag** on the water to aim, release to cast. Longer drag = farther cast.
- **Drone button**: tap before casting to reveal fish silhouettes for 5 seconds.
- **Reeling**: once a fish bites, tap rhythmically to reel in. Watch the tension
  bar — red means the 15 lb braid is about to snap; too slack and the fish
  gets away.

## Project layout

| Path | Purpose |
| --- | --- |
| `project.godot` | Godot 4 project config: portrait 720×1280, pixel-art rendering, touch input, Android export settings |
| `icon.svg` | App icon placeholder |
| `scenes/fishing.tscn` | Main portrait fishing scene: water, shoreline, HUD, cast control, tension bar |
| `scripts/fishing.gd` | Core loop: aim and cast, drone timer, bite detection, reeling, catch resolution |
| `scripts/fish.gd` | Fish data and behaviour: species stats, movement, bite, fight, and escape |

## Build milestones

1. Godot portrait skeleton: lake scene, animated water, HUD, tap-drag casting
   with a placeholder bobber and bite
2. Fish spawning and species behaviour: panfish, bass, and pike movement,
   bites, catches, and escapes
3. Tension-bar reeling minigame with rhythmic tapping, line snap at high
   tension, and escape at low tension
4. Scout drone 5-second reveal with cooldown, plus the weather system and its
   bite/aggression effects
5. Coins, lake select, boss fish, and local save for profile, lures, and
   catch records
6. Workbench 3D-printing for Texas-rigged worm, topwater frog, and squarebill
   crankbait, gated to larger fish
7. Pixel-art polish, water and splash animation, sound, and Android export
   with on-device touch testing

## Open questions (v1)

- Are the Michigan lakes real named lakes or fictional lakes inspired by them,
  and how many are in v1?
- Should the scout drone have a per-trip limit or cooldown, or be usable before
  every cast?
- Is the 15 lb braid a fixed limit, or should upgraded line be purchasable in
  the Workbench alongside lures?

## License

MIT — see the project for details. Built with Godot 4 and GDScript.
