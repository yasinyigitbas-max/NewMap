# light_grid: test for engine patch e (tile light grid in the Mobile renderer)

A night street with ONE merged ground mesh and ONE merged wall per side (like the game's merged meshes), street
lamps (omni) and headlights (spot), no shadows. Env: `LG_GRID` (0 old per-mesh lists, 1 grid, 2 = switched on at
frame 45), `LG_OMNI`, `LG_SPOT`, `LG_SPLIT` (1 = ground in 5 m pieces), `LG_CULL` (1 lights have a cull mask that
includes everything, 2 lamps skip the ground's layer), `LG_CAM` (0, 1, 2), `LG_FRAMES`, `LG_NAME`.

    LG_NAME=on24 LG_GRID=1 LG_OMNI=24 LG_SPOT=4 xvfb-run -a -s "-screen 0 1280x720x24" <engine> \
        --path engine/tests/light_grid --rendering-driver vulkan --rendering-method mobile

13 Nov 2026: the patch now also cuts the view depth in 64 slices (a pixel's lights = tile bits AND slice bits).
Every shot below was repeated with it and is bit-identical to the tile-only version, 40 lamps included. On an idle
machine: 40 lamps + 4 spots 58.7 / 58.8 ms a frame with slices against 63.6 / 61.9 without; 6 lamps 44.8 against
54.9 (unpatched engine 55.6). llvmpipe numbers, a hint only.

12 Nov 2026, 1280x720, x86 llvmpipe, engine = baseline + patch e:
| compare | pixels that differ (of 921600) | largest difference (of 255) |
|---|---|---|
| unpatched engine vs patched with the grid off, 6 and 24 lamps | 0 | 0 |
| grid off vs on, 1 lamp | 0 | 0 |
| grid off vs on, 6 lamps + 2 spots (within the 8-per-mesh limit) | 2447 | 3 |
| same, lights with a cull mask (`LG_CULL=1`) | 2447 | 3 |
| same, lamps skip the ground layer (`LG_CULL=2`) | 2322 | 3 |
| same, camera 1 / camera 2 | 5848 / 79 | 5 / 2 |
| grid on from the start vs switched on at frame 45 | 0 | 0 |
| grid on, ground as one mesh vs ground in 5 m pieces, 24 lamps | 66 | 85 (piece edges) |
| grid off vs on, 24 lamps + 4 spots | 758241 | 222 (the old path lights 8 per mesh; see `results/compare_grid.png`) |

The small differences with <= 8 lights come from the order the lights are added up (distance order in the grid,
pairing order in the old path).

Frame times on llvmpipe swing by +-15 % between identical runs and are not a guide to the phone.

A trap found on the way: calling `light_process_omni` under a run-time condition inside the loop (an `if` or a
`continue` for the cull-mask test) made the light lose its diffuse term on llvmpipe, although the condition was
true. The patch therefore filters the tile's light bits before the loops and calls the light functions
unconditionally. Whether that was llvmpipe or glslang was not found out; if lights look wrong on the phone, look
here first.

Not tested here: shadowed lights with the grid, reflection probes, sub-viewports, more than 32 lights of one kind
in view (the nearest 32 are kept), XR / multiview (the grid switches itself off), orthogonal cameras (off).
