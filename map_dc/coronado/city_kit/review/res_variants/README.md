# Residential variants and the pilot area (18 Nov, branch claude/grow-residential) - for Yasin

NOT LOCKED. Nothing here is approved yet: you approve or change the variants before any wider growth.

## What a "variant" is here
The residential sample (the pilot's hill rows r_n / r_s) is two rows of houses on 10th St. The lattice city needs whole
blocks, so each variant is one QUADRANT of a junction (100 x 100 m), cut the way the residential streets already
expect: two alleys (the streets have alley mouths at 54-60 m and no driveways), houses facing both streets, garages on
the alleys, and the inside square (D) used for something else. A 200 m block is four quadrants of four different
junctions; every block in the pilot area holds all four variants, and no two quadrants facing each other across a
street are the same variant.

On the hill: each quadrant follows the same surface as the streets around it (it is fitted to the four junction pads
of its block), every lot is a level terrace at its sidewalk height (the sample's rule), with low retaining walls at
the property line (steps on the path), between neighbours and at the back. Alleys and parks follow the slope.

| Variant | Character | Lots | Inside square (D) | Kit pieces it brings in (previously unused in bold) |
|---|---|---|---|---|
| V1 village bungalows | the village's old core: craftsman and Victorian bungalows, Cape Cods, white pickets, low hedges, big jacarandas | 3 + 3 + 3 lots of 13-15 m | pocket playground: bark play area, two swings, slide, climbing frame, benches facing the play, picnic under sails, grill, fountain, planting beds | **craftsman_olive, craftsman_stucco, craftsman_large, victorian_blue, cape_grey, cape_white, ranch_porch**, **fence_gate_picket, fence_post_picket, fence_gate_privacy**, golf cart |
| V2 spanish hill | 1920s-30s Spanish Revival and Tudor on bigger lots, iron front fences, stucco garden walls, bougainvillea on the walls | 3 + 2 + 2 (B and C lots 20 m wide) | ranch houses fronting the alley with their own garages (the old big back lots, split later) | **spanish_peach, spanish_pink, spanish_large, spanish_small, tudor_brick, narrow_2sty_stucco_clay**, **garages single_stucco_clay**, **fence_stucco_wall, plant_bougainvillea_wall**, **golf_cart_blue** |
| V3 beach cottages | narrow 8 m lots near the ocean: two-storey narrow houses and beach cottages, vinyl rail fronts, weathered board fences, kayaks, beach umbrellas, boat trailers | 4 + 5 + 5 | a quiet green: Norfolk pine, Torrey pine, a small memorial with benches, picnic tables, the dog walkers' bin | **narrow_2sty_siding, narrow_cottage_siding, narrow_cottage_stucco_clay, beach_white**, **fence_vinyl_canal_rail, fence_post_vinyl, fence_weathered_board**, **tree_norfolk_pine_c, tree_torrey_pine_b**, kayak rack, boat trailer |
| V4 mid-century | 1950s-60s ranches, contemporaries and colonials, privet hedges or chain-link, flat-roof garages with solar panels | 3 + 3 + 3 | mid-century houses fronting the alley, garage doors to the lane | **ranch_pink, ranch_siding, hipranch_nogarage, contemporary_grey, contemporary_white, colonial_blue, colonial_white, mcm_shed, mcm_white, mcm_large**, **garages single_stucco_flat, prop_solar_panel_x3, hedge_privet_2m** |

On every house (all variants): porch light, house numbers (**prop_house_numbers_tile / _wood**), mailbox on the wall or
on a post (**prop_mailbox_post_metal**), downspouts at the corners (**prop_downspout_3m**), meters and the hose reel
on the side wall, an AC unit (**prop_ac_condenser_compact** too), sometimes a dish (**prop_satellite_dish_round**) or a
window unit; front bed with planting, lawn sprinklers or a dry lawn (owners who do not water); the back yard closed by
fences from the house walls (a side gate), a gate to the garage strip, the three bin carts inside it, patio, grill,
chairs, an arbor, a clothesline or a swing; now and then a house being redone (a roll-off dumpster on the pad, a
temporary fence, cones). Garages and carports on the alley with a car, a golf cart or a boat trailer beside them;
power poles along the alleys (off the asphalt) with a drop to each house (wires piece w_rv).

## Shops (outside and inside together)
Three corner shops among the houses, each with its own room (interiors/rooms/rooms_res.gd), designed as quiet,
lived-in neighbourhood shops:
- **Hillside Books** (10th St x E Ave, in V1): a used bookshop, cases round the walls, one island, the owner's counter
  against the right wall, local history in the window, old maps on the walls.
- **Ridge Coffee** (9th St x G Ave, in V4, at the top of the ridge): the regulars' cafe, one booth, small tables in
  the window, pastry case and espresso machine, a self-serve fridge and the neighbourhood notice board.
- **Ocean Blvd Surf** (11th St x J Ave, in V3, a block from the beach): boards up the long wall, wetsuits and a
  changing room, the rental quiver, a beach cruiser in the window, ding-repair bench in the back room.
Houses have no rooms (the interiors rules make only shops walk-in). Say if you want one house as a sample.

## The pilot area
Six blocks between J, G, E and C Ave and 9th, 10th and 11th St (grid u -800..-200, v -200..200) on Country Club Ridge,
24 quadrant pieces `r_q_<junction>_<corner>` + the wires `w_rv`. Why there: the largest stretch of the residential
zone with plain 200 m residential blocks on every side (no ring road, no 250 m pitch, no other zone inside); every
street round it is already built; it carries the zoning map's hill (blocks rise 0-8 m), so the sloped variants are
tested for real; 10th St runs straight into it from the pilot. Bake cells (200 m): x -4..-2, z -1..0 (cell_-4_-1,
cell_-3_-1, cell_-2_-1, cell_-4_0, cell_-3_0, cell_-2_0).

## Pictures (this folder)
`V*_air / street / side / alley / inside / front`: each variant on its own quadrant (V1 = r_q_m400_0_se, V1b =
r_q_m600_200_nw on the steepest slope, V2 = r_q_m600_0_se, V3 = r_q_m800_200_ne, V4 = r_q_m600_m200_se); `shop_*`: the
three shops from the street and from inside, by day and in the evening. Cloud preview: no shadows, and the weathered
building shader draws about 40 % too dark here; colours are not final.
