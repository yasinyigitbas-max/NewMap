# Coronado indoor props (page I)

Shop interior furniture and fixtures, built from scratch to SPEC.md. **Near and collision tiers only** — these pieces are viewed at 0–25 m inside a shop and are not drawn at mid or far distances. All 62 pass `tools/indoor/i_check.py` (18 Nov 2026).

```
props/indoor/shared/      13 shared fixtures
props/indoor/food/        14 cafe / restaurant / bar / bakery pieces
props/indoor/grocery/     5 grocery / liquor / fuel-shop pieces
props/indoor/clothing/    5 clothing / shoe pieces (fitting room is a full cubicle)
props/indoor/salon/       5 salon / barber pieces
props/indoor/gift/        4 gift / books / pharmacy / gallery pieces
props/indoor/office/      3 office / bank / clinic pieces
props/indoor/services/    6 laundry / workshop pieces
props/indoor/sport/       3 sport / surf / gym pieces
props/indoor/venue/       4 cinema / theatre pieces
props/indoor/_bake/       slots_i.json: page I bake slots
props/manifest_in*.json   one manifest per category
atlases/props_i_{color_clean,normal,orm}.png
tools/indoor/             i_check.py, builders, trims, compose
previews/indoor/          one hero per piece + _contact_sheet_indoor_<category>.jpg
```

The glbs reference page I as `../../../atlases/props_i_*.png` (same depth as waterfront and streetside), so keep the layout. One material and one draw call per prop. Kit glass is opaque (`ti_glass`).

## Texture budget

Page I is a new atlas: **1024 colour / 512 normal / 256 ORM = 1.75 MB** (ASTC 4x4 with mips).

It is **streamed only with interiors**. It is **not** part of the 8 MB street-resident props cap. Street pages A + B + C + grime + W stay at **7.583 MB of 8 MB**. This set never writes to those pages.

Shared trim tiles (128 px/m): `ti_wood`, `ti_laminate`, `ti_metal`, `ti_paint`, `ti_fabric`, `ti_glass` (opaque), `ti_plastic`, `ti_brass`. Unique lettering, screens and labels go in small bake slots from row y=256 (see `_bake/slots_i.json`).

## Tiers and checks

- Tiers: **near + col only**. Mid and far are not built and are not required.
- `tools/indoor/i_check.py` is the indoor acceptance test: naming, near+col present, one mesh / one material, triangle cap, page I textures only, origin at the footprint centre, ground at y=0.
- Chairs and stools get collision (one box, or one cylinder on a few round pieces).
- Budgets are maximums (tiny 300 / small 600 / medium 1200 / large 2500). Nothing in this folder exceeds its target.

## Pieces (tris near, collision, footprint w x d, height in metres)

