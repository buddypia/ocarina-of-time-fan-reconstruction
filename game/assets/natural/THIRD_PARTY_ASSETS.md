# Licensed inputs for the authored reconstruction

Recorded 2026-09-29. Game layout, progression, dialogue, geometry assembly, shaders and authoring scripts are produced in this workspace. Selected environment and anatomy inputs are third-party CC0 assets; they are **not original meshes created here and are not recovered Nintendo game data**.

## Runtime environment inputs

Files beneath `game/assets/natural/`:

- [Rock Face 01 — Poly Haven](https://polyhaven.com/a/rock_face_01), Dario Barresi: scanned rock geometry and diffuse, normal and packed surface textures.
- [Rocky Terrain 02](https://polyhaven.com/a/rocky_terrain_02), [Cobblestone Floor 08](https://polyhaven.com/a/cobblestone_floor_08), [Slab Tiles](https://polyhaven.com/a/slab_tiles), [Medieval Blocks 05](https://polyhaven.com/a/medieval_blocks_05), Poly Haven: selected 2K diffuse, OpenGL normal and AO/roughness/metal maps. Earlier material alternatives are retained as source assets.

Poly Haven identifies these assets as [CC0](https://docs.polyhaven.com/en/faq). The authored scene changes placement, scale and material settings; it does not assert ownership of the underlying scans.

## Other runtime and production inputs

See [the complete asset record](../THIRD_PARTY_ASSETS.md) for the anatomical player, licensed inputs, references and reproduction commands.

## Fire Temple volcanic masonry — 2026-09-29

`volcanic_rock_tiles/{diff,nor_gl,arm}.jpg`: **Volcanic Rock Tiles**, Charlotte Baglioni / [Poly Haven](https://polyhaven.com/a/volcanic_rock_tiles), [CC0](https://polyhaven.com/license). Downloaded through the public API's 2k JPG entries. Original MD5 verified before use; download URLs and SHA-256 are retained in `production/authored/fire-volcanic-manifest.json`. Used on authored temple stonework. Authored lava maps and the Goron study are separate assets.
