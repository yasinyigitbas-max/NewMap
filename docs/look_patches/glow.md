# Patch note: the look's lamp glow inside the bake's own shader (look job 3)

Status: NOT applied. The look pack does it at run time instead: `tools/city/look/glow.gdshader` is put on each cell's
`glow_halo` / `glow_pool` node when the cell comes in (`look.gd attach_stream`, rig `--glow=1|0`). That swap is fine
for the test app; in the game it is simpler to have the change in `rt_glow.gdshader` itself, behind a global value.
The shaders in `map_dc/coronado/city_kit/shaders/` belong to the building-shader session (Yasin's brief), so this is
written down, not done.

## What to change in `map_dc/coronado/city_kit/shaders/rt/rt_glow.gdshader`
1. Add a global `ck_glow_style` (project.godot `[shader_globals]`, float, default 0 = today's look exactly):
   ```
   ck_glow_style={
   "type": "float",
   "value": 0.0
   }
   ```
2. In the shader: `global uniform float ck_glow_style;` and, when it is above 0.5, the vertex and fragment code of
   `tools/city/look/glow.gdshader` (copy its two function bodies into an `if (ck_glow_style > 0.5)` branch; the
   `else` branch is today's code unchanged). The uniforms of glow.gdshader become constants or plain uniforms with
   the same defaults.
3. The look sets `RenderingServer.global_shader_parameter_set(&"ck_glow_style", 1.0)`; then `look.gd`'s
   `attach_stream` / `_restyle` can go.

## Why
- The halo was a flat 1.5 m disc that turns white (colour x energy 1.6 clips) and cuts into the lamp head and the wall
  behind it with a hard line (it is drawn with the depth test and no depth fade).
- The pool lies 4 cm over the road: a raised pavement or a kerb hides the part over it with a hard straight edge.
- Both ignore the night haze (fog_disabled), so far lamps shine as bright as near ones.

## What it costs
- Per pixel: a few more arithmetic steps (three exp() in the halo, one in the pool), no texture read, the same
  additive blend. Per vertex: one distance, one exp.
- Pixels: halo quads 1.8 x wider (3.2 x their area); they are small. Pool quads 0.85 x (0.72 x their area); they are
  the big ones that overlap along every street, so the total is likely a little LESS than before. Not measured.
- A depth fade (soft edges where a quad meets geometry) was NOT used: it needs the depth texture, which in the Mobile
  renderer is an extra copy of the depth buffer every frame: a full-screen cost.
- No extra draw: still one MultiMesh per kind per cell, hidden by day.
