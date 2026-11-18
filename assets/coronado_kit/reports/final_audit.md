# Final audit - Coronado kit v2 (2026-11-15 18:41 UTC+3)

Rule: SPEC.md section 7 final audit + pre-push audit (md5 44950d3f3882df8327c8ba5735eabb37). Over budget = DISCARDED from the push; the 590-tri red hydrant is the only approved exception. Full SPEC.md re-read at 18:40 UTC+3 before this run.

Buildings: 80 pass / 0 fail / 0 discarded of 80.  Props/fences/foliage (manifest entries): 178 pass / 0 fail / 0 discarded / 0 without files of 178.  Parks: 11 pass of 11.

High-poly bakes: buildings use shared-atlas bakes; every opening/ornament region (O_*) has a high-poly normal + AO bake (house atlas: textures/bake, 24/24; city atlas: 11 own in textures/bake_city + 16 inherited from the house atlas). Wall/roof tiles are photo-derived PBR tiles with normal + ORM. Props/fences: manifest high_tris = high-poly source baked into props page normal/AO. Foliage: card and bark atlases baked from high-poly sources (foliage/_bake).

Texture note: the W_concrete wall tile reads as a grungy green "camo" texture; no building uses it any more (hospital and parking garage moved to W_stucco). The W_shingle strip in bld_color.png got a 96 px mirrored cross-fade at its right end, so the u-wrap seam behind cape_grey right wall is gone.

Detail floor: the near hero of every building was opened and judged in group contact sheets at 18:30 UTC+3 on 15 Nov 2026 (box clock; houses against previews/houses/test_ranch_hero.png on the same sheets; log in reports/hero_review.json). All 80 judged at or above the test_ranch floor. Observation: the commercial side elevations (com_bistro, com_surf_shop, com_realty) are sparser than their fronts (1-3 windows, downspout, side sign); I judged them at the floor, not above it.

Walls: grazing-light blotch check on 4 sides. 2nd-sun = second sun angle, fine = thin-strip mode, relief = shingle/brick/stone mode. MANUAL PASS = the automatic check misfired, and I inspected the render myself with an evidence image (cape_grey right: flags hug the window reveals, and the shingle u-wrap seam was fixed in the atlas; victorian_blue front: siding grain on the sun-facing turret facet). Sources: reports/<group>/<name>.json, logs/houses_wc.log, logs/wc_houses2.log, logs/rejudge.log, logs/wc_motel.log, reports/wallcheck_verified.json (newest wins).

ext_hospital (flagged: mottled green wall tile): walls are now W_stucco only (no building in buildings/ uses W_concrete any more; the parking garage was switched too). Rebuild ext13: validator PASS, walls front/left/right/back PASS, 4625/890/10 tris (cap 5000/1500/120). NEAR close-up previews/extras/closeups/ext_hospital_close_er_entry.png (rendered 18:14, opened and judged 18:30): clean painted stucco, EMERGENCY sign on the entry canopy, window surrounds and sills, wall lamps, steps. PASS, promoted.

Far tiers: far roofs keep their cover's far strip. Flat-roof city buildings with an R_clay deck (it reads as a dark membrane near/mid) now use the F_flat strip tinted to match: civ_library, civ_police, civ_rec_center, apt_stucco3_cream, apt_spanish_revival, ext_hospital, lmk_navy_gatehouse, lmk_village_theatre. Those far tiers were re-exported and re-validated. Tier previews re-rendered 18:30-18:34 and checked 18:38: far roof colour now matches near/mid. The 16 earlier re-renders (chain3, finished 18:24) were checked at 18:26.

## Buildings

