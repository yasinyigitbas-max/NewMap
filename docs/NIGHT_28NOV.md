# Night of 28 Nov: bugs, phone performance, the look (branch `claude/night-28nov`)

Yasin's words: "squash the bugs and give me a much more performant and bug free game by the morning WITHOUT REDUCING
THE VISUAL FIDELITY ... work in your own branch and don't break the game". Everything below is on
`claude/night-28nov` (based on `main` 69fd34a98), tested on the PC with the phone's physics (Jolt on its own thread)
and on the Redmi (connected by cable all night).

## How the phone was tested without hands
The Redmi refuses adb taps, so the app now plays the game by itself: `phone_rig.sh run NAME --autoplay`
(`tools/city/rig/autoplay.gd`): New game, 25 s walking (turns where it gets stuck), back into the start car, 20 s
driving, out, a traffic car taken twice. Every check prints `RIG auto ok / FAIL`, and each phase prints its frame
times and the cost of every system (`perf_marks.h`, now including the traversal's parts). Result files:
`map_dc/coronado/city_kit/review/phone/auto*.txt` (kept local, not pushed).

## Your list
| You saw | Cause | Fixed in |
|---|---|---|
| old NPCs among the new ones, near and far | the far crowd was still the old figures; near, the new bodies were 12 (8 men, 4 women places): the 5th woman nearby was an old figure; a body not ready showed the old figure | no old figure is drawn anywhere; 18 new bodies; no traffic cyclists (their riders are old figures); only seen people block you |
| hijack: a second car over the first, an old driver in it | one tap was read twice (the touch and Godot's mouse made from it), so the car was taken twice | taps read once; a car cannot be taken twice |
| textures not loading while driving | in a car the player node stayed visible where he got in; the streamer follows the camera only while he is hidden | hidden in a car again |
| your character appearing out of the car | (most likely) the double hijack: two cars, his pose copied from one, the camera on the other. Measured on the phone: 0 frames over 2 m from the seat, at every speed | as above |
| missing terrain | (most likely) the same streaming bug: driving, only the far ground loaded | as above; not seen on foot |
| empty stores | the export left out `interiors/builtin/builtin_glass.tres` (the damage system's glass): every shop room failed to load on the phone | export_presets.cfg |
| props floating in the air | the 21 Nov shop trims swapped tall buildings for 2-storey ones; the roof units, terrace furniture and wall ACs of the two prop overlays (d_cc, d_pilot) stayed at the old heights | superchecker on both (only props in the air): 599 removed, 42 set down; city rebaked |
| the move buttons over GAS / BRAKE | the traversal's buttons stayed on in a car | hidden in a car; on foot moved clear of the HUD's Use box |

## Found on the way (system by system)
- Crash at the start of a new game on the phone (build-28nov-0101): fixed before the night (traversal code read the
  physics world outside the physics step).
- Touch: the map's tap fired twice (the second undid the first); phone apps opened twice and opened while scrolling;
  a drag that began on a HUD box turned the camera; panning the map while driving steered the car; a finger held
  while getting into a car / pausing stayed held; the bike's pedal stayed held after getting off.
- Damage on the phone: car impacts and punches never reached the damage system (its ray ran outside the physics
  step): no scrape marks on the real wall, wrong sparks and sounds.
- The game opened the old test laps when downloaded (fixed before the night).

## Performance (the Redmi)
- The phone is held by the CPU, not the GPU (GPU ~15 ms a frame walking).
- The new bodies' physics was the cost: 25 ms a frame walking, 94 ms in the worst stretch; 70 % of it one probe
  (`_find_squeeze`, 6-20 rays a tick per person). One box query now skips the rays in open space, with the same result:
  squeeze 5.7 -> 2.4 ms a frame walking, 20.3 -> 5.1 ms in the worst stretch.
- A physics spiral (a long frame followed by 8 physics steps, which made the next frame long) held the game at 7.5 fps
  in a stretch: at most 4 steps a frame on the phone now.
- The crowd's new-body update runs once a frame, not on every physics step.
- The texture arrays were rebuilt (9 -> 11 ground layers): the bake's late-loading textures 29 -> 1, draws a little fewer.
- The streaming drive on the Redmi (`--plan=stream --probe`, the final build, upscaler on): 55.7 fps at 108, 210 and
  280 km/h, median frame 17.0 ms (the last recorded runs, pb3 / pb7_stream_life: 44-49 fps, median 19.5-25 ms).
  health.py still says FAIL: one 239 ms frame at the start of the first loop, 24-27 frames over 33 ms a loop, one
  teleport ready after 3.5 s (the gate is 3 s). The older runs failed it too (worst 473 ms).
- Autoplay walking: 21-23 ms a frame in most runs, 41 ms in the last (the phone at 31-33 C after hours of runs, and
  more people round him); the worst frame is now ~80 ms where it was 150 ms (the step cap).

## The look
- The sharpening upscaler (SGSR, your engine's patch) is on by default on the phone: +0.9 ms GPU, plainly sharper
  (`review/night_28nov/upscale_walk_crop_off_on.png`, left off, right on).

## Not done / to look at
- make_places.gd on today's bake gives far fewer bus stops (64, was 154), no swim spots and no cafe seats: the
  committed places.bin / streets.bin (21 Nov) were kept. Worth a look before the next places run.
- The traversal's bone fitting (feet, hands: `trav_mods`) costs 3-8 ms a frame on the phone; not touched.
- The phone frame time while walking is ~21 ms (about 47 fps), driving ~30 ms: better than before but not 60.

## Round 2 (Yasin's phone pictures, 28 Nov morning)
| You saw | Cause | Fix |
|---|---|---|
| bricks / floors turning to straight lines | a headless import rewrote `bld_color.png.import` with Godot's defaults: no mipmaps, no compression; the 2048 atlas sampled at full size at every distance aliases into streaks | restored (committed settings); the new props_g / props_k atlases given mipmaps and compression too; anisotropic building normals; `phone_rig.sh export` refuses a kit texture without mipmaps |
| white squares and lines in the air | damage marks laid where a hit was asked when the rays met nothing (a car's jolt on a bump); the mark shader's multiply came out flat pale on the phone | marks only on a surface met; the shader blends normally |
| people climbing over shop doors, onto tables and stools | the player's traversal moves (step-up, vault, grab) ran for people; doors opened only for the player | no climbing moves for people; shop doors open for them too |
| people sitting on tables | the lab's bench sit (stand in front, sit back) used for shop and cafe seats: "in front" was the table | shop seats by the pose copy (the old figure's own seat) |
| walk 3-4 steps, stop, walk | on/off following at a pace faster than the walker | they follow the walker's own velocity and stop only when it stops |
| the wrist broken when aiming | the pistol 0.50 m from the face folded the arms up; the grip turned the hand 41 degrees down | 0.55 m and 20 degrees (side views compared) |
| menus too small on phones | fixed-pixel menus on a 1080 px screen | the 2D layer scaled to a 480 px short side (2.25x on the Redmi); the HUD keeps its size |
| "0.0 m/s" under the money box | the rig's own debug line | hidden in the game |

## Holes in the ground (found, NOT filled)
A scan of every piece's ground on a 0.5 m grid (`scratchpad/holes.py`, from the superchecker dumps) found 179 places
on the island with no ground, 4,488 m2 in all. Filling them means new ground in locked, hand-made pieces: Yasin's call.
The biggest:
- a whole empty block, 40 x 40 m at x 353..393, z -740..-700, between n_apt_b1_7th and n_apt_b1_be
- strips 1-5 m wide where the fl_*_1 fill pieces meet the s_rg_se streets (z 355-364, x -580..328), and along z 0..100
  (x 579..1420: f_se, fl_2_0 .. fl_7_0)
- 192 m2 at (-270, -642) by v_nw; 40 m2 at (-222, -622)
- the west edge seams at x ~ -985 (z -1275, -983..-900, 9..155, and z 190 x -980..-809)
- seams round s_civ and the stadium (x -100..-50, x ~ -305, z -591..-500); 62 m2 at z ~ -209.5 (j_am_9th, n_w_c9/c11)
- two 53 m2 holes at the ferry landing (334 and 366, -1616.5)
