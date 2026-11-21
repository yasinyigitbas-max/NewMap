# Hotel Bel (hero landmark) build sources

Built with the coronado_kit_v2 generator (/workspace/coronado_kit_v2/tools) copied to a working dir with
`kit_tools.patch` applied (geom: KIT_ROOT env override, exact bbox culling in vertex_ao, union_faces and fix_tjunctions, output identical; build: turret `no_head`, box `notj`; validate: landmark category accepts the hero class).

- `city_hero.py`  the hand-designed Hotel Bel (drop into the kit tools dir)
- `atlas_add.py`  additive city-atlas edit: R_shingle (red shingle tile row), S_shingle swatch, SG_hotelbel sign
- `hb_run.py`     build + validate (+ `--wc` wall check) into _staging/landmarks/lmk_hotel_bel
- `hb_count.py`   per-part triangle breakdown of a tier
- `hb_render.py`  Blender Cycles review renders (run through kiosks/bl.sh)
