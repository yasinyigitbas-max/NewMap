from _common import *
NAME='n_w_w0b'; U=-937.0; V=-1300.0; W=37.0; D=86.0; Y0=2.15; HDR='/home/user/NewMap/OUT/hdr_w0b.txt'
DOC="""Piece n_w_w0b (WEST FILL, the small spot Yasin marked north of the 56 % block): u -937..-900, v -1300..-1214, 37 x 86 m; flat 2.0..2.1.
PLANNER: the industrial edge's ALLOTMENTS: beds on mulch inside a picket fence with a gate, a tool shed, water,
benches; workers from the yards next door keep plots here."""
SITES=[]
PAINTS=[("mulch",4,4,33,76,"the allotment beds"),("concrete",0,78,37,82,"the path")]
BODY='\n'+''.join([
 chain([(3,3),(34,3),(34,77),(3,77)],2,16.0,1.1,"allotments: a picket fence round them",gate="fence_gate_picket",kind="picket"),
 ''.join(put("plant_agave_americana_small",8+i*7,10+j*8,0,"allotments: a bed") for i in range(4) for j in range(8)),
 put("prop_container_20ft_blue",28,12,0,"allotments: the tool shed"),
 put("prop_drinking_fountain",18,79.4,0,"path: water"), put("prop_park_bench",8,80.6,180,"path: a bench facing the beds"),
])
