from _common import *
R=ring_block('n_w_w4', -986.0, -591.0, '/home/user/NewMap/OUT/hdr_w4.txt', """Piece n_w_w4 (WEST FILL, the west strip): u -986..-809, v -591..-409, 177 x 182 m; land 4.2 (west) to 6.2 (north-east).
SITE: as the block north of it (ring road west behind a sound wall; aprons north / south x 125..132.5, east z 44..51.5 and
130..137.5).
PLANNER: houses round the edges as in the block north; in its heart RIDGEVIEW ELEMENTARY: two classroom wings on the
school yard with a playground and the playing field; staff and drop-off off the alley.""",
  rows=[('east','e',174.0,4.0,178.0,['ranch_pink','craftsman_stucco','spanish_white','mcm_shed','tudor_brick','colonial_white','hipranch_grey','craftsman_sage'],132.0,True),
        ('north','n',3.0,8.0,120.0,['contemporary_grey','ranch_peach','spanish_small','victorian_blue','cape_grey','mcm_teal'],40.0,True),
        ('south','s',179.0,8.0,120.0,['spanish_pink','craftsman_cedar','ranch_siding','colonial_blue','beach_white','tudor_stucco'],142.0,True)],
  lanes=[('asphalt',125,0,132,182,'the back alley, north apron to south apron (x 125..132.5)'),('asphalt',6,40,125,46,'the north houses\' back lane'),
         ('asphalt',6,136,125,142,'the south houses\' back lane')],
  extra_sites=[('civic/civ_school_wing',45.0,66.0,'s','school_a'),('civic/civ_school_wing',90.0,66.0,'s','school_b')], extra_paints=[('concrete',10,66,120,74,'the school yard\'s walk'),('mulch',12,104,40,130,'the school playground'),('asphalt',96,104,125,134,'staff and drop-off lot off the alley')], extra_body=''.join([put('prop_play_structure',24,116,0,'school playground: the climbing frame'),put('prop_swing_set',34,110,0,'school playground: swings'),put('prop_slide',18,124,0,'school playground: the slide'),put('prop_shade_sail',30,124,0,'school playground: shade'),put('prop_park_bench',26,101.6,0,'school yard: a bench for the teacher on duty facing the playground'),put('prop_poster_case',60,75,0,'school: the notices'),put('prop_bike_rack',50,76,0,'school: bikes'),put('prop_bike_rack',53,76,0,'school: bikes'),put('prop_drinking_fountain',70,75,0,'school yard: water'),stalls_col(100,107,131,90),put('prop_sign_school',123,100,90,'school: the school sign on the alley'),lane_wear(125,0,132,182,True),lane_wear(6,40,125,46,False),lane_wear(6,136,125,142,False)]))
globals().update(R)
