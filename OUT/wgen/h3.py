from _common import *
NAME='n_w_h3'; U=-195.0; V=-294.0; W=40.0; D=40.0; Y0=6.15; HDR='/home/user/NewMap/OUT/hdr_h3.txt'
DOC='''Piece n_w_h3 (WEST FILL, a 40 x 40 m hole in the stadium's car park): u -195..-155, v -294..-254, flat.
PLANNER: a PICNIC GROVE for tailgaters who walk off the lot: lawn, tables, grills, benches (its trees come with the tree layer).'''
SITES=[]
PAINTS=[("concrete",18,0,22,40,"a path through it")]
BODY='\n'+''.join([
 ''.join(put("prop_picnic_table",x,z,0,"picnic grove: a table on the lawn") for x,z in ((8,8),(32,8),(8,30),(32,30))),
 ''.join(put("prop_bbq_kettle",x,z,0,"picnic grove: a grill by the tables") for x,z in ((12,14),(28,24))),
 put("prop_trash_receptacle",20.0,20.0,0,"picnic grove: a bin on the path") if False else '',
 put("prop_park_bench",17.0,20.0,-90,"picnic grove: a bench by the path facing the lawn"),
 put("prop_lamp_victorian",22.6,10.0,0,"picnic grove: lit"),
])
