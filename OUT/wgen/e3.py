from _common import *
R=ring_block('n_w_e3', -591.0, 209.0, '/home/user/NewMap/OUT/hdr_e3.txt', """Piece n_w_e3 (WEST FILL, the south-west edge): u -591..-409, v 209..288, 182 x 79 m; land 2.0..4.2 toward the shore.
SITE: a street north (aprons x 44..51.5, 130..137.5), the ring road south.
PLANNER: beach-side houses facing the north street, a back lane, the sound wall to the ring road.""",
  rows=[('r0','n',3.0,2.0,42.0,['spanish_peach','beach_blue','ranch_pink'],56.0,True),
        ('r1','n',3.0,54.0,128.0,['craftsman_stucco','beach_white','mcm_teal','spanish_small','ranch_siding'],56.0,True),
        ('r2','n',3.0,140.0,180.0,['beach_large','spanish_white','cape_grey'],56.0,True)],
  lanes=[('asphalt',0,56.0,182.0,62.0,'the back lane'),('asphalt',44.0,0,52.0,56.0,'lane from the north apron'),('asphalt',130.0,0,138.0,56.0,'lane from the north apron')],
  extra_sites=[], extra_paints=[],
  extra_body=''.join([lane_wear(0,56.0,182.0,62.0,False),tyre(48,3,0),tyre(134,3,0)]), W=182.0, D=79.0, wall=False)
globals().update(R)
