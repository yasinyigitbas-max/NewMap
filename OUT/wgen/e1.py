from _common import *
R=ring_block('n_w_e1', -930.0, 209.0, '/home/user/NewMap/OUT/hdr_e1.txt', """Piece n_w_e1 (WEST FILL, the south-west edge's west end): u -930..-809, v 209..256, 121 x 47 m; flat at 2.0.
SITE: a street north (apron x 69..76.5), the ring road south. PLANNER: beach cottages facing the north street, a shared
lot off the apron between them, their yards fenced against the sound wall to the ring road.""",
  rows=[('w','n',3.0,2.0,62.0,['beach_white','beach_teal','spanish_small','beach_blue'],46.0,False),('e','n',3.0,84.0,119.0,['beach_blue','beach_teal'],46.0,False)],
  lanes=[('asphalt',64,0,82,44,'the shared lot off the apron (x 69..76.5)')],
  extra_body=''.join([stalls_col(66.5,6,40,90),stalls_col(79.5,6,40,-90),tyre(72.75,3,0),wear(64,0,82,44,6),'\tc.cmu(Vector2(0.6, 46.4), Vector2(120.4, 46.4), "ring road: the sound wall")\n']), W=121.0, D=47.0, wall=False)
globals().update(R)
