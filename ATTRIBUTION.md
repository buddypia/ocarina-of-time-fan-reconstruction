# Third-Party Licenses & Attributions / 著作権表示・出典一覧

This project relies on and appreciates the open-source software and open-access creative works listed below.

---

## 1. Game Engine: Godot Engine
- **License**: MIT License
- **Copyright**: (c) 2014-present Godot Engine contributors, (c) 2007-2014 Juan Linietsky, Ariel Manzur
- **Website**: https://godotengine.org/
- **Text**: See `production/authored/GODOT-LICENSE.txt` or https://godotengine.org/license

```text
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
...
```

---

## 2. 3D Scans & PBR Textures: Poly Haven
- **License**: CC0 1.0 Universal (Public Domain Dedication)
- **Website**: https://polyhaven.com/
- **Assets Used**:
  - [Rock Face 01](https://polyhaven.com/a/rock_face_01) by Dario Barresi (Scanned rock geometry, diffuse, normal, packed surfaces)
  - [Rocky Terrain 02](https://polyhaven.com/a/rocky_terrain_02)
  - [Cobblestone Floor 08](https://polyhaven.com/a/cobblestone_floor_08)
  - [Slab Tiles](https://polyhaven.com/a/slab_tiles)
  - [Medieval Blocks 05](https://polyhaven.com/a/medieval_blocks_05)
  - [Volcanic Rock Tiles](https://polyhaven.com/a/volcanic_rock_tiles) by Charlotte Baglioni
- **License Details**: All assets on Poly Haven are published under CC0. See https://polyhaven.com/license.

---

## 3. Human Anatomy & Character Base: MakeHuman Assets
- **License**: CC0 1.0 Universal (Graphical Assets)
- **Source**: [MakeHuman Community System Assets](https://static.makehumancommunity.org/assets/assetpacks/makehuman_system_assets.html)
- **Commit Reference**: `a8bc2d54ff0ac92e78ff71431b1023eda42bf482`
- **License Note**:
  - The [MakeHuman License](https://github.com/makehumancommunity/makehuman/blob/master/LICENSE.md) explicitly distinguishes program code (AGPL) from graphical assets and targets (CC0).
  - Only CC0 graphical base meshes and targets are adapted; no MakeHuman application code is included or linked.
  - Character garments, hair styling, armature modifications, and animation studies were independently created in this repository.

---

## 4. Upstream PC Port Reference: Ship of Harkinian (Shipwright)
- **Project**: [Shipwright / Ship of Harkinian](https://github.com/HarbourMasters/Shipwright)
- **Authors**: Harbour Masters & Contributors
- **License**: Project code under GPL-2.0 / MIT (see upstream repository for individual component licenses).
- **Notice**: Shipwright is kept as an upstream reference implementation and does not distribute proprietary game assets. Users of the native port must provide their own legally acquired ROM dump.

---

## 5. Visual Reference Photography (Reference Only, Not Runtime Assets)
The following public domain photographs served as visual studies for shape and material construction. They are **not** bundled as game textures:
- **Evans Plunge**: National Park Service / Wikimedia Commons (Public Domain)
- **Met Museum Shoes & Cranequin**: The Metropolitan Museum of Art Open Access (Public Domain)
- **NOAA Sea Anemone Studies**: NOAA Ocean Exploration (Public Domain)
- **Kilauea Volcano Study**: U.S. Geological Survey (USGS) (Public Domain)
- **Durham Cathedral Nave**: Visual study for architectural layout only (not redistributed).

---

## 6. Independently Authored Audio and Music
- All sound effects (chimes, footsteps, splashes, impacts) are procedurally synthesized via Python (`production/authored/make_audio.py`).
- Background music loops and ocarina melodies are newly synthesized arrangements created for this project, not original soundtrack recordings or audio rips.

---

Detailed technical hashes and URL manifests can be reviewed in:
- `production/authored/THIRD_PARTY_ASSETS.md`
- `production/authored/*-reference-manifest.json`