| group | piece | footprint, height (m) | near | budget | col |
|---|---|---|---:|---:|---:|
| shared | shop_counter | 1.82 x 0.67, 0.96 | 648 | 900 | 12 |
| shared | cash_register | 0.45 x 0.41, 0.51 | 334 | 500 | 12 |
| shared | wall_shelf | 1.00 x 0.33, 2.00 | 526 | 1000 | 12 |
| shared | gondola_aisle | 1.22 x 0.54, 1.82 | 560 | 1100 | 12 |
| shared | display_table | 1.36 x 0.77, 0.78 | 548 | 800 | 12 |
| shared | glass_display_case | 1.24 x 0.59, 1.10 | 466 | 1100 | 12 |
| shared | waiting_bench | 1.48 x 0.52, 0.88 | 496 | 500 | 12 |
| shared | side_chair | 0.44 x 0.50, 0.92 | 380 | 550 | 12 |
| shared | potted_plant | 0.45 x 0.36, 0.85 | 349 | 400 | 44 |
| shared | indoor_bin | 0.30 x 0.36, 0.54 | 246 | 250 | 44 |
| shared | drinks_fridge | 0.79 x 0.76, 2.00 | 486 | 1100 | 12 |
| shared | brochure_rack | 0.52 x 0.42, 1.55 | 386 | 400 | 12 |
| shared | menu_board | 1.70 x 0.08, 0.93 | 236 | 400 | 12 |
| food | cafe_table | 0.76 x 0.76, 0.75 | 384 | 600 | 44 |
| food | restaurant_table | 1.20 x 0.80, 0.76 | 420 | 800 | 12 |
| food | cafe_chair | 0.44 x 0.44, 0.91 | 494 | 550 | 12 |
| food | bar_stool | 0.40 x 0.40, 0.93 | 472 | 550 | 44 |
| food | booth_bench | 1.30 x 0.64, 1.05 | 340 | 600 | 12 |
| food | espresso_machine | 0.74 x 0.94, 0.92 | 814 | 1100 | 12 |
| food | pastry_case | 1.40 x 0.71, 1.20 | 608 | 1100 | 12 |
| food | gelato_case | 1.62 x 0.79, 1.19 | 486 | 1100 | 12 |
| food | soda_fountain | 0.72 x 0.67, 1.16 | 770 | 800 | 12 |
| food | bakery_shelf | 1.20 x 0.42, 2.00 | 826 | 1100 | 12 |
| food | wine_backbar | 1.60 x 0.41, 2.10 | 1096 | 1200 | 12 |
| food | kitchen_line | 2.22 x 0.84, 2.06 | 1582 | 2000 | 12 |
| food | beer_taps | 0.62 x 0.28, 0.62 | 526 | 600 | 12 |
| food | bar_counter | 2.20 x 0.77, 1.11 | 720 | 1200 | 12 |
| grocery | checkout_counter | 2.00 x 0.78, 1.40 | 822 | 1200 | 12 |
| grocery | chest_freezer | 1.64 x 0.73, 0.94 | 606 | 1100 | 12 |
| grocery | grocery_shelf | 1.20 x 0.46, 2.05 | 702 | 1200 | 12 |
| grocery | produce_stand | 1.40 x 0.70, 1.21 | 656 | 1100 | 12 |
| grocery | cigarette_cabinet | 0.92 x 0.34, 1.10 | 408 | 900 | 12 |
| clothing | clothes_rack | 1.44 x 0.48, 1.70 | 956 | 1000 | 12 |
| clothing | fitting_room | 1.14 x 1.36, 2.12 | 1088 | 2500 | 12 |
| clothing | mannequin | 0.52 x 0.44, 1.74 | 590 | 900 | 44 |
| clothing | shoe_bench | 1.10 x 0.38, 0.59 | 508 | 550 | 12 |
| clothing | shoe_wall | 1.20 x 0.36, 2.00 | 486 | 1100 | 12 |
| salon | barber_chair | 0.67 x 0.80, 1.30 | 934 | 1100 | 12 |
| salon | mirror_station | 1.20 x 0.44, 1.99 | 1024 | 1200 | 12 |
| salon | nail_table | 1.10 x 0.62, 1.13 | 406 | 900 | 12 |
| salon | salon_product_shelf | 1.02 x 0.39, 2.02 | 1150 | 1200 | 12 |
| salon | wash_basin | 0.69 x 1.10, 1.11 | 758 | 1000 | 12 |
| gift | card_spinner | 0.61 x 0.56, 1.55 | 720 | 900 | 44 |
| gift | gallery_frame | 0.70 x 0.07, 0.90 | 222 | 400 | 12 |
| gift | pharmacy_shelf | 1.13 x 0.40, 2.00 | 514 | 1100 | 12 |
| gift | bookcase | 1.02 x 0.36, 2.05 | 418 | 1100 | 12 |
| office | filing_cabinet | 0.50 x 0.67, 1.32 | 434 | 800 | 12 |
| office | office_chair | 0.56 x 0.59, 1.05 | 608 | 800 | 12 |
| office | office_desk | 1.50 x 0.75, 0.74 | 420 | 1000 | 12 |
| services | washer | 0.68 x 0.74, 0.98 | 942 | 1100 | 12 |
| services | dryer | 0.65 x 0.80, 0.99 | 936 | 1100 | 12 |
| services | garment_rail | 1.54 x 0.41, 1.67 | 1084 | 1100 | 12 |
| services | workbench | 1.60 x 0.89, 1.48 | 644 | 1100 | 12 |
| services | laundry_counter | 1.80 x 0.72, 1.08 | 748 | 1200 | 12 |
| services | pegboard_wall | 1.22 x 0.25, 2.00 | 714 | 1100 | 12 |
| sport | bike_stand | 1.40 x 0.70, 0.96 | 332 | 800 | 12 |
| sport | surfboard_rack | 0.62 x 0.84, 1.53 | 560 | 800 | 12 |
| sport | weight_bench | 1.16 x 0.84, 1.11 | 460 | 900 | 12 |
| venue | theatre_seat | 0.58 x 0.59, 1.02 | 386 | 800 | 12 |
| venue | ticket_booth | 1.26 x 1.14, 2.20 | 880 | 1800 | 12 |
| venue | stanchion | 0.40 x 0.74, 0.99 | 180 | 500 | 12 |
| venue | poster_case | 0.84 x 0.10, 1.20 | 224 | 700 | 12 |
| **total** | **62** | | **37719** | | |

## Build

```bash
export IN_KIT=/path/to/coronado_kit
# one Blender at a time, -t 2, nice 19
./tools/indoor/i_build.sh inshared
```

