from _common import *
R=ring_block('n_w_x1', -791.0, -391.0, '/home/user/NewMap/OUT/hdr_x1.txt', """Piece n_w_x1 (WEST FILL, between the west strip and the campus's south-west): u -791..-609, v -391..-300, 182 x 91 m;
land 4.2 (west) to 6.2 (east). SITE: a street north (aprons x 44..51.5, 130..137.5), streets west and east (aprons z
44..51.5), the residential quarter's yards south.
PLANNER: RESIDENTIAL: houses facing the north street, a back lane from the west apron to the east apron, a second row
of houses facing the lane with their yards fenced against the quarter's yards behind.""",
  rows=[('n1','n',3.0,4.0,42.0,['ranch_peach','spanish_small','beach_teal'],44.0,True),
        ('n2','n',3.0,54.0,128.0,['craftsman_sage','tudor_brick','mcm_teal','colonial_white','spanish_white'],44.0,True),
        ('n3','n',3.0,140.0,178.0,['hipranch_sand','ranch_porch','cape_white'],44.0,True),
        ('s1','n',56.0,4.0,178.0,['ranch_pink','spanish_peach','craftsman_olive','contemporary_white','mcm_white','cape_grey','tudor_stucco','ranch_siding','beach_blue','colonial_blue','spanish_pink','craftsman_cedar'],90.4,False)],
  lanes=[('asphalt',0,44,182,50,'the back lane (west apron to east apron, z 44..51.5)'),('asphalt',44,0,52,44,'lane from the first north apron'),('asphalt',130,0,138,44,'lane from the second north apron')],
  extra_body=''.join([lane_wear(0,44,182,50,False),tyre(3,47,90),tyre(179,47,-90),tyre(48,3,0),tyre(134,3,0)]), W=182.0, D=91.0, wall=False)
globals().update(R)
