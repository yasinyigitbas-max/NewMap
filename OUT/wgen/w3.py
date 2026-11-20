from _common import *
R=ring_block('n_w_w3', -986.0, -791.0, '/home/user/NewMap/OUT/hdr_w3.txt', """Piece n_w_w3 (WEST FILL, the west strip, Country Club Ridge's foot): u -986..-809, v -791..-609, 177 x 182 m.
SITE: the ring road west (no aprons: the houses back onto it behind a sound wall), streets north, south and east; the
land rises 2 m from west (4.2) to east (6.2), the north and south streets with it; aprons on the north and south
streets at x 125..132.5, on the east street at z 44..51.5 and 130..137.5.
PLANNER: RESIDENTIAL (ZONING: the west houses running down Country Club Ridge): houses face the east, north and south
streets, every back yard fenced with a gate to its parking pad off a back lane; the lanes join an alley between the
two street aprons; in the block's heart RIDGE POCKET PARK (playground, lawn, tables, benches facing the play).""",
  rows=[('east','e',174.0,4.0,178.0,['craftsman_sage','ranch_peach','spanish_white','tudor_brick','mcm_teal','craftsman_cedar','colonial_white','ranch_porch'],132.0,True),
        ('north','n',3.0,8.0,120.0,['spanish_pink','cape_white','hipranch_sand','victorian_yellow','contemporary_white','ranch_siding'],40.0,True),
        ('south','s',179.0,8.0,120.0,['colonial_blue','spanish_peach','craftsman_olive','beach_teal','mcm_white','tudor_stucco'],142.0,True)],
  lanes=[('asphalt',125,0,132,182,'the back alley, north apron to south apron (x 125..132.5)'),('asphalt',6,40,125,46,'the north houses\' back lane'),
         ('asphalt',6,136,125,142,'the south houses\' back lane')],
  extra_sites=[], extra_paints=[('mulch',40,64,70,92,'the pocket park\'s play pad'),('concrete',6,98,120,102,'the park path')], extra_body=''.join([put('prop_play_structure',52,76,0,'pocket park: the climbing frame on mulch'),put('prop_swing_set',44,70,0,'pocket park: swings'),put('prop_slide',64,86,0,'pocket park: the slide'),put('prop_park_bench',55,95.4,180,'pocket park: a bench facing the play'),put('prop_park_bench',74,78,-90,'pocket park: a bench facing the play'),put('prop_picnic_table',90,80,0,'pocket park: a table on the lawn'),put('prop_picnic_table',100,116,0,'pocket park: a table on the lawn'),put('prop_drinking_fountain',72,100.6,0,'pocket park: water on the path'),put('prop_lamp_victorian',30,100.6,0,'pocket park: lit'),put('prop_lamp_victorian',90,100.6,0,'pocket park: lit'),lane_wear(125,0,132,182,True),lane_wear(6,40,125,46,False),lane_wear(6,136,125,142,False),tyre(128.5,3,0),tyre(128.5,179,0)]))
globals().update(R)
