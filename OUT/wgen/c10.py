from _common import *
NAME='n_w_c10'; U=-305.0; V=-240.0; W=96.0; D=31.0; Y0=6.15; HDR='/home/user/NewMap/OUT/hdr_c10.txt'
DOC='''Piece n_w_c10 (WEST FILL, the stadium's south-west fan plaza): u -305..-209, v -240..-209, 96 x 31 m, flat.
SITE: the stadium's car park north, the south street (aprons x 44..51.5, 89..91.5) south.
PLANNER: a FAN PLAZA where the crowd comes off the south street: two ticket and snack kiosks, benches, bins against the
kiosks, bike racks, bollards against cars, the team statue, a bus shelter on the street.'''
SITES=[("commercial/com_kiosk",30.0,22.0,"s","kiosk_w"),("commercial/com_kiosk",66.0,22.0,"s","kiosk_e")]
PAINTS=[("plaza",0,0,96,31,"the fan plaza")]
BODY='\n'+''.join([
 put("prop_obelisk_monument",48.0,12.0,0,"fan plaza: the team statue in the middle"),
 ''.join(put("prop_park_bench",x,z,yw,"fan plaza: a bench facing the statue") for x,z,yw in ((40,12,90),(56,12,-90))),
 put("prop_trash_receptacle",26.9,19.0,0,"fan plaza: a bin against the kiosk's side"), put("prop_recycling_receptacle",69.1,19.0,0,"fan plaza: recycling against the kiosk's side"),
 ''.join(put("prop_bike_rack",x,27.0,0,"fan plaza: bikes") for x in (8.0,12.0,84.0,88.0)),
 ''.join(put("prop_bollard_steel",x,30.0,0,"fan plaza: bollards along the street edge") for x in (20.0,24.0,36.0,60.0,72.0,76.0)),
 put("prop_bus_shelter",46.0,29.4,0,"fan plaza: the game-day shuttle shelter facing the street"),
 ''.join(put("prop_lamp_victorian",x,4.0,0,"fan plaza: lit for night games") for x in (10.0,86.0)),
])
