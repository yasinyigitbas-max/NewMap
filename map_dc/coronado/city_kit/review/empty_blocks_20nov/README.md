# Empty land left, 20 Nov evening (for the Hospital session)

Yasin, 20 Nov: "take a note of the empty spaces and tell the hospital session to fill them meaningfully without touching
anything that already exists."

Measured on the assembled city (city_grid_layout.json, main at the time of writing) with tools/city/audit/ground_dump.gd
and tools/city/audit/empty_blocks.py: 124 blocks of 200 m touched by streets, 97 built, 8 partly, 19 empty; inside the
ring road the land is built (a few small scraps only, the pale squares in the picture). Picture: empty_blocks.jpg (green
built, grey streets, pale empty land, red empty blocks, orange partly built with their share).

Block corners are the grid frame (x along 10th, z along Amber; each block is the 200 m square from its corner to +200 m).

## Empty (under 10 % built)
- North edge, along and beyond the ring: (-1000,-1800) (-800,-1800) (-600,-1800) (-400,-1800) (-200,-1800) (0,-1800) (200,-1800)
- West edge, along and beyond the ring: (-1200,-1200) (-1200,-1000) (-1200,-800) (-1200,-600) (-1200,-400) (-1200,-200) (-1200,0) (-1200,200)
- South-east, by the bay: (600,0) (800,0) (1000,0) (600,200)

## Partly built (share built)
(400,-1800 20 %) (600,-1800 29 %) (800,-1600 46 %) (1000,-1400 23 %) (-1000,200 23 %) (-800,200 41 %) (-600,200 49 %) (-400,200 58 %)

## The rules for filling them
- Do not touch anything that already exists: no change to any existing piece, row of city_grid_layout.json, locked file
  or the land under built pieces. New pieces only, in new layout rows (as the Hospital and University fills did).
- Fill them meaningfully: what belongs where (the ring's edge, the coast, the bay, next to what already stands), as an
  architect, planner and designer would; hand placement, no generators; the house rules in CLAUDE.md and the
  coronado-super-builder skill (superchecker indoors and outdoors, true-size colliders, ground not sunk or floating).
- Start from main (it has everything: today's fills, the shops' rooms, street life, the bug fixes).
