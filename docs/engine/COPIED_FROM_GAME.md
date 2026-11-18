# Engine (reference copy)

Copied 18 Nov from coronado-source `engine/` (Yasin): Coronado's own Godot 4.7.2 Android build - patches
(incl. `e_mobile_light_grid.patch`, the clustered / tiled light grid: 32 omni + 32 spot lights, project setting
`rendering/lights_and_shadows/mobile_light_grid`), the design note LIGHTS_DESIGN.md, build / publish scripts and the
build records. The built .aar binaries stay on the game repo's engine-bin/* branches. NewMap builds and checks pieces
with the stock 4.7.2 editor; the light grid matters when the map plans real lights (lamp counts per view).
