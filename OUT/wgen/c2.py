from _common import *
NAME='n_w_c2'; U=-391.0; V=-700.0; W=91.0; D=91.0; Y0=6.15; HDR='/home/user/NewMap/OUT/hdr_c2.txt'
DOC='''Piece n_w_c2 (WEST FILL, the civic park): u -391..-300, v -700..-609, 91 x 91 m, flat.
SITE: a street west (aprons z 39..46.5), a street south (aprons x 44..51.5), the fire station and lot north (n_w_c1), the
civic heart east (v_nw).
PLANNER: the neighbourhood's park beside the civic heart (CITY_PLAN: parks in the transition areas): a PLAYGROUND on a
mulch pad (play structure, swings, slide, benches facing it for the parents), a fenced DOG RUN with its gate and a bench
inside, an open lawn, picnic tables, paths lit at night, a small lot off the south apron.'''
SITES=[]
PAINTS=[("concrete",0,40,91,44,"the east-west path"),("concrete",44,0,48,91,"the north-south path"),("mulch",8,52,40,82,"the playground's mulch pad"),
        ("gravel",54,8,88,38,"the dog run"),("asphalt",40,74,91,91,"the park's lot (south apron x 44..51.5)")]
BODY='\n'+''.join([
 put("prop_play_structure",22.0,66.0,0,"playground: the climbing frame on mulch"),
 put("prop_swing_set",12.0,58.0,0,"playground: swings on mulch"),
 put("prop_slide",34.0,58.0,0,"playground: the slide on mulch"),
 put("prop_park_bench",22.0,49.8,0,"playground: a bench for the parents facing it"),
 put("prop_park_bench",42.0,66.0,-90,"playground: a bench facing it from the path side"),
 put("prop_drinking_fountain",42.6,46.0,0,"park: water where the paths cross"),
 chain([(54,8),(88,8),(88,38),(54,38)],3,15.0,1.6,"dog run: chain-link round it",gate="fence_gate_wrought_iron"),
 put("prop_park_bench",72.0,30.0,180,"dog run: a bench inside, facing the run"),
 put("prop_beach_sign_dog",52.6,22.0,90,"dog run: the rules sign at its gate"),
 put("prop_trash_receptacle",53.2,26.0,0,"dog run: the bag bin against its fence"),
 put("prop_picnic_table",20.0,20.0,0,"park: a table on the lawn"), put("prop_picnic_table",30.0,30.0,0,"park: a table on the lawn"),
 put("prop_lamp_victorian",46.0,20.0,0,"park: the paths lit"), put("prop_lamp_victorian",20.0,42.0,0,"park: the paths lit"), put("prop_lamp_victorian",70.0,42.0,0,"park: the paths lit"),
 put("prop_bike_rack",38.0,86.0,90,"park: bikes by the lot"),
 stalls_row(56.0,88.0,78.0,180), tyre(48.0,88.0,0.0), wear(40,74,91,91,5),
 put("prop_sprinkler_impact",70.0,60.0,0,"park: the lawn's sprinkler"),
])
