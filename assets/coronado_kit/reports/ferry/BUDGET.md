# Passenger ferry: budget class `vessel` (APPROVED by Yasin 20 Nov 2026; recorded in SPEC.md section 7)

## Why a new class
SPEC section 4 has no vessel class. The ferry is 21 m long, two decks, and is seen from the landing and the bay, so it is
sized like a landmark building (SPEC: Landmark 8,000 / 2,500 / 200, e.g. "ferry pavilion"), not like a prop or a car
(vehicles kit: 4,000 / 600 / 260). Most of its triangles are railings, benches, fenders and the wheelhouse gear that make it
read as a passenger ferry; the hull itself is cheap.

## Class `vessel` (maximums; approved as proposed)
| Tier | Budget | Notes |
|---|---|---|
| near | **8,000** | 0-60 m: colour + normal + ORM (AO in R) |
| mid | **2,400** (30 %) | 60-220 m: colour only; no railings, benches or small gear (SPEC mid rule) |
| far | **200** | 220 m+: closed hull + cabin / wheelhouse boxes + hardtop, window band painted |
| col | at most 12 boxes | hull (3), main cabin, upper-deck slab, wheelhouse, hardtop |

## Measured
Final (pass 4, `tools/pipeline.sh p4`, reports/k_check.json): **ALL PASS**, 0 flipped faces.

| tier | tris | budget (vessel class) | verts | bounds L x B x H (m, incl. rails/mast) |
|---|---:|---:|---:|---|
| near | 5,748 | 8,000 | 6,951 | 21.21 x 7.09 x 9.01 (y -1.46..7.55) |
| mid  | 1,158 | 2,400 | 1,816 | 21.16 x 6.78 x 7.83 |
| far  |   186 |   200 |   302 | 21.00 x 6.60 x 7.27 |
| col  |    84 | 12 boxes max | 7 boxes | 20.1 x 6.6 x 7.55 (y -1.55..6.0) |

High-poly bake source: 41,938 tris (not shipped). Hull 21.0 m LOA x 6.6 m beam, keel/skeg 1.45 m below the waterline, main deck +1.42..2.04 (sheer).
Textures: ferry_color 1024 + ferry_normal 512 + ferry_orm 512 = **2.000 MiB** ASTC 4x4 + mips. One material = 1 draw call per tier.

## Texture memory
One own page: colour 1024, normal 512, ORM 512 = **2.000 MiB** at ASTC 4x4 + mips (same as one kiosk page).
SPEC 82 says a single prop never gets its own texture above 512; the ferry needs its own page because nothing in the
protected props pages fits a 21 m hull. Options for Yasin:
1. **Count it in the vehicles pool** (recommended: the vehicles kit already has its own atlas; the ferry is a vehicle).
2. Colour 2048 / normal 512 / ORM 512 = 6.0 MiB for sharper hull lettering and window frames up close (not needed at landing distance).
3. Leanest: colour 512 / normal 256 / ORM 256 = 0.5 MiB (soft; lettering unreadable).

## Draw calls
One mesh + one material per tier (near / mid / far). Collision is a separate box mesh with no material.

## Frame
Y up, bow = +Z (vehicles-kit convention), X = starboard, metres. Origin on the design waterline (y = 0) at the hull's
length and beam centre. Keel (skeg) at y = -1.45, hull bottom at -1.20. Water should be drawn at y = 0.

## Approval (Yasin, 20 Nov 2026)
- Class `vessel` = **8,000 / 2,400 / 200** tris (near / mid / far), collision at most **12 boxes**. Budgets are maximums.
- Texture: the ferry page (2.000 MiB at ASTC 4x4 + mips) is **counted under the vehicles texture budget** (option 1 above), not under props.
- Shipped files: `vehicles/ferry/` (veh_ferry_passenger near/mid/far/col GLBs, `ferry_{color,normal,orm}.png`, `CREDITS.md`),
  `vehicles/manifest_ferry.json`. The GLBs reference the PNGs next to them. The pre-push re-check on the copied files is `reports/ferry/k_check.json` (ALL PASS).
- Previews: `previews/ferry/fin_*.jpg` (hero, side, bow, stern, aft, upper, wheel, aerial, tiers, dry hull, plus the `fin_nomaps` / `fin_ao` map proofs).
