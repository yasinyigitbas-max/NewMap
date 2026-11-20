# The Hospital session's fill of its empty land (20 Nov): built, superchecked indoors and outdoors, LOCKED

Yasin: "populate them. act like architects and city planners, build indoors and outdoors, take the elevation of the map
into consideration, then run superchecker on everything you built to bugfix and lock; plenty of props, plenty of life";
"dont fill what is beyond the last highway"; "fill that thin strip in between somehow too"; "dont wait for approval this
time ... be much more prone to delete a prop or road mark"; "DONT FORGET TO RUN THE SUPERCHECKER BEFORE YOU SEND THEM TO
COORDINATOR ... BOTH INDOORS AND OUTDOORS". Method: `BUILD_GUIDE.md`. Per area: `fw.md`, `fn.md`, `fe.md`.

| Area | Pieces (grid pos) | Trees | Rooms |
|---|---|---|---|
| fw, NW column u -400..-200, v -1600..-800 (Crown Hill west slope) | n_fw_bay / slope / crest / court ([0,0,0]) | t_fw_* 22 | 8 |
| fn, north end u -200..400, v -1600..-1400 + greenway strip u 375..400 | n_fn_west / mid / east / strip ([0,2,0]) | t_fn_* 21 | 19 |
| fe, east blocks u 259..ring, v -1000..-800 + ring band u 509..ring, v -800..0 | n_fe_b1w / b1e / b2 / r7 / r5 / r3 / r1 ([0,4,0]) | t_fe_* 17 | 11 |

Rows for integrate.py: `review/grow_hospital_blocks.json` (15 pieces; the t_* tree pieces come in through
`zoning/trees/{fw,fn,fe}_*.json`). Area layouts used for the checks: `layout/{fw,fn,fe}_area.json`.
Not filled: blocks u 800..1000 at v -1400..-1000 (beyond the ring: sea and shoreline). The pocket u 353..393,
v -740..-700 holds n_apt_b1_be's tennis courts: left alone. The ring band v -1400..-1200 was already built (m_gr_*).

## The coordinator's own checks before locking (20 Nov)
- Superchecker re-run by me on all 15 pieces, outdoors and every room (`sc.py check` against each area layout through
  the scratch wrapper `OUT/fill/fw/sc_fw.py`: this branch's sc_lib has no SC_LAYOUT switch): 0 fixes left in any room
  (all remaining room findings report-only: sign_wrong, shop_lacks, staff_door_off, thin_wall, window_empty, no_counter);
  outdoors every "one right answer" is no_collision / column_no_collision ONLY, which is the checker's blind spot: it
  reads prop colliders only under Props/PropCol, and the true-size colliders live in PropColExact (the locked n_hp_west
  shows the same). The rest report-only (wide_batch, empty_area, edge_step / ground_step).
- Colliders (`OUT/colexact_verify.gd`) on all 30 pieces: every collider on its drawn prop, largest gap 0.1 mm, none
  without a prop; only sprinklers and iceplant patches without (by design).
- Ground overlap of each new piece with every other piece in its area dump (1 m cells, `OUT/py/overlap_new.py`): 0 m2.
- Lock: 30 pieces + 38 room files locked --by=Yasin; lock test RESULT PASS.

## Deleted by the superchecker pass (Yasin: delete when unsure)
About 265 props outdoors (fw 108, fn 67, fe 90) and 29 oil marks + all lane-wear stripes (fw / fn), 52 room items. Cost:
EVERY playground's play items went (fn's three playgrounds are lawn, fw's bay tot lot and fe's b1w / b1e / r7 play
pads are empty), most park benches and tables went: the parks are quieter than planned.

## What no check here can see / not done
- Nobody has looked at a single picture of any of it (no shots, no bake, no phone run).
- No room behind: n_fn_east's inn office door (its contract opens the whole 324 m2 floor; needs an office-bay contract),
  n_fn_mid's three beach-condo lobby doors.
- Seams over 2 cm: fn along Amber 26 m at up to 2.3 cm; fn strip ends 0.39 m (v -1200) and 7.7 cm (v -1000), each ~1 m,
  where the house block's own edge stands that high; fe junction corners 2.5-5.6 cm over 2-7 m (in the junctions' own
  corner cells), fe at r_q_250_m1000_se up to 6 cm over ~1 m.
- fw slope / crest: 33 % grass banks between stepped pads, ground_step up to 11 cm; n_fw_bay ground 42.9k triangles.
- Trees thin (2-6 per piece): the tree plan's in-view limit was mostly used by the streets' own trees.
- Shop names repeat across areas (Crown Hill / Hilltop in fw and fe).
- The exact colliders are patched into the saved files; any rebuild of a piece needs `exact_colliders.gd` again.
