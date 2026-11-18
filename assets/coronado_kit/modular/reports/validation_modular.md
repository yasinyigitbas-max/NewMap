# Modular starter set validation

Pieces: 116/116 pass. Examples: 11/11 pass.

Snap-in houses are checked against `mod_house_small` = 1650/500/40 (SPEC §7: snap-in houses 1650 cap, approved by Yasin 15 Nov 2026 19:36) and must meet the full house detail floor, chimney and entry-step railing included.

| group | piece | class | near/mid/far | budget | col boxes | baked opening regions | result |
|---|---|---|---|---|---|---|---|
| houses | house_roof_chimney_brick | mod_house_trim | 72/16/12 | 90/24/12 | 1 | - | PASS |
| houses | house_roof_chimney_brick_clay | mod_house_trim | 60/16/12 | 90/24/12 | 1 | - | PASS |
| houses | house_roof_gable_endl_3m_clay_stucco | mod_house_roof | 158/31/7 | 240/72/8 | 1 | O_vent | PASS |
| houses | house_roof_gable_endl_3m_clay_stucco_white | mod_house_roof | 158/31/7 | 240/72/8 | 1 | O_vent | PASS |
| houses | house_roof_gable_endl_3m_comp_siding | mod_house_roof | 164/31/7 | 240/72/8 | 1 | O_vent | PASS |
| houses | house_roof_gable_endl_3m_comp_stucco | mod_house_roof | 164/31/7 | 240/72/8 | 1 | O_vent | PASS |
| houses | house_roof_gable_endr_3m_clay_stucco | mod_house_roof | 158/31/7 | 240/72/8 | 1 | O_vent | PASS |
| houses | house_roof_gable_endr_3m_clay_stucco_white | mod_house_roof | 158/31/7 | 240/72/8 | 1 | O_vent | PASS |
| houses | house_roof_gable_endr_3m_comp_siding | mod_house_roof | 164/31/7 | 240/72/8 | 1 | O_vent | PASS |
| houses | house_roof_gable_endr_3m_comp_stucco | mod_house_roof | 164/31/7 | 240/72/8 | 1 | O_vent | PASS |
| houses | house_roof_gable_run_3m_clay | mod_house_roof | 76/12/4 | 160/50/8 | 1 | - | PASS |
| houses | house_roof_gable_run_3m_comp | mod_house_roof | 76/12/4 | 160/50/8 | 1 | - | PASS |
| houses | house_trim_corner_white | mod_house_trim | 10/6/6 | 40/12/8 | 1 | - | PASS |
| houses | house_wall_1p5m_small_siding | mod_house_wall | 64/16/20 | 120/40/24 | 1 | O_small_white | PASS |
| houses | house_wall_1p5m_small_stucco | mod_house_wall | 64/16/20 | 120/40/24 | 1 | O_small_white | PASS |
| houses | house_wall_1p5m_small_stucco_white | mod_house_wall | 64/16/20 | 120/40/24 | 1 | O_small_white | PASS |
| houses | house_wall_3m_bay_siding | mod_house_wall | 314/100/60 | 360/120/80 | 2 | O_win_casement | PASS |
| houses | house_wall_3m_bay_stucco | mod_house_wall | 314/100/60 | 360/120/80 | 2 | O_win_casement | PASS |
| houses | house_wall_3m_bay_stucco_white | mod_house_wall | 314/100/60 | 360/120/80 | 2 | O_win_casement | PASS |
| houses | house_wall_3m_door_siding | mod_house_wall | 242/66/44 | 320/100/56 | 5 | O_door_white, O_lamp, O_number | PASS |
| houses | house_wall_3m_door_stucco | mod_house_wall | 242/66/44 | 320/100/56 | 5 | O_door_white, O_lamp, O_number | PASS |
| houses | house_wall_3m_door_stucco_clayhood | mod_house_wall | 242/66/44 | 320/100/56 | 5 | O_door_white, O_lamp, O_number | PASS |
| houses | house_wall_3m_door_stucco_white | mod_house_wall | 242/66/44 | 320/100/56 | 5 | O_door_white, O_lamp, O_number | PASS |
| houses | house_wall_3m_door_stucco_white_clayhood | mod_house_wall | 242/66/44 | 320/100/56 | 5 | O_door_white, O_lamp, O_number | PASS |
| houses | house_wall_3m_garage_siding | mod_house_wall | 36/16/16 | 160/50/24 | 1 | O_garage_panel | PASS |
| houses | house_wall_3m_garage_stucco | mod_house_wall | 36/16/16 | 160/50/24 | 1 | O_garage_panel | PASS |
| houses | house_wall_3m_garage_stucco_white | mod_house_wall | 36/16/16 | 160/50/24 | 1 | O_garage_panel | PASS |
| houses | house_wall_3m_utility_siding | mod_house_wall | 96/16/20 | 220/70/48 | 1 | O_small_white, O_vent | PASS |
| houses | house_wall_3m_utility_stucco | mod_house_wall | 96/16/20 | 220/70/48 | 1 | O_small_white, O_vent | PASS |
| houses | house_wall_3m_utility_stucco_white | mod_house_wall | 96/16/20 | 220/70/48 | 1 | O_small_white, O_vent | PASS |
| houses | house_wall_3m_window_pair_siding | mod_house_wall | 110/24/36 | 220/70/48 | 1 | O_win_casement | PASS |
| houses | house_wall_3m_window_pair_stucco | mod_house_wall | 110/24/36 | 220/70/48 | 1 | O_win_casement | PASS |
| houses | house_wall_3m_window_pair_stucco_white | mod_house_wall | 110/24/36 | 220/70/48 | 1 | O_win_casement | PASS |
| houses | house_wall_3m_window_siding | mod_house_wall | 84/16/20 | 220/70/48 | 1 | O_shutter, O_win_dh_white | PASS |
| houses | house_wall_3m_window_stucco | mod_house_wall | 84/16/20 | 220/70/48 | 1 | O_shutter, O_win_dh_white | PASS |
| houses | house_wall_3m_window_stucco_white | mod_house_wall | 84/16/20 | 220/70/48 | 1 | O_shutter, O_win_dh_white | PASS |
| houses | house_wall_4p5m_utility_siding | mod_house_wall | 150/36/36 | 240/72/48 | 1 | O_small_white, O_vent, O_win_casement | PASS |
| houses | house_wall_4p5m_utility_stucco | mod_house_wall | 150/36/36 | 240/72/48 | 1 | O_small_white, O_vent, O_win_casement | PASS |
| houses | house_wall_4p5m_utility_stucco_white | mod_house_wall | 150/36/36 | 240/72/48 | 1 | O_small_white, O_vent, O_win_casement | PASS |
| houses | house_wall_4p5m_window_small_siding | mod_house_wall | 138/36/36 | 240/72/48 | 1 | O_shutter, O_small_white, O_win_dh_white | PASS |
| houses | house_wall_4p5m_window_small_stucco | mod_house_wall | 138/36/36 | 240/72/48 | 1 | O_shutter, O_small_white, O_win_dh_white | PASS |
| houses | house_wall_4p5m_window_small_stucco_white | mod_house_wall | 138/36/36 | 240/72/48 | 1 | O_shutter, O_small_white, O_win_dh_white | PASS |
| shops | shop_back_6m_stucco | mod_shop_back | 168/56/4 | 300/90/8 | 1 | O_apt_door, O_lamp, O_louver, O_small_white | PASS |
| shops | shop_front_6m_bakery_navy | mod_shop_front | 300/60/26 | 700/210/48 | 1 | O_shopdoor, O_storefront | PASS |
| shops | shop_front_6m_books_green | mod_shop_front | 300/60/26 | 700/210/48 | 1 | O_shopdoor, O_storefront | PASS |
| shops | shop_front_6m_cafe_red | mod_shop_front | 300/60/26 | 700/210/48 | 1 | O_shopdoor, O_storefront | PASS |
| shops | shop_front_6m_surf_black | mod_shop_front | 300/60/26 | 700/210/48 | 1 | O_shopdoor, O_storefront | PASS |
| shops | shop_roof_6m_end | mod_shop_roof | 347/58/58 | 600/80/72 | 1 | O_louver | PASS |
| shops | shop_roof_6m_mid | mod_shop_roof | 322/56/56 | 600/80/72 | 1 | O_louver | PASS |
| shops | shop_roof_6m_single | mod_shop_roof | 372/60/60 | 600/80/72 | 1 | O_louver | PASS |
| shops | shop_side_12m_stucco | mod_shop_side | 356/84/8 | 420/126/10 | 1 | O_apt_door, O_lamp, O_louver, O_small_white | PASS |
| shops | shop_side_12m_stucco_l | mod_shop_side | 356/84/8 | 420/126/10 | 1 | O_apt_door, O_lamp, O_louver, O_small_white | PASS |
| shops | shop_trim_cornice_corner_l | mod_shop_trim | 20/10/10 | 40/12/10 | 1 | - | PASS |
| shops | shop_trim_cornice_corner_r | mod_shop_trim | 20/10/10 | 40/12/10 | 1 | - | PASS |
| urban | urb_apt_back_6m | mod_apt_back | 296/96/4 | 450/140/16 | 3 | O_apt_door, O_lamp, O_win_casement | PASS |
| urban | urb_apt_balcony_6m | mod_apt_balcony | 224/36/12 | 420/140/40 | 1 | - | PASS |
| urban | urb_apt_front_6m_balcony | mod_apt_front | 986/212/42 | 1000/280/48 | 14 | O_apt_door, O_apt_slider, O_number | PASS |
| urban | urb_apt_front_6m_boarded | mod_apt_front | 396/192/4 | 800/240/16 | 3 | O_apt_door, O_apt_slider | PASS |
| urban | urb_apt_front_6m_open | mod_apt_front | 418/120/4 | 800/240/16 | 3 | O_apt_door, O_apt_slider, O_number | PASS |
| urban | urb_apt_roof_6x12 | mod_apt_roof | 338/56/56 | 600/80/72 | 1 | O_louver | PASS |
| urban | urb_apt_side_12m | mod_apt_side | 220/64/4 | 500/150/16 | 1 | O_vent, O_win_casement | PASS |
| urban | urb_awning_6m | mod_awning | 110/42/8 | 160/60/16 | 1 | - | PASS |
| urban | urb_brk_back_6m_3sty | mod_brk_back | 290/90/10 | 500/150/16 | 3 | O_apt_door, O_lamp, O_small_white, O_win_dh_white | PASS |
| urban | urb_brk_back_6m_4sty | mod_brk_back | 346/102/12 | 500/150/16 | 3 | O_apt_door, O_lamp, O_small_white, O_win_dh_white | PASS |
| urban | urb_brk_corner_pier_3sty | mod_brk_corner | 270/42/24 | 440/100/40 | 1 | - | PASS |
| urban | urb_brk_corner_pier_4sty | mod_brk_corner | 342/42/24 | 440/100/40 | 1 | - | PASS |
| urban | urb_brk_front_6m_3sty | mod_brk_front | 412/100/10 | 900/260/16 | 1 | O_shopdoor, O_storefront, O_win_dh_div | PASS |
| urban | urb_brk_front_6m_3sty_corner | mod_brk_front | 422/110/10 | 950/280/16 | 1 | O_shopdoor, O_storefront, O_win_dh_div | PASS |
| urban | urb_brk_front_6m_3sty_walkup | mod_brk_front | 606/150/10 | 900/260/16 | 5 | O_apt_door, O_number, O_win_dh_div | PASS |
| urban | urb_brk_front_6m_4sty | mod_brk_front | 508/120/12 | 900/260/16 | 1 | O_shopdoor, O_storefront, O_win_dh_div | PASS |
| urban | urb_brk_front_6m_4sty_corner | mod_brk_front | 518/130/12 | 950/280/16 | 1 | O_shopdoor, O_storefront, O_win_dh_div | PASS |
| urban | urb_brk_front_6m_4sty_walkup | mod_brk_front | 702/170/12 | 950/280/16 | 5 | O_apt_door, O_number, O_win_dh_div | PASS |
| urban | urb_brk_roof_6x14_3sty | mod_brk_roof | 346/56/60 | 620/80/72 | 1 | O_louver | PASS |
| urban | urb_brk_roof_6x14_3sty_run | mod_brk_roof | 150/8/8 | 300/60/72 | 1 | - | PASS |
| urban | urb_brk_roof_6x16_4sty | mod_brk_roof | 354/56/60 | 620/80/72 | 1 | O_louver | PASS |
| urban | urb_brk_side_14m_3sty | mod_brk_side | 354/92/10 | 700/200/16 | 1 | O_vent, O_win_dh_div | PASS |
| urban | urb_brk_side_16m_4sty | mod_brk_side | 450/112/12 | 700/200/16 | 1 | O_vent, O_win_dh_div | PASS |
| urban | urb_canopy_6m | mod_canopy | 340/84/8 | 380/120/16 | 4 | - | PASS |
| urban | urb_civ_colonnade_6m | mod_civ_colonnade | 758/202/44 | 800/220/56 | 6 | - | PASS |
| urban | urb_civ_column | mod_civ_col | 146/62/36 | 280/90/40 | 1 | - | PASS |
| urban | urb_civ_cornice_6m | mod_civ_cornice | 128/24/8 | 160/50/16 | 1 | - | PASS |
| urban | urb_civ_entry_6m | mod_civ_entry | 478/94/64 | 800/240/120 | 5 | O_apt_door, O_glass_plain | PASS |
| urban | urb_civ_parapet_6m | mod_civ_parapet | 118/22/6 | 140/50/16 | 1 | - | PASS |
| urban | urb_civ_pediment_6m | mod_civ_pediment | 308/56/16 | 360/120/24 | 1 | - | PASS |
| urban | urb_civ_window_6m | mod_civ_window | 214/40/36 | 600/180/120 | 1 | O_civic_win | PASS |
| urban | urb_grt_fireescape_6m | mod_grt_escape | 380/120/120 | 500/160/120 | 8 | - | PASS |
| urban | urb_grt_front_6m_abandoned | mod_grt_front | 112/40/8 | 650/200/12 | 1 | O_apt_door | PASS |
| urban | urb_grt_front_6m_boarded | mod_grt_front | 160/70/54 | 600/180/120 | 1 | O_shopdoor | PASS |
| urban | urb_stg_back_6m | mod_stg_back | 66/20/6 | 220/70/6 | 1 | O_louver | PASS |
| urban | urb_stg_front_6m | mod_stg_front | 76/28/20 | 400/120/120 | 1 | O_rollup | PASS |
| urban | urb_stg_roof_6x12 | mod_stg_roof | 342/56/56 | 480/80/72 | 1 | O_louver | PASS |
| urban | urb_stg_side_12m | mod_stg_side | 66/20/6 | 280/90/6 | 1 | O_louver | PASS |
| urban | urb_storefront_6m | mod_storefront | 170/34/26 | 700/210/120 | 1 | O_shopdoor, O_storefront | PASS |
| urban | urb_svc_front_6m_bank | mod_svc_front | 666/228/92 | 800/280/120 | 4 | O_apt_door, O_glass_plain | PASS |
| urban | urb_svc_front_6m_bigbox | mod_svc_front | 200/82/58 | 800/240/120 | 3 | O_shopdoor, O_storefront | PASS |
| urban | urb_svc_front_6m_cinema | mod_svc_front | 192/80/52 | 750/220/120 | 1 | O_shopdoor, O_storefront | PASS |
| urban | urb_svc_front_6m_fastfood | mod_svc_front | 348/78/48 | 700/210/120 | 3 | O_shopdoor, O_storefront | PASS |
| urban | urb_svc_front_6m_laundry | mod_svc_front | 228/60/26 | 650/200/120 | 1 | O_shopdoor, O_storefront | PASS |
| urban | urb_svc_front_6m_pawn | mod_svc_front | 228/60/26 | 650/200/120 | 1 | O_shopdoor, O_storefront | PASS |
| urban | urb_svc_front_6m_pharmacy | mod_svc_front | 228/60/26 | 650/200/120 | 1 | O_shopdoor, O_storefront | PASS |
| urban | urb_twr_back_8m_10sty | mod_twr_back | 462/160/24 | 900/200/32 | 3 | O_apt_door, O_lamp, O_ribbon | PASS |
| urban | urb_twr_back_8m_10sty_glass | mod_twr_back | 930/208/24 | 1000/220/32 | 3 | O_apt_door, O_glass_plain, O_lamp | PASS |
| urban | urb_twr_corner_pier_10sty | mod_twr_corner | 330/54/24 | 480/140/40 | 1 | - | PASS |
| urban | urb_twr_front_8m_10sty | mod_twr_front | 760/210/24 | 1400/280/32 | 5 | O_ribbon, O_shopdoor, O_storefront | PASS |
| urban | urb_twr_front_8m_10sty_glass | mod_twr_front | 1144/236/24 | 1600/320/32 | 5 | O_glass_plain, O_shopdoor | PASS |
| urban | urb_twr_roof_8x20 | mod_twr_roof | 498/92/80 | 840/120/96 | 1 | O_louver | PASS |
| urban | urb_twr_side_20m_10sty | mod_twr_side | 416/150/24 | 1200/240/32 | 1 | O_ribbon, O_vent | PASS |
| urban | urb_twr_side_20m_10sty_glass | mod_twr_side | 1142/198/24 | 1400/280/32 | 1 | O_glass_plain, O_vent | PASS |
| urban | urb_wh_back_12m | mod_wh_back | 208/80/4 | 500/150/12 | 3 | O_apt_door, O_lamp, O_louver, O_rollup | PASS |
| urban | urb_wh_dock_12m | mod_wh_dock | 346/114/30 | 360/120/32 | 5 | - | PASS |
| urban | urb_wh_front_12m_office | mod_wh_front | 242/108/108 | 600/180/120 | 3 | O_apt_door, O_win_casement | PASS |
| urban | urb_wh_front_12m_rollup | mod_wh_front | 152/48/48 | 600/180/120 | 1 | O_rollup, O_win_casement | PASS |
| urban | urb_wh_roof_12x24 | mod_wh_roof | 666/92/84 | 1000/120/96 | 1 | O_louver | PASS |
| urban | urb_wh_roof_sawtooth_12x24 | mod_wh_roof | 144/60/12 | 360/120/16 | 1 | - | PASS |
| urban | urb_wh_roof_shed_12x24 | mod_wh_roof | 114/24/12 | 280/100/16 | 1 | - | PASS |
| urban | urb_wh_side_24m | mod_wh_side | 218/56/4 | 550/160/12 | 1 | O_louver, O_win_casement | PASS |

