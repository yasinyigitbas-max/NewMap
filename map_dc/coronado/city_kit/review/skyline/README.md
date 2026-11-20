# The skyline ring: San Diego round the horizon (20 Nov 2026)

Yasin: "PLACE FLAT CARD ACCURATE VIEWS OF SAN DIEGO TO ALL FOUR SIDES, WHATEVER IS ACTUALLY VISIBLE WHEN LOOKED TOWARD
THAT DIRECTION FROM THE ISLAND, FLATCARDS SHOULD BE ALWAYS DISPLAYED, IMMUNE TO THE LOD, EVER VISIBLE".

## Files
| File | What |
|---|---|
| `tools/city/look/make_skyline.py` | paints the cards (Python, numpy + Pillow) from the data below; no photograph used |
| `map_dc/coronado/city_kit/skyline/landmarks.json` | every landmark with its real position and height, and the source of each |
| `map_dc/coronado/city_kit/skyline/skyline_day.png` | the cards, 6144 x 256 RGBA: rows 0-127 the NEAR ring, rows 128-255 the FAR ring; wraps round 360 deg |
| `map_dc/coronado/city_kit/skyline/skyline_lights.png` | where lights shine at night, 3072 x 128, one channel |
| `map_dc/coronado/city_kit/skyline/skyline.json` | the frame, the near ring's radius by direction, the 3D boxes (bridge, Coronado Shores) |
| `tools/city/look/skyline.gd` + `skyline.gdshader` | builds the one mesh and draws it |
| `tools/city/bake/city_stream.gd` | adds it next to the far world (export `skyline`, on by default): wherever the city is drawn |
| `tools/city/look/look.gd` | `_apply` tints it to the hour's haze and turns its lights on at night |
| `atlas_preview.png` (here) | the whole painted strip over a plain sky; shots `day/`, `night/` (here) |

Re-paint after a change of the data: `python3 tools/city/look/make_skyline.py` (10 s), then Godot's import.

## Orientation (how the map sits on the real compass)
- The game world (`map_dc/roads/lane_graph.json` "meta"): x east, z south, metres from 32.7157 N 117.1611 W.
- The city kit's frame (`tools/city/pilot/zoning/grid.py`, `integrate.py`): origin Amber x 10th = world (-1757, 3296)
  = 32.6859 N 117.1799 W, which is the real Orange Ave x 10th St in Coronado (Amber is Orange Ave). +Z (v) runs along
  Amber toward SSW, +X (u) along 10th toward ESE: grid -Z points to true bearing 26.40 deg, +X to 116.40 deg.
