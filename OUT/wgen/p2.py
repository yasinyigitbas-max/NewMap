from _common import *
NAME='n_w_p2'; U=-188.0; V=-642.0; W=40.0; D=30.0; Y0=6.15; HDR='/home/user/NewMap/OUT/hdr_p2.txt'
DOC="""Piece n_w_p2 (WEST FILL, the 40 x 30 m hole inside the civic heart v_ne, the spot Yasin marked east of the 18 % block):
u -188..-148, v -642..-612, flat.
PLANNER: a SUCCULENT GARDEN round the civic heart's own trees and bench that stand in this hole (v_ne's norfolk pine,
two date palms and a bench): the whole of it mulch, agaves in beds away from their trunks and the bench; no path, no
furniture of its own (the bench is v_ne's)."""
SITES=[]
PAINTS=[("mulch",0,0,40,30,"the dry garden")]
BODY='\n'+''.join([
 ''.join(put("plant_agave_americana",x,z,0,"succulent garden: agaves on mulch") for x,z in ((8,5),(28,5),(34,25),(26,26))),
 ''.join(put("plant_agave_americana_small",x,z,0,"succulent garden: young agaves") for x,z in ((14,4),(22,7),(30,10))),
])
