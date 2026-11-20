from _common import *
NAME='n_w_w1'; U=-938.0; V=-1186.0; W=38.0; D=177.0; Y0=2.15; HDR='/home/user/NewMap/OUT/hdr_w1.txt'
DOC="""Piece n_w_w1 (WEST FILL, the strip between the ring road's houses and the gritty edge): u -938..-900, v -1186..-1009,
38 x 177 m; land 2.0 (north) to 4.1 (south).
PLANNER: RIDGE GARDEN NURSERY: rows of plants on gravel inside a chain-link fence, the sales hut at the north end, a
parking strip, a bench; the land climbs 2 m along it."""
SITES=[("commercial/com_kiosk",19.0,8.0,"n","nursery_hut")]
PAINTS=[("gravel",2,20,36,170,"the nursery's growing rows"),("asphalt",2,0,36,6,"the customers' parking strip")]
BODY='\n'+''.join([
 chain([(1.5,18),(36.5,18),(36.5,172),(1.5,172)],0,30.0,5.8,"nursery: chain-link round the rows"),
 ''.join(put("plant_potted_leafy" if (i+j)%2 else "plant_potted_succulent",6+i*6.5,24+j*6,0,"nursery: a row of pots for sale","normal") for i in range(5) for j in range(0,24,2)),
 ''.join(put("plant_agave_americana",8+i*10,170-6,0,"nursery: agaves in the back row") for i in range(3)),
 put("prop_park_bench",30,12,180,"nursery: a bench by the hut facing the street"),
 put("prop_menu_board",26,6.8,0,"nursery: today's specials"),
])
