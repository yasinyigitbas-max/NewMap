from _common import *
NAME='n_w_h4'; U=-145.0; V=-294.0; W=40.0; D=40.0; Y0=6.15; HDR='/home/user/NewMap/OUT/hdr_h4.txt'
DOC='''Piece n_w_h4 (WEST FILL, a 40 x 40 m hole in the stadium's car park): u -145..-105, v -294..-254, flat.
PLANNER: a second pair of TENNIS COURTS (the stadium end's public courts).'''
SITES=[]
PAINTS=[("concrete",2,2,38,38,"the courts")]
BODY='\n'+''.join([
 chain([(2,2),(38,2),(38,38),(2,38)],2,20.0,1.6,"tennis: the cage keeps balls in",gate="fence_gate_wrought_iron"),
 put("prop_tennis_net",11.0,20.0,0,"tennis: the net"), put("prop_tennis_net",29.0,20.0,0,"tennis: the net"),
 put("prop_park_bench",20.0,20.0,90,"tennis: players' bench between the courts"),
])
