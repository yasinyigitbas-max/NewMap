extends SceneTree
## Piece n_apt_b1_bw - apartment band fill, BLOCK 1 (B Ave - Adela Ave, 7th - 8th St), its WEST part: B Ave x 8th St.
## Layout row: pos [250, 6, -600], yaw 0 (the apartment sample's junction frame, so the seams with the locked a_ne
## line up exactly). Quadrant coordinates: u = east of B Ave's centre line, v = north of 7th St's centre line
## (sx = +1, sz = -1). Outline: u 9.2-100 (B Ave property line to the lot line with n_apt_b1_be), v 100-190.8 (the lot
## line with the sample's a_ne to 8th St's property line).
##
## LAND: flat. The land under it lies 6.10-6.17 m; B Ave and 8th St are built at pad 6.0 with the walk at 6.15, and
## a_ne's ground is 6.15. The whole piece is one level floor at the walk height (local 0.15): every edge meets its
## street walk and a_ne flush (0 cm by construction); the trial land fit lowers the land 5 cm under it.
##
## WHO LIVES HERE AND WHY IT LOOKS LIKE THIS (planner / architect / exterior designer):
## This corner is the OLDEST part of the apartment band: two-storey Spanish courts and white courts from the 1920s-30s,
## when B Ave was the streetcar line out of the centre, and two 1950s walk-ups that filled the gaps. Old buildings
## had no parking, so the tenants rent the lock-up garages built later along the alleys and park on the stalls
## behind. 8th St is the walk into the centre, so the corner has the two shops the street walks past every morning:
##  S1 corner (u 9.2-54, v 146-190.8): the BAKERY on the corner (bread and coffee on the way to work: a bench under
##     its window, a bike rack along its front, papers), a brick walk-up with a BARBER downstairs and a flat above,
##     the white court; a Spanish court on B Ave behind the bakery. Behind them the old courtyard the buildings share
##     (picnic table under a jacaranda, the clothesline, a bougainvillea bed on the court's back wall), closed by a
##     fence with a gate to the stalls; the bakery's and barber's bins in a CMU enclosure the truck reaches from the
##     alley.
##  S2 (u 9.2-54, v 100-140): two 1950s walk-ups on B Ave; behind them the families' play corner (swings and slide on
##     a bark pad, a bench facing it for the parent, a bin), stalls off the alley continuing a_ne's stall row.
##  S3w (u 60-100, v 146-190.8): a Spanish court and a small walk-up on 8th St; behind them the courts' CITRUS AND
##     HERB GARDEN (bark beds, an arbor with two chairs, a hose cart) - old tenants garden; stalls off the alley.
##  S4w (u 60-100, v 100-140): the LOCK-UP GARAGES row on the alley (rented by the courts), a garden-apartment wing
##     whose front windows look over a_ne's playground (eyes on the playground), its back yard with the clothesline
##     and grill, stalls along the u-alley.
## Alleys: v-alley u 54-60 (continues a_ne's to 8th St's apron at u 304-310 m), u-alley v 140-146 (B Ave's apron at
## v -740..-746 to the east). Poles on gravel pads at the alley edges, never on asphalt or a stall.
## Walk-in places (for the rooms pass, NOT built here): the bakery, the barber.
## Built once by its own script; a draft until Yasin has seen it. Never re-run after that.
const F := preload("res://tools/city/pilot/pieces/apt_fill_lib.gd")
const I := preload("res://tools/city/pilot/pieces/ind_lib.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const K := preload("res://tools/city/pilot/kit_lib.gd")
const NAME := "n_apt_b1_bw"
func _init() -> void: _run.call_deferred()

func _run() -> void:
	var sx := 1.0; var sz := -1.0
	var ctx := F.begin(NAME, sx, sz)
	var bl: Node3D = ctx.bl; var props: K.Props = ctx.props; var dec: K.Decals = ctx.dec
	var rr: RandomNumberGenerator = ctx.rr; var paints: Array = ctx.paints; var stalls: Array = ctx.stalls
	var poles: Array = ctx.poles; var blds: Array = ctx.blds
	# ---------------------------------------------------------------- alleys (ground first)
	F.alley(paints, props, dec, rr, sx, sz, false, 54.0, 100.0, 190.8, poles, [[132.0, 60.7], [172.5, 60.7]], NAN, [1])   # east edge: the west edge is all stalls
	F.alley(paints, props, dec, rr, sx, sz, true, 140.0, 9.2, 100.0, poles, [[15.0, 139.3], [63.0, 146.7]])   # where no fence or stall is
	if OS.get_environment("APT_GROUND_ONLY") == "1":
		F.finish(ctx, 9.2, 100.0, 100.0, 190.8); quit(); return

	# ================================================================ S1: the corner (u 9.2-54, v 146-190.8)
	# the bakery on the corner, 2.5 m back behind its own paved forecourt (its bench and rack stand there, the public
	# walk stays clear); the barber's brick walk-up beside it on the same forecourt line
	var bakery := F.place(bl, sx, sz, "commercial/com_bakery", 13.7, 181.3, "+v", "bakery", 0.7)
	var barber := F.place(bl, sx, sz, "ck/ck_brk3_row2", 25.4, 181.3, "+v", "barber", 0.75)
	paints.append(F.rect(sx, sz, 9.2, 188.3, 31.6, 190.8, "concrete"))           # the shops' forecourt
	for b: Dictionary in [bakery, barber]:
		F.back_of_house(props, b, false); blds.append(b)
	# bakery door at u 10.4 (corner end): the bench under the window east of it, the rack along the front, papers at the
	# corner end of the forecourt where the walkers come round, a bin by the door for cups
	F.put(props, "prop_park_bench", "worn", sx, sz, 16.2, 189.0, 180.0)            # faces 8th St, back to the window
	F.put(props, "prop_trash_receptacle", "dirty", sx, sz, 12.4, 189.6)
	F.put(props, "prop_newspaper_box_red", "worn", sx, sz, 18.6, 189.7, 0.0)       # between the two shops, clear of both doors
	F.put(props, "prop_bike_rack", "rusty", sx, sz, 20.6, 189.9, 0.0)              # parallel to the front, between the shops
	# barber: shop door at local -1.1 (u 26.5), flat door at local 3.0 (u 22.4): the waiting bench outside under the
	# window at the shop's east end, a pot between the two doors is too tight: none
	F.put(props, "prop_park_bench", "worn", sx, sz, 29.7, 189.0, 180.0)
	F.wall(props, barber, "prop_porch_light_coach_bronze", "worn", "front", -1.1 - 0.9, 2.25, 0.05)
	F.wall(props, barber, "prop_mailbox_wall_black", "worn", "front", 3.0 + 1.1, 1.3, 0.05)
	F.grime(dec, Vector2(9.2, -188.0), Vector2(31.6, -188.0), rr)
	dec.add(14, Vector2(10.4, -189.5), 0.0, 2.0, 1.6, F.GY, Color(1, 1, 1, 0.55))  # worn in front of the bakery door
	# the white court on 8th St, 3 m front yard (walks, hedge, a tree): the street row goes on east of the shops
	var court := F.place(bl, sx, sz, "apartments/apt_court_white", 44.4, 183.3, "+v", "white_court_8th")
	F.dress(court, paints, props, dec, rr, sx, sz, 190.8, true, false, [1.0])        # west wall 3 m from the barber: no AC there
	blds.append(court)
	# the Spanish court on B Ave behind the bakery (front 3 m back from the walk)
	var spb := F.place(bl, sx, sz, "apartments/apt_spanish_white", 17.2, 157.0, "-u", "spanish_court_b")
	F.dress(spb, paints, props, dec, rr, sx, sz, 9.2, true, true)
	blds.append(spb)
	# stalls off the v-alley for the shops' staff and the tenants (u 47.4-54), the bins enclosure at their north end
	# open to the alley (the truck backs in)
	var s1 := F.pad(paints, stalls, dec, rr, sx, sz, false, 147.2, 166.0, 54.0, -1.0)
	(ctx.stops as Array).append_array(s1)
	paints.append(F.rect(sx, sz, 47.4, 166.0, 54.0, 174.0, "asphalt"))
	F.enclosure(props, F.q(sx, sz, 50.0, 170.0), 90.0)
	dec.add(6, Vector2(52.2, -170.0), 0.0, 2.0, 3.0, F.GY, Color(1, 1, 1, 0.6))     # the truck's drips at the enclosure mouth
	# the shared courtyard: fence along the alley with the gate opposite the stalls' middle, along the stalls with a gate,
	# closed to the enclosure and the white court's back wall
	F.fence_uv(props, sx, sz, 22.2, 148.0, 22.2, 146.6)
	F.fence_gate(props, sx, sz, 22.2, 146.6, 47.0, 146.6, 12.0)
	F.fence_gate(props, sx, sz, 47.0, 146.6, 47.0, 166.9, 10.0)
	F.fence_uv(props, sx, sz, 47.0, 166.9, 48.3, 166.9)
	F.fence_uv(props, sx, sz, 48.3, 173.2, 52.6, 173.2)                              # off the enclosure's corner, clear of the court's meters and AC
	F.fence_uv(props, sx, sz, 52.6, 173.2, 52.6, 178.6)
	F.fence_gate(props, sx, sz, 31.6, 179.0, 35.8, 179.0, 2.1)                     # the gap between barber and court
	F.fence_uv(props, sx, sz, 12.2, 166.2, 12.2, 174.1)                             # the gap between the Spanish court and the bakery
	# life in the court (each has its reason)
	F.put(props, "prop_picnic_table", "worn", sx, sz, 36.0, 160.0, 15.0)         # Sunday lunch in the shade
	F.put(props, "tree_jacaranda_a", "normal", sx, sz, 39.5, 156.0, 40.0)       # the court's old tree
	F.put(props, "prop_clothesline", "worn", sx, sz, 33.0, 170.5, 90.0)         # sun from the south, out of the walk
	paints.insert(0, F.rect(sx, sz, 23.0, 166.5, 26.0, 173.5, "mulch"))        # a bed along the bakery's yard
	for k in 3: F.put(props, ["plant_bougainvillea_mound", "plant_bird_of_paradise", "plant_agave_americana_small"][k], "normal", sx, sz, 24.5, 167.6 + k * 2.4, k * 70.0)
	F.put(props, "prop_adirondack_white", "worn", sx, sz, 42.0, 151.0, 200.0)
	F.put(props, "prop_adirondack_wood", "worn", sx, sz, 43.6, 151.4, 170.0)
	F.put(props, "prop_hose_reel_cart", "worn", sx, sz, 45.6, 162.5, -90.0)
	dec.add(14, Vector2(34.6, -153.0), 30.0, 1.0, 9.0, F.GY, Color(1, 1, 1, 0.5))  # the path worn from the gate to the doors
	F.put(props, "prop_sprinkler_impact", "worn", sx, sz, 30.0, 154.0, 0.0, false)

	# ================================================================ S2 (u 9.2-54, v 100-140)
	var w1 := F.place(bl, sx, sz, "ck/ck_apt3_row3", 18.2, 111.6, "-u", "walkup_b_s")
	var w2 := F.place(bl, sx, sz, "ck/ck_apt3_row2", 18.2, 129.6, "-u", "walkup_b_n")
	F.dress(w1, paints, props, dec, rr, sx, sz, 9.2, true, true)
	F.dress(w2, paints, props, dec, rr, sx, sz, 9.2, true, true)
	blds.append(w1); blds.append(w2)
	# stalls continue a_ne's row on the other side of the lot line (same line, same depth)
	var s2 := F.pad(paints, stalls, dec, rr, sx, sz, false, 100.6, 138.6, 54.0, -1.0)
	(ctx.stops as Array).append_array(s2)
	F.fence_gate(props, sx, sz, 47.6, 100.2, 47.6, 139.4, 19.0)                   # the yard's back fence behind the stalls, a gate
	F.fence_uv(props, sx, sz, 24.4, 100.2, 47.6, 100.2)                             # lot line with a_ne
	F.fence_uv(props, sx, sz, 47.6, 139.4, 24.4, 139.4)                             # along the alley
	F.fence_uv(props, sx, sz, 24.4, 139.4, 24.4, 135.4)                             # to the north walk-up's back corner
	F.fence_uv(props, sx, sz, 24.4, 100.2, 24.4, 102.5)                             # to the south walk-up's back corner
	F.fence_gate(props, sx, sz, 22.0, 120.75, 22.0, 123.45, 1.35)                   # across the gap between the two walk-ups, a gate
	# the play corner between the two backs: bark pad, swings and a slide, the parent's bench facing it, a bin
	paints.insert(0, F.rect(sx, sz, 31.0, 113.0, 43.0, 124.0, "mulch"))
	F.put(props, "prop_swing_set", "worn", sx, sz, 35.0, 120.5, 0.0)
	F.put(props, "prop_slide", "worn", sx, sz, 40.5, 117.5, 0.0)
	F.put(props, "prop_park_bench", "worn", sx, sz, 37.0, 109.8, 180.0)            # faces north, onto the play
	F.put(props, "prop_trash_receptacle", "worn", sx, sz, 39.0, 109.8)
	dec.add(14, Vector2(35.0, -120.5), 0.0, 3.0, 2.4, F.GY, Color(1, 1, 1, 0.55)) # the bark kicked bare under the swings
	F.put(props, "tree_ficus_b", "normal", sx, sz, 44.5, 132.0, 120.0)             # shade over the grill corner
	F.put(props, "tree_coral_a", "normal", sx, sz, 29.0, 104.0, 30.0)

	# ================================================================ S3w (u 60-100, v 146-190.8)
	var sp3 := F.place(bl, sx, sz, "apartments/apt_spanish_revival", 71.0, 182.8, "+v", "spanish_court_8th")
	var w3 := F.place(bl, sx, sz, "ck/ck_apt3_row2", 91.6, 181.8, "+v", "walkup_8th_w")
	F.dress(sp3, paints, props, dec, rr, sx, sz, 190.8, true, false)
	F.dress(w3, paints, props, dec, rr, sx, sz, 190.8, true, true)
	blds.append(sp3); blds.append(w3)
	var s3 := F.pad(paints, stalls, dec, rr, sx, sz, false, 147.6, 168.8, 60.0, 1.0)
	(ctx.stops as Array).append_array(s3)
	F.fence_gate(props, sx, sz, 66.6, 146.6, 99.6, 146.6, 18.0)
	F.fence_uv(props, sx, sz, 66.6, 146.6, 66.6, 168.9)
	F.fence_uv(props, sx, sz, 66.6, 168.9, 66.6, 177.6)                              # behind the court's west end
	F.fence_uv(props, sx, sz, 99.6, 146.6, 99.6, 175.6)                              # lot line with n_apt_b1_be
	F.fence_uv(props, sx, sz, 99.6, 175.6, 97.8, 175.6)                              # to the walk-up's back corner
	F.fence_gate(props, sx, sz, 80.2, 178.0, 85.4, 178.0, 2.6)                      # between the court and the walk-up
	# the citrus and herb garden: three bark beds, an arbor with two chairs facing the beds, the hose cart
	for k in 3:
		var bu := 70.0 + k * 7.0
		paints.insert(0, F.rect(sx, sz, bu, 151.0, bu + 4.5, 162.0, "mulch"))
		F.put(props, ["plant_agave_americana", "plant_bird_of_paradise", "plant_bougainvillea_mound"][k], "normal", sx, sz, bu + 2.25, 153.5, k * 40.0)
		F.put(props, ["plant_bird_of_paradise", "plant_potted_leafy", "plant_agave_americana_small"][k], "normal", sx, sz, bu + 2.25, 158.8, k * 55.0 + 20.0)
	F.put(props, "tree_magnolia_b", "normal", sx, sz, 94.5, 155.0, 210.0)
	F.put(props, "prop_garden_arbor", "worn", sx, sz, 82.0, 166.4, 0.0)
	F.put(props, "prop_adirondack_wood", "worn", sx, sz, 81.0, 164.8, 180.0)
	F.put(props, "prop_adirondack_white", "worn", sx, sz, 83.2, 164.8, 165.0)
	F.put(props, "prop_hose_reel_cart", "worn", sx, sz, 69.0, 148.4, 90.0)
	F.put(props, "prop_sprinkler_popup", "worn", sx, sz, 92.0, 162.0, 0.0, false)

	# ================================================================ S4w (u 60-100, v 100-140)
	# the lock-up garages, doors on the alley (cars straight in), each a different owner's: mixed doors and roofs
	var gar := ["garages/single_stucco_comp", "garages/single_stucco_clay", "garages/single_siding_comp", "garages/single_stucco_flat", "garages/single_stucco_comp", "garages/single_stucco_clay", "garages/single_siding_comp"]
	for k in gar.size():
		var gb := F.place(bl, sx, sz, String(gar[k]), 63.6, 106.35 + k * 3.7, "-u", "lockup_%d" % k, 0.85)
		blds.append(gb)
		paints.append(F.rect(sx, sz, 60.0, 104.6 + k * 3.7 - 0.1, 60.6, 108.1 + k * 3.7 - 0.1, "concrete"))   # the lip at each door
		W.oil(dec, rr, Vector2(58.5, -(106.35 + k * 3.7)), 90.0, F.GY, 0.55)               # drips where a car waits at the door
	# the garden wing faces SOUTH over a_ne's playground (residents watch the kids); a walk in front of it to the alley
	var gw := F.place(bl, sx, sz, "apartments/apt_garden_mint", 84.0, 112.0, "-v", "garden_wing_b1", 0.7)
	F.dress(gw, paints, props, dec, rr, sx, sz, 102.6, false, true)
	blds.append(gw)
	paints.append(F.rect(sx, sz, 60.0, 101.2, 98.5, 102.6, "concrete"))           # the front walk, out to the alley south of the garages
	var s4 := F.pad(paints, stalls, dec, rr, sx, sz, true, 70.0, 99.4, 140.0, -1.0)
	(ctx.stops as Array).append_array(s4)
	F.fence_gate(props, sx, sz, 67.2, 133.4, 99.6, 133.4, 16.0)                   # yard fence behind the stalls
	F.fence_uv(props, sx, sz, 67.2, 133.4, 67.2, 116.6)                            # yard side, along the garages' backs
	F.fence_uv(props, sx, sz, 67.2, 116.6, 73.0, 116.6)                            # to the wing's back corner
	F.fence_uv(props, sx, sz, 95.0, 116.6, 99.6, 116.6)
	F.fence_uv(props, sx, sz, 99.6, 116.6, 99.6, 133.4)                            # lot line with n_apt_b1_be
	F.put(props, "prop_clothesline", "worn", sx, sz, 78.0, 126.5, 0.0)
	F.put(props, "tree_ficus_a", "normal", sx, sz, 96.5, 128.0, 300.0)

	# ================================================================ POLISH PASS (Yasin 19 Nov: "run a polish pass in all your
	# quarters ... plenty of props"): only ADDS, with its own random sequence, after everything above (which stays identical):
	# every building's downspouts, house numbers, vine or dish, back-wall grime; and the spots chosen here, each a cluster
	# whose items go in only where their own spot is free (apt_fill_lib.polish_*)
	var prr := W.rng_for(NAME + "_polish")
	var prect := Rect2(9.2, -190.8, 90.8, 90.8)
	for pb: Dictionary in blds: F.polish_building(ctx, pb, prr, prect)
	for psp: Array in [["garden", 30, 148.5, 0], ["tools", 44, 163, 0], ["sit", 27, 160, 90], ["sit", 30, 132, 0], ["garden", 44, 106, 90], ["lounge", 43, 128, -90], ["sit", 72, 170, 0], ["bins", 88, 148.4, 0], ["sit", 86, 121, 0], ["garden", 72, 130, 0], ["tools", 97, 122, 90]]:
		F.polish_spot(ctx, String(psp[0]), float(psp[1]), float(psp[2]), float(psp[3]), prr, prect)

	F.finish(ctx, 9.2, 100.0, 100.0, 190.8)
	quit()
