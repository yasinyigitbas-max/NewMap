# The east shore beyond the ring (20 Nov): grass, then sand, then the sea

Yasin: "FILL THAT RED AREA WITH GRASS > SAND AND BEYOND IT SHOULD BE THE SEA, PUT LOTS OF RELEVANT PROPS IN THAT AREA,
MAKE THE SEA SAND CONNECTION SEAMLESS AND BUBBLY LIKE THE WATERFRONT AND AROUND THE ISLAND". The red area: all land
between the ring road's east edge and the sea, u ~660..1460, v -1700..0 (picture OUT/fill/empty_left.png, 1 px = 1 m,
x = u + 420, y = v + 1620; red = land with no piece). Everything in BUILD_GUIDE.md applies (read it whole), plus:

## The land and the water (read-only: no land writes)
- The terrain already falls to the sea here: the 0 m line runs from about u 700, v -1650 to u 1060, v -1200, u 1300,
  v -800, u 1400, v -400 to u 1450, v 0 (terrain_grid.npz, 4 m). Do NOT write land.
- The sea (tools/city/look/sea.gd) is a mesh at 0 m reaching 25 m in under the land; the foam strip x_shore_foam
  (locked; zoning/shore_foam.json, chunks along this whole shore, foam shader shaders/shore_foam.gdshader) lies on the
  0 m line. SEAMLESS = your sand follows the land EXACTLY near the water: the +5 cm over the land eases to 0 within 10 m
  of the 0 m line, and the sand goes on UNDER the water, following the land, to 25 m past the 0 m line (like f_sw: "the
  sand slopes into the water and on under it, the shore line moves with the slope, no hard edge"). Then the sea cuts
  your sand exactly where the foam lies. Verify: the 0 m contour of your ground within 0.3 m of shore_foam.json's line.
- Grass > sand: grass (a park band) from the ring's edge; the grass turns to sand along a soft, curving line (not
  straight, a 3-6 m blend / a dune edge with iceplant and dune grass patches), sand down into the water. Width of grass
  and sand follows the land: grass where the land is above ~2.5 m, sand below (so where the land is a hill the grass
  runs further out; where it is low the beach is wide). Use the kit's sand / grass ground materials the waterfront and
  f_sw use.
- Ground triangles: soft ground at a 2-4 m grid, finer only at the paths, pads and the water's edge; each piece under
  ~40k ground triangles: split your area into pieces of about 250-350 m.

## What goes here (planner: who comes, from where)
People come from the city across the ring (on foot at existing crossings / junction corners, by car only to car parks
reached from EXISTING street aprons or the existing roads beyond the ring; never a new driveway into a street piece).
Beach park: a promenade path along the grass/sand edge, beach accesses (paths + outdoor showers + bike racks + bins at
each), lifeguard towers facing the water every ~200-300 m, umbrellas and towels where people sit, volleyball courts,
kayak / paddle board racks, fire rings, picnic tables and BBQ grills on the grass, benches facing the sea, restroom /
snack kiosk buildings (their doors get rooms: kiosk, cafe), a few lookouts on the high ground, life rings, signage,
lamps along the promenade, dog-beach fence at one end, a small car park or two. Footpaths worn across the sand from each
access to the water. Lots of props, each with its reason; no wear on sand except footpaths; oil only in car parks.
Trees: palms / clumps by docs/TREE_PLAN.md (parks rule) as hand lists, never on sand below the dune line.

## Superchecker and the rest: as BUILD_GUIDE (delete when unsure, indoors and outdoors), exact colliders, verify.
