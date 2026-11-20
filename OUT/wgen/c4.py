from _common import *
NAME='n_w_c4'; U=-95.0; V=-590.0; W=45.0; D=181.0; Y0=6.15; HDR='/home/user/NewMap/OUT/hdr_c4.txt'
DOC='''Piece n_w_c4 (WEST FILL, the stadium promenade): u -95..-50, v -590..-409, 45 x 181 m, flat.
SITE: between the stadium (west) and the city centre's south-west block (c_sw) and the Amber shops (n_w_c5) east; no
street touches it except the north end.
PLANNER: the STADIUM PROMENADE, a green walk from the city centre to the stadium: a paved path, lawns, benches facing the
lawns, lamps, bike racks, a statue at the stadium end, drinking fountains.'''
SITES=[]
PAINTS=[("concrete",18,0,27,181,"the promenade path"),("plaza",10,150,35,181,"the stadium end's square")]
BODY='\n'+''.join([
 ''.join(put("prop_park_bench",x,z,yw,"promenade: a bench beside the path facing the lawn") for x,z,yw in ((17.0,30,-90),(28.0,60,90),(17.0,90,-90),(28.0,120,90))),
 ''.join(put("prop_lamp_victorian",27.4,z,0,"promenade: lit at night") for z in (15.0,55.0,95.0,135.0)),
 put("prop_obelisk_monument",22.5,166.0,0,"promenade: the statue at the stadium end"),
 ''.join(put("prop_park_bench",x,z,yw,"stadium square: a bench facing the statue") for x,z,yw in ((14.0,166,90),(31.0,166,-90))),
 put("prop_drinking_fountain",28.0,100.0,0,"promenade: water"), put("prop_bike_rack",12.0,176.0,0,"stadium square: bikes"),
 put("prop_trash_receptacle",11.0,154.0,0,"stadium square: a bin at its edge"),
 ''.join(put("plant_bird_of_paradise",x,z,0,"promenade: a bed of flowers") for x,z in ((6,40),(38,80),(6,120),(38,30))),
])
