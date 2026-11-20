from _common import *
NAME='n_w_p1'; U=-252.0; V=-652.0; W=40.0; D=40.0; Y0=6.15; HDR='/home/user/NewMap/OUT/hdr_p1.txt'
DOC='''Piece n_w_p1 (WEST FILL, a 40 x 40 m hole inside the civic heart v_nw): u -252..-212, v -652..-612, flat.
PLANNER: the civic heart's MEMORIAL GREEN: a cross of paths, the memorial in the middle, benches facing it, flower beds.'''
SITES=[]
PAINTS=[("concrete",18,0,22,40,"path"),("concrete",0,18,40,22,"path"),("plaza",14,14,26,26,"the memorial's square")]
BODY='\n'+''.join([
 put("prop_obelisk_monument",20.0,20.0,0,"memorial green: the war memorial"),
 ''.join(put("prop_park_bench",x,z,yw,"memorial green: a bench facing the memorial") for x,z,yw in ((20,12,0),(20,28,180),(12,20,90),(28,20,-90))),
 ''.join(put("plant_bird_of_paradise",x,z,0,"memorial green: flower beds in the corners") for x,z in ((8,8),(32,8),(8,32),(32,32))),
 put("prop_lamp_victorian",23.0,23.0,0,"memorial green: lit"),
])
