# Damage: what each thing does when hit (draft for Yasin, 25 Nov 2026)

Yasin's rule (25 Nov, contract section 5): **damage follows real-world logic.** "We shouldn't be
able to break off a hydrant by kicking it." Broken hydrants spray water. Human strength stays human.

Stage A (built now) gives **every surface marks, dust, sparks and sound**, and windows and doors their states. Nothing
else breaks yet. Stage B (after your go) is the table in part 2: each prop gets health and a behaviour.

## 1. How hard each kind of blow is (the `amount` sources pass)

| Kind | amount | Why |
|---|---|---|
| BULLET | 10 | A handgun bullet carries ~400-500 J into a small point: it holes glass, chips masonry, splinters wood, dents thin metal, does not move anything heavy. |
| PUNCH | 10 | A punch peaks around 1-3 kN for a few ms (~50-100 J at most). It scuffs, never breaks anything bolted. |
| KICK | 15 | A kick is roughly 1-2 kN, longer than a punch (more push). Enough to tip light loose things. |
| BLUNT | by weapon | A bat or a pipe: later, when there are weapons. |
| CAR | the car's change of speed (m/s) | `CityCar` already measures it (the same number that dents the car). 3 = a bump, 10 = a hard crash. |
| FALL | landing speed | Only marks soft ground (dirt, grass, sand) on a hard landing. |

What reaches a **window or a door** (part of the amount; stage A, built):

| | glass pane (hp 25, cracks at 15) | door leaf (hp 60) |
|---|---|---|
| bullet | 50 % (5 a shot): **holes 1, 2, cracks at the 3rd, breaks at the 5th** | 25 %: 24 shots (a bullet goes through a door, it does not take it off its hinges) |
| punch | 100 %: cracks at the 1st, breaks at the 3rd | 50 %: never in practice (12 punches) |
| kick | 100 % of 15: cracks at the 1st, breaks at the 2nd | 100 %: 4 kicks (kicking a door in is real) |
| car | 300 % | 300 % |

The numbers are a first guess: tell me if a window should take more or fewer shots.

## 2. Props (stage B: NOT built yet, for your review)

Two kinds of thing, as you said: **bolted or heavy metal** only marks under human blows and bullets; only a car above a
speed (higher for heavier and better anchored things) knocks it over or breaks it off. **Light or loose** things can be
kicked over; **brittle** things (glass, ceramic, thin plastic, wooden slats) break from bullets and repeated hits.

| Prop | Real thing | Punch / kick | Bullet | Car knocks it at | What happens | Why |
|---|---|---|---|---|---|---|
| Fire hydrant | cast iron, ~100-150 kg, bolted to the water main with a breakaway flange | mark, dull clang | dent, sparks | 25 km/h | breaks off at the flange; **a water column from the stump**, a spreading puddle, the sound; until put back | the flange is made to snap so the main is safe; a person cannot load it anywhere near that |
| Bollard (steel, set in concrete) | 30-100 kg, footing in concrete | mark | dent, sparks | 35 km/h (decorative); never (a crash bollard) | bends over at its foot | steel post in a footing: needs a car's energy |
| Street lamp | steel or aluminium pole on a breakaway base | mark | dent; the lamp head **goes dark** after 1 shot | 40 km/h | falls along the car's way; lamp dark | breakaway bases are made for cars; glass in the head breaks from a bullet |
| Parking meter | ~25 kg head on a post | mark | dent; the glass face cracks | 20 km/h | snaps at the post, coins | a light post, a heavy head |
| Mailbox post / sign post | thin steel post | mark | dent | 15 km/h | bends over | a thin post |
| Mailbox (USPS box) | ~120 kg, bolted | mark | dent | 30 km/h | tips over | heavy and bolted |
| Bin, fixed | metal, bolted | mark | dent | 20 km/h | tips over, rubbish | |
| Bin, loose (plastic wheelie bin) | ~15 kg | **2 kicks tip it over** | holes | 5 km/h | tips, rolls | light, loose |
| Newsbox | ~30 kg, loose | **3 kicks tip it over** | dent, the window cracks | 10 km/h | tips over, papers | loose metal box |
| Traffic cone | ~3 kg | **1 kick** sends it flying | hole | any touch | flies | a cone |
| Sign board (A-frame), chair, crate | light | **1 kick** | holes, splinters | any touch | falls / slides | light |
| Bench (wooden slats on iron) | slats on a bolted frame | mark | **a slat splinters after 3 shots**, drops after 6 | 25 km/h | slats splinter, the frame bends | wooden slats are brittle, the frame is not |
| Bus shelter glass panel | toughened glass | cracks at the 2nd kick, shatters at the 4th | cracks at 1, shatters at 2 | any | shatters into small cubes | toughened glass goes all at once |
| Fence panel (wood / picket) | slats on posts | a slat cracks at 4 kicks | splinters | 15 km/h | **the panel drops**, posts stay | |
| Fence (metal) | | mark | sparks | 25 km/h | bends | |
| Phone / electric box | steel cabinet | mark | dent, sparks | 30 km/h | dents, sparks | |
| **Big tree** | trunk > 25 cm | mark (bark) | bark scar | **never** | **the car stops against it, the tree shakes, leaves drop, the bark is scarred** | you said big trees never break |
| Small tree | trunk < 15 cm | nothing | bark scar | 30 km/h | **snaps**, falls the car's way | |
| Palm | fibrous, very flexible | nothing | fibre scar | 20 km/h bends, 60 km/h snaps | **bends and springs back**, snaps only at speed | palms bend in hurricanes and rarely snap |
| Hedge, bush | | leaves | leaves fly | any | leaves fly, it parts and springs back | |
| Building walls, roads, pavements | | scuff | **holes and chips (built: stage A)** | scrape, chips | marks only (no holes through walls: not in this job) | |

Every number above is a guess with a reason; change any of them and I will put your numbers in.

## 3. Rules every behaviour keeps (the contract)
- A standing breakable is on collision layer 3 (bit 4); once it falls it becomes debris on layer 7 (bit 64): nobody
  climbs or stands on debris. Window panes and door leaves are on layer 4 (bit 8) while intact or cracked.
- `obstacle_changed(box)` whenever something falls, a window or door breaks, or debris settles.
- `prop_broken(target_id, at, kind)` when a prop breaks.
- Draw calls: a prop that is knocked leaves its merged batch by being hidden in it (its instance scaled to nothing, as
  CityBreakables does today), and a pooled copy takes its place: no new batch per prop.
- State saved like the windows (`break_state`): a broken hydrant stays broken when you come back, until it is put back.
