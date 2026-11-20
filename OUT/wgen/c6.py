from _common import *
NAME='n_w_c6'; U=-591.0; V=-391.0; W=182.0; D=91.0; Y0=6.15; HDR='/home/user/NewMap/OUT/hdr_c6.txt'
DOC='''Piece n_w_c6 (WEST FILL, south of the campus): u -591..-409, v -391..-300, 182 x 91 m, flat.
SITE: the campus's south street north (aprons x 44..51.5, 130..137.5), streets west and east (aprons z 44..51.5), the
residential quarter (r_q) and the park block (n_w_c7) south.
PLANNER: FACULTY APARTMENTS facing the campus's dorms across the street (spanish, garden, stucco), and on the east corner
BRIGHT START CHILD CARE with its fenced playground; parking courts behind off the aprons, yards with barbecues.'''
SITES=[("apartments/apt_spanish_revival",14.0,3.0,"n","faculty_1"),("apartments/apt_garden_cream",66.0,3.0,"n","faculty_2"),
       ("apartments/apt_stucco3_cream",92.0,3.0,"n","faculty_3"),("apartments/apt_spanish_white",114.0,3.0,"n","faculty_4"),
       ("civic/civ_school_wing",160.0,3.0,"n","child_care")]
PAINTS=[("concrete",0,0,182,3,"frontage"),("asphalt",44,0,52,40,"lane from the first north apron"),("asphalt",128,0,140,40,"lane from the second north apron"),
        ("asphalt",0,40,140,60,"the residents' parking (west apron z 44..51.5)"),("mulch",146,32,180,60,"the child care's playground"),("asphalt",140,62,182,88,"child care drop-off lot (east apron)")]
BODY='\n'+''.join([
 stalls_row(4.0,124.0,43.0,180,((42,54),)), stalls_row(4.0,124.0,57.0,0,((42,54),)),
 put("prop_lot_light_pole",30.0,50.0,0,"parking: lights"), put("prop_lot_light_pole",100.0,50.0,0,"parking: lights"),
 wear(0,40,140,60,14), tyre(3.0,48.0,90.0), tyre(48.0,3.0,0.0), tyre(134.0,3.0,0.0), oil(20.2,43.0), oil(90.4,57.0),
 chain([(146,32),(180,32),(180,60),(146,60)],2,17.0,1.1,"child care: a picket fence round its playground",gate="fence_gate_picket",kind="picket"),
 put("prop_play_structure",156.0,44.0,0,"child care playground: the climbing frame on mulch"),
 put("prop_slide",170.0,40.0,0,"child care playground: the slide"),
 put("prop_swing_set",170.0,52.0,0,"child care playground: swings"),
 put("prop_shade_sail",154.0,54.0,0,"child care playground: shade over the sandpit side"),
 put("prop_park_bench",163.0,58.0,180,"child care playground: a bench for the staff facing it"),
 stalls_row(144.0,178.0,66.0,180), tyre(179.0,48.0,-80.0), wear(140,62,182,88,6),
 put("prop_sign_no_parking",141.0,63.0,0,"drop-off: 10 minutes"),
 ''.join(put("prop_bbq_kettle",x,30.0,0,"faculty apartments: a grill in the yard") for x in (14.0,66.0,110.0)),
 ''.join(put("prop_picnic_table",x,26.0,0,"faculty apartments: a table in the yard") for x in (20.0,72.0)),
 ''.join(put("prop_bike_rack",x,1.6,0,"apartments: bikes along the frontage") for x in (28.0,80.0,104.0)),
 put("prop_lamp_victorian",40.0,1.2,0,"frontage: lamps"), put("prop_lamp_victorian",126.0,1.2,0,"frontage: lamps"),
 put("prop_poster_case",143.4,1.6,0,"child care: the notices by its gate"),
])
