NAME='n_w_s2b'; U=-591.0; V=-900.0; W=91.0; D=91.0; Y0=6.15; HDR='/home/user/NewMap/OUT/hdr_s2b.txt'
DOC='''Piece n_w_s2b (WEST FILL, north of the campus): u -591..-500, v -900..-809, 91 x 91 m, flat 6.0..6.15.
SITE: 6th St on the south (aprons x 4..6.5, 44..51.5), a street on the west (aprons z 39..46.5), the gritty edge's lot
north, the student plaza (n_w_s2c) and the market block (n_w_s2a) east.
PLANNER: the STUDENT STRIP facing the student union and the gate café across 6th St: a shop row (PRINT & COPY, BOBA
TEA, PHONE FIX), a second row (BURRITO BAR, TEXTBOOK EXCHANGE), THE QUAD PUB, a corner terrace with tables; behind, a
lot off the west street and the 6th St lane, bins against the back walls.'''
SITES=[("commercial/com_boutique_row",14.0,88.0,"s","print_boba"),("commercial/com_orange_row",34.0,88.0,"s","burrito_books"),
       ("commercial/com_bar_crown",58.0,88.0,"s","quad_pub"),("commercial/com_orange_corner",72.0,88.0,"s","corner_deli")]
PAINTS=[("concrete",0,88,91,91,"frontage"),("plaza",79,60,91,88,"the corner terrace"),("asphalt",44,40,52,91,"lane from the 6th St apron"),
        ("asphalt",0,38,91,48,"the back lane from the west apron"),("asphalt",0,20,79,38,"the strip's back lot")]
BODY='''
	for ct: Array in [[82.0, 66.0], [88.0, 66.0], [82.0, 72.0], [88.0, 72.0], [82.0, 78.0], [88.0, 78.0]]:
		c.put("prop_cafe_table", "worn", c.gp(float(ct[0]), float(ct[1])), 0.0, "corner terrace: tables for the deli and the pub")
		c.put("prop_cafe_chair", "worn", c.gp(float(ct[0]) - 0.8, float(ct[1])), 90.0, "corner terrace: a chair at its table", false)
		c.put("prop_cafe_chair", "worn", c.gp(float(ct[0]) + 0.8, float(ct[1])), -90.0, "corner terrace: a chair at its table", false)
	c.put("prop_menu_board", "worn", c.gp(63.8, 89.6), 0.0, "The Quad Pub: game night on the board")
	c.put("prop_menu_board", "worn", c.gp(25.0, 89.6), 0.0, "Burrito Bar: the day's specials")
	for bx: float in [3.0, 5.5, 46.0, 49.0]: c.put("prop_bike_rack", "worn", c.gp(bx, 89.8), 0.0, "student strip: bikes along the walk")
	for nb: Array in [[79.6, 89.6, "prop_newspaper_box_red"], [80.6, 89.6, "prop_newspaper_box_blue"]]: c.put(String(nb[2]), "worn", c.gp(float(nb[0]), float(nb[1])), 0.0, "corner: the student paper and the city paper")
	c.put("prop_trash_receptacle", "worn", c.gp(78.9, 86.0), 0.0, "corner terrace: a bin against the deli's corner")
	for lp: float in [20.0, 52.0, 86.0]: c.put("prop_lamp_victorian", "worn", c.gp(lp, 90.2), 0.0, "frontage: lamps")
	var sx := 4.0
	while sx < 77.0:
		if absf(sx - 48.0) > 5.0: c.stalls.append([sx, 24.0, 0.0, c.yf(sx, 24.0)])
		sx += 2.7
	c.put("prop_lot_light_pole", "worn", c.gp(30.0, 35.0), 0.0, "back lot: a light")
	c.cracks(0.0, 20.0, 79.0, 48.0, 12, 0.55); c.tyre(Vector2(3.0, 43.0), 90.0, 6.0, 0.45); c.tyre(Vector2(48.0, 50.0), 0.0, 6.0, 0.45)
	for ol: Array in [[12.1, 24.0], [33.7, 24.0], [63.4, 24.0]]: c.oil(Vector2(float(ol[0]), float(ol[1])), 0.0)
	for dz: Array in [[14.0, 71.6, "prop_dumpster_3yd_green"], [34.0, 71.6, "prop_dumpster_3yd_blue"], [58.0, 71.8, "prop_dumpster_3yd_green"]]: c.put(String(dz[2]), "worn", c.gp(float(dz[0]), float(dz[1])), 0.0, "the strip's bins against the back walls")
'''