| group | building | near/mid/far | cap | validator | baked AO | walls | hero | result |
|---|---|---|---|---|---|---|---|---|
| houses | beach_blue | 1461/308/30 | 1500/450/40 | ok | yes | front:PASS; left:PASS; right:PASS; back:PASS | previews/houses/beach_blue_hero.png | PASS |
| houses | beach_teal | 1461/308/22 | 1500/450/40 | ok | yes | front:PASS; left:PASS; right:PASS; back:PASS | previews/houses/beach_teal_hero.png | PASS |
| houses | beach_white | 1449/308/30 | 1500/450/40 | ok | yes | front:PASS; left:PASS; right:PASS; back:PASS | previews/houses/beach_white_hero.png | PASS |
| houses | cape_grey | 1418/300/30 | 1500/450/40 | ok | yes | front:PASS; left:PASS/relief/2nd-sun; right:MANUAL PASS (evidence: previews/houses/wallcheck_evidence/cape_grey_right.png); back:PASS | previews/houses/cape_grey_hero.png | PASS |
| houses | cape_white | 1418/300/30 | 1500/450/40 | ok | yes | front:PASS; left:PASS; right:PASS; back:PASS | previews/houses/cape_white_hero.png | PASS |
| houses | colonial_blue | 2341/404/22 | 2500/750/60 | ok | yes | front:PASS; left:PASS; right:PASS; back:PASS | previews/houses/colonial_blue_hero.png | PASS |
| houses | colonial_white | 2313/404/22 | 2500/750/60 | ok | yes | front:PASS; left:PASS; right:PASS; back:PASS | previews/houses/colonial_white_hero.png | PASS |
| houses | contemporary_grey | 1783/326/10 | 2500/750/60 | ok | yes | front:PASS; left:PASS; right:PASS; back:PASS | previews/houses/contemporary_grey_hero.png | PASS |
| houses | contemporary_white | 1791/326/10 | 2500/750/60 | ok | yes | front:PASS; left:PASS; right:PASS; back:PASS | previews/houses/contemporary_white_hero.png | PASS |
| houses | craftsman_cedar | 2242/415/22 | 2500/750/60 | ok | yes | front:PASS/2nd-sun; left:PASS/2nd-sun/fine; right:PASS; back:PASS | previews/houses/craftsman_cedar_hero.png | PASS |
| houses | craftsman_olive | 2279/406/22 | 2500/750/60 | ok | yes | front:PASS; left:PASS; right:PASS; back:PASS | previews/houses/craftsman_olive_hero.png | PASS |
| houses | craftsman_sage | 2279/406/22 | 2500/750/60 | ok | yes | front:PASS; left:PASS; right:PASS; back:PASS | previews/houses/craftsman_sage_hero.png | PASS |
| houses | craftsman_stucco | 2239/411/22 | 2500/750/60 | ok | yes | front:PASS; left:PASS; right:PASS; back:PASS | previews/houses/craftsman_stucco_hero.png | PASS |
| houses | hipranch_grey | 1473/348/38 | 1500/450/40 | ok | yes | front:PASS; left:PASS; right:PASS; back:PASS | previews/houses/hipranch_grey_hero.png | PASS |
| houses | hipranch_nogarage | 1219/274/22 | 1500/450/40 | ok | yes | front:PASS; left:PASS; right:PASS; back:PASS | previews/houses/hipranch_nogarage_hero.png | PASS |
| houses | hipranch_sand | 1451/348/38 | 1500/450/40 | ok | yes | front:PASS; left:PASS; right:PASS; back:PASS | previews/houses/hipranch_sand_hero.png | PASS |
| houses | mcm_shed | 1437/327/31 | 1500/450/40 | ok | yes | front:PASS; left:PASS/2nd-sun; right:PASS; back:PASS | previews/houses/mcm_shed_hero.png | PASS |
| houses | mcm_teal | 1454/326/31 | 1500/450/40 | ok | yes | front:PASS; left:PASS; right:PASS/relief/2nd-sun; back:PASS | previews/houses/mcm_teal_hero.png | PASS |
| houses | mcm_white | 1486/326/31 | 1500/450/40 | ok | yes | front:PASS; left:PASS; right:PASS/relief/2nd-sun; back:PASS | previews/houses/mcm_white_hero.png | PASS |
| houses | ranch_peach | 1422/354/22 | 1500/450/40 | ok | yes | front:PASS; left:PASS; right:PASS; back:PASS | previews/houses/ranch_peach_hero.png | PASS |
| houses | ranch_pink | 1410/354/22 | 1500/450/40 | ok | yes | front:PASS; left:PASS; right:PASS; back:PASS | previews/houses/ranch_pink_hero.png | PASS |
| houses | ranch_porch | 1422/354/22 | 1500/450/40 | ok | yes | front:PASS; left:PASS; right:PASS; back:PASS | previews/houses/ranch_porch_hero.png | PASS |
| houses | ranch_siding | 1372/354/22 | 1500/450/40 | ok | yes | front:PASS; left:PASS; right:PASS; back:PASS | previews/houses/ranch_siding_hero.png | PASS |
| houses | spanish_peach | 2294/419/37 | 2500/750/60 | ok | yes | front:PASS; left:PASS; right:PASS; back:PASS | previews/houses/spanish_peach_hero.png | PASS |
| houses | spanish_pink | 2296/419/37 | 2500/750/60 | ok | yes | front:PASS; left:PASS; right:PASS; back:PASS | previews/houses/spanish_pink_hero.png | PASS |
| houses | spanish_small | 1357/312/22 | 1500/450/40 | ok | yes | front:PASS; left:PASS; right:PASS; back:PASS | previews/houses/spanish_small_hero.png | PASS |
| houses | spanish_white | 2294/419/37 | 2500/750/60 | ok | yes | front:PASS; left:PASS; right:PASS; back:PASS | previews/houses/spanish_white_hero.png | PASS |
| houses | tudor_brick | 1678/326/42 | 2500/750/60 | ok | yes | front:PASS; left:PASS/relief/2nd-sun; right:PASS/relief/2nd-sun; back:PASS | previews/houses/tudor_brick_hero.png | PASS |
| houses | tudor_stucco | 1718/326/42 | 2500/750/60 | ok | yes | front:PASS; left:PASS; right:PASS; back:PASS | previews/houses/tudor_stucco_hero.png | PASS |
| houses | victorian_blue | 2458/523/46 | 2500/750/60 | ok | yes | front:MANUAL PASS (evidence: previews/houses/wallcheck_evidence/victorian_blue_front.png); left:PASS; right:PASS; back:PASS | previews/houses/victorian_blue_hero.png | PASS |
| houses | victorian_yellow | 2385/492/46 | 2500/750/60 | ok | yes | front:PASS; left:PASS; right:PASS; back:PASS | previews/houses/victorian_yellow_hero.png | PASS |
| apartments | apt_beach_condo | 3452/834/18 | 3500/1000/80 | ok | yes | front:PASS; left:PASS; right:PASS; back:PASS | previews/apartments/apt_beach_condo_hero.png | PASS |
| apartments | apt_court_white | 3113/633/22 | 3500/1000/80 | ok | yes | front:PASS; left:PASS; right:PASS; back:PASS | previews/apartments/apt_court_white_hero.png | PASS |
| apartments | apt_dingbat_pink | 3297/719/16 | 3500/1000/80 | ok | yes | front:PASS; left:PASS; right:PASS; back:PASS | previews/apartments/apt_dingbat_pink_hero.png | PASS |
| apartments | apt_dingbat_teal | 3297/719/16 | 3500/1000/80 | ok | yes | front:PASS; left:PASS; right:PASS; back:PASS | previews/apartments/apt_dingbat_teal_hero.png | PASS |
| apartments | apt_garden_cream | 3445/789/22 | 3500/1000/80 | ok | yes | front:PASS/fine/2nd-sun; left:PASS; right:PASS; back:PASS | previews/apartments/apt_garden_cream_hero.png | PASS |
| apartments | apt_garden_mint | 3459/781/10 | 3500/1000/80 | ok | yes | front:PASS; left:PASS; right:PASS; back:PASS | previews/apartments/apt_garden_mint_hero.png | PASS |
| apartments | apt_spanish_revival | 3038/902/10 | 3500/1000/80 | ok | yes | front:PASS; left:PASS; right:PASS; back:PASS | previews/apartments/apt_spanish_revival_hero.png | PASS |
| apartments | apt_spanish_white | 3306/874/22 | 3500/1000/80 | ok | yes | front:PASS; left:PASS; right:PASS; back:PASS | previews/apartments/apt_spanish_white_hero.png | PASS |
| apartments | apt_stucco3_cream | 3088/658/10 | 3500/1000/80 | ok | yes | front:PASS; left:PASS; right:PASS; back:PASS | previews/apartments/apt_stucco3_cream_hero.png | PASS |
| apartments | apt_stucco3_peach | 3440/686/22 | 3500/1000/80 | ok | yes | front:PASS; left:PASS; right:PASS; back:PASS | previews/apartments/apt_stucco3_peach_hero.png | PASS |
| apartments | apt_townhouse_cays | 3452/968/76 | 3500/1000/80 | ok | yes | front:PASS; left:PASS; right:PASS; back:PASS | previews/apartments/apt_townhouse_cays_hero.png | PASS |
| apartments | apt_townhouse_modern | 3082/954/28 | 3500/1000/80 | ok | yes | front:PASS; left:PASS; right:PASS; back:PASS | previews/apartments/apt_townhouse_modern_hero.png | PASS |
| commercial | com_bakery | 1880/372/10 | 2400/700/40 | ok | yes | front:PASS; left:PASS; right:PASS; back:PASS | previews/commercial/com_bakery_hero.png | PASS |
| commercial | com_bank | 1724/274/10 | 2500/750/60 | ok | yes | front:PASS; left:PASS; right:PASS; back:PASS | previews/commercial/com_bank_hero.png | PASS |
| commercial | com_bar_crown | 1936/326/10 | 2400/700/40 | ok | yes | front:PASS; left:PASS; right:PASS; back:PASS | previews/commercial/com_bar_crown_hero.png | PASS |
| commercial | com_bistro | 1298/286/10 | 2400/700/40 | ok | yes | front:PASS; left:PASS; right:PASS; back:PASS | previews/commercial/com_bistro_hero.png | PASS |
| commercial | com_boutique_row | 2072/447/10 | 3600/1050/60 | ok | yes | front:PASS; left:PASS; right:PASS; back:PASS | previews/commercial/com_boutique_row_hero.png | PASS |
| commercial | com_cafe_seaside | 1186/257/10 | 1200/350/20 | ok | yes | front:PASS; left:PASS; right:PASS; back:PASS | previews/commercial/com_cafe_seaside_hero.png | PASS |
| commercial | com_gas_station | 2332/467/10 | 2500/750/60 | ok | yes | front:PASS; left:PASS; right:PASS; back:PASS | previews/commercial/com_gas_station_hero.png | PASS |
| commercial | com_orange_corner | 2366/496/10 | 2400/700/40 | ok | yes | front:PASS; left:PASS; right:PASS; back:PASS | previews/commercial/com_orange_corner_hero.png | PASS |
| commercial | com_orange_row | 2870/599/10 | 3600/1050/60 | ok | yes | front:PASS; left:PASS; right:PASS; back:PASS | previews/commercial/com_orange_row_hero.png | PASS |
| commercial | com_realty | 1168/237/10 | 1200/350/20 | ok | yes | front:PASS; left:PASS; right:PASS; back:PASS | previews/commercial/com_realty_hero.png | PASS |
| commercial | com_surf_shop | 1262/266/10 | 2400/700/40 | ok | yes | front:PASS; left:PASS; right:PASS; back:PASS | previews/commercial/com_surf_shop_hero.png | PASS |
| civic | civ_church | 4722/1018/64 | 5000/1500/120 | ok | yes | front:PASS; left:PASS; right:PASS; back:PASS | previews/civic/civ_church_hero.png | PASS |
| civic | civ_city_hall | 4507/532/22 | 5000/1500/120 | ok | yes | front:PASS; left:PASS; right:PASS; back:PASS | previews/civic/civ_city_hall_hero.png | PASS |
| civic | civ_community_center | 2361/448/30 | 5000/1500/120 | ok | yes | front:PASS; left:PASS; right:PASS; back:PASS | previews/civic/civ_community_center_hero.png | PASS |
| civic | civ_fire_station | 3737/502/50 | 5000/1500/120 | ok | yes | front:PASS; left:PASS; right:PASS; back:PASS | previews/civic/civ_fire_station_hero.png | PASS |
| civic | civ_harbor_office | 2685/460/22 | 5000/1500/120 | ok | yes | front:PASS; left:PASS; right:PASS; back:PASS | previews/civic/civ_harbor_office_hero.png | PASS |
| civic | civ_library | 2270/564/10 | 5000/1500/120 | ok | yes | front:PASS; left:PASS; right:PASS; back:PASS | previews/civic/civ_library_hero.png | PASS |
| civic | civ_museum | 4692/686/22 | 5000/1500/120 | ok | yes | front:PASS; left:PASS; right:PASS; back:PASS | previews/civic/civ_museum_hero.png | PASS |
| civic | civ_police | 3809/554/10 | 5000/1500/120 | ok | yes | front:PASS; left:PASS; right:PASS; back:PASS | previews/civic/civ_police_hero.png | PASS |
| civic | civ_post_office | 2094/518/22 | 5000/1500/120 | ok | yes | front:PASS; left:PASS; right:PASS; back:PASS | previews/civic/civ_post_office_hero.png | PASS |
| civic | civ_rec_center | 3576/510/10 | 5000/1500/120 | ok | yes | front:PASS; left:PASS; right:PASS; back:PASS | previews/civic/civ_rec_center_hero.png | PASS |
| civic | civ_school_wing | 2188/550/30 | 5000/1500/120 | ok | yes | front:PASS; left:PASS; right:PASS; back:PASS | previews/civic/civ_school_wing_hero.png | PASS |
| extras | ext_grocery_market | 2066/517/10 | 6000/1750/100 | ok | yes | front:PASS; left:PASS; right:PASS; back:PASS | previews/extras/ext_grocery_market_hero.png | PASS |
| extras | ext_hospital | 4625/890/10 | 5000/1500/120 | ok | yes | front:PASS; left:PASS; right:PASS; back:PASS | previews/extras/ext_hospital_hero.png | PASS |
| extras | ext_marina_office | 2454/346/22 | 5000/1500/120 | ok | yes | front:PASS; left:PASS; right:PASS; back:PASS | previews/extras/ext_marina_office_hero.png | PASS |
| extras | ext_motel_crown | 4873/1214/20 | 5000/1500/120 | ok | yes | front:PASS/fine/2nd-sun; left:PASS; right:PASS; back:PASS | previews/extras/ext_motel_crown_hero.png | PASS |
| extras | ext_parking_garage | 1850/456/38 | 2000/600/40 | ok | yes | front:PASS; left:PASS; right:PASS; back:PASS | previews/extras/ext_parking_garage_hero.png | PASS |
| landmarks | lmk_beach_lookout | 3528/646/68 | 8000/2500/200 | ok | yes | front:PASS; left:PASS; right:PASS; back:PASS | previews/landmarks/lmk_beach_lookout_hero.png | PASS |
| landmarks | lmk_blue_dome_chapel | 6118/1218/64 | 8000/2500/200 | ok | yes | front:PASS; left:PASS; right:PASS; back:PASS | previews/landmarks/lmk_blue_dome_chapel_hero.png | PASS |
| landmarks | lmk_bridge_tollhouse | 2590/420/22 | 8000/2500/200 | ok | yes | front:PASS; left:PASS; right:PASS; back:PASS | previews/landmarks/lmk_bridge_tollhouse_hero.png | PASS |
| landmarks | lmk_crown_boathouse | 4052/760/66 | 8000/2500/200 | ok | yes | front:PASS; left:PASS; right:PASS; back:PASS | previews/landmarks/lmk_crown_boathouse_hero.png | PASS |
| landmarks | lmk_crown_hotel_annex | 7343/1104/78 | 8000/2500/200 | ok | yes | front:PASS; left:PASS; right:PASS; back:PASS | previews/landmarks/lmk_crown_hotel_annex_hero.png | PASS |
| landmarks | lmk_ferry_landing | 3598/670/56 | 8000/2500/200 | ok | yes | front:PASS; left:PASS; right:PASS; back:PASS | previews/landmarks/lmk_ferry_landing_hero.png | PASS |
| landmarks | lmk_glorietta_mansion | 7215/722/22 | 8000/2500/200 | ok | yes | front:PASS; left:PASS; right:PASS; back:PASS | previews/landmarks/lmk_glorietta_mansion_hero.png | PASS |
| landmarks | lmk_navy_gatehouse | 2742/532/36 | 8000/2500/200 | ok | yes | front:PASS; left:PASS; right:PASS; back:PASS | previews/landmarks/lmk_navy_gatehouse_hero.png | PASS |
| landmarks | lmk_red_spire_church | 5568/1040/56 | 8000/2500/200 | ok | yes | front:PASS; left:PASS/2nd-sun; right:PASS; back:PASS | previews/landmarks/lmk_red_spire_church_hero.png | PASS |
| landmarks | lmk_village_theatre | 4877/852/10 | 8000/2500/200 | ok | yes | front:PASS; left:PASS; right:PASS; back:PASS | previews/landmarks/lmk_village_theatre_hero.png | PASS |

