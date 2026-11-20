from _common import *
NAME='n_w_w2b'; U=-982.0; V=-991.0; W=82.0; D=91.0; Y0=4.15; HDR='/home/user/NewMap/OUT/hdr_w2b.txt'
DOC="""Piece n_w_w2b (WEST FILL, between the ring road and the gritty edge): u -982..-900, v -991..-900, 82 x 91 m; land 4.0..4.6.
PLANNER: RIDGE COMMUNITY GARDEN AND PLAYGROUND for the apartments and the gritty edge: allotment beds on mulch inside a
picket fence with its gate, the tool shed (a container), water, a playground on mulch, benches, tables."""
SITES=[]
PAINTS=[("mulch",6,6,50,50,"the allotments"),("concrete",0,52,82,56,"the path"),("mulch",54,60,80,86,"the playground pad")]
BODY='\n'+''.join([
 chain([(5,5),(51,5),(51,51),(5,51)],2,24.0,1.1,"allotments: a picket fence round the beds",gate="fence_gate_picket",kind="picket"),
 ''.join(put("plant_agave_americana_small",10+i*8,12+j*9,0,"allotments: a bed") for i in range(5) for j in range(4)),
 ''.join(put("plant_bird_of_paradise",12+i*9,46,0,"allotments: flowers along the fence") for i in range(4)),
 put("prop_container_20ft_green",44,20,0,"allotments: the tool shed"),
 put("prop_drinking_fountain",28,53.4,0,"path: water by the garden gate"),
 put("prop_play_structure",66,72,0,"playground: the climbing frame"), put("prop_swing_set",76,64,0,"playground: swings"), put("prop_slide",58,80,0,"playground: the slide"),
 put("prop_park_bench",64,58.6,0,"playground: a bench facing it"), put("prop_picnic_table",30,72,0,"a table on the lawn"),
 put("prop_lamp_victorian",40,55.4,0,"path: lit"),
])
