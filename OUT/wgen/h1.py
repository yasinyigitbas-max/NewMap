from _common import *
NAME='n_w_h1'; U=-295.0; V=-294.0; W=40.0; D=40.0; Y0=6.15; HDR='/home/user/NewMap/OUT/hdr_h1.txt'
DOC='''Piece n_w_h1 (WEST FILL, a 40 x 40 m hole in the stadium's car park): u -295..-255, v -294..-254, flat.
PLANNER: the stadium's car park left four kit-park-sized holes; this one becomes TENNIS COURTS (two, in a chain-link cage).'''
SITES=[]
PAINTS=[("concrete",2,2,38,38,"the courts")]
BODY='\n'+''.join([
 chain([(2,2),(38,2),(38,38),(2,38)],2,20.0,1.6,"tennis: the cage keeps balls in",gate="fence_gate_wrought_iron"),
 put("prop_tennis_net",11.0,20.0,0,"tennis: the net"), put("prop_tennis_net",29.0,20.0,0,"tennis: the net"),
 put("prop_park_bench",20.0,20.0,90,"tennis: players' bench between the courts"),
])
