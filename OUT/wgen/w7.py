from _common import *
NAME='n_w_w7'; U=-980.0; V=9.0; W=171.0; D=181.0; Y0=4.15; HDR='/home/user/NewMap/OUT/hdr_w7.txt'
DOC="""Piece n_w_w7 (WEST FILL, the crest of Country Club Ridge): u -980..-809, v 9..190, 171 x 181 m; the land climbs from
2.0 (south-west, toward the shore) to 8.2 (north-east, the crest).
SITE: a street north (aprons x 119..126.5), the east street (aprons z 44..51.5, 130..137.5), the ring road south and west.
PLANNER: RIDGE PARK (ZONING: Country Club Ridge's west houses run down to the beach and the park): an OVERLOOK on the
crest with benches facing south-west over the shore, lawns falling down the ridge, a playground, a picnic grove with
grills, paths lit at night, the park's lot off the east apron, the snack hut; its trees come with the tree layer."""
SITES=[("commercial/com_kiosk",150.0,60.0,"w","snack_hut")]
PAINTS=[("asphalt",128,40,171,58,"the park's lot (east apron z 44..51.5)"),("plaza",120,8,165,34,"the overlook terrace on the crest"),
        ("concrete",90,0,96,181,"the north-south path"),("concrete",0,96,171,100,"the east-west path"),("mulch",100,110,140,140,"the playground's mulch pad"),
        ("concrete",120,34,126,40,"steps from the lot to the overlook")]
BODY='\n'+''.join([
 ''.join(put("prop_park_bench",x,30.6,180,"overlook: a bench facing south-west over the ridge to the shore") for x in (126,134,142,150,158)),
 put("prop_obelisk_monument",142,14,0,"overlook: the ridge's survey marker and plaque"),
 put("prop_drinking_fountain",164,20,0,"overlook: water"),
 ''.join(put("prop_lamp_victorian",x,z,0,"park: the paths lit") for x,z in ((96.6,20),(96.6,70),(96.6,130),(40,100.6),(140,100.6))),
 put("prop_play_structure",114,124,0,"playground: the climbing frame on mulch"), put("prop_swing_set",130,116,0,"playground: swings"), put("prop_slide",130,134,0,"playground: the slide"),
 put("prop_park_bench",120,142.6,180,"playground: a bench for the parents facing it"), put("prop_shade_sail",106,136,0,"playground: shade"),
 ''.join(put("prop_picnic_table",x,z,0,"picnic grove: a table on the slope") for x,z in ((30,40),(46,30),(30,60),(50,56),(20,80))),
 ''.join(put("prop_bbq_kettle",x,z,0,"picnic grove: a grill by the tables") for x,z in ((38,44),(42,62))),
 stalls_row(131,168,44,180), stalls_row(131,168,54,0), tyre(168,48,-80), wear(128,40,171,58,6),
 put("prop_menu_board",148.6,58.6,-90,"snack hut: ice cream and drinks"),
 ''.join(put("prop_bike_rack",x,61.0,0,"park: bikes by the lot") for x in (130,134)),
 put("prop_sprinkler_impact",60,140,0,"park: the lawn's sprinkler"), put("prop_sprinkler_impact",40,160,0,"park: the lawn's sprinkler"),
 put("prop_beach_sign_rules",92,178,0,"park: the park rules at the south path's end"),
])
