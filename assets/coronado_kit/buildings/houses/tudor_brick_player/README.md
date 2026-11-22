# tudor_brick_player

Player-house variant of `houses/tudor_brick`. The stock model is unchanged (same names and ids).

- Only the n1 lot in `tools/city/pilot/pieces/n_hs_b6_tenth.gd` (north side of 10th St, with the double_stucco_clay garage) points at this folder.
- The near mesh carries the interior shell (floors, partitions, stair, doors, window reveals, skirting, wainscot, tile dado). Mid and far stay closed shells.
- Windows are real openings. The six stock diamond panes and the rear `O_small_white` are dropped on the near mesh and replaced with an alpha-blend glass primitive (`window_glass`, double-sided, no vertex colour). Interior reveals line up with those façade openings. The living-west / kitchen-east holes from an earlier pass were in the wrong place: the west light is in the office, the east light straddles dining and kitchen at z = -0.10..0.90, and the utility has the small high rear window. The player variant also punches a stacked gable light above each side window so the bedroom and the attic bath have daylight. Mid and far do not get those attic cuts (LOD will close them at distance).
- Home lives only on the HUD map (`player_home.json`). There is no 3D pin on the model.
- Furniture is **hand-placed**. See `furniture.json` (room, purpose, focal point, every prop's position / yaw / id). Do not run a bay generator or template over this house.
- Near budget: 2500. Shell uses 2444 (spare 56 of the original 806), including 18 glass triangles. Props use their own page-H / I / J / K budgets.
