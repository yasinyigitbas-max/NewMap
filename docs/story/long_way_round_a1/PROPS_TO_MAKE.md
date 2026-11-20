# Props to make for *The Long Way Round* (A1 edition)
Everything the script needs that the kit doesn't have yet, apart from the flat interior and the sketch panels. Each entry
says:
- what it is and where it's used;
- its size, look, parts and states;
- its budget, using the kit's own rules in `assets/coronado_kit/SPEC.md`: near / mid / far triangles, atlas pages,
  normal maps and AO baked on every near tier, a 512 px cap per prop, "real detail from references, never blocky".

Two things the kit already has, so they're off the list:
- **The taxi:** `vehicles/models` has a `taxi` model. Benny's car is that taxi with a few extras (section 5).
- **The temporary fence, cones and barricades** for the burned Fish House are kit props: `temp_fence_panel`,
  `barricade_type1`, `cone_28in`.

---

## 1. The Fish House: burned state
**Where it is:** The Fish House is the **left bay (x −11.7 to 1.0 m) of `com_spanish_arcade_block`** on the waterfront
(piece `n_wf_b1e`): a two-storey white stucco block with brown-shuttered upper windows and a long red-tile arcade roof on
square columns along the front. **Pier Poke & Tacos is the right bay of the same building**, and it must stay untouched.
So the burn is **local**: one bay, its stretch of arcade, and the upstairs windows above it.

**Used in:**
- M19 (the night of the fire, then the morning after);
- M21 (Gus in a wheelchair in front of it);
- M22 (the landing is next door);
- the epilogue (rebuilt).

### States
| State | When | What the player sees |
|---|---|---|
| **A: normal** | until M19 | the building as it is, plus the shop's sign |
| **B: burning** | M19 night | state C's geometry plus fire and smoke effects (particles and lights, made in the engine, not modelled), the awning section still up but glowing |
| **C: burned** | from M19 to the epilogue | the decals and props below |
| **D: rebuilt** | epilogue | state A, plus the new sign *THE FISH HOUSE – GUS & KAI* and fresh paint (a slightly whiter stucco tint on that bay only) |

