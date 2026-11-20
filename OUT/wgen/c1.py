from _common import *
NAME='n_w_c1'; U=-391.0; V=-791.0; W=182.0; D=91.0; Y0=6.15; HDR='/home/user/NewMap/OUT/hdr_c1.txt'
DOC='''Piece n_w_c1 (WEST FILL, civic band north): u -391..-209, v -791..-700, 182 x 91 m, flat 6.0..6.15.
SITE: 6th St north (aprons x 44..51.5, 130..137.5), streets west and east (aprons z 44..51.5), the civic heart (v_nw)
and the civic park (n_w_c2) south.
PLANNER: the civic band's front on 6th St, opposite the campus's east side: FIRE STATION 2 (engine bays straight onto
6th St over its apron, the training yard behind off the west apron), the POST OFFICE (customer lot off the second 6th St
apron), ST. ANDREW'S CHURCH (its garden behind); a shared lot behind them off the east apron.'''
SITES=[("civic/civ_fire_station",48.0,3.0,"n","fire_station"),("civic/civ_post_office",100.0,4.0,"n","post_office"),("civic/civ_church",166.0,4.0,"n","church")]
PAINTS=[("concrete",36,0,60,3,"the fire station's apron to the engine bays"),("concrete",0,30,60,91,"the fire station's training yard"),("asphalt",0,44,36,52,"lane from the west apron"),
        ("concrete",80,0,120,4,"the post office's steps and walk"),("asphalt",120,0,150,40,"the post office lot (6th St apron x 130..137.5)"),
        ("concrete",150,0,182,4,"the church's walk"),("asphalt",60,50,182,80,"the shared lot behind (east apron z 44..51.5)"),("grass",150,34,182,50,"the church garden")]
BODY='\n'+''.join([
 put("prop_hydrant_red",35.4,6.0,0,"fire station: the hydrant at its corner, against the wall"),
 put("prop_sign_no_parking",34.0,1.0,0,"fire station: keep the apron clear"),
 put("prop_sign_no_parking",61.0,1.0,0,"fire station: keep the apron clear"),
 ''.join(put("prop_cone_28in",10+k*3.0,60.0,0,"training yard: cones for the driving drills") for k in range(6)),
 put("prop_barricade_type3",30.0,70.0,0,"training yard: a barricade for drills"),
 put("prop_container_20ft_red",6.0,80.0,0,"training yard: the hose and gear store"),
 put("prop_bbq_gas_cart",58.6,28.0,-90,"fire station: the crew's grill against its back wall"),
 put("prop_picnic_table",52.0,34.0,0,"fire station: the crew's table out back"),
 put("prop_usps_collection_box",86.0,1.4,180,"post office: collection boxes on the walk"),
 put("prop_usps_collection_box",87.0,1.4,180,"post office: collection boxes on the walk"),
 put("prop_bike_rack",115.0,2.0,0,"post office: bikes by the steps"),
 put("prop_newspaper_box_red",118.0,1.4,180,"post office: papers"),
 put("prop_trash_receptacle",113.0,4.6,0,"post office: a bin against its corner"),
 stalls_row(123.0,147.0,8.0,180), stalls_row(123.0,147.0,36.0,0),
 put("prop_lot_light_pole",135.0,22.0,0,"post office lot: a light"),
 tyre(134.0,3.0,0.0), oil(128.4,8.0), wear(120,0,150,40,8),
 put("prop_poster_case",156.0,2.0,0,"church: the service times case by the walk"),
 put("plant_potted_leafy",162.0,3.2,0,"church: planters at the doors"), put("plant_potted_leafy",170.0,3.2,0,"church: planters at the doors"),
 put("prop_park_bench",160.0,44.0,0,"church garden: a bench facing the church's back"),
 put("prop_park_bench",172.0,44.0,0,"church garden: a bench facing the church's back"),
 put("prop_obelisk_monument",166.0,46.0,0,"church garden: the parish memorial"),
 ''.join(put("plant_bird_of_paradise",152.0+k*6,36.0,0,"church garden: a flower border") for k in range(5)),
 stalls_row(64.0,178.0,54.0,180,((44,52),)), stalls_row(64.0,178.0,76.0,0),
 put("prop_lot_light_pole",100.0,65.0,0,"shared lot: lights"), put("prop_lot_light_pole",150.0,65.0,0,"shared lot: lights"),
 tyre(179.0,48.0,-80.0), wear(60,50,182,80,14), oil(80.0,54.0), oil(120.5,76.0),
 put("prop_dumpster_3yd_green",112.4,14.0,90,"post office: waste against its east wall"),
])
