from _common import *
NAME='n_w_e1b'; U=-966.0; V=209.0; W=36.0; D=31.0; Y0=2.15; HDR='/home/user/NewMap/OUT/hdr_e1b.txt'
DOC="""Piece n_w_e1b (WEST FILL, the corner pocket by the ring road): u -966..-930, v 209..240, 36 x 31 m; flat 2.0.
PLANNER: a BEACH-SIDE POCKET: a rinse shower and a bench for people walking up from the shore, bike racks, a table."""
SITES=[]
PAINTS=[("concrete",0,0,36,5,"walk"),("sand",10,10,26,24,"a patch of sand by the shower")]
BODY='\n'+''.join([
 put("prop_beach_shower",18,17,0,"pocket: a rinse shower for people off the beach"), put("prop_park_bench",18,6.6,0,"pocket: a bench facing the sand"),
 ''.join(put("prop_bike_rack",x,3,0,"pocket: bikes") for x in (4,8,28)), put("prop_picnic_table",6,20,0,"pocket: a table"),
])
