from _common import *
NAME='n_w_q4'; U=-134.0; V=-538.0; W=28.0; D=36.0; Y0=6.15; HDR='/home/user/NewMap/OUT/hdr_q4.txt'
DOC="""Piece n_w_q4 (WEST FILL, a small hole left inside the civic heart (v_se)): u -134..-106, v -538..-502, 28 x 36 m, flat.
PLANNER: a small PLAYGROUND for families visiting the civic offices: mulch pad, play structure, swings, a bench facing it."""
SITES=[]
PAINTS=[('mulch',4,6,24,30,'the play pad')]
BODY='\n'+''.join([put('prop_play_structure',14,16,0,'playground: the climbing frame'),put('prop_swing_set',14,26,0,'playground: swings'),put('prop_park_bench',14,2.6,0,'playground: a bench facing it')])
