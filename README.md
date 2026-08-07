# DON’T DODGE

Korean: [README.ko.md](README.ko.md)

DON’T DODGE is a Godot 4.7 web hack-and-slash prototype about making split-second decisions: should you kill a threat, erase it, or dodge it yourself? Each run asks you to survive four combat waves for 90 seconds.

## Play now

[**🎮 Play DON’T DODGE in your browser**](https://threelight2000.github.io/dont-dodge/)

Use a recent desktop browser such as Chrome or Edge. Browser autoplay rules mean music and sound effects begin after `Start Game` or an audio button is pressed.

## The game’s question

The prototype tests whether the same threat feels more interesting when the player can choose between a focused attack, a defensive response, or repositioning. It is a focused gameplay experiment rather than a finished commercial game.

## Core rules

- Start with 3 HP and survive 90 seconds across 4 waves.
- Melee, ranged, charger, volley, and elite enemies telegraph different attacks at different threat distances.
- `Attack` can finish or knock back nearby enemies. `Dodge` and `Nullify` share a pool of 2 defense charges.
- Perfect dodges, attack interrupts, projectile removal, and enemy takedowns charge the Ultimate gauge.
- A perfect dodge requires an attack or projectile to connect during the first 0.15 seconds of a W invulnerable dash.
- Each experience level presents 3 cards containing a weapon, technique, or weapon evolution choice.
- The Dagger, Guardian Mace, and Battle Spear change combat rules as well as damage: E access and W’s defense cost differ by weapon.

## Controls

| Action | Keyboard |
| --- | --- |
| Move | Arrow keys |
| Attack | `Q` |
| Dodge | `W` |
| Nullify projectiles / knock back | `E` |
| Ultimate | `R` |
| Pause | `Esc` |

BGM and SFX can be toggled separately in the lobby and pause menu. The browser’s autoplay policy requires `Start Game` or the relevant audio button before playback begins.

## Run locally

- Godot `4.7`
- GDScript
- Compatibility renderer
- Fast development checks: macOS
- Primary target: desktop web browsers

The default scene is `scenes/dont_dodge/dont_dodge.tscn`.

```sh
godot --path . --editor
```

If `godot` is not on your PATH, use `godot4` or `/Applications/Godot.app/Contents/MacOS/Godot`.

## Validation

Check that the project and scripts load:

```sh
godot --headless --path . --editor --quit
```

Run the core combat regression checks:

```sh
godot --headless --path . --script tests/dont_dodge_validation.gd
```

Check the bilingual catalog and translation keys:

```sh
godot --headless --path . --script tests/dont_dodge_localization_validation.gd
```

The combat suite covers enemy attack order, spawn limits, damage resolution, wave transitions, pausing, Ultimate range, and presentation boundaries without changing combat rules.

## Web build and deployment

The web preset in `export_presets.cfg` creates the GitHub Pages build. Pushing to `main` runs `.github/workflows/deploy-pages.yml` and deploys the browser build.

- Play URL: `https://threelight2000.github.io/dont-dodge/`
- Local web export requires the Godot 4.7.1 web export templates.

## Project layout

```text
scenes/dont_dodge/             Main game scenes
scripts/dont_dodge/            Combat rules, input, entities, tuning
scripts/dont_dodge/visuals/    Dungeon backdrop and combat presentation
`scripts/dont_dodge/dont_dodge_localization.gd`
                              Korean and English game catalog and locale helper
assets/third_party/kenney/     CC0 RPG atlas and sound sources
tests/                         Combat and localization validation
docs/                          Design, vision, and performance notes
```

Gameplay owns movement, attacks, collisions, damage, and wave progression. Presentation uses static Kenney tiles and code-driven pixel effects; it does not decide damage, collision radius, attack range, or progression.

## Current scope and limits

Implemented:

- Combat progression, enemy telegraphs, projectiles, damage/death, and three-stage upgrade choices
- Keyboard and on-screen UI input
- Local JSON Lines combat logs at `user://dont_dodge_runs.jsonl`
- Kenney dungeon tiles plus code-driven pixel characters, drops, projectiles, and ability marks
- Independent BGM/SFX settings and combat/UI effects
- Korean/English selection and persistence from the title and pause screens

Not implemented:

- Frame-by-frame state animation, shaders, or dedicated particle art
- Equipment, shops, long-term meta progression, or online features
- Production build and store-submission automation

The reference resolution is `1600×900`. Very narrow windows may require a separate check of the upgrade selection layout.

Pixel tiles and effects live in `scripts/dont_dodge/visuals/` and only handle presentation. Collision radii, attack ranges, and wave progression remain in the gameplay layer.

## Licenses and assets

The code and original documentation in this repository are released under the [MIT License](LICENSE).

- The UI font is [Noto Sans KR](https://github.com/notofonts/noto-cjk), distributed under the SIL Open Font License 1.1.
- Graphics use the [Kenney Roguelike/RPG Pack](https://kenney.nl/assets/roguelike-rpg-pack), and effects use [Kenney Impact Sounds](https://kenney.nl/assets/impact-sounds); both are CC0.
- The public source for the `Eight Tension` BGM is the [YouTube upload](https://www.youtube.com/watch?v=RIetjAmkfDo).
- Included asset files and license text are under `assets/third_party/kenney/`.

## Excluded from the repository

`.godot/`, build/export outputs, editor settings, local environment files, and secrets are ignored by `.gitignore`. Combat logs stay under `user://` and are not written to the repository.
