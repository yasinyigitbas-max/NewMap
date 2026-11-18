# CREDITS - shared building atlas (phase A houses)

All texture pixels in textures/bld_color.png / bld_normal.png / bld_orm.png come from real photo-scanned textures under CC0 1.0. No CC-BY or CC-BY-SA material is used in the building atlas, so there is no per-asset ShareAlike record yet; any CC-BY-SA source added later will be listed here per atlas region and asset. Mapillary imagery was used only as colour/wear reference, never as texture pixels. Geometry, the high-poly trim/opening bakes (normal map + AO) and all house models are made from scratch.

| source texture | provider | licence | atlas regions |
|---|---|---|---|
| white_stucco | Poly Haven (polyhaven.com) | CC0 1.0 | W_halftimber, W_stucco |
| exterior_wall_cladding_03 | Poly Haven (polyhaven.com) | CC0 1.0 | W_siding |
| roof_slates_02 | Poly Haven (polyhaven.com) | CC0 1.0 | R_shake, W_shingle |
| red_brick | Poly Haven (polyhaven.com) | CC0 1.0 | W_brick |
| fine_grained_wood | Poly Haven (polyhaven.com) | CC0 1.0 | O_door_craftsman, O_win_casement, O_win_diamond, T_dark, W_halftimber |
| castle_wall_slates | Poly Haven (polyhaven.com) | CC0 1.0 | W_stone |
| white_planks_clean | Poly Haven (polyhaven.com) | CC0 1.0 | O_* painted frames, T_white, W_bb |
| weathered_brown_planks | Poly Haven (polyhaven.com) | CC0 1.0 | O_door_spanish, O_garage_wood, T_deck |
| concrete_floor_02 | Poly Haven (polyhaven.com) | CC0 1.0 | T_concrete |
| corrugated_iron | Poly Haven (polyhaven.com) | CC0 1.0 | R_metal, T_metal |
| terracotta_floor_tiles | Poly Haven (polyhaven.com) | CC0 1.0 | T_terracotta |
| clay_roof_tiles | Poly Haven (polyhaven.com) | CC0 1.0 | R_clay |
| asphalt_02 | Poly Haven (polyhaven.com) | CC0 1.0 | R_comp |
| bitumen | Poly Haven (polyhaven.com) | CC0 1.0 | R_flat |
| SurfaceImperfections017 | ambientCG (ambientcg.com) | CC0 1.0 | O_* wear/grime |

## Park ground atlas (textures/ground_*.png, 1024 x 1024; parks/*_ground_*.glb)
| Source | Author / site | Licence | Regions |
|---|---|---|---|
| grass_ground | Poly Haven (polyhaven.com) | CC0 1.0 | G_grass |
| concrete_pavement | Poly Haven (polyhaven.com) | CC0 1.0 | G_paving |
| park_sand, coast_sand_01 | Poly Haven (polyhaven.com) | CC0 1.0 | G_sand |
| wood_chips | Poly Haven (polyhaven.com) | CC0 1.0 | G_chips |
| smooth_concrete_floor | Poly Haven (polyhaven.com) | CC0 1.0 | G_curb, G_court (base) |
| weathered_brown_planks | Poly Haven (polyhaven.com) | CC0 1.0 | G_timber |

Props, fences and foliage: see CREDITS_props.md.

## Prop wear overlay (15 Nov 2026)

`atlases/props_grime.png` (512, shipped) is a tiling dirt / smear map used by `shaders/prop_wear.gdshader`.
Colour from Poly Haven dirty_concrete (CC0 1.0). Mask and stain from ambientCG SurfaceImperfections017 and Smear007 (CC0 1.0).
The hand-painted worn / dirty colour pages are archived in `_archive/props_condition_pages/` and are not shipped.
