# Ground and land

## The order the ground must fit (residential session, learned the hard way)
1. **The land** (`zoning/terrain_grid.npz`): the hills live INSIDE the blocks, not only on the streets. A block that
   only follows its four streets cuts the hilltop off (the residential zone: 45 of 65 quadrants under the land).
2. **The streets as built**: their real height profile, property line and alley mouths. Measure them
   (`tools/city/pilot/zoning/leg_measure.gd` -> `zoning/legs_measured.json`). Assuming the standard section put 32
   quadrants up to 1.6 m off their streets. Read each edge height just OUTSIDE the block, on the walk, never on the
   road (0.15 m lower) and never 1-2 m further out (the kerb return).
3. **The neighbours**: two blocks that touch share ONE line of heights. Check every shared seam with numbers (both
   blocks' heights along the line, worst step; aim under 2 cm).

## Inside a block
- Buildings stand level: a pad at the height of the middle of the front, eased into the slope over about 5 m. Two
  buildings with a gap between them: give the gap its own pad or it becomes a hump.
- Lots on a hill are level terraces at their frontage height, with retaining faces at the property line (steps on the
  path), between neighbours and at the back. Where two blocks' terraces meet mid-block at different heights there MUST
  be a retaining wall on the shared line: its absence is the 3,123 m of jumps in the residential zone.
- Garages follow the alley (cars drive straight in). Alleys and park lawns follow the surface; play and picnic pads are
  level with a low edge.
- Wall-hung props go with their building's pad; loose props with the ground under them.
- A fence or wall panel stands at the LOWEST ground along its length (-3 cm), or its downhill end floats.
- A skirt 0.3 m deep under every block edge, in the edge's own material: any residual gap shows a face, not grass.
- Do not merge floor cells into long runs: a long edge against two short cells is a T-joint and cracks on a slope.
- Planting strips 0.2-0.3 m inside the block edge leave a dark sliver of asphalt: pave it like the walk.
- Split ground triangles only where the slope bends (midpoint more than 3 cm off): a fixed 2 m grid made 18k triangles a
  block; adaptive gives 3-6k.

## Measuring (19 Nov)
- **Ground dump**: `tools/city/audit/ground_dump.gd` writes every piece's ground mesh. On the PC (2 GB card) the
  whole-city run dies after about 250 pieces and leaves cut-short `_v.bin` / `_i.bin` beside an old `.json`: dump in
  parts of 70 layout rows (a copy of the script with `--from` / `--to`), then join the parts and rebase the offsets.
  `lower_land_to_pieces.py` refuses a cut-short dump.
- **`tools/city/audit/ground_check.py OUT/ground`** (about 20 s): per family the m2 of piece ground under the land
  (buried, more than 30 cm, more than 1 m), floating edge cells beside empty land (hanging), and the metres of seam
  that jump between pieces. It is NOT in `checks.sh`; run it yourself after any new or changed piece.
- It does not compare buildings or props with their own block's ground. Nothing does yet.

## The land fix of 19 Nov (only the land changed)
`tools/city/pilot/zoning/lower_land_to_pieces.py OUT/ground [--fit] [--ease-from=<old grid>] [--out=<npz> | --write]`
1. **Lower**: where the land is not 5 cm under a growth piece's lowest ground, the land nodes those cells rest on go
   to 5 cm under the lowest piece ground within their 4 m reach. Never raises; sea nodes untouched. Only `grow_*`
   layout rows may ask: the road kit and the approved samples were fitted by `terrain.py` and stay.
2. **`--fit`**: every node a growth cell rests on is raised back toward the piece ground right at the node, never past
   what every piece cell it carries allows (roads included). Removes most floating edges.
3. **`--ease-from`**: the empty land between pieces moves by a harmonic field that equals the change on the piece
   nodes and is 0 at roads, samples, the sea and the box edge. No bank stays beside a block; the land still meets
   every road exactly.
4. `bake_game_terrain.py` writes `terrain/data_citykit/height.f32z` (about 4 minutes on the PC). On Windows it rewrites
   `meta.json` with CRLF line endings and identical content: restore that file.

Numbers, whole city, 18 Nov land -> after the fix: piece ground under the land 311,101 -> 308 m2 (the approved beach
block `f_sw`, left alone because its ground reaches under the sea level); floating edges 784 -> 187 m2; road ground
under the land 0 -> 0; banks over 1 m beside a block 58 -> 3; island lowest -0.99 m, highest 14.11 -> 14.10 m.
Still wrong: 3,123 m of jumps between residential blocks; 138 m2 of growth edge still floats where a lower terrace lies
within the same 4 m of land grid (the grid cannot follow a terrace edge closer than that).

## Do and do not
- Dry run first, into a copy. Read the per-family table: if a family you did not mean to touch asks for changes, stop.
  (The first map-wide dry run wanted 1,400 node changes round roads and would have pushed land under the sea beside the
  waterfront sample.)
- Before / after pictures with the land loaded: `TERRAIN=<json>` for `shots.gd`, with the `.f32` and `.u8` beside it.
- Do NOT run `tools/city/run/terrain.sh` or `terrain.py`: they re-solve the island from `zoning/piece_ground.npz`,
  which has no growth blocks, and reshape approved ground under other zones.
- `zoning/terrain.png` and `zoning/piece_ground.npz` are still the 18 Nov state.

## The shore at the waterfront (19 Nov)
`tools/city/pilot/zoning/waterfront_shore.py` (dry run by default) redrew the water line at the pier and the beach
block f_sw to two lines Yasin drew on a picture, and the foam strip with it. What it taught:
- A coast line drawn after a waterfront piece can cut across the piece's own water: look at every waterfront piece
  from straight above with the land AND the foam strip (`x_shore_foam`) loaded.
- The sand's edge under a foam strip must be ONE even slope through the water line. Where a node just seaward drops
  to a piece's sea bed, the edge becomes a saw of 4 m teeth with water showing between sand and foam.
- Foam joins: two strips add up to one only when they lie on the same line and one fades out over exactly the metres
  the other fades in (the shader fades over UV.x 0..0.03 and 0.97..1). Read the piece's own water-line formula
  (`f_sw.gd _shore_z`); do not assume a straight line.
- Never let the land rise above a piece's dry ground along the piece's own water line: it shows as pale lobes.
- `ground_check.py` now reports about 350 m2 of f_sw "under the land": that is the sand Yasin asked for, on purpose.
