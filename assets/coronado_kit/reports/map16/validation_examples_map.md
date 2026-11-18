# Merged map layouts validation

20/22 pass.

| layout | class | near/mid/far | budget | pieces | col boxes | mid/near | far IoU | result |
|---|---|---|---|---|---|---|---|---|
| apt3_row2 | apartment | 3112/764/10 | 3500/1000/80 | 8 | 1 | 0.25 | 0.99 | PASS |
| apt3_row3 | apartment_large | 3596/944/10 | 5000/1500/120 | 11 | 1 | 0.26 | 0.99 | PASS |
| brk3_corner2 | apartment | 3434/784/34 | 3500/1000/80 | 10 | 1 | 0.23 | 0.996 | PASS |
| brk3_row2 | apartment | 2998/726/34 | 3500/1000/80 | 8 | 1 | 0.24 | 0.997 | PASS |
| brk3_row3 | apartment | 3460/826/34 | 3500/1000/80 | 11 | 1 | 0.24 | 0.999 | PASS |
| civ_hall3 | civic | 2848/513/112 | 5000/1500/120 | 16 | 1 | 0.18 | 0.993 | PASS |
| garage_w6_stucco | mod_house_small | 1182/280/32 | 1650/500/40 | 10 | 2 | 0.24 | 0.969 | PASS |
| garage_w9_clay | mod_house_small | 1390/348/32 | 1650/500/40 | 12 | 2 | 0.25 | 0.978 | PASS |
| garage_w9_siding | mod_house_small | 1442/372/32 | 1650/500/40 | 16 | 2 | 0.26 | 0.976 | PASS |
| house_w6_clay | mod_house_small | 1364/304/22 | 1650/500/40 | 11 | 2 | 0.22 | 0.979 | PASS |
| house_w6_comp | mod_house_small | 1362/296/22 | 1650/500/40 | 11 | 2 | 0.22 | 0.98 | PASS |
| house_w6_comp_siding | mod_house_small | 1428/328/22 | 1650/500/40 | 15 | 2 | 0.23 | 0.98 | PASS |
| house_w6_peach_porch | mod_house_small | 1627/352/22 | 1650/500/40 | 11 | 2 | 0.22 | 0.979 | PASS |
| house_w9_pink_hip | mod_house_small | 1394/300/22 | 1650/500/40 | 12 | 2 | 0.22 | 0.977 | PASS |
| shop_row2_surf_cafe | shop | 2314/524/30 | 2400/700/40 | 10 | 1 | 0.23 | 0.989 | PASS |
| shop_row3 | shop | 3096/692/40 | 3600/1050/60 | 13 | 1 | 0.22 | 0.99 | PASS |
| shop_row4 | shop | 3878/860/50 | 4800/1400/80 | 16 | 1 | 0.22 | 0.99 | PASS |
| stg_row2 | warehouse | 1094/245/30 | 2000/600/40 | 8 | 1 | 0.22 | 0.981 | FAIL: far vs mid: window/banding rows 1 on far vs 4 on mid |
| stg_row3 | warehouse | 1576/349/40 | 2000/600/40 | 11 | 1 | 0.22 | 0.981 | FAIL: far vs mid: window/banding rows 1 on far vs 3 on mid |
| svb_row2 | shop | 1572/436/32 | 2400/700/40 | 8 | 1 | 0.28 | 0.998 | PASS |
| svb_row3 | shop | 2154/594/32 | 3600/1050/60 | 11 | 1 | 0.28 | 0.998 | PASS |
| twr_bay1 | tower | 2552/762/74 | 4000/1200/80 | 5 | 1 | 0.3 | 0.994 | PASS |
