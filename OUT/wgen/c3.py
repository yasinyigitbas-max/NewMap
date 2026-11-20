from _common import *
NAME='n_w_c3'; U=-391.0; V=-591.0; W=86.0; D=182.0; Y0=6.15; HDR='/home/user/NewMap/OUT/hdr_c3.txt'
DOC='''Piece n_w_c3 (WEST FILL, east of the campus): u -391..-305, v -591..-409, 86 x 182 m, flat.
SITE: the street along the campus's east side west (aprons z 44..51.5, 130..137.5), a street north (aprons x 44..51.5),
the civic heart east (v_sw), the street south of the campus band south.
PLANNER: STAFF TOWNHOUSES facing the campus (the garage and the stadium walk) across the street, their parking courts
behind off the aprons, back yards; the SENIOR CENTER on the south corner with a garden of benches and tables.'''
SITES=[("apartments/apt_townhouse_cays",3.0,18.3,"w","townhouses_1"),("apartments/apt_townhouse_cays",3.0,70.3,"w","townhouses_2"),
       ("apartments/apt_townhouse_modern",3.0,94.0,"w","townhouses_3"),("apartments/apt_townhouse_cays",3.0,118.3,"w","townhouses_4"),
       ("civic/civ_community_center",3.0,160.0,"w","senior_center")]
PAINTS=[("concrete",0,0,3,182,"the frontage on the walk"),("asphalt",0,44,40,52,"lane from the first west apron"),("asphalt",0,130,40,138,"lane from the second west apron"),
        ("asphalt",40,10,70,128,"the residents' parking court"),("asphalt",44,0,52,10,"lane from the north apron"),("concrete",30,140,86,182,"the senior center's garden walks"),
        ("grass",36,146,80,176,"the senior center's lawn")]
BODY='\n'+''.join([
 stalls_col(44.0,14.0,126.0,90,((42,54),)), stalls_col(66.0,14.0,126.0,-90),
 put("prop_lot_light_pole",55.0,40.0,0,"court: lights"), put("prop_lot_light_pole",55.0,100.0,0,"court: lights"),
 wear(40,10,70,128,14), tyre(3.0,48.0,90.0), tyre(3.0,134.0,90.0), tyre(48.0,3.0,0.0), oil(44.0,30.2,90), oil(66.0,90.6,90),
 ''.join(put("prop_bbq_kettle",30.0,z,0,"townhouses: a grill in the back yard") for z in (14.0,72.0,118.0)),
 ''.join(put("prop_clothesline",34.0,z,90,"townhouses: washing out back") for z in (24.0,96.0)),
 ''.join(put("prop_bike_rack",2.0,z,90,"townhouses: bikes by the doors, along the frontage") for z in (32.0,84.0,108.0)),
 put("prop_mailbox_cluster" if False else "prop_usps_collection_box",1.4,40.0,90,"townhouses: the mailbox on the walk"),
 put("prop_park_bench",50.0,156.0,180,"senior center garden: a bench facing the lawn"),
 put("prop_park_bench",64.0,156.0,180,"senior center garden: a bench facing the lawn"),
 put("prop_park_bench",50.0,170.0,0,"senior center garden: a bench facing the lawn"),
 put("prop_picnic_table",72.0,166.0,0,"senior center garden: a table for cards outdoors"),
 put("prop_drinking_fountain",33.0,150.0,0,"senior center garden: water by the walk"),
 ''.join(put("plant_bird_of_paradise",40.0+k*6,178.0,0,"senior center garden: a flower border") for k in range(6)),
 put("prop_bench_bus_stop",1.4,176.0,90,"senior center: a seat on the walk facing the street"),
 put("prop_trash_receptacle",22.9,170.0,0,"senior center: a bin against its corner"),
 put("prop_lamp_victorian",34.0,160.0,0,"senior center garden: lit"),
])