### State C, outside (decals and overlay props, on this one building instance only)
1. **Soot plumes** (decals), one above each opening of the bay: the shop window(s) and the door. Black-brown, densest at
   the top edge of the opening, fanning **up and outward** in a tall soft triangle (about 1.5× the opening's width,
   reaching 2.5–3 m up, over the arcade roof's underside and onto the upper wall). Feathered edges, with darker streaks
   following the stucco texture. The two upstairs windows above the bay get a smaller plume each, coming out *under*
   their shutters (the fire reached the first floor through the ceiling). Shutters on those two windows: charred
   (a darker, blistered variant of the shutter colour, decal or material tint).
2. **The arcade underside** over the bay: the whole soffit black, with the tile edge above it cracked and smoked. Two
   columns in front of the bay: soot on the inner faces only (the faces toward the fire); their outer faces are just
   dirty.
3. **The fallen awning section** (a new prop, medium, ≤1,200 tris): the part of the red-tile arcade roof directly in
   front of the fryer has collapsed.
   - The building mesh keeps its roof; the prop sits **under** it as the fallen piece, and a dark decal on the
     building's roof slope reads as the hole. If you prefer, the hole can be real: a shader mask cuts a 2.5 × 1.5 m
     opening in the tile roof of this instance, the same way the car doors are masked in `car_paint.gdshader`.
   - The prop is a 2.5 × 1.5 m slab of tile roof lying at an angle: one end on the ground, the other leaning on the
     column base. Broken clay tiles hanging off the low end; charred rafters (4 × 2 inch timbers, black with silver-grey
     ash on the edges and orange-brown wood where cracks open) sticking out of the high end; a scatter of loose broken
     tiles (separate mini-meshes merged into the prop) on the ground around it.
4. **The shop window:** the glass is gone. Swap the window for a **jagged-edge glass cut-out** (a few shards still in
   the frame's corners, smoked brown-grey) or simply no glass, with the frame scorched. The door: open, hanging on one
   hinge, its glass gone, its push bar black.
5. **The sign:** *THE FISH HOUSE*, burned. The sign board is half black, two letters fallen off, so it reads
   **THE FI H HOU E**. One of the fallen letters (the S) lies on the ground in front, as a tiny prop (≤150 tris).
6. **Water and ash on the ground:** a dark-wet decal spreading from the door across the sidewalk (the fire hoses), with
   floating black ash flecks and a faint rainbow sheen at its edge; ash footprints leading out to the street.
7. **Kit props placed in front:** `temp_fence_panel` ×4 across the bay (the screen version), `cone_28in` ×2,
   `barricade_type1` ×1. **Yellow caution tape:** a new tiny prop, one straight tape run of 3 m (a single strip of
   two triangles with a repeating texture, *CAUTION – DO NOT ENTER*; it sags 10 cm in the middle), snapped between two
   fence panels and across the door.
8. **One flower bouquet and a hand-written card** taped to the fence (it appears from the morning after: the regulars
   care). Card text: *We love you Gus. — Brenda & Admiral*. Small prop ≤300 tris.

### State C, inside (the room `g_wfa_b1e__…the_fish_house` as a burned variant)
- **Walls and ceiling:** the room's own materials get a burn tint: black at the top fading to brown at waist height,
  clean-ish below the knees (heat rises; that's what real fire rooms look like). Do it with a vertical gradient on the
  room's materials, not by repainting every texture.
- **The fryer:** a new prop, medium (≤900 tris). A two-basket commercial deep fryer (stainless, 40 cm wide, 1.15 m tall
  with the backsplash), burst: its tank split open at a seam, the top bent up, oil burnt to a black glossy crust down
  its front and pooled on the floor, both baskets thrown, one on the floor. The normal state of the same fryer is
  needed for Acts 1–3 (M6, M7, M19 golden hour): **make both states from one model**, clean and burst.
- **Stools:** the six counter stools: two burned (seat foam gone, black frame), two knocked over, two upright and
  sooty. A material tint plus a "burned seat" variant mesh of the kit's stool (≤300 tris each).
- **The counter:** top blackened and blistered at the fryer end; the menu board above it warped and black, the
  printed menu half legible (*FISH TACOS $… / CLAM CHOWD…*).
- **Debris:** two piles of fallen ceiling (plasterboard sheets and insulation, medium ≤800 tris each) under the hole;
  broken plates; a burned chair; a soaked, blackened apron on a hook (Gus's).
- **The photo frame** is *not* in the room. Gus carried it out. It's in M19's hospital scene, and it's Kai's (section 7).
- **Light:** only daylight through the gone window and the roof hole, with dust in the light shafts.

---

## 2. Whitmore's model (the waterfront under glass)
**Used in:** M14 (the Villager Theatre gala set-up). The player must **notice** that The Fish House is missing from it.

**What it is:** an architect's presentation model of the waterfront, on a plinth, under a glass display case. It's
expensive, perfect and cold.

### Dimensions and parts
- **The plinth:** 2.4 m long × 1.2 m deep × 0.9 m high. A dark walnut-veneer box with a thin brass edge strip at the top.
  On the front face, a brushed-brass plaque (40 × 12 cm) engraved:
  **WHITMORE POINT – THE FUTURE OF CORONADO – A PRESTON WHITMORE DEVELOPMENT**.
- **The glass case:** 2.3 × 1.1 × 0.55 m, five panes (four sides and a lid), thin brass corner rails. One transparent
  material, kept to the five quads (overdraw on the phone).
- **The model inside, at 1:300 scale** (1 m of model = 300 m of town; the model covers about 690 × 330 m of
  waterfront):
  - **Ground and sea:** the base is the real waterfront's layout, simplified: the beach as warm sand-coloured flock, the
    sea as glossy dark-blue resin with a few white wave lines painted on, the streets as smooth grey, Pier St climbing up
    from the water.
  - **The pier and the Ferry Landing:** white miniature, recognisable by shape (the pier's T-head; the ferry landing's
    pavilion roof).
  - **The existing buildings around** (Casa del Mar Inn, the Bayview Inn, the holiday flats): **plain white blocks**,
    no windows, like a real architect's context model. This is important: the "old town" is drawn as blank white boxes.
  - **Whitmore's project** in the centre, in full detail and colour:
    - a 40-storey tower of blue-green glass, 0.42 m tall in the model (≈125 m), with a slender crown, on a podium of
      shops;
    - a marina of white yachts (tiny, about 3 cm each, 12 of them);
    - a lawn with lollipop trees (green foam balls on wire trunks);
    - tiny white people in pairs, walking;
    - two cars.
  - **Where The Fish House stands in reality, there is the tower's plaza.** Its square paving runs right over where the
    building should be. **A player who has worked at The Fish House should see in one look that their place is gone.**
    The game helps: the camera holds on the model (M14), and the block's real outline is drawn on the model's ground as
    a very faint dashed line (the architect's "existing to be demolished" mark), with a tiny printed label: *EXISTING
    STRUCTURE – TO BE REMOVED*.
- **Small extras on the plinth top, outside the case:** a stack of glossy brochures (with the same tower on the cover), a
  pair of white gloves, a tiny vase of white lilies (the hero's delivery).

### Budget
Large prop: near ≤2,500 tris, mid 30 %, far 20 (it's indoors and only seen close; a mid tier is still needed for the
theatre's wide shot).
- The tower and podium: about 600 tris.
- The yachts, trees, people and cars: cards, or very low-poly merged meshes, about 700 tris.
- The ground and sea: about 300 tris.
- The plinth and case: about 300 tris.
- **One 512 px texture** for the model's colours, plus the shared props page for the plinth wood and brass.

---

## 3. Mrs. Finch's radio (1970s Navy surplus radio set)
**Used in:**
- M15: on the wall photo only (a young Finch at a much bigger console);
- M21: Finch takes it out of a cupboard, and the hero repairs it;
- M22: it's on her table during the whole climax; we hear her through it, and cut to her at it.

**What it is:** an invented 1970s naval HF radio, receiver and transmitter in one cabinet. Do **not** copy a real model:
it's called **RT-74** in stencil on its front.

### Dimensions and look
- **The cabinet:** 48 cm wide × 30 cm tall × 35 cm deep. Grey-green crinkle-painted steel (the classic military "haze
  grey with a green cast"), rounded edges, four rubber feet, two folding chrome carry handles on the front corners.
- **The front panel** (the hero detail; it's seen close):
  - a **large horizontal tuning window** across the top half (30 × 8 cm), behind glass, showing a printed frequency
    scale (white numbers on black, 2.0 to 30.0 MHz) and a red needle that slides across it. **Back-lit amber** when the
    set is on;
  - **an analog S-meter** (a round window, 7 cm, with a black needle on a white arc scale labelled 1–9 and +20 +40);
  - **six knobs:**
    - a big main tuning knob (6 cm, knurled black bakelite with a finger dimple);
    - five smaller ones (VOLUME, RF GAIN, BAND, MODE, SQUELCH; white stencilled labels under each);
  - **four toggle switches** with chrome bat handles (POWER, LAMP, NB, TX), and a red jewel lamp above POWER;
  - **two jacks** (PHONES, MIC);
  - stencilled top-left: **RT-74**; bottom right, a riveted ID plate (aluminium, tiny engraved text, with a navy anchor
    logo);
  - wear: paint rubbed through to bare steel round the main knob and the handle grips, scratches, a coffee ring on top.
- **The back** (it matters for the repair): a removable rear panel held by six thumb screws. Behind it:
  - **four glass vacuum tubes** in sockets (each 3 cm across, 8–10 cm tall, silver getter tops; they glow faint orange
    when working);
  - one cartridge fuse in a clip;
  - two short loose wires with spade ends (the repair: put them back on their terminals);
  - dust everywhere inside, and one spider web.
- **Accessories** (separate meshes, so they can be handled):
  - **the hand microphone:** black, palm-size, with a push-to-talk bar on its side, on a black coiled cord (cord drawn
    as a modelled coil, about 1 m stretched), with a metal hang-up hook on the cabinet's side;
  - **headphones:** a big 1970s padded pair, black leatherette cups, a steel band, a straight cord;
  - **a dust cover:** grey canvas with a drawstring (for the cupboard state in M21).

### States
- **In the cupboard:** under the dust cover, with dust on the top faces (a material switch).
- **Repaired and off:** clean-ish, dial dark.
- **On:** the amber dial lit (emissive), the jewel lamp red, the tubes glowing (emissive) if the back is open, the needles
  movable by the game (the S-meter needle jumps when someone speaks; give both needles their own pivot).
- **Repair minigame needs:**
  - the rear panel as a separate mesh, with its six screws as separate tiny meshes;
  - each of the four tubes as its own mesh (one is dark and loose in its socket at the start);
  - the fuse and the two wires as separate meshes;
  - pivots for all of them.

### Budget
A medium prop at ≤1,200 tris for the cabinet with the front detail in the normal map; the accessories and the repair
parts ≤600 more. The props page; 512 px max. The front panel's printing (the scale and the stencils) needs a sharp
texture region: give the front panel its own 512 × 256 slot.

---

## 4. Marek's notebook and his gold pen
**Used in:**
- M7 (he writes the debt in it);
- M14 (he turns it round to show the interest);
- M17 (the player steals it from the Ocean Travel office desk);
- M18 (Finch decodes it on her kitchen table: close-ups of the pages).

### The notebook
- **Size:** a pocket notebook, 9 × 14 cm closed, 1.5 cm thick.
- **Cover:** black leather, soft and worn: rubbed brown at the corners and along the spine, a crease across the front
  where it's sat in a coat pocket for years. A black elastic band around it, a little stretched. A faded ribbon bookmark
  (dark red) hanging out of the bottom.
- **Pages:** cream, slightly yellowed at the edges; some pages with coffee-ring stains, one corner torn out.
- **Meshes:**
  - closed (≤150 tris);
  - open flat on a table (≤250 tris): two pages visible, with a slight curve toward the spine.
- **The page textures** for M18 (512 × 512 each, three spreads; the open mesh swaps between them):
  - **Spread 1 (round 1):** a grid of small hand-drawn symbols in blue ballpoint (about 15 different invented symbols:
    a circle with a dot, a triangle with a tail, two short bars and so on), each followed by numbers. Month names are
    symbols too. Written fast, slanting right.
  - **Spread 2 (round 2):** the same hand: a column of symbols and amounts with dollar figures circled, one symbol (for
    "W", Whitmore) repeated down the margin.
  - **Spread 3 (round 3):** one entry larger than the others, underlined twice: symbols for "July 4", "11", "12", "4",
    and a little drawing of a boat with a flag and a small cross next to it.
  - **The key** (Finch works it out; the UI shows the solved table): the symbol-to-number mapping must be consistent
    across the three spreads. **Make the symbol set and the key as a small table first**, before drawing the pages,
    so the puzzle can be built from it.
  - Also: one ordinary page with the hero's debt in the native script (M7) and a running total (5000 → 4800 → 5800).
    This page is not in code: Marek's private sums in his own language.

### The gold pen
- A heavy fountain-style pen, 14 cm, gold-plated with a black lacquer band at the cap; the gold worn to brass at the
  grip. A clip on the cap (it clips onto the notebook's elastic band). ≤200 tris.
- It's on the desk with the notebook in M17, and in Marek's hand in M7 and M14 (held like a cigarette between two
  fingers).

---

## 5. Two paint jobs (and Benny's extras)

### 5a. Benny's taxi (the existing `taxi` model)
The kit's `taxi` model is the base. Benny's car is one specific taxi in the world: a "hero" instance with:
- **The paint:** if the `taxi` model is a single livery, Benny's version is a **two-tone**: sun-yellow body
  (#F2C230) with a **leaf-green lower band** below the door line (#2E8B4F), the line between them a thin white pinstripe.
  On both front doors, in hand-painted white script with a black drop shadow: ***Benny's*** and under it, smaller, a
  phone number (invented: 619-555-0107).
- **Roof sign:** the taxi's roof light, with an ad on each side: **KBNY 88.1 – BENNY'S FAVOURITE**.
- **The dent:** the rear left door pushed in (about 4 cm deep, a soft crease from the handle backwards, paint cracked in
  the middle of it). Do it as a vertex offset on that door plus a decal, so the door can still open with the door
  shader.
- **Inside** (seen from the back seat in M1, M12):
  - **a hula-girl dashboard doll** (a new tiny prop, ≤300 tris): 12 cm tall, grass skirt, flower lei, arms up; she
    wobbles on a spring (give her a pivot at the ankles so the game can sway her);
  - wooden-bead seat cover on the driver's seat;
  - a pine-tree air freshener on the mirror;
  - a thermos and a family-size bag of chips on the passenger seat (M12);
  - an old camcorder on the dash (M12).
- **The number:** **07** on the rear fenders and on the roof light (it's the taxi with Bus 7's lucky number; it doesn't
  matter, Benny just likes it).

### 5b. The harbour patrol boat (the kit's `boat_express`)
The `boat_express` (the white T-top boat with a blue stripe and twin outboards) re-painted as the harbour patrol.
**Used in:** P1 (the rescue), M18 (at the Ferry Landing at dawn), M22 (the mayday and the rescue).
- **The hull:** light grey (#A7ADB0), satin, instead of white.
- **The band:** replace the thin blue stripe with a **wide navy band** (#1F2E4D, about 40 cm tall) along the hull at the
  stripe's height, with a thin white line above it. Do **not** use any real agency's diagonal racing stripe: keep it a
  plain horizontal band.
- **Lettering:** **HARBOR PATROL** in white block capitals inside the navy band on both sides, about 25 cm tall. The hull
  number **HP-3** on both sides of the bow, black, 30 cm tall.
- **On the T-top** (new small props, mounted on the existing frame):
  - **a light bar:** 1.2 m, two blue lenses and a white centre (emissive; the game flashes them);
  - **a searchlight:** a 30 cm round lamp on a yoke, with a handle at the back. **Separate mesh with its pivot at the
    yoke**, so it can sweep; the beam is a light and a cone effect in the engine.
- **Gear on deck:** two orange life rings with **HP-3** on them (one is thrown in P1: a separate mesh), a grey first-aid
  box, a coiled yellow throw line, and two fenders over the side.
- The seat cushions: dark grey instead of white. The wood trim stays.
- **Budget:** the same model, so the same tris; the livery is a new texture page variant of the boat's atlas regions
  (paint_navy, paint_white and so on are already regions on this model, so it's a recolour plus a lettering decal).

### 5c. The *Good Hope*'s name (the kit's `boat_troller`)
One decal, not a model:
- **GOOD HOPE** painted by hand on both sides of the bow, in white capitals, 20 cm tall, letters uneven, the paint flaking;
- a rust streak running down from the second O;
- the home port painted under it in the native script of the localisation (or left blank). Smaller.

---

## 6. The yard signs (M17)
**Used in:** M17, the container-yard stealth at the docks. **The signs are the level design**, so they must be readable
from about 8 m in the game's stealth view, at night, by a flashlight.

### Rules for all of them
- **A plain, bold sans-serif** (like the road-sign style), high contrast, nothing decorative. A beginner must be able to
  read them.
- **Weathered:** sun-faded, rust bleeding from the screw holes, one corner bent, dirt at the bottom edge.
- **Mounting:** each sign is a thin plate (2 cm with a bevel, so it has an edge in the flashlight) with two or four
  screws, mounted on a fence panel (`temp_fence_panel` or a yard fence), a container door, a door or a post. A post
  version (a galvanised square post, 2.2 m) for the free-standing ones.
- **The text should be a separate layer**: ideally the plate texture has no words, and the words are drawn by the game
  (Label3D or a text decal). Then the Word Fog and the translation tiers can work on signs exactly as on speech: a
  player who knows *ENTRY* sees it sharp, and a tap translates it. If baked text is easier, make each sign twice: with
  and without text.

### The signs
| Sign | Size | Look | Where |
|---|---|---|---|
| **NO ENTRY** | 60 × 40 cm | white plate, red border, red bold text; a red circle with a white bar above the words | on the yard's side gate (a guard behind it) |
| **STAFF ONLY** | 30 × 10 cm | brushed aluminium plate with black engraved text, on a door at eye height | on the unlocked door with the hi-vis vest inside |
| **DANGER – CRANE** | 60 × 45 cm | the industrial danger style: a black top band with a red oval and white **DANGER**, the white lower half with black text **CRANE OVERHEAD – KEEP CLEAR** and a pictogram of a hook over a figure | on a post under the dock crane's path |
| **WET FLOOR** | an A-frame, 30 × 60 cm, yellow plastic | a yellow folding floor sign with black **WET FLOOR** and the slipping-figure pictogram, on both faces. A small prop (≤300 tris), and it can fall over (it's knocked down if the player runs into it, which makes noise) | at the puddle by the office door |
| **NO SMOKING** | 30 × 30 cm | white plate, a red circle with a red diagonal bar over a black cigarette, **NO SMOKING** under it | on the office wall by the stairs (Dutch smokes right under it: the joke and the clue) |
| **PUSH / PULL** | 20 × 6 cm stickers | white text on black, or black on white, square-cornered; **PUSH** on one leaf and **PULL** on the other | the office's double door (the wrong one bangs) |
| **OCEAN TRAVEL** | 1.2 × 0.4 m | a cheap shop sign: a sun-bleached blue board with a white sailing-ship logo and **OCEAN TRAVEL – CRUISES – FLIGHTS – TOURS**, one letter faded | the front of the office (seen in M10 and M17) |

**Budget:** each sign ≤150 tris (a plate with a bevel); the A-frame ≤300. One shared 512 px sign sheet in the props page:
all the plates on one sheet, the text either on it or (better) drawn by the game.

---

## 7. Smaller story props (one line each)
These are tiny props the scenes rely on. They're cheap, and they're worth making properly, because the camera holds on
each one:
- **Gus's grandmother's photo frame:** a 20 × 25 cm wooden frame, the glass cracked across one corner, an old
  black-and-white photo of a woman in an apron outside a fish stall (M19, the epilogue). ≤200 tris.
- **The spare key on a fish keyring:** a brass key on a ring with a small blue enamel fish (M19). ≤150 tris.
- **Ruth's sunflower-seed bag:** a crumpled brown paper bag with a printed sunflower, a few seeds and shells by it on the
  desk (P2, M8, M16, the courthouse steps). ≤150 tris.
- **Rosa's pressed flower and note:** a flat dried flower and a lined paper note in pencil, inside the picture
  dictionary from city hall's free-books table. The book is a ≤300-tris prop with an open state (P2, M13).
- **The job card:** an index card on a corkboard with a hand-drawn fish and the words *HELP WANTED – THE FISH HOUSE – ASK
  FOR GUS – NO EXPERIENCE – NOT AFRAID OF FIRE* (M5). A texture on a card quad.
- **The number ticket and the counter screen at city hall:** a small paper ticket *41* and a red LED number screen above
  the counter, which the game can change (P2, M8). The screen is a box ≤100 tris with an emissive number.

## 8. City hall's interview dressing (P2: character creation and the controls tutorial)
P2 happens in the existing **City Hall Front Desk** room. The kit already has the waiting benches, office desks and
chairs, filing cabinets, the clothes rack (`clothes_rack`) and the changing booth with its mirror (`fitting_room`).
These are the only new things:
- **The coffee machine:** the tutorial's punch target (Beat 6). A free-standing office coffee machine on a side
  table: 40 × 45 × 60 cm, brushed steel and black plastic, a small display, three buttons, a cup slot with a drip
  tray, a hand-written note taped to it: *OUT OF ORDER (AGAIN)*. Small prop ≤600 tris.
  - **Three hit states** (the game plays them on the three punches): a dent on its side panel at each hit (a blend
    shape or three swapped side panels), the note flying off at the second.
  - At the third, it lights up and pours: an emissive display, a steam particle, a paper cup appearing in the slot (a
    tiny cup prop, ≤100 tris).
  - It needs to be a **punch target** for the combat code (the lock-on points at it).
- **A flag on a stand:** a pole 2.2 m with a gold finial, a weighted base, the US flag hanging folded on the pole (no
  wind indoors: it's a draped mesh, not cloth). Medium ≤800 tris.
- **The height-chart poster:** a 60 × 210 cm paper poster taped to the wall: metric and imperial lines, numbers every
  10 cm, a faint printed seal. A decal (one texture, 256 × 1024). It must line up with the real metres, because the
  height slider is set against it.
- **The number screen:** see section 7 (a red LED number over the counter, changed by the game: 39, 40, 41, 42).
- **The tickets:** a paper ticket dispenser on a post by the entrance (a red ticket roll, ≤300 tris), and the paper
  ticket *41* in the hero's hand (a card quad).
- **Two hand-written signs** on card, taped to the table and the rail: *FREE BOOKS* and *FREE CLOTHES* (decals).
- **The box of picture dictionaries** on the table: a cardboard box with five or six books standing in it (the books
  are the same ≤300-tris prop as Rosa's book).
- **The grey NAVY sweatshirt:** a clothing item for the character system, not a prop. Heather grey, crew neck, one size
  too big (the sleeves cover half the hands), **NAVY** in dark-blue block capitals across the chest. Worn by the hero
  and Omar in P2, and by the newcomer in the epilogue. The player can take it off at home (the wardrobe).
