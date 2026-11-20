from _common import *
NAME='n_w_w2a'; U=-986.0; V=-900.0; W=177.0; D=91.0; Y0=4.15; HDR='/home/user/NewMap/OUT/hdr_w2a.txt'
DOC="""Piece n_w_w2a (WEST FILL, the west strip's north end at the gritty edge): u -986..-809, v -900..-809, 177 x 91 m; land
4.0 (west) to 6.2 (south-east). SITE: the south street (aprons x 125..132.5), the east street (aprons z 39..46.5), the
ring road west, the garden block and the gritty edge north.
PLANNER: the step from the gritty edge to the ridge's houses: APARTMENTS facing the south street (garden, stucco,
spanish, dingbat, court), their parking court behind off the alley and the east apron, yards with washing lines,
barbecues and tables; the sound wall to the ring road."""
SITES=[("apartments/apt_garden_mint",16.0,88.0,"s","apts_1"),("apartments/apt_stucco3_peach",44.0,88.0,"s","apts_2"),
       ("apartments/apt_spanish_revival",68.0,88.0,"s","apts_3"),("apartments/apt_dingbat_pink",90.0,88.0,"s","apts_4"),
       ("apartments/apt_court_white",110.0,88.0,"s","apts_5"),("apartments/apt_garden_cream",155.0,88.0,"s","apts_6")]
PAINTS=[("concrete",0,88,177,91,"frontage"),("asphalt",125,30,133,91,"the alley from the south apron"),("asphalt",20,24,177,46,"the parking court (east apron z 39..46.5)")]
BODY='\n'+''.join([
 stalls_row(22,122,28,180), stalls_row(22,122,42,0), stalls_row(136,172,28,180),
 ''.join(put("prop_lot_light_pole",x,35,0,"court: lights") for x in (50,100,155)),
 wear(20,24,177,46,18), tyre(174,43,-80), tyre(129,88,0),
 ''.join(put("prop_clothesline",x,62,0,"apartments: washing in the yard") for x in (16,68,110)),
 ''.join(put("prop_bbq_kettle",x,58,0,"apartments: the residents' grill") for x in (40,90,150)),
 ''.join(put("prop_picnic_table",x,66,0,"apartments: a table in the yard") for x in (30,140)),
 ''.join(put("prop_bike_rack",x,89.6,0,"apartments: bikes along the frontage") for x in (30,58,79,121)),
 put("prop_bus_shelter",100,90.2,180,"south street: a bus shelter facing the street"),
 '\tc.cmu(Vector2(0.6, 0.6), Vector2(0.6, 90.4), "ring road: the sound wall")\n',
 put("prop_dumpster_3yd_green",122,24,0,"apartments: the shared bins at the court's end"), put("prop_dumpster_3yd_blue",118.4,24,0,"apartments: recycling"),
])