- So **true north is 26.4 deg anticlockwise of -Z** seen from above (the notes' "north is -v" is 26 deg off). A camera yaw
  in the rig / look_shots (0 = -Z, 90 = +X) looks to bearing yaw + 26.4: true N = yaw -26.4, E = 63.6, S = 153.6, W = 243.6.
- Checked against the game terrain (`terrain/data_citykit/class.r8z`, row 0 north): North Island's runways come out at
  true 122 / 194 deg, the published headings of NZY 11/29 and 18/36 (290 / 180 magnetic + 11 deg declination). The
  bridge approach the kit already has (s_br_appr_6, grid 1089,-911) converts to 32.6889 N 117.1651 W, at the real
  Coronado toll plaza.
- The cards are painted as seen from C = grid (0, -600) (Orange Ave at 7th, 32.6908 N 117.1770 W, the middle of the built
  city), eye 6 m above the sea.

## What each direction shows (true bearing from C, distance, height above the horizon)
- **North-north-east, 0-50 deg: downtown San Diego across the bay**, 2.2-3.6 km. The 50 tallest towers at their real
  positions and heights (One America Plaza 152 m at 15.8 deg / 2.9 km, 2.9 deg high; Symphony Towers 152 m at 30.6 deg;
  Manchester Grand Hyatt 151 m at 22.7 deg, 3.8 deg high; Electra, Pacific Gate, Pinnacle on the Park I + II at 49.5 deg,
  Emerald Plaza, the Harbor Club twins, Marriott Marquis, Hilton Bayfront ...), crowns roughly after the real ones
  (One America's pyramid, Symphony's arch, Electra's spire), red aviation lights on the tallest, windows lit at night.
  In front of them the low bayfront; behind them the Bankers Hill / Hillcrest / Golden Hill mesas (100-110 m at 5-8 km)
  with houses, Mission Hills and Clairemont to the north (340-360 deg), Mount Soledad 251 m (339 deg, 17.7 km, 0.7 deg).
- **North-east to east, 50-110 deg: the bridge, Barrio Logan, the inland mountains.** The San Diego-Coronado Bridge as a
  3D model at its real place (below); the NASSCO / BAE shipyards with gantry cranes and ships; the Naval Base's grey
  ships at 32nd St (115 deg, 5.4 km); behind, the mountains: Cowles 486 m (45 deg, 19 km), Mount Helix (65 deg),
  El Cajon Mtn and Viejas (54 / 65 deg, ~40 km), Cuyamaca Peak 1,985 m (62 deg, 60 km, 1.6 deg), the Laguna Mountains
  (73 deg, 74 km), San Miguel Mountain 783 m (88 deg, 22.5 km, 1.9 deg: the big cone), Lyons Peak (88 deg, 39 km).
- **East-south-east to south, 110-180 deg: Chula Vista, Otay, Tijuana.** National City, Chula Vista, Eastlake on their
  mesas (lights at night); Mother Miguel, the Jamul Mountains, Otay Mountain 1,088 m (109 deg, 33 km, 1.8 deg), the San
  Ysidro Mountains, Tecate Peak (103 deg, 54 km); Otay Mesa; Imperial Beach low on the water (162 deg, 13 km); Tijuana
  on its hills (130-150 deg, 20-26 km) with the twin Torres de Agua Caliente, Cerro Colorado, the coastal hills toward
  Rosarito (156-159 deg). Coronado Shores' ten towers (48 m, k) along the beach south-east of the Hotel del, as 3D boxes.
- **South-south-west, 180-240 deg: open Pacific** with the Islas Coronado (Mexico) low on the horizon at 192-202 deg,
  31 km: South island 180 m comes out 0.19 deg above the sea after the earth's curve, North island 0.13 deg.
- **West to north-west, 244-330 deg: Point Loma** across the bay, 6.3-8 km: the ridge (crest 88-129 m) from its south
  tip (244 deg) round to Loma Portal (330 deg), about 1 deg high, the Old Point Loma Lighthouse on top at 251 deg /
  6.3 km (1.2 deg).
- **In front of Point Loma's north half, 285-340 deg: North Island** (the Navy air station beyond the map): one aircraft
  carrier at the deep-water piers (315 deg, 1.9 km, island 62 m), hangars, the control tower; the airport and Harbor
  Island low beyond.
- Below the horizon all round: the sea from where the game's sea ends (camera far 900 m) to the horizon, coloured like
  that sea's far edge (mostly haze); above the horizon a haze band fading out by +3.5 deg into the sky.

## How it is drawn (one mesh, one material, ONE draw)
- **FAR ring** (mountains, mesas, Tijuana, islands, sea, haze band): unit directions, the camera's position ignored
  (they are 10-75 km away; walking the island moves them < 3 deg at 33 km).
- **NEAR ring** (downtown, shipyards, North Island, Point Loma): vertices on a ring whose radius per direction is the
  real distance of what is painted there (2.0-6.4 km, `skyline.json` "ring"), looked at from the real camera (its offset
  from C capped at 1.6 km, and eased back to C's view within 600 m of the ring), so they shift with parallax like the real
  ones: downtown grows and turns as you go north.
- **SOLIDS** (the bridge and Coronado Shores, 0.2-3 km from parts of the island: no card can stand there): plain boxes
  at their true places (1,170 triangles): the bridge's deck as a smooth curve through the real curve (blue box girders,
  white rail with lights, 61-64 m over the channel, a tapered pier every 120 m) starting where the kit's own approach
  `s_br_appr_6` ends (grid 1089,-911, 7 m) and landing at I-5 in Barrio Logan.
- Never culled, never faded: custom AABB of 200 km round the origin (always holds the camera), extra cull margin 16 km,
  no visibility range, no LOD tier, no shadow casting, no occlusion culling, top-level node not in any cell.
- Never clipped: the vertex shader writes the rings at ndc depth 1e-9 (reverse-Z: the sky and the far plane are 0), so
  every surface of the city, the far world and the sea wins the depth test and the cards still cover the sky; camera.far
  (900 m) cannot cut them. The solids keep their true depth inside the far plane (so the sea and the city sort with them
  like with any object) and go to 5e-9..1e-7 beyond it.
- Unshaded, `fog_disabled`: the haze is painted in (1 - exp(-d / 25 km) toward the look's day haze), and the shader
  tints it to the look's haze of the hour (`tint` = haze now / day haze, set by look.gd `_apply`), adds a little more
  haze for thicker looks (`haze_more`, from the look's fog density: day +0.18, overcast +0.4) and adds the night lights
  (`lights` = the look's lights 0..1). Without the look it follows the streamer's `ck_night` itself.
- Alpha blended, drawn first of the see-through things (render priority -128), so lamp halos stay in front.
- No seams: the ring is one strip whose texture wraps (u 0..1 over 360 deg, repeat), painted wrap-round; the near and
  far halves of the atlas are kept apart by clear rows (mip maps).

## What it costs
- 1 draw call, ~3,300 triangles (rings 2,160 + solids 1,170), ~4,100 vertices, built once at start (a few ms).
- Textures: 6144 x 256 RGBA + 3072 x 128, VRAM-compressed (ETC2 on the phone, S3TC on the PC) with mip maps:
  **2.10 MB + 0.26 MB = 2.36 MB** of graphics memory. skyline.json 71 KB.
- Per pixel only where the ring shows (above the horizon behind open views, a strip a few degrees high): 2 texture
  reads and a few steps, no lights, no fog. Not measured on the phone (no phone in this session).

## What is approximate (say this to Yasin)
- From the sources: the 50 towers (heights, positions), San Miguel, Otay, Cuyamaca, the islands, the bridge's length /
  clearance / curve / centre. **From Claude's own knowledge ("k" in landmarks.json): every other summit, the mesas,
  Point Loma's crest heights, the bridge's points between its ends, the shipyards and ships, the carrier and hangars,
  Coronado Shores**; positions good to a few hundred metres, heights to tens of metres.
- Building widths and colours are estimates; crowns are simplified; windows and lit windows are a pattern, not the real
  facades. Downtown's low and mid-rise mass (150 buildings, 12-80 m) is a deterministic scatter inside the real downtown
  area, not the real buildings.
- The mountains are smooth summits with long shoulders roughened by noise: the real ridgelines between the named peaks
  are not traced (no elevation data here); their heights above the horizon at the peaks are computed correctly.
- Parallax: the near ring is exact for things at the ring's radius in each direction; things nearer or farther than it
  in the same direction (Barrio Logan behind the bridge's line, Mission Hills behind the airport) shift a little wrong.
  The far ring has no parallax (fine at 10+ km).
- The ring cannot know what stands nearer than 900 m and is not built (the green preview plane in the shots is the
  rig's stand-in for unbuilt land): it draws the sea's colour below the horizon everywhere.
- The bridge is 3D but plain (no lamp posts, no toll plaza); seen from 200 m it is a clean blue box girder on slabs.
  It writes its true depth inside 900 m, so it is NOT immune to being hidden by nearer objects (correctly so).
- The carrier is always there (in reality one or two carriers are in port on most days, sometimes none).
- Shots were taken in the cloud preview (lavapipe, no shadows, sky reflection off); colours there differ a little from
  the phone. Not run on the phone; no aerial shot (the shot tool stands at eye height).
