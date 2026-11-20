from _common import *
NAME='n_w_q1'; U=-678.0; V=-930.0; W=16.0; D=11.0; Y0=6.15; HDR='/home/user/NewMap/OUT/hdr_q1.txt'
DOC="""Piece n_w_q1 (WEST FILL, a small hole left inside the gritty edge (the square Yasin marked in the 51 % block)): u -678..-662, v -930..-919, 16 x 11 m, flat.
PLANNER: a POCKET GARDEN for the walk-ups round it: a bench facing a flower bed."""
SITES=[]
PAINTS=[('concrete',0,0,16,3,'walk')]
BODY='\n'+''.join([put('prop_park_bench',8,2.0,0,'pocket garden: a bench facing the bed'),''.join(put('plant_bird_of_paradise',3+k*5,7,0,'pocket garden: the bed') for k in range(3))])
