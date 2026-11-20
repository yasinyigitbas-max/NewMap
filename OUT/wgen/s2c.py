NAME='n_w_s2c'; U=-545.0; V=-940.0; W=45.0; D=40.0; Y0=6.15; HDR='/home/user/NewMap/OUT/hdr_s2c.txt'
DOC='''Piece n_w_s2c (WEST FILL, the pocket between the gritty edge's lot and the student strip): u -545..-500,
v -940..-900, 45 x 40 m, flat.
PLANNER: a STUDENT POCKET PARK behind the strip: a mural wall against the gritty lot, lawn, tables, a ping-pong-less
corner of benches facing the lawn, bike racks, a drinking fountain; reached from the strip's back lane and the market
block.'''
SITES=[]
PAINTS=[("concrete",0,0,45,4,"walk along the mural wall"),("concrete",20,4,24,40,"the path through it"),("concrete",0,36,45,40,"the walk on the strip's side")]
BODY='''
	c.cmu(Vector2(0.4, 0.6), Vector2(44.6, 0.6), "pocket park: a block wall to the gritty lot, painted as a mural (tags)")
	for pt: Array in [[8.0, 14.0], [36.0, 14.0], [8.0, 26.0], [36.0, 26.0]]: c.put("prop_picnic_table", "worn", c.gp(float(pt[0]), float(pt[1])), 0.0, "pocket park: tables for lunch from the strip")
	for bn: Array in [[19.0, 10.0, 90.0], [25.0, 30.0, -90.0]]: c.put("prop_park_bench", "worn", c.gp(float(bn[0]), float(bn[1])), float(bn[2]), "pocket park: a bench on the path facing the lawn")
	c.put("prop_drinking_fountain", "worn", c.gp(24.8, 20.0), 0.0, "pocket park: water by the path")
	for br: float in [4.0, 7.0, 38.0, 41.0]: c.put("prop_bike_rack", "worn", c.gp(br, 38.0), 0.0, "pocket park: bikes on the strip side")
	c.put("prop_trash_receptacle", "worn", c.gp(22.0, 1.8), 0.0, "pocket park: a bin against the mural wall")
	c.put("prop_lamp_victorian", "worn", c.gp(22.0, 37.2), 0.0, "pocket park: lit at night")
	for pl: Array in [[3.0, 20.0], [42.0, 20.0]]: c.put("plant_bird_of_paradise", "normal", c.gp(float(pl[0]), float(pl[1])), c.rr.randf_range(0, 360), "pocket park: flower beds at its sides")
'''
