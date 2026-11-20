from _common import *
NAME='n_w_p2'; U=-188.0; V=-642.0; W=40.0; D=30.0; Y0=6.15; HDR='/home/user/NewMap/OUT/hdr_p2.txt'
DOC='''Piece n_w_p2 (WEST FILL, the 40 x 30 m hole inside the civic heart v_ne, the spot Yasin marked east of the 18 % block):
u -188..-148, v -642..-612, flat.
PLANNER: a SUCCULENT GARDEN for the civic offices' lunch break: a dry garden on mulch, a path, benches, a table.'''
SITES=[]
PAINTS=[("concrete",0,13,40,17,"path"),("mulch",2,2,38,12,"dry garden"),("mulch",2,18,38,28,"dry garden")]
BODY='\n'+''.join([
 ''.join(put("plant_agave_americana",x,z,0,"succulent garden: agaves on mulch") for x,z in ((6,6),(18,8),(30,6),(10,24),(26,22),(34,25))),
 ''.join(put("plant_potted_succulent",x,z,0,"succulent garden: pots along the path") for x,z in ((12,12.3),(28,12.3))),
 ''.join(put("prop_park_bench",x,z,0,"succulent garden: a bench facing the garden") for x,z in ((8,17.8),(32,17.8))),
 put("prop_picnic_table",20.0,23.0,0,"succulent garden: a lunch table"), put("prop_drinking_fountain",20.0,12.4,0,"succulent garden: water"),
])