## Props, fences, foliage (props validator run 18:15 UTC+3: reports/props_validation_all.md, 974/974 files pass)

| batch | asset | tris | budget | files checked | high-poly bake | result |
|---|---|---|---|---|---|---|
| house | ac_condenser | near 428 | 600 | 4 | yes | PASS |
| house | ac_condenser_compact | near 418 | 600 | 4 | yes | PASS |
| house | ac_window | near 46 | 600 | 4 | yes | PASS |
| yard | adirondack_white | near 200 | 600 | 4 | yes | PASS |
| yard | adirondack_wood | near 200 | 600 | 4 | yes | PASS |
| park | bandstand | near 2242/mid 406/far 14 | 2500 | 10 | yes | PASS |
| fences | barbed_wire | near 54/mid 18/far 18 | 60 | 10 | yes | PASS |
| construction | barricade_type1 | near 64 | 600 | 4 | yes | PASS |
| construction | barricade_type3 | near 108 | 1200 | 4 | yes | PASS |
| yard | bbq_gas_cart | near 952 | 1200 | 4 | yes | PASS |
| yard | bbq_kettle | near 280 | 1200 | 4 | yes | PASS |
| park | beach_sign_dog | near 32 | 1200 | 4 | yes | PASS |
| park | beach_sign_rip | near 32 | 1200 | 4 | yes | PASS |
| park | beach_sign_rules | near 32 | 1200 | 4 | yes | PASS |
| street | bench_bus_stop | near 256 | 600 | 4 | yes | PASS |
| street | bike_rack | near 540 | 1200 | 4 | yes | PASS |
| city | billboard | near 984/mid 72/far 18 | 2500 | 10 | yes | PASS |
| street | bollard_concrete | near 156 | 600 | 4 | yes | PASS |
| street | bollard_iron | near 104 | 600 | 4 | yes | PASS |
| street | bollard_steel | near 190 | 600 | 4 | yes | PASS |
| fences | brick_wall | near 52/mid 18/far 6 | 60 | 10 | yes | PASS |
| street | bus_shelter | near 510/mid 56/far 10 | 2500 | 10 | yes | PASS |
| city | cemetery_gate | near 1180/mid 308/far 20 | 1200 | 10 | yes | PASS |
| fences | chainlink | near 4/mid 2/far 2 | 4 | 10 | yes | PASS |
| fences | chainlink_lot | near 4/mid 2/far 2 | 4 | 10 | yes | PASS |
| fences | chainlink_lot_post | near 50/mid 14/far 6 | 60 | 10 | yes | PASS |
| fences | chainlink_post | near 42 | 60 | 4 | yes | PASS |
| construction | channelizer_drum | near 314 | 600 | 4 | yes | PASS |
| fences | cmu_wall | near 52/mid 18/far 6 | 60 | 10 | yes | PASS |
| construction | cone_18in | near 98 | 300 | 4 | yes | PASS |
| construction | cone_28in | near 98 | 300 | 4 | yes | PASS |
| city | container_20ft_blue | near 472/mid 176/far 10 | 2500 | 10 | yes | PASS |
| city | container_20ft_green | near 472/mid 176/far 10 | 2500 | 10 | yes | PASS |
| city | container_20ft_red | near 472/mid 176/far 10 | 2500 | 10 | yes | PASS |
| city | container_20ft_white | near 472/mid 176/far 10 | 2500 | 10 | yes | PASS |
| city | dock_crane | near 2447/mid 389/far 20 | 2500 | 10 | yes | PASS |
| house | downspout_3m | near 140 | 300 | 4 | yes | PASS |
| park | drinking_fountain | near 288 | 1200 | 4 | yes | PASS |
| construction | dumpster_3yd_blue | near 424 | 1200 | 4 | yes | PASS |
| construction | dumpster_3yd_green | near 424 | 1200 | 4 | yes | PASS |
| construction | dumpster_rolloff_20yd | near 640/mid 34/far 10 | 2500 | 10 | yes | PASS |
| yard | garden_arbor | near 316 | 1200 | 4 | yes | PASS |
| fences | gate_picket | near 32 | 60 | 4 | yes | PASS |
| fences | gate_privacy | near 46/mid 2/far 2 | 60 | 10 | yes | PASS |
| fences | gate_rolling_chainlink | near 60/mid 18/far 2 | 60 | 10 | yes | PASS |
| fences | gate_wrought_iron | near 35/mid 18/far 10 | 60 | 10 | yes | PASS |
| yard | golf_cart_blue | near 1090 | 1200 | 4 | yes | PASS |
| yard | golf_cart_white | near 1090 | 1200 | 4 | yes | PASS |
| fences | graffiti_cmu_panel | near 56/mid 18/far 6 | 60 | 10 | yes | PASS |
| house | gutter_kstyle_2m | near 42 | 300 | 4 | yes | PASS |
| city | headstone_cross | near 248/mid 108/far 20 | 600 | 10 | yes | PASS |
| city | headstone_flat | near 48 | 300 | 4 | yes | PASS |
| city | headstone_upright | near 66 | 600 | 4 | yes | PASS |
| foliage | hedge_boxwood_low_2m | near 178 | 200 | 2 | yes (card/bark atlas bake, foliage/_bake) | PASS |
| foliage | hedge_privet_2m | near 178 | 200 | 2 | yes (card/bark atlas bake, foliage/_bake) | PASS |
| house | hose_reel_cart | near 166 | 600 | 4 | yes | PASS |
| house | hose_reel_wall | near 94 | 600 | 4 | yes | PASS |
| house | house_numbers_tile | near 20 | 300 | 4 | yes | PASS |
| house | house_numbers_wood | near 10 | 300 | 4 | yes | PASS |
| street | hydrant_red | near 590 | 600 | 4 | yes | PASS |
| street | hydrant_wet_barrel | near 354 | 600 | 4 | yes | PASS |
| construction | k_rail | near 34 | 1200 | 4 | yes | PASS |
| street | lamp_cobra | near 820/mid 66 | 1200 | 7 | yes | PASS |
| street | lamp_globe | near 684/mid 45 | 1200 | 7 | yes | PASS |
| street | lamp_victorian | near 1150/mid 78 | 1200 | 7 | yes | PASS |
| park | lifeguard_tower | near 480/mid 72/far 14 | 2500 | 10 | yes | PASS |
| city | lot_light_pole | near 170/mid 92/far 18 | 1200 | 10 | yes | PASS |
| house | mailbox_post_metal | near 86 | 300 | 4 | yes | PASS |
| house | mailbox_post_wood | near 86 | 300 | 4 | yes | PASS |
| house | mailbox_wall_black | near 136 | 300 | 4 | yes | PASS |
| house | mailbox_wall_brass | near 136 | 300 | 4 | yes | PASS |
| street | manhole_cover | near 78 | 300 | 4 | yes | PASS |
| house | meter_electric | near 60 | 300 | 4 | yes | PASS |
| house | meter_gas | near 88 | 300 | 4 | yes | PASS |
| street | newspaper_box_blue | near 158 | 600 | 4 | yes | PASS |
| street | newspaper_box_red | near 158 | 600 | 4 | yes | PASS |
| city | obelisk_monument | near 398/mid 120/far 20 | 600 | 10 | yes | PASS |
| foliage | palm_canary_date_a | near 956/mid 152/far 2 | 1500 | 4 | yes (card/bark atlas bake, foliage/_bake) | PASS |
| foliage | palm_canary_date_b | near 956/mid 152/far 2 | 1500 | 4 | yes (card/bark atlas bake, foliage/_bake) | PASS |
| foliage | palm_mexican_fan_a | near 856/mid 142/far 2 | 1500 | 4 | yes (card/bark atlas bake, foliage/_bake) | PASS |
| foliage | palm_mexican_fan_b | near 856/mid 142/far 2 | 1500 | 4 | yes (card/bark atlas bake, foliage/_bake) | PASS |
| foliage | palm_mexican_fan_c | near 856/mid 142/far 2 | 1500 | 4 | yes (card/bark atlas bake, foliage/_bake) | PASS |
| foliage | palm_queen_a | near 560/mid 76/far 2 | 1500 | 4 | yes (card/bark atlas bake, foliage/_bake) | PASS |
| foliage | palm_queen_b | near 560/mid 76/far 2 | 1500 | 4 | yes (card/bark atlas bake, foliage/_bake) | PASS |
| park | park_bench | near 180 | 600 | 4 | yes | PASS |
| street | parking_meter | near 30 | 300 | 4 | yes | PASS |
| yard | patio_set_4 | near 672 | 1200 | 4 | yes | PASS |
| street | pay_station | near 42 | 600 | 4 | yes | PASS |
| fences | picket_white | near 50/mid 18/far 14 | 60 | 10 | yes | PASS |
| park | picnic_table | near 292 | 1200 | 4 | yes | PASS |
| foliage | plant_agave_americana | near 468 | 500 | 2 | yes (card/bark atlas bake, foliage/_bake) | PASS |
| foliage | plant_agave_americana_small | near 468 | 500 | 2 | yes (card/bark atlas bake, foliage/_bake) | PASS |
| foliage | plant_bird_of_paradise | near 346 | 500 | 2 | yes (card/bark atlas bake, foliage/_bake) | PASS |
| foliage | plant_bougainvillea_mound | near 468 | 500 | 2 | yes (card/bark atlas bake, foliage/_bake) | PASS |
| foliage | plant_bougainvillea_wall | near 128 | 500 | 2 | yes (card/bark atlas bake, foliage/_bake) | PASS |
| foliage | plant_iceplant_patch | near 138 | 500 | 1 | yes (card/bark atlas bake, foliage/_bake) | PASS |
| foliage | plant_lawn_patch | near 120 | 300 | 2 | yes (card/bark atlas bake, foliage/_bake) | PASS |
| foliage | plant_potted_leafy | near 292 | 500 | 2 | yes (card/bark atlas bake, foliage/_bake) | PASS |
| foliage | plant_potted_succulent | near 200 | 500 | 2 | yes (card/bark atlas bake, foliage/_bake) | PASS |
| park | play_structure | near 1276/mid 70/far 14 | 2500 | 10 | yes | PASS |
| house | porch_light_barn | near 118 | 600 | 4 | yes | PASS |
| house | porch_light_coach | near 96 | 600 | 4 | yes | PASS |
| house | porch_light_coach_bronze | near 96 | 600 | 4 | yes | PASS |
| fences | post_picket | near 10 | 60 | 4 | yes | PASS |
| fences | post_privacy | near 20/mid 10/far 8 | 60 | 10 | yes | PASS |
| fences | post_vinyl | near 24 | 60 | 4 | yes | PASS |
| fences | post_wrought_iron | near 50/mid 10/far 8 | 60 | 10 | yes | PASS |
| house | propane_cylinder_100lb | near 236 | 600 | 4 | yes | PASS |
| house | propane_tank_250gal | near 256 | 600 | 4 | yes | PASS |
| street | recycling_receptacle | near 298 | 600 | 4 | yes | PASS |
| park | riprap_boulder | near 214 | 1200 | 4 | yes | PASS |
| park | riprap_pile | near 406 | 1200 | 4 | yes | PASS |
| park | riprap_slope | near 522 | 1200 | 4 | yes | PASS |
| house | satellite_dish | near 94 | 600 | 4 | yes | PASS |
| house | satellite_dish_round | near 94 | 600 | 4 | yes | PASS |
| park | shade_sail | near 174 | 1200 | 4 | yes | PASS |
| street | sign_no_parking | near 366 | 1200 | 4 | yes | PASS |
| street | sign_ped_crossing | near 366 | 1200 | 4 | yes | PASS |
| street | sign_school | near 370 | 1200 | 4 | yes | PASS |
| street | sign_speed25 | near 366 | 1200 | 4 | yes | PASS |
| street | sign_stop | near 546 | 1200 | 4 | yes | PASS |
| street | sign_street_names | near 342 | 1200 | 4 | yes | PASS |
| street | signal_mast_arm | near 1122/mid 64 | 1200 | 7 | yes | PASS |
| street | signal_post | near 856/mid 34 | 1200 | 7 | yes | PASS |
| city | skate_bowl_section | near 308/mid 92/far 17 | 600 | 10 | yes | PASS |
| city | skate_funbox | near 300 | 600 | 4 | yes | PASS |
| city | skate_grind_rail | near 152 | 600 | 4 | yes | PASS |
| city | skate_quarter_pipe | near 392/mid 34/far 14 | 600 | 10 | yes | PASS |
| park | slide | near 528 | 1200 | 4 | yes | PASS |
| house | solar_panel | near 40 | 600 | 4 | yes | PASS |
| house | solar_panel_x3 | near 80 | 1200 | 4 | yes | PASS |
| yard | sprinkler_impact | near 47 | 300 | 4 | yes | PASS |
| yard | sprinkler_popup | near 240 | 300 | 4 | yes | PASS |
| street | storm_drain_curb_inlet | near 26 | 300 | 4 | yes | PASS |
| street | storm_drain_grate | near 10 | 300 | 4 | yes | PASS |
| fences | stucco_wall | near 52/mid 18/far 6 | 60 | 10 | yes | PASS |
| park | swing_set | near 352/mid 100/far 6 | 2500 | 10 | yes | PASS |
| city | switch_rack | near 1166/mid 116/far 18 | 1200 | 10 | yes | PASS |
| city | tank_horizontal_propane | near 460/mid 180/far 10 | 2500 | 10 | yes | PASS |
| city | tank_vertical | near 1636/mid 162/far 18 | 2500 | 10 | yes | PASS |
| construction | temp_fence_panel | near 58/mid 14/far 2 | 60 | 10 | yes | PASS |
| construction | temp_fence_panel_screen | near 58/mid 16/far 2 | 60 | 10 | yes | PASS |
| construction | temp_fence_stand | near 54 | 600 | 4 | yes | PASS |
| park | tennis_net | near 122 | 1200 | 4 | yes | PASS |
| city | transformer_substation | near 1578/mid 92/far 20 | 2500 | 10 | yes | PASS |
| yard | trash_cart_black | near 386 | 600 | 4 | yes | PASS |
| yard | trash_cart_blue | near 386 | 600 | 4 | yes | PASS |
| yard | trash_cart_green | near 386 | 600 | 4 | yes | PASS |
| street | trash_receptacle | near 298 | 600 | 4 | yes | PASS |
| foliage | tree_coral_a | near 880/mid 142/far 2 | 2500 | 4 | yes (card/bark atlas bake, foliage/_bake) | PASS |
| foliage | tree_coral_b | near 824/mid 136/far 2 | 2500 | 4 | yes (card/bark atlas bake, foliage/_bake) | PASS |
| foliage | tree_eucalyptus_a | near 876/mid 138/far 2 | 2500 | 4 | yes (card/bark atlas bake, foliage/_bake) | PASS |
| foliage | tree_eucalyptus_b | near 760/mid 152/far 2 | 2500 | 4 | yes (card/bark atlas bake, foliage/_bake) | PASS |
| foliage | tree_ficus_a | near 1252/mid 202/far 2 | 2500 | 4 | yes (card/bark atlas bake, foliage/_bake) | PASS |
| foliage | tree_ficus_b | near 1104/mid 180/far 2 | 2500 | 4 | yes (card/bark atlas bake, foliage/_bake) | PASS |
| foliage | tree_jacaranda_a | near 964/mid 160/far 2 | 2500 | 4 | yes (card/bark atlas bake, foliage/_bake) | PASS |
| foliage | tree_jacaranda_b | near 868/mid 138/far 2 | 2500 | 4 | yes (card/bark atlas bake, foliage/_bake) | PASS |
| foliage | tree_magnolia_a | near 980/mid 154/far 2 | 2500 | 4 | yes (card/bark atlas bake, foliage/_bake) | PASS |
| foliage | tree_magnolia_b | near 868/mid 140/far 2 | 2500 | 4 | yes (card/bark atlas bake, foliage/_bake) | PASS |
| foliage | tree_norfolk_pine_a | near 1110/mid 134/far 2 | 2000 | 4 | yes (card/bark atlas bake, foliage/_bake) | PASS |
| foliage | tree_norfolk_pine_b | near 1310/mid 164/far 2 | 2000 | 4 | yes (card/bark atlas bake, foliage/_bake) | PASS |
| foliage | tree_norfolk_pine_c | near 678/mid 94/far 2 | 2000 | 4 | yes (card/bark atlas bake, foliage/_bake) | PASS |
| foliage | tree_torrey_pine_a | near 336/mid 78/far 2 | 2500 | 4 | yes (card/bark atlas bake, foliage/_bake) | PASS |
| foliage | tree_torrey_pine_b | near 336/mid 78/far 2 | 2500 | 4 | yes (card/bark atlas bake, foliage/_bake) | PASS |
| house | tv_antenna | near 162 | 600 | 4 | yes | PASS |
| street | usps_collection_box | near 76 | 600 | 4 | yes | PASS |
| street | utility_pole | near 1112/mid 25/far 6 | 2500 | 10 | yes | PASS |
| street | utility_pole_transformer | near 1874/mid 51/far 6 | 2500 | 10 | yes | PASS |
| house | vent_box | near 30 | 300 | 4 | yes | PASS |
| house | vent_plumbing | near 70 | 300 | 4 | yes | PASS |
| house | vent_turbine | near 140 | 300 | 4 | yes | PASS |
| fences | vinyl_canal_rail | near 54/mid 18/far 2 | 60 | 10 | yes | PASS |
| construction | water_barrier_orange | near 54 | 1200 | 4 | yes | PASS |
| construction | water_barrier_white | near 54 | 1200 | 4 | yes | PASS |
| city | water_tower | near 2476/mid 394/far 20 | 2500 | 10 | yes | PASS |
| fences | weathered_board | near 52/mid 12/far 2 | 60 | 10 | yes | PASS |
| fences | wood_privacy | near 56/mid 12/far 2 | 60 | 10 | yes | PASS |
| fences | wrought_iron | near 56/mid 18/far 16 | 60 | 10 | yes | PASS |

## Parks (layouts of kit props/foliage + ground)

| park | near tris (sum of instances) | assets | errors | result |
|---|---|---|---|---|
| park_beach_access | 5500 | 13 | ok | PASS |
| park_dog_run | 3514 | 7 | ok | PASS |
| park_glorietta_lawn | 17674 | 10 | ok | PASS |
| park_memorial_green | 9160 | 7 | ok | PASS |
| park_playground_village | 6000 | 11 | ok | PASS |
| park_pocket_orange | 4452 | 7 | ok | PASS |
| park_spreckels_crown | 26210 | 18 | ok | PASS |
| park_star_circle | 12246 | 7 | ok | PASS |
| park_succulent_garden | 6364 | 7 | ok | PASS |
| park_tennis_courts | 1550 | 5 | ok | PASS |
| park_tidelands_bay | 18894 | 12 | ok | PASS |

## Discarded (over budget)

- none

## Failing

- none
