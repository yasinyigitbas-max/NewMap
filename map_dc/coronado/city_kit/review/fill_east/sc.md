# The last scraps inside the ring road (20 Nov evening): n_sc_*, LOCKED

Yasin: "just fill the tiny spaces empty in the ring road", "i dont want you to do anything beyond the ring road", and
(relayed by the perf-bugs session) "fill them meaningfully without touching anything that already exists".
Edges and heights measured on the current city (main): `tools/city/pilot/pieces/n_sc_site.gd` (each neighbour's ground edge
every 1 m; ground = land + 5 cm, eased to each edge's exact height), land table `n_sc_land.gd`.

| Piece | Scrap | What is there |
|---|---|---|
| n_sc_mid | R4 u -390.8..-305, v -409..-391 (unbuilt v -400 street line, staff townhouses / stadium shops) | Stadium Walk West: 3 m path, lawn, globe lamps, drinking fountain, planting, bollards at the stadium drive |
| n_sc_mid | R5 u -95..-16, same line (stadium promenade / Amber shops) | Stadium Walk East: the same greenway, paved forecourt at Amber with 2 bike racks, bollards at the drive |
| n_sc_mid | R7 u -209..-191, v -240..-209.2 (between the two fan plazas) | Fan Link: paved plaza joining them, two planted beds, drinking fountain, lamps |
| n_sc_west | R2 the wedge between the ring's inner walk and the Ridge Garden Nursery, v -1150..-1009.2 (0-38 m wide) | Ridge Corner Garden: lawn, path in from the -1000 street to a paved court, lamp, bougainvillea / agave screen on the nursery fence |
| n_sc_south | R12, R6, R9, R8, R10: slivers between the beach-side houses' back edges and the ring's inner walk (0-18 m wide) | planted buffer: lawn, privet hedge 0.8 m off the back edges where 4 m+ wide (245 segments), bougainvillea and agaves |

Not filled (measured): scraps 1 and 3 lie west of the ring road (outside it); 11 is the pilot's post office (b_se); 13 the
civic block's pocket park (v_nw); the ferry gap; the tennis-court pocket (u 354..393, v -739..-700); the ring's own gap in
the south-east corner. Nothing beyond the ring road.

Checks (area layout `layout/sc_area.json`, 98 rows): superchecker: 22 items deleted (all 7 bins "in the open", all 14
benches and the picnic table "stand alone, nothing to sit with"); after that only report-only kinds (wide_batch,
empty_area, edge_step: 4 cm over 2 m at R4's west end, 7 cm over 4 m at R8's east cross street). validate 0, check_life 0,
audit_trees 0 lines on n_sc_*. Exact colliders on all three, largest gap 0.0 mm (sprinklers without, by design).
Ground overlap with the 91 neighbouring pieces 0; land over the ground 0. Locked; lock test RESULT PASS.
Not done: no hand trees (the strips are narrow and the boulevard palms fill the in-view limit; the garden could take a
clump later); no seats left (the checker's rule); nobody has looked at it at eye height.
