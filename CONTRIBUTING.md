# Contributing Guidelines / 貢献ガイドライン

Thank you for your interest in contributing to the **Ocarina of Time (Authored Fan Reconstruction)** project!
To keep this project safe, legal, and functional on GitHub, all contributors must strictly follow these guidelines.

---

## 🚨 Cardinal Rules (Must Read Before Contributing)

### 1. Zero Copyrighted Assets / No ROM Dumps (絶対厳守)
- **NEVER** commit, upload, or submit Nintendo game ROMs, byte-identical extracted data, proprietary audio files, or commercial assets.
- **NEVER** include links to pirate sites, ROM repositories, or unauthorized download mirrors.
- All 3D models, textures, animations, and scripts must be either:
  1. **Independently authored** (created by you or documented with generation scripts in `production/authored/`).
  2. Licensed under **CC0 / Public Domain / Compatible Open Licenses** with full provenance documented in `THIRD_PARTY_ASSETS.md`.
- Pull Requests containing copyrighted Nintendo assets will be **rejected and permanently closed**.

### 2. No Secrets, Credentials, or Local Machine Paths
- **Never** commit API keys, tokens, SSH keys, passwords, or personal credentials.
- Ensure scripts and tests use relative paths from the project root (`ROOT / "game"`), rather than hardcoded local absolute paths (e.g. `/Users/username/...`).

### 3. File Size Constraints (< 100 MB Limit)
- GitHub strictly rejects any single file greater than 100 MB.
- Do not commit prebuilt `.app` bundles, `.pck` files, or large `.zip` packages. Those belong in GitHub Releases.
- Respect `.gitignore` rules at all times.

---

## Getting Started

### Development Requirements
- **Godot Engine 4.x** (v4.7.2+ recommended)
- **Python 3.10+** (with NumPy and Pillow for texture/audio generation scripts)
- **Blender 4.x+** (optional, for regenerating 3D models from `production/authored/`)

### Running the Source Project
```sh
# 1. Import assets into Godot
python3 tools/authored.py import

# 2. Launch the game in editor / debug preview
python3 tools/authored.py play
```

### Running Automated Verifications
```sh
# Run headless quest verification tests
python3 tools/authored.py verify --jabu --fixture --headless
python3 tools/authored.py verify --time-quest --fixture --headless
python3 tools/authored.py verify --forest-temple --headless
python3 tools/authored.py verify --fire-mountain --headless
```

---

## Pull Request Checklist

Before submitting a PR, verify:
- [ ] No copyrighted assets (ROMs, Nintendo sound rips, official meshes) are added.
- [ ] Any new 3D assets, textures, or sounds have clear provenance and license recorded in `ATTRIBUTION.md`.
- [ ] No API keys, credentials, or personal absolute paths are introduced.
- [ ] No single file exceeds 50 MB (and strictly below GitHub's 100 MB limit).
- [ ] Automated headless verification passes (`python3 tools/authored.py verify ...`).
- [ ] Code follows existing conventions in `game/scripts/` (clean GDScript, explicit type safety where applicable).
- [ ] Git commit messages are descriptive and follow standard English developer conventions.
