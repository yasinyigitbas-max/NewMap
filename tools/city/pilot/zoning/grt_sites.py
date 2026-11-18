"""Gritty edge growth (18 Nov, claude/grow-gritty): the pilot area's block sites -> map_dc/coronado/city_kit/review/grow_grt_blocks.json.

The pilot area is the 3 x 4 run of 100 m quadrants between the locked industrial sample (J Ave x 3rd St) and the locked
gritty sample (G Ave x 5th St): u -800..-500, v -1300..-900 in the grid frame. The gritty sample holds four of them;
this table serves the other EIGHT: the four quadrants of G Ave x 4th St, the east two of J Ave x 4th St and the east
two of J Ave x 5th St. Every one of them is a quadrant of a junction (the sample pattern: a piece's origin is its
junction centre, the quadrant is (sx * u, sz * v) with u, v = 0..100 from that centre).

Per site:
  plu / plv   the property line of the street along v (an Ave, at u = 0) and of the street along u (a numbered St, at v
              = 0): 9.2 on res / std streets (apt_lib), 14.3 on 4th St (the strip arterial section, ROADKIT_SPEC.md)
  apr         driveway aprons of the 4th St leg on this side (centres along u, 9 m wide; road_art art_leg "apr"),
              copied from the locked-in-review s_ar_* scripts; 5th St legs have their alley apron at 54-60
  centre      the height (pad metres) of the city block's centre, the corner where the quadrant's two inner edges meet:
              the pad of a locked sample quadrant in the same block (flat), else the mean of the block's four street
              midpoints; the piece's ground runs from its streets' sidewalks (measured from the built street pieces)
              to this corner (Coons patch with smoothstep edges, grt_grow_lib.gd)
  recipe      v1 yard edge (industrial side), v2 trade street (the middle), v3 walk-up homes (toward the apartments and
              the campus); the seed varies buildings and businesses so no two sites are dressed the same
Run: python3 -I tools/city/pilot/zoning/grt_sites.py   (then zoning/integrate.py picks the rows up)
"""
import json, os

HERE = os.path.dirname(os.path.abspath(__file__))
KIT = os.path.normpath(os.path.join(HERE, "../../../../map_dc/coronado/city_kit"))

J4 = (-800.0, -1200.0, 2.0)     # J Ave x 4th St (art junction j_ar_j4), pad 2
G4 = (-600.0, -1200.0, 4.0)     # G Ave x 4th St (j_ar_g4), pad 4
J5 = (-800.0, -1000.0, 4.0)     # J Ave x 5th St (resstd j_rs_3l1r_a), pad 4

# piece, junction, sx, sz, plu, plv, aprons on the numbered street, lane V opens onto it, centre pad, recipe, why
SITES = [
    ("g_v1_j4ne", J4, 1, -1, 9.2, 14.3, [62.0], True, 2.0, "v1",
     "J Ave x 4th, NE: backs onto the locked industrial sample (i_se); J Ave turns industrial north of the alley"),
    ("g_v2_g4nw", G4, -1, -1, 9.2, 14.3, [56.0, 85.0], True, 2.0, "v2",
     "G Ave x 4th, NW: the 4th St shop front opposite the trade core; the bus stop going west is in front"),
    ("g_v1_g4ne", G4, 1, -1, 9.2, 14.3, [62.0], True, 3.0, "v1",
     "G Ave x 4th, NE: industrial extension to the north (3rd St), the yards carry on"),
    ("g_v2_j4se", J4, 1, 1, 9.2, 14.3, [45.0, 80.0], False, 6.0, "v2",
     "J Ave x 4th, SE: same city block as the sample's g_nw, the edge's busiest corner"),
    ("g_v3_g4sw", G4, -1, 1, 9.2, 14.3, [62.0], True, 6.0, "v3",
     "G Ave x 4th, SW: homes between the 4th St shops and the sample's g_nw"),
    ("g_v3_g4se", G4, 1, 1, 9.2, 14.3, [56.0, 85.0], True, 6.0, "v3",
     "G Ave x 4th, SE: faces E Ave and the Crown Hill apartments: walk-ups, a court; the bus stop going east"),
    ("g_v2_j5ne", J5, 1, -1, 9.2, 9.2, [], True, 6.0, "v2",
     "J Ave x 5th, NE: 5th St shops facing the sample (bus route on 5th St)"),
    ("g_v3_j5se", J5, 1, 1, 9.2, 9.2, [], True, 6.0, "v3",
     "J Ave x 5th, SE: toward the campus (students live in the gritty edge, ZONING.md)"),
    # 19 Nov, the rest of the zone (Yasin: "roll out to your whole zone"): the four quadrants between J Ave and the
    # ring road (Alameda Blvd along the base fence). The ring's 4th St stub has no driveway aprons (road_rg _stub_art):
    # lane V stays closed to 4th St there; 5th St's stub has its alley apron at 54-60.
    ("g_v1_j4nw", J4, -1, -1, 9.2, 14.3, [], False, 2.0, "v1",
     "J Ave x 4th, NW: backs onto the industrial sample's i_sw, the base fence beyond the ring: used cars and salvage"),
    ("g_v2_j4sw", J4, -1, 1, 9.2, 14.3, [], False, 3.0, "v2",
     "J Ave x 4th, SW: the 4th St shop front toward the ring"),
    ("g_v3_j5nw", J5, -1, -1, 9.2, 9.2, [], True, 3.0, "v3",
     "J Ave x 5th, NW: homes behind a phone shop and a laundromat"),
    ("g_v3_j5sw", J5, -1, 1, 9.2, 9.2, [], True, 4.5, "v3",
     "J Ave x 5th, SW: toward the campus: student rentals over a noodle bar"),
]


def main():
    sites = []; rows = []
    for k, (piece, (u, v, pad), sx, sz, plu, plv, apr, lvo, centre, recipe, why) in enumerate(SITES):
        if k >= 8: k = {8: 8, 9: 9, 10: 10, 11: 11}[k]      # the rollout sites' seeds pick their own versions
        sites.append({"piece": piece, "junction": [u, v], "pad": pad, "sx": sx, "sz": sz, "plu": plu, "plv": plv,
                      "apr": apr, "lane_v_open": lvo, "centre": centre, "recipe": recipe, "seed": k, "why": why,
                      "cells_uv": [[u + sx * 9.2, v + sz * 9.2], [u + sx * 100.0, v + sz * 100.0]]})
        rows.append({"piece": piece, "pos": [u, pad, v], "yaw": 0.0})
    out = {"note": __doc__.strip().split("\n")[0], "area": "pilot u -800..-500, v -1300..-900; zone rollout adds u -900..-800, v -1300..-900 (grid frame)",
           "sites": sites, "rows": rows}
    p = os.path.join(KIT, "review/grow_grt_blocks.json")
    json.dump(out, open(p, "w"), indent=1)
    print("wrote %s: %d sites" % (p, len(sites)))


if __name__ == "__main__":
    main()
