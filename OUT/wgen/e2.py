from _common import *
R=ring_block('n_w_e2', -791.0, 209.0, '/home/user/NewMap/OUT/hdr_e2.txt', """Piece n_w_e2 (WEST FILL, the south-west edge): u -791..-609, v 209..275, 182 x 66 m; the land falls from 4.2 (east) to
2.0 (west) toward the shore. SITE: a street north (aprons x 44..51.5, 130..137.5), the ring road south.
PLANNER: the beach side's houses (beach cottages, ranches, spanish) facing the north street on their own pads down the
slope, a back lane between the aprons, a sound wall along the ring road behind it.""",
  rows=[('r0','n',3.0,2.0,42.0,['beach_white','beach_teal','spanish_small'],46.0,True),
        ('r1','n',3.0,54.0,128.0,['beach_blue','ranch_peach','spanish_white','beach_large','cape_white'],46.0,True),
        ('r2','n',3.0,140.0,180.0,['ranch_porch','beach_teal','spanish_pink'],46.0,True)],
  lanes=[('asphalt',0,46.0,182.0,52.0,'the back lane'),('asphalt',44.0,0,52.0,46.0,'lane from the north apron'),('asphalt',130.0,0,138.0,46.0,'lane from the north apron')],
  extra_sites=[], extra_paints=[],
  extra_body=''.join([lane_wear(0,46.0,182.0,52.0,False),'\tc.cmu(Vector2(0.6, 65.40), Vector2(181.40, 65.40), "ring road: the sound wall behind the lane")\n',tyre(48,3,0),tyre(134,3,0)]), W=182.0, D=66.0, wall=False)
globals().update(R)
