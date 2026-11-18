# Patch note for the bake: record the trees so blob shadows cost nothing at run time (look job 4)

Status: NOT applied (`bake_runtime.gd` is the streaming session's). The look shows the blobs without it
(`tools/city/look/blob_shadows.gd`, rig `--blobs=1`), but it has to read every cell's foliage meshes back from the GPU
when the cell comes in: tens of ms a cell in the cloud. That is why `--blobs` is off by default.

## The change
In `tools/city/bake/bake_runtime.gd`, where a plant goes into a cell (the foliage branch of the prop loop, next to
where `cell.lights` gets a lamp): if the plant sways (`wind`) and is big enough (height >= 2.5 m, crown radius >=
1.2 m, from `mm.mesh.get_aabb()` times the instance's scale), append `[x, y, z, height, radius]` (the foot in world
space) to a new list `cell.trees`. Near and mid tier of the same plant: record it once (the near tier only).
At the end of the cell, next to `root.set_meta(&"lights", rec.lights)`:

    root.set_meta(&"trees", rec.trees)

and, best, build the blob MultiMesh there too (the code of `blob_shadows.gd build()` from that list): one more node
per cell, `look_blobs`, with `tools/city/look/blob.gdshader`, `cast_shadow` off. The look then only sets the
material's `sun_dir` / `strength` / `haze` (it already does, `look.gd _apply`).

Parked cars: the stalls are already in the cell (`meta stalls`: x, y, z, yaw); when the game draws parked cars, the
same MultiMesh can take a stretched blob per stall (custom data: height 1.4, radius 2.3; the shader stretches along
the sun direction already).

## Why
Sun shadows end at 50 m (the game's setting; more would cost the phone a bigger shadow map pass), so beyond that
every tree stands on bright ground and the street looks flat and cut out.

## Cost
- One draw per cell that has trees (measured in the cloud: +5 to +8 draws a view; the budget is 150, the views
  measure 60-120).
- Pixels: only blobs beyond ~40 m reach the fragment stage (nearer ones are collapsed in the vertex shader), and those
  are small; a multiply blend, a few arithmetic steps, no texture read.
- Disk / memory: 32 bytes of transform + 16 of custom data per tree.
