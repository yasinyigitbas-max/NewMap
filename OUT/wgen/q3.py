from _common import *
NAME='n_w_q3'; U=-238.0; V=-568.0; W=29.0; D=20.0; Y0=6.15; HDR='/home/user/NewMap/OUT/hdr_q3.txt'
DOC="""Piece n_w_q3 (WEST FILL, a small hole left inside the civic heart (v_sw)): u -238..-209, v -568..-548, 29 x 20 m, flat.
PLANNER: a LUNCH CORNER for the civic offices: two tables and a bike rack."""
SITES=[]
PAINTS=[('concrete',0,0,29,20,'paving')]
BODY='\n'+''.join([put('prop_picnic_table',8,10,0,'lunch corner: a table'),put('prop_picnic_table',20,10,0,'lunch corner: a table'),put('prop_bike_rack',14,18.6,0,'lunch corner: bikes')])