## Example assemblies

| example | class | near/mid/far | budget | pieces | col boxes | mid/near | result |
|---|---|---|---|---|---|---|---|
| ex_house_cottage_clay | mod_house_small | 1620/372/22 | 1650/500/40 | 13 | 2 | 0.23 | PASS |
| ex_house_garage_siding | mod_house_small | 1622/388/22 | 1650/500/40 | 17 | 2 | 0.24 | PASS |
| ex_house_ranch_stucco | mod_house_small | 1630/364/22 | 1650/500/40 | 13 | 2 | 0.22 | PASS |
| ex_shop_corner_bakery | corner_shop | 1356/306/10 | 2500/750/60 | 7 | 1 | 0.23 | PASS |
| ex_shop_row_cafe_books | shop | 1960/424/10 | 2400/700/40 | 10 | 1 | 0.22 | PASS |
| mod_apt_row | apartment | 2582/776/34 | 3500/1000/80 | 8 | 1 | 0.3 | PASS |
| mod_brk_row | apartment | 3174/778/34 | 3500/1000/80 | 11 | 1 | 0.25 | PASS |
| mod_stg_row | warehouse | 558/184/10 | 2000/600/40 | 8 | 1 | 0.33 | PASS |
| mod_svc_row | shop | 1776/404/10 | 2400/700/40 | 8 | 1 | 0.23 | PASS |
| mod_twr_office | tower | 3580/1056/50 | 4000/1200/80 | 8 | 1 | 0.29 | PASS |
| mod_wh_shed | warehouse | 1626/444/18 | 2000/600/40 | 8 | 1 | 0.27 | PASS |
