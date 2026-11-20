# Street-food kiosks: budget class `kiosk` (APPROVED by Yasin 20 Nov 2026; recorded in SPEC.md section 7)

## Why a new class
SPEC section 4 has no kiosk or vendor-stall class. The closest is **Large prop: 1,500-2,500 near, mid 30 %, far 20**
(bus shelter, lifeguard tower). A kiosk is a dressed, walk-up, hero-distance prop: the counter food, bottles, signs and umbrella
are what make it read as a hot dog cart rather than a box. SPEC 174 also says plain or blocky counts as a FAIL. The five kiosks
need **2,400-3,200 near**, so they fit inside the proposed class, but over the large-prop cap.

## Class `kiosk` (maximums; approved as proposed)
| Tier | Budget | Notes |
|---|---|---|
| near | **4,500** | 0-60 m, colour + normal + ORM (AO in R). Headroom left on purpose: no kiosk uses more than 71 % |
| mid | **1,350** (30 %) | 60-220 m, colour only, no counter dressing |
| far | **200** | silhouette only, colour only |
| col | at most 12 boxes | body or counter, posts and legs. No collision on umbrellas, awnings or canopies (walk-under rule) |

Over the existing Large-prop cap (2,500 near / 20 far): **hot dog (2,460) and shave ice (2,396) are within 2,500; paleta (2,634), lemonade (2,744) and taco (3,182) exceed it**.
All five far tiers are over 20 (52-164). A 20-triangle far would be a flat card that can't show an umbrella or canopy shape.
If Yasin wants them inside Large instead, the taco stand would lose the trompo, pineapple and leaf topper, tortillas, salsa tubs
and truss (about -700). The far tiers can drop to about 40 by using a box + umbrella cone only.

## Measured (final p4 pipeline; reports/k_check.json)
| Kiosk | glb name | near | mid | far | col boxes | footprint w x d (near bounds) | height |
|---|---|---|---|---|---|---|---|
| Hot dog cart | prop_kiosk_hotdog_cart | 2,460 | 556 | 164 | 1 | 1.97 x 1.97 m | 2.40 m |
| Paleta cart | prop_kiosk_paleta_cart | 2,634 | 784 | 114 | 1 | 1.73 x 1.39 m | 2.20 m |
| Taco stand | prop_kiosk_taco_stand | 3,182 | 420 | 126 | 8 | 3.14 x 3.65 m | 2.78 m |
| Shave-ice shack | prop_kiosk_shaveice_shack | 2,396 | 330 | 52 | 3 | 3.15 x 2.83 m | 3.04 m |
| Lemonade stand | prop_kiosk_lemonade_stand | 2,744 | 554 | 88 | 6 | 2.51 x 1.24 m | 2.50 m |

All tiers: 1 mesh, 1 material, tangents, OPAQUE. Near links colour + normal + ORM (occlusionTexture = ORM, AO in R). Mid/far are colour only.
Pivot is at ground level, at the centre of the main body. Mid is 13-30 % of near (kiosk mid tiers drop all counter dressing).

## Texture memory
One shared page for all five kiosks: colour 1024, normal 512, ORM 512 = **2.000 MiB** at ASTC 4x4 + mips.
That is about 0.4 MiB per kiosk, the same as one 512 prop page each. SPEC 82 ("a single prop never gets its own texture above
512") is respected in spirit, because the page is shared.

**Props cap is 8 MB.** Street props were at 7.583 MB, and the bicycle page (1.0 MiB) takes that to about 8.63 MB. Adding the
kiosks makes about **10.6 MB, 2.6 MB OVER the cap.** Options for Yasin:
1. **Count kiosks (and the bicycle) as vehicles / set-dressing with their own pool** (recommended: they are hero props, few
   instances, near the boardwalk only).
2. Lean page: colour 1024, normal 256, ORM 256 = **1.5 MiB** (normal detail halves; the sign lettering stays sharp).
3. Leanest: colour 512, normal 256, ORM 256 = **0.5 MiB**. Signs go soft; not recommended.
4. Pack the kiosks into props page B leftovers: needs a repack of B, which is a protected atlas, so not done without approval.

## Draw calls
One mesh + one material per tier per kiosk (5 MultiMesh types). All five share one material and texture set.

## Approval (Yasin, 20 Nov 2026)
- Class `kiosk` = **4,500 / 1,350 / 200** tris (near / mid / far), collision at most **12 boxes**. Budgets are maximums.
- Texture: the kiosks get **their own texture pool of 2 MiB** (the shared kiosk page above: 2.000 MiB at ASTC 4x4 + mips). It is
  NOT counted against the 8 MB props cap (option 1 above).
- Shipped files: `props/kiosks/` (GLBs near/mid/far/col, `kiosks_{color,normal,orm}.png`, `CREDITS.md`), `props/manifest_kiosks.json`.
  The GLBs reference the PNGs next to them. The pre-push re-check on the copied files is `reports/kiosks/k_check.json` (ALL PASS).
  The final maps are a pass-5 re-bake after a cap-winding fix in `tools/kiosks/kgeo.py`; triangle counts are unchanged from the table above.
- Previews: `previews/kiosks/fin_*.jpg` (hero/back/top/wheel/tiers per kiosk, lineups, and `fin_nomaps_*` / `fin_ao_*` map proofs).
