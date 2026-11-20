from _common import *
NAME='n_w_c9'; U=-95.0; V=-391.0; W=79.0; D=181.0; Y0=6.15; HDR='/home/user/NewMap/OUT/hdr_c9.txt'
DOC='''Piece n_w_c9 (WEST FILL, Amber Avenue's west side by the stadium): u -95..-16, v -391..-210, 79 x 181 m, flat.
SITE: Amber Avenue's walk east (the city's spine), the stadium west, streets north and south.
PLANNER: AMBER AVENUE SHOPS face the avenue (an arcade block, a bakery, a shop row, the AMBER DINER, a boutique row, a
surf shop, a corner shop); behind them a planted walk to the stadium with benches and bike racks (no lot: Amber's
shoppers walk, the stadium has its own parking).'''
SITES=[("commercial/com_spanish_arcade_block",76.0,20.0,"e","arcade"),("commercial/com_bakery",76.0,43.0,"e","bakery"),
       ("commercial/com_orange_row",76.0,64.0,"e","shop_row"),("commercial/com_bistro",76.0,86.0,"e","amber_diner"),
       ("commercial/com_boutique_row",76.0,108.0,"e","boutiques"),("commercial/com_surf_shop",76.0,128.0,"e","surf_shop"),
       ("commercial/com_orange_corner",76.0,146.0,"e","corner_shop")]
PAINTS=[("concrete",76,0,79,181,"Amber's frontage"),("concrete",40,0,60,181,"the walk behind the shops to the stadium"),("plaza",60,156,79,181,"a corner plaza with tables")]
BODY='\n'+''.join([
 ''.join(put("prop_bike_rack",50.0,z,90,"stadium walk: bikes") for z in (20.0,60.0,100.0,140.0)),
 ''.join(put("prop_park_bench",41.0,z,-90,"stadium walk: a bench facing the lawn") for z in (40.0,80.0,120.0)),
 ''.join(put("prop_lamp_victorian",58.6,z,0,"stadium walk: lit") for z in (10.0,50.0,90.0,130.0,170.0)),
 ''.join(put("prop_menu_board",78.4,z,90,"Amber: a shop's board on the walk") for z in (43.0,86.0,146.0)),
 ''.join(put("prop_cafe_table",x,z,0,"corner plaza: tables") for x,z in ((64,162),(70,162),(64,170),(70,170))),
 put("prop_newspaper_box_red",78.4,58.0,90,"Amber: papers"), put("prop_newspaper_box_blue",78.4,59.0,90,"Amber: papers"),
 put("prop_trash_receptacle",59.4,155.0,0,"corner plaza: a bin"), put("prop_drinking_fountain",59.4,100.0,0,"stadium walk: water"),
 ''.join(put("plant_potted_leafy",78.6,z,0,"Amber: planters between the shops") for z in (33.5,55.0,97.0,119.0,139.0)),
])
