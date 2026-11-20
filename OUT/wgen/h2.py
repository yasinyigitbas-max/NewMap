from _common import *
NAME='n_w_h2'; U=-245.0; V=-294.0; W=40.0; D=40.0; Y0=6.15; HDR='/home/user/NewMap/OUT/hdr_h2.txt'
DOC='''Piece n_w_h2 (WEST FILL, a 40 x 40 m hole in the stadium's car park): u -245..-205, v -294..-254, flat.
PLANNER: a PLAYGROUND for families on game days: mulch pad, play structure, swings, slide, shade sail, benches facing it, a picket fence with a gate.'''
SITES=[]
PAINTS=[("mulch",4,4,36,36,"the playground's mulch")]
BODY='\n'+''.join([
 chain([(3,3),(37,3),(37,37),(3,37)],2,20.0,1.1,"playground: a picket fence round it",gate="fence_gate_picket",kind="picket"),
 put("prop_play_structure",14.0,16.0,0,"playground: the climbing frame"), put("prop_swing_set",28.0,12.0,0,"playground: swings"),
 put("prop_slide",28.0,26.0,0,"playground: the slide"), put("prop_shade_sail",12.0,28.0,0,"playground: shade"),
 put("prop_park_bench",20.0,34.0,180,"playground: a bench for the parents facing it"),
])
