# New trees for Coronado: brief for the artist (19 Nov 2026)

The old trees are being replaced (Yasin: they looked too bad). This page says what the new ones must be so that they
look good AND the game stays at 60 fps on the target phone. It adds to the kit's general rules in
`assets/coronado_kit/SPEC.md` (read sections 1-5 there too); where this page is stricter, this page wins.

## Why trees need their own brief
The game runs on Android phones; the test phone is a Redmi (Mali-G610 GPU). On 19 Nov we measured on that phone what each
kind of object costs to draw (`docs/DRAW_CENSUS.md`). **Trees and plants are the most expensive thing in the city.** In
the densest street, hiding them saved 27 % of the graphics time, more than all the buildings near the camera, and more
than the sun's shadows. About 40 % of the trees' cost comes from cut-out leaves (leaf cards with see-through gaps):
the same trees drawn as solid cards were that much cheaper. The rest is how many leaf surfaces lie on top of each other
on the screen.

So the number of triangles matters least. What matters is **how many pixels of see-through leaf card the screen gets,
layered how many times over**. A tree that looks full with few, well-placed cards wins over one built of many small
cards.

## The rules

### 1. Crown build: solid inside, cut-out only at the edge
- Build every crown as a **solid inner volume** (closed, opaque, no alpha: a rough blob of the crown's mass, leaf-coloured,
  normal-mapped) with **cut-out leaf cards only round its outside**, where the silhouette is. The cards may overlap the
  solid core, but no card should lie fully inside it (it would never be seen and still costs).
- The solid core must be on its own part of the mesh with an **alpha of 1 everywhere in its texture region**, so the
  game can draw it without cut-out cost.
- From any side, a line of sight through the crown should cross **at most 2-3 cut-out cards** before it hits the core or
  leaves the tree. Avoid "card stacks": many cards behind each other in the same direction.
- **Tight cards:** trim every leaf card to its leaves. No more than about 30 % of a card's area may be empty
  (transparent). A big quad with a small cluster in the middle costs the whole quad.
- Prefer **fewer, larger leaf clusters per card** over many small cards.
- Palms: fronds are cards by nature. Keep fronds as single strips (no doubled-up layers), trunk solid.

### 2. Budgets per tree (maximums, aim lower)
| Kind | Near (0-60 m) | Mid (60-220 m) | Far (220 m +) |
|---|---|---|---|
| Street / park tree (crown 5-12 m) | 2,500 triangles | 800 | 2 (one card) |
| Palm | 1,500 | 500 | 2 |
| Yard tree, Norfolk pine | 2,000 | 600 | 2 |
| Shrub, agave, bird-of-paradise, bougainvillea | 300-500 | none | none |

Besides triangles, per model:
- **Cut-out leaf card area (near):** at most about 2.5 times the crown's own outline seen from the side (the sum of all
  card areas, not counting the solid core). Report the number per model.
- **Mid tier:** the same crown with about a third of the cards and the solid core simplified; leaf cards bigger, never
  smaller than on the near tier. Colour + normal map is fine (the game measured that the mid tier's shader detail costs
  almost nothing); the saving that counts is FEWER cut-out cards.
- **Far tier:** one camera-facing card with the tree painted on it, from the same atlas page as the tree (see 4).
- Shrubs and other small plants (under 2.5 m) have no mid or far tier.

### 3. One mesh, one material, one atlas per tier
- Each tier of each tree is **one mesh with one material** (one surface). Bark, core and leaves all come from the same
  atlas page. A second material doubles the tree's draws and the game cannot batch it with the other trees.
- File names as the kit has them: `<kind>_<species>_<variant>_normal_near.glb`, `..._normal_mid.glb`,
  `..._normal_far.glb`, and the collision `..._col.glb` (a simple trunk shape). Add the entry to
  `assets/coronado_kit/foliage/manifest_foliage.json` like the existing ones (regions, class, budget, tier triangles,
  footprint, height, atlas, alpha MASK).

### 4. Textures
- Trees use the four plant atlas pages (`trees_palms`, `trees_broadleaf`, `trees_conifer`, `trees_shrubs`), **1024 x
  1024 each**, colour + normal. A new tree must fit on one of them (the game stacks the pages into one texture array;
  a fifth page is possible but costs memory: ask first). Bark regions 512 x 512 at most.
- **Ambient occlusion baked into the colour:** darker towards the inside of the crown and under it, lighter at the tips.
  This is most of what makes a card tree look like a tree and not a pile of paper.
- **Alpha:** a clean mask (0 or 1, alpha test at 0.5). The leaf edges must hold their shape when the texture is shrunk
  (mipmaps): leaves clustered, not single thin leaves with gaps between them. The game thickens distant leaves a little,
  but cannot rescue texture that is mostly gaps.
- The far card's painting also goes on the tree's own page (it uses the same texture).
- Total memory for all trees and plants: 16 MB after compression (SPEC section 3).

### 5. How it must look (where the old trees failed)
- **Normals pointing out of the crown:** set the leaf cards' and the core's vertex normals to point outwards from the
  crown's centre (a sphere or ellipsoid round the crown), not the card's own flat normal. Then the crown is lit as one
  round mass (bright on the sun side, darker on the other) instead of every card flashing. This one step changes the
  look most.
- Silhouette first: the outline against the sky must read as the species from 60-200 m. Check the mid tier's outline
  against the near one: no jump at 60 m.
- Colour variation inside a crown (younger lighter leaves at the tips, darker inside) and between the two or three
  variants of a species (a, b, c: different shape AND slightly different colour).
- Trunk and main branches visible at the bottom of the crown; bark not a flat colour.
- Real Coronado species and sizes (jacaranda, coral tree, ficus, magnolia, eucalyptus, Torrey and Norfolk pine, the
  palms): reference photos per species, in the delivery.

### 6. How the game uses the model (keep these, or wind and switching break)
- **Pivot at the foot of the trunk, on the ground, Y up, 1 unit = 1 metre.** The game measures the distance to the tree
  from the pivot and sways the crown by height above it.
- **Wind:** the game bends the tree by height above the pivot (full bend at about 8 m up) and flutters the leaves by
  their distance from the trunk. So: the trunk stands on the pivot, the crown sits above, leaves are away from the trunk
  axis. Nothing to paint for wind; just do not put leaf cards at ground level or inside the trunk.
- **Shadows:** only the near tier casts a sun shadow (within 50 m). The solid core also makes the shadow cheaper and
  fuller: the cut-out cards are drawn into the shadow map too.
- The game merges many trees into one batch (it already does): that saves CPU, not GPU. It does NOT make a heavy tree
  cheaper. Only fewer see-through pixels do.

### 7. Delivery and checks
Per tree, a table: triangles per tier; cut-out card area and solid core area (square metres) for near and mid; the
atlas page and regions used; footprint, height; a side picture of each tier, and one with the near tier's cards shown
in a flat colour (so the card layering can be judged).

We then put the new trees into the city and measure them on the phone the same way the old ones were measured
(`tools/city/rig/rig.gd --plan=census`, the states `hide_plants` and `plants_opaque`, before and after). A tree that
makes the city slower than the old one did, for the same street, goes back. The goal: **the new trees cost at most what
the old ones cost (better: half), and look clearly better.**
