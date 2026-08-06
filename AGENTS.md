# DON'T DODGE Agent Guide

## Project principles

- This is a Godot 4.7 web hack-and-slash prototype.
- Validate fun before feature completeness, architecture, scalability, content volume, or technical elegance.
- Do not add features that were not requested.
- Desktop web browsers are the primary target; macOS is the fast development-test environment.
- Use statically typed GDScript wherever practical.
- Separate gameplay logic from presentation.
- Separate input devices from player commands.
- Prefer composition over deep inheritance.
- Do not implement a custom ECS during the early prototype stage.
- Avoid unnecessary per-frame allocations.
- Do not edit or commit `.godot/` or build outputs.
- Avoid large, direct edits to complex `.tscn` files; keep scenes small and focused.
- Run a headless validation after work when the Godot CLI is available.
- Each task should address one gameplay hypothesis or one defect.
- Do not commit or push without the user's explicit instruction.

## Localization principles

- Korean (`ko`) is the default locale; English (`en`) is the only additional supported locale unless a task explicitly expands the scope.
- Keep player-facing text in `localization/dont_dodge.csv` and access it through the `Localization` autoload/helper and `TranslationServer`; do not add new hardcoded UI strings to GDScript, scenes, or gameplay data.
- Store translation keys in data fields such as `title_key`, `description_key`, and `detail_key`, never rendered language strings.
- Dynamic UI state must retain translation keys plus format arguments. Resolve nested names at render time so active HUD, tooltips, feedback, upgrade, challenge, and result text changes locale correctly.
- Persist locale changes in `user://dont_dodge_settings.cfg` under `[localization] locale`, preserving the existing audio and tutorial settings in that file.
- Write natural English UI copy rather than literal translations, and verify that English mode leaves no Hangul in visible text or tooltips.
- Use automatic wrapping, expandable containers, or appropriate minimum widths when localized text can grow. Check title and other affected layouts at 1600×900, 1366×768, and 1280×720 in both locales.
- When changing localization, run the catalog/data-key validation and the existing Godot headless gameplay regression checks. Do not alter gameplay rules, tuning values, or combat state to accommodate translation.
