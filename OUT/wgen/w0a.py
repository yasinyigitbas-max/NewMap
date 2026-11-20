from _common import *
NAME='n_w_w0a'; U=-1000.0; V=-1400.0; W=31.0; D=200.0; Y0=2.15; HDR='/home/user/NewMap/OUT/hdr_w0a.txt'
DOC="""Piece n_w_w0a (WEST FILL, the strip inside the ring road at the north-west): u -1000..-969, v -1400..-1200, 31 x 200 m; land 2.1..2.6.
PLANNER: a GREEN BUFFER between the ring road and the industrial edge: a walking and running path, benches facing the
lawn, a drinking fountain, lamps; its trees (a windbreak) come with the tree layer."""
SITES=[]
PAINTS=[("concrete",13,0,17,200,"the path")]
BODY='\n'+''.join([
 ''.join(put("prop_park_bench",12.4,z,-90,"buffer path: a bench facing the lawn") for z in (40,100,160)),
 ''.join(put("prop_lamp_victorian",17.6,z,0,"buffer path: lit") for z in (20,70,120,170)),
 put("prop_drinking_fountain",17.6,100,0,"buffer path: water"), put("prop_trash_receptacle",17.6,42,0,"buffer path: a bin by the bench") if False else '',
])
