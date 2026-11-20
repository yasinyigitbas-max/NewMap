NAME='n_w_s2a'; U=-500.0; V=-991.0; W=91.0; D=182.0; Y0=6.15; HDR='/home/user/NewMap/OUT/hdr_s2a.txt'
DOC='''Piece n_w_s2a (WEST FILL, north of the campus, east of the gritty edge): u -500..-409, v -991..-809, 91 x 182 m,
flat 6.0..6.15. SITE: 6th St on the south (aprons x 39..46.5), a street north (aprons x 39..46.5), the apartment
band's street east (aprons z 44..51.5, 130..137.5), the student strip and the pocket park west.
PLANNER: across 6th St from the campus bus station: the CAMPUS MARKET (a grocery students walk to off the bus) with its
lot on 6th St's apron and the east apron, carts and a corral, the pylon sign; north of it STUDENT APARTMENTS facing the
east street (stucco, garden, court) and townhouses on the north street; their court behind holds the residents'
parking and a SAND VOLLEYBALL COURT with barbecues and tables.'''
SITES=[("extras/ext_grocery_market",60.0,150.0,"s","campus_market"),("apartments/apt_stucco3_cream",88.0,22.0,"e","apts_n"),
       ("apartments/apt_garden_mint",88.0,75.0,"e","apts_m"),("apartments/apt_court_white",88.0,105.0,"e","apts_s"),
       ("apartments/apt_townhouse_modern",30.0,3.0,"n","townhouses")]
PAINTS=[("asphalt",0,150,91,182,"the market's lot (6th St apron x 39..46.5)"),("asphalt",76,124,91,150,"the lot's way to the east apron (z 130..137.5)"),
        ("concrete",44,146,76,150,"the market's front walk"),("asphalt",60,44,91,52,"lane from the east apron (z 44..51.5)"),
        ("asphalt",20,30,60,60,"the residents' parking in the court"),("asphalt",39,0,47,30,"lane from the north apron"),
        ("sand",8,70,26,88,"the sand volleyball court"),("concrete",0,0,20,3,"townhouses' walk")]
BODY='''
	# ---- the market: carts, corral, pylon sign, the lot's stalls, lights, marks
	c.put("prop_pylon_sign", "worn", c.gp(84.0, 178.0), 0.0, "Campus Market: the pylon sign on 6th St")
	c.put("prop_cart_corral", "worn", c.gp(30.0, 166.0), 90.0, "lot: the cart corral in the middle of the rows")
	for sc: Array in [[51.0, 151.6, 92.0], [70.0, 158.0, 40.0], [12.0, 170.0, 120.0]]: c.put("prop_shopping_cart", "worn", c.gp(float(sc[0]), float(sc[1])), float(sc[2]), "Campus Market: carts by the door and some left in the lot")
	c.put("prop_ice_chest", "worn", c.gp(78.0, 147.0), 0.0, "Campus Market: the ice chest on the front walk")
	c.put("prop_vending_soda", "worn", c.gp(43.6, 146.8), 0.0, "Campus Market: drinks against its front wall")
	for nb: Array in [[76.6, 147.6, "prop_newspaper_box_red"], [77.4, 145.0, "prop_newspaper_box_blue"]]: c.put(String(nb[2]), "worn", c.gp(float(nb[0]), float(nb[1])), 0.0, "Campus Market: papers by the door")
	var lx := 4.0
	while lx < 74.0:
		if absf(lx - 42.75) > 6.0:
			c.stalls.append([lx, 156.0, 180.0, c.yf(lx, 156.0)]); c.stalls.append([lx, 176.0, 0.0, c.yf(lx, 176.0)])
		lx += 2.7
	for lp: float in [20.0, 60.0]: c.put("prop_lot_light_pole", "worn", c.gp(lp, 166.0), 0.0, "market lot: lights")
	c.cracks(0.0, 150.0, 91.0, 182.0, 14, 0.45); c.tyre(Vector2(42.75, 178.0), 0.0, 7.0, 0.5); c.tyre(Vector2(88.0, 134.0), -80.0, 6.0, 0.45)
	for ol: Array in [[9.4, 156.0], [25.6, 176.0], [52.0, 156.0]]: c.oil(Vector2(float(ol[0]), float(ol[1])), 0.0)
	c.put("prop_dumpster_3yd_green", "worn", c.gp(43.6, 128.0), 90.0, "Campus Market: waste against its west wall")
	c.put("prop_dumpster_3yd_blue", "worn", c.gp(43.6, 131.6), 90.0, "Campus Market: cardboard against its west wall")
	# ---- the residents' court: parking, volleyball, barbecues, tables, washing
	var pz := 33.0
	while pz < 58.0:
		c.stalls.append([24.0, pz, 90.0, c.yf(24.0, pz)]); c.stalls.append([56.0, pz, -90.0, c.yf(56.0, pz)])
		pz += 2.7
	c.put("prop_volleyball_net", "worn", c.gp(17.0, 79.0), 0.0, "court: the sand volleyball net")
	for bq: Array in [[34.0, 78.0], [34.0, 84.0]]: c.put("prop_bbq_kettle", "worn", c.gp(float(bq[0]), float(bq[1])), 0.0, "court: barbecues by the volleyball")
	for pt: Array in [[42.0, 72.0], [42.0, 86.0], [50.0, 79.0]]: c.put("prop_picnic_table", "worn", c.gp(float(pt[0]), float(pt[1])), 0.0, "court: tables for the residents")
	for ad: Array in [[6.0, 92.0], [9.0, 93.0], [12.0, 92.0]]: c.put("prop_adirondack_white", "worn", c.gp(float(ad[0]), float(ad[1])), 180.0, "court: chairs facing the volleyball court")
	c.put("prop_clothesline", "worn", c.gp(64.0, 100.0), 0.0, "apartments: washing out behind the court apartments")
	for br: float in [70.0, 73.0]: c.put("prop_bike_rack", "worn", c.gp(br, 61.6), 0.0, "apartments: residents' bikes")
	c.cracks(20.0, 30.0, 60.0, 60.0, 8, 0.5); c.tyre(Vector2(88.0, 48.0), -80.0, 6.0, 0.45); c.tyre(Vector2(43.0, 3.0), 0.0, 6.0, 0.45)
	c.put("prop_lot_light_pole", "worn", c.gp(40.0, 45.0), 0.0, "court parking: a light")
	# ---- the east street walk: a bench at the walk-ups, papers
	c.put("prop_park_bench", "worn", c.gp(89.6, 58.0), 90.0, "east street: a bench on the walk facing the street")
'''
