from _common import *
NAME='n_w_q2'; U=-244.0; V=-695.0; W=24.0; D=30.0; Y0=6.15; HDR='/home/user/NewMap/OUT/hdr_q2.txt'
DOC="""Piece n_w_q2 (WEST FILL, a small hole left inside the civic heart (v_nw)): u -244..-220, v -695..-665, 24 x 30 m, flat.
PLANNER: a quiet SEATING GARDEN for the civic offices: a bench facing beds of agaves, a fountain."""
SITES=[]
PAINTS=[('concrete',10,0,14,30,'path'),('mulch',2,4,9,26,'bed'),('mulch',15,4,22,26,'bed')]
BODY='\n'+''.join([''.join(put('plant_agave_americana_small',5,8+k*6,0,'seating garden: agaves') for k in range(3)),''.join(put('plant_agave_americana_small',19,8+k*6,0,'seating garden: agaves') for k in range(3)),put('prop_park_bench',12,10,90,'seating garden: a bench on the path facing a bed'),put('prop_drinking_fountain',12.0,26,0,'seating garden: water')])
