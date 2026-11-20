NAME='n_w_s1'; U=-791.0; V=-900.0; W=182.0; D=91.0; Y0=6.15; HDR='/home/user/NewMap/OUT/hdr_s1.txt'
DOC='''Piece n_w_s1 (WEST FILL, north of the campus, west half): u -791..-609, v -900..-809, 182 x 91 m.
SITE: 6th St's north walk on the south (6.15), the gritty edge's yards behind (north, 5.1..6.15), side streets west and
east (aprons at z 39..46.5); the land falls about 1 m to the west (4.9..6.1); 6th St aprons at x 44..51.5 and 130..137.5.
PLANNER: where the students live, facing the campus's north side across 6th St (ZONING): a row of STUDENT APARTMENTS
(garden, stucco, spanish, a dingbat) along 6th St, then by the campus's north-west gate a little STUDENT STRIP: GATE
PIZZA, CAMPUS CYCLES, THE GATEHOUSE (pub), the STUDENT HOUSING OFFICE. Behind, a through alley from the west street to
the east street with residents' parking off it, yards with washing lines and barbecues, the power line on gravel.'''
SITES=[("apartments/apt_garden_cream",16.0,88.0,"s","apts_1"),("apartments/apt_stucco3_peach",63.2,88.0,"s","apts_2"),
       ("apartments/apt_spanish_white",85.0,88.0,"s","apts_3"),("apartments/apt_dingbat_teal",104.0,88.0,"s","apts_4"),
       ("commercial/com_bistro",120.0,88.0,"s","gate_pizza"),("commercial/com_surf_shop",146.0,88.0,"s","campus_cycles"),
       ("commercial/com_bar_crown",158.0,88.0,"s","gatehouse_pub"),("commercial/com_realty",171.0,88.0,"s","housing_office")]
PAINTS=[("concrete",0,88,182,91,"the frontage along 6th St's walk"),("asphalt",44,46,52,91,"lane from the 6th St apron (x 44..51.5)"),
        ("asphalt",128,46,140,91,"lane from the second 6th St apron"),("asphalt",0,40,182,46,"the through alley (west apron z 39..46.5 to east apron)"),
        ("asphalt",0,30,182,40,"residents' parking along the alley's north side"),("gravel",0,0,182,3,"the power line's easement")]
BODY='''
	# ---- 6th St frontage: bikes, papers, the pizza terrace, the bike shop's stands, the pub's board
	for bx: float in [30.0, 33.0, 36.0, 39.0]: c.put("prop_bike_rack", "worn", c.gp(bx, 89.4), 0.0, "apartments: residents' bikes along the frontage")
	c.put("prop_menu_board", "worn", c.gp(127.4, 89.6), 0.0, "Gate Pizza: slice deals on the walk")
	for bb: float in [141.0]: c.put("prop_bike_rack", "worn", c.gp(bb, 89.8), 0.0, "Campus Cycles: bikes out front for sale and repair")
	c.put("prop_menu_board", "worn", c.gp(164.2, 89.6), 0.0, "The Gatehouse: trivia night on the board")
	for nb: Array in [[166.0, 89.8, "prop_newspaper_box_red"], [175.6, 89.8, "prop_newspaper_box_blue"]]: c.put(String(nb[2]), "worn", c.gp(float(nb[0]), float(nb[1])), 0.0, "6th St: papers at the student strip")
	c.put("prop_trash_receptacle", "worn", c.gp(126.9, 87.0), 0.0, "Gate Pizza: a bin against its corner")
	c.put("prop_poster_case", "worn", c.gp(175.2, 87.2), 0.0, "housing office: rooms to let in the window case")
	for lp: float in [24.0, 76.0, 132.0, 178.0]: c.put("prop_lamp_victorian", "worn", c.gp(lp, 90.2), 0.0, "6th St frontage: lamps")
	# ---- the alley and the parking: stalls on its north side, marks, lights, signs
	var sx := 4.0
	while sx < 178.0:
		if absf(sx - 48.0) > 5.0 and absf(sx - 134.0) > 7.0: c.stalls.append([sx, 35.0, 180.0, c.yf(sx, 35.0)])
		sx += 2.7
	for lp2: float in [30.0, 90.0, 150.0]: c.put("prop_lot_light_pole", "worn", c.gp(lp2, 46.6), 0.0, "alley: lights along it")
	c.cracks(0.0, 30.0, 182.0, 46.0, 24, 0.55)
	for ol: Array in [[20.2, 35.0], [60.7, 35.0], [101.2, 35.0], [155.2, 35.0]]: c.oil(Vector2(float(ol[0]), float(ol[1])), 0.0)
	for tm: Array in [[3.0, 43.0, 90.0], [179.0, 43.0, -90.0], [48.0, 47.0, 0.0], [134.0, 47.0, 0.0]]: c.tyre(Vector2(float(tm[0]), float(tm[1])), float(tm[2]), 6.0, 0.45)
	c.put("prop_sign_speed25", "worn", c.gp(2.0, 47.4), 90.0, "alley: slow")
	# ---- back yards between the alley and the buildings: washing lines, barbecues, a picnic table
	for cl: Array in [[14.0, 60.0], [80.0, 62.0], [104.0, 62.0]]: c.put("prop_clothesline", "worn", c.gp(float(cl[0]), float(cl[1])), 0.0, "apartments: washing out in the back yard")
	for bq: Array in [[24.0, 64.0], [64.0, 62.0]]: c.put("prop_bbq_kettle", "worn", c.gp(float(bq[0]), float(bq[1])), 0.0, "apartments: the residents' barbecue in the yard")
	for pt: Array in [[28.0, 58.0], [70.0, 56.0]]: c.put("prop_picnic_table", "worn", c.gp(float(pt[0]), float(pt[1])), 0.0, "apartments: a table in the yard")
	c.put("prop_adirondack_wood", "worn", c.gp(90.0, 58.0), 180.0, "apartments: a chair in the yard facing the sun")
	# ---- the bins against the shops' back walls, the power line on gravel
	for pz: float in [20.0, 70.0, 120.0, 170.0]: c.put("prop_utility_pole", "worn", c.gp(pz, 1.5), 0.0, "rear easement: the power line on poles, on gravel")
'''
