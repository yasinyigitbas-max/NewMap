# Patch note: lit windows on far buildings at night (for the PC session; 18 Nov, look job 5)

Far buildings (beyond 220 m, the far world) do not light their windows at night: the kit's far atlas
(`assets/coronado_kit/textures/far_color.png`) has no glow mask. This session may not edit `rt_far*`, so here is the
change, tried in memory: pictures `review/look_18nov/far_windows/` (`*_night_before` / `*_night_after`, the far world
alone at night).

## The cheapest way (no extra texture read)
1. **The window mask in the far atlas's alpha.** `tools/city/look/make_far_glow.py` finds the painted windows (texels
   clearly darker than the wall around them on wall-light bands; band edges and frame rings cleaned up; 9.9 % of the
   atlas) and writes `runtime_tex/far_color_glow.png` = the far atlas with that mask as alpha (derived, the kit file is
   not touched). Preview: `window_mask_preview.jpg`. Run it next to `make_arrays.py` in the bake steps.
2. **The bake** (`bake_runtime.gd` `_mat_far("solid")`): bind `runtime_tex/far_color_glow.png` as `albedo_tex` instead
   of `far_color.png`. Its import must keep the alpha (the default import does; VRAM-compressed RGBA: 4 MB instead of
   2 MB for the 2048 x 2048 atlas).
3. **The shader** (`city_kit/shaders/rt/rt_far.gdshaderinc`): exactly `tools/city/look/far_glow_patch.gdshaderinc`
   (differences marked "NIGHT"): a world position and normal varying, and in the fragment of the solid (not RT_CUT)
   version, at night only, `EMISSION = mask * lamp * on`, with the same rule as the near windows (`rt_bldg`): per 3 m bay
   of each wall a third stay dark, the rest come on one by one with `ck_night`, mostly warm bulbs, some neutral, one in
   twelve a dim cold light. `ck_look_windows = 0` gives the old single orange.
## Matching the near windows
- Same palette, the same share of dark windows, the same dusk ramp. Not the same window-by-window pattern: the near
  shader finds each window from the kit's real window quads, the far box only has painted marks, so at the 220 m switch
  a few windows change state. At that distance a window is 2-4 pixels; not checked on the phone whether it is noticed.
## Cost
- No extra texture read (the mask rides in the atlas alpha already read). At night ~20 ops on far-building pixels
  (two `sin` hashes, a few mixes); by day a branch skips it. Two more varyings (world position, normal).
- Memory: the far atlas with alpha, about +2 MB.
