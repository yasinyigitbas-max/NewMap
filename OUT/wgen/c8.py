from _common import *
NAME='n_w_c8'; U=-391.0; V=-391.0; W=86.0; D=182.0; Y0=6.15; HDR='/home/user/NewMap/OUT/hdr_c8.txt'
DOC='''Piece n_w_c8 (WEST FILL, west of the stadium): u -391..-305, v -391..-209, 86 x 182 m, flat.
SITE: a street west (aprons z 44..51.5, 130..137.5) facing the campus's south-east and the park block, a street north and
south (aprons x 44..51.5), the stadium east.
PLANNER: the stadium's west side: STADIUM TEAM STORE, THE BULLPEN (sports bar), the TOUCHDOWN DINER face the west street;
behind them the TAILGATE LOT (rows, lights, grills on the edges) between the street and the stadium.'''
SITES=[("commercial/com_boutique_row",3.0,20.0,"w","team_store"),("commercial/com_bar_crown",3.0,70.0,"w","bullpen_bar"),("commercial/com_bistro",3.0,100.0,"w","touchdown_diner")]
PAINTS=[("concrete",0,0,3,182,"frontage"),("asphalt",0,44,24,52,"lane from the first west apron"),("asphalt",0,130,24,138,"lane from the second west apron"),
        ("asphalt",24,6,84,176,"the tailgate lot"),("asphalt",44,176,52,182,"to the south apron"),("concrete",0,140,24,182,"the corner plaza")]
BODY='\n'+''.join([
 ''.join(stalls_row(28.0,80.0,z,180 if k%2==0 else 0) for k,z in enumerate((10,30,34,54,58,78,82,102,106,126,130,150,154,172))),
 ''.join(put("prop_lot_light_pole",54.0,z,0,"tailgate lot: lights between the rows") for z in (32.0,80.0,128.0)),
 ''.join(put("prop_bbq_kettle",x,z,0,"tailgate lot: a grill left at the lot edge") for x,z in ((25.4,40.0),(25.4,116.0))),
 put("prop_bbq_gas_cart",25.6,160.0,90,"tailgate lot: a gas grill at the edge"),
 wear(24,6,84,176,26), tyre(3.0,48.0,90.0), tyre(3.0,134.0,90.0), tyre(48.0,180.0,0.0),
 ''.join(oil(x,z) for x,z in ((33.4,30.0),(49.6,54.0),(60.4,102.0),(44.2,150.0))),
 put("prop_menu_board",1.0,64.0,90,"The Bullpen: game-day specials"), put("prop_menu_board",1.0,94.0,90,"Touchdown Diner: the menu"),
 ''.join(put("prop_bike_rack",1.6,z,90,"stadium side: bikes along the frontage") for z in (34.0,44.0)),
 put("prop_newspaper_box_red",1.2,58.0,90,"stadium side: the sports paper"),
 ''.join(put("prop_cafe_table",x,z,0,"corner plaza: tables outside the diner") for x,z in ((8,150),(14,150),(8,158),(14,158))),
 put("prop_bus_shelter",1.2,166.0,90,"corner plaza: the game-day bus shelter facing the street"),
 put("prop_bench_bus_stop",1.4,174.0,90,"bus stop: a seat"),
 put("prop_dumpster_3yd_green",19.0,64.0,0,"The Bullpen: waste against its back wall"),
])
