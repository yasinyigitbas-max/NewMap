from _common import *
NAME='n_w_c5'; U=-50.0; V=-502.0; W=34.0; D=93.0; Y0=6.15; HDR='/home/user/NewMap/OUT/hdr_c5.txt'
DOC='''Piece n_w_c5 (WEST FILL, Amber Avenue's west side south of the centre): u -50..-16, v -502..-409, 34 x 93 m, flat.
SITE: Amber's walk east, the city centre's block north, the promenade west.
PLANNER: AMBER SHOPS facing the avenue: a boutique row, a bakery, a corner shop, a realty office, a café; benches and
planters on the walk.'''
SITES=[("commercial/com_boutique_row",31.0,13.0,"e","boutiques"),("commercial/com_bakery",31.0,33.0,"e","bakery"),
       ("commercial/com_orange_corner",31.0,50.0,"e","corner_shop"),("commercial/com_realty",31.0,64.0,"e","realty"),("commercial/com_cafe_seaside",31.0,78.0,"e","cafe")]
PAINTS=[("concrete",31,0,34,93,"Amber's frontage"),("concrete",0,0,15,93,"the walk behind to the promenade")]
BODY='\n'+''.join([
 ''.join(put("plant_potted_leafy",33.4,z,0,"Amber: planters between the shops") for z in (23.0,42.0,58.0,70.0)),
 put("prop_menu_board",33.4,30.0,90,"bakery: today's bread"), put("prop_menu_board",33.4,84.0,90,"café: the menu"),
 put("prop_park_bench",33.4,88.0,90,"Amber: a bench on the walk facing the avenue"),
 ''.join(put("prop_bike_rack",6.0,z,90,"back walk: bikes") for z in (20.0,60.0)),
])
