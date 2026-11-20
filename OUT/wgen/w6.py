from _common import *
R=ring_block('n_w_w6', -986.0, -191.0, '/home/user/NewMap/OUT/hdr_w6.txt', """Piece n_w_w6 (WEST FILL, the west strip, on the ridge): u -986..-809, v -191..-9, 177 x 182 m; the land climbs from
4.2 (north-west) to 8.2 (south-east), Country Club Ridge.
SITE: ring road west behind a sound wall; aprons north / south x 125..132.5, east z 44..51.5 and 130..137.5.
PLANNER: houses on their own level pads stepping up the ridge round the edges; in its heart RIDGE COMMUNITY CHURCH with
its lot off the alley and its garden.""",
  rows=[('east','e',174.0,4.0,178.0,['mcm_large','spanish_large','craftsman_large','colonial_large_garage','mcm_white','spanish_white','craftsman_sage','tudor_stucco'],132.0,True),
        ('north','n',3.0,8.0,120.0,['contemporary_grey','hipranch_sand','spanish_pink','victorian_blue','ranch_peach','colonial_white'],40.0,True),
        ('south','s',179.0,8.0,120.0,['beach_large','mcm_teal','spanish_peach','craftsman_cedar','cape_large','tudor_brick'],142.0,True)],
  lanes=[('asphalt',125,0,132,182,'the back alley, north apron to south apron (x 125..132.5)'),('asphalt',6,40,125,46,'the north houses\' back lane'),
         ('asphalt',6,136,125,142,'the south houses\' back lane')],
  extra_sites=[('civic/civ_church',60.0,122.0,'s','ridge_church')], extra_paints=[('asphalt',80,52,125,100,'the church lot off the alley'),('concrete',52,122,68,136,'the church steps to the lane')], extra_body=''.join([stalls_row(84,121,56,180),stalls_row(84,121,96,0),put('prop_lot_light_pole',102,76,0,'church lot: a light'),put('prop_poster_case',70,124,0,'church: service times'),put('prop_park_bench',30,90,90,'church garden: a bench facing the church'),put('prop_park_bench',30,110,90,'church garden: a bench facing the church'),put('prop_obelisk_monument',20,100,0,'church garden: the memorial cross'),''.join(put('plant_bird_of_paradise',36,82+k*8,0,'church garden: flowers') for k in range(5)),lane_wear(125,0,132,182,True),lane_wear(6,40,125,46,False),lane_wear(6,136,125,142,False)]))
globals().update(R)
