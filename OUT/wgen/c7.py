from _common import *
NAME='n_w_c7'; U=-500.0; V=-300.0; W=91.0; D=91.0; Y0=6.15; HDR='/home/user/NewMap/OUT/hdr_c7.txt'
DOC='''Piece n_w_c7 (WEST FILL, the neighbourhood park south of the campus): u -500..-409, v -300..-209, 91 x 91 m, flat.
SITE: streets south (aprons x 39..46.5) and east (aprons z 39..46.5), the faculty apartments north, houses west (r_q).
PLANNER: the residential quarter's park: two TENNIS COURTS in a chain-link cage (gate on the path), a SAND VOLLEYBALL
court, a lawn with tables, benches facing the courts, a small lot off the east apron.'''
SITES=[]
PAINTS=[("concrete",6,6,48,46,"the tennis courts"),("concrete",0,48,91,52,"the park path"),("sand",56,64,82,84,"the volleyball court"),
        ("asphalt",60,30,91,48,"the park's lot (east apron z 39..46.5)")]
BODY='\n'+''.join([
 chain([(6,6),(48,6),(48,46),(6,46)],2,21.0,1.6,"tennis: the cage keeps balls in",gate="fence_gate_wrought_iron"),
 put("prop_tennis_net",16.0,26.0,0,"tennis: the net across the court"), put("prop_tennis_net",38.0,26.0,0,"tennis: the net across the court"),
 put("prop_park_bench",27.0,26.0,90,"tennis: players' bench between the courts, facing one", ),
 put("prop_park_bench",14.0,50.8,180,"park path: a bench facing the courts"), put("prop_park_bench",40.0,50.8,180,"park path: a bench facing the courts"),
 put("prop_volleyball_net",69.0,74.0,0,"volleyball: the net"),
 ''.join(put("prop_picnic_table",x,z,0,"park: a table on the lawn") for x,z in ((20,66),(34,78),(12,82))),
 put("prop_drinking_fountain",50.0,50.8,0,"park: water on the path"), put("prop_trash_receptacle",48.6,46.8,0,"tennis: a bin against the cage corner"),
 put("prop_lamp_victorian",30.0,49.2,0,"park path: lit"), put("prop_lamp_victorian",70.0,49.2,0,"park path: lit"),
 stalls_row(64.0,88.0,33.5,180), wear(60,30,91,48,5), tyre(88.0,43.0,-80.0),
 put("prop_bike_rack",58.0,46.0,0,"park: bikes by the lot"),
])
