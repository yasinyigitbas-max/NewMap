from _common import *
R=ring_block('n_w_e4', -391.0, 209.0, '/home/user/NewMap/OUT/hdr_e4.txt', """Piece n_w_e4 (WEST FILL, the south-west edge by the beach road): u -391..-209, v 209..302, 182 x 93 m; flat at 2.0.
SITE: a street north (aprons x 44..51.5, 130..137.5), the ring road south (the beach beyond it).
PLANNER: beach-side houses facing the north street; on the east end the SURF SHACK (surf shop) and the BEACH BEAN café
facing the street with bikes, boards and tables; a back lane, the sound wall to the ring road.""",
  rows=[('r0','n',3.0,2.0,42.0,['beach_teal','beach_white','spanish_small'],66.0,True),
        ('r1','n',3.0,54.0,128.0,['beach_blue','ranch_peach','beach_large','spanish_pink','cape_white'],66.0,True)],
  lanes=[('asphalt',0,66.0,182.0,72.0,'the back lane'),('asphalt',44.0,0,52.0,66.0,'lane from the north apron'),('asphalt',130.0,0,138.0,66.0,'lane from the north apron')],
  extra_sites=[('commercial/com_surf_shop',150.0,3.0,'n','surf_shack'),('commercial/com_cafe_seaside',166.0,3.0,'n','beach_bean')], extra_paints=[('concrete',140,0,182,3,'the shops\' frontage'),('concrete',172,3,182,30,'the café terrace')],
  extra_body=''.join([lane_wear(0,66.0,182.0,72.0,False),'\tc.cmu(Vector2(0.6, 92.40), Vector2(181.40, 92.40), "ring road: the sound wall behind the lane")\n',tyre(48,3,0),tyre(134,3,0),put('prop_kayak_rack',143,1.6,0,'Surf Shack: boards and kayaks on the rack outside'),put('prop_bike_rack',158.2,1.6,0,'the shops: bikes'),put('prop_menu_board',171,1.4,0,'Beach Bean: the menu'),''.join(put('prop_cafe_table',x,z,0,'Beach Bean: a table on its terrace') for x,z in ((175,8),(179,8),(175,14),(179,14),(175,20))),put('prop_beach_shower',178,28,0,'Beach Bean: a rinse shower for people off the beach')]), W=182.0, D=93.0, wall=False)
globals().update(R)
