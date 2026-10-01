# Ocarina of Time

Read `docs/PROGRESS.md` and `README.md` before changing this deliverable. The standing visual and interaction criteria are in `../docs/CREATIVE_QUALITY_STANDARD.md`.

The requested outcome is the complete Ocarina of Time game. A launcher, successful compilation, source coverage, or a ROM-selection screen does not prove that outcome. Keep all gameplay and completion checks unverified until actually exercised.

The user now explicitly requires us to author the missing game data autonomously. Do not wait for a user ROM. Author editable models, environments, interactions and sound in `game/`, using Godot as the runtime for authored content. Preserve the pinned Shipwright source and native builds as a separate reference path, and retain upstream attribution. Do not replace the requested game with an unrelated adventure or call upstream implementation original work. Full-game acceptance remains the original goal; a representative playable scene is progress, not completion.

Keep saves local to this deliverable and isolate test saves. Preserve the native port's `runtime` and `SHIP_HOME` path. Never replace existing saves or game archives automatically. Do not download game ROMs. Mark authored assets as authored reconstruction, not recovered original data or byte-identical ROM contents.

Commands run from this folder unless stated otherwise. Native smoke tests may start and close only their own process and capture only its window. Browser work, if needed, follows the root `pw-agent` instructions.
