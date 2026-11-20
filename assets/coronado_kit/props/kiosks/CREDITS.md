# Street-food kiosks: credits

All five kiosks share one texture page (`tex/kiosks_{color,normal,orm}.png`). The page is painted procedurally (tools/kcompose.py)
from the photo-scanned sources below, plus normal and AO baked from our own high-poly models (tools/kbl_bake.py).

## Photo PBR sources: ambientCG (CC0 1.0, public domain; attribution not required, given anyway)
https://ambientcg.com. All sets are the 1K-JPG downloads, kept in cc0/.

| Set | Used for |
|---|---|
| Metal009, Metal011 | brushed stainless (cart bodies, deck, lids, heater) |
| Metal049A | chrome (frames, poles, rims, napkin box) |
| PaintedMetal004 | painted and powder-coated steel (legs, tank, panels, wheel discs) |
| Rust004 | tea-staining in occluded stainless corners |
| CorrugatedSteel005 | shave-ice shack roof |
| Fabric026, Fabric071 | canvas weave (umbrellas, canopies, valances), sarape speckle |
| PaintedWood007A, WoodSiding008 | painted shiplap, trims, lemonade boards |
| Wood049 | raw and varnished wood (counters, crates, skid, plywood, paint chips) |
| Plastic010, Plastic013A | moulded plastic (bottles, cups, cooler, surfboard) |
| Rubber004 | tyres, grips, feet, hose, citrus peel bumps |
| Ice002 | ice block / shave ice |
| Ground054 | sand-dust weathering layer |
| Fingerprints002, Scratches005, Smear008, SurfaceImperfections003 | wear: fingerprints, scratches, smears, imperfections |

Downloaded for evaluation but not used in the shipped page: Concrete034, Fabric004, Fabric072, Metal012, PaintedMetal009,
PaintedWood005, PaintedWood009B, Planks037A, Wood066.

## Fonts (rasterised into sign artwork only; no font files ship)
Google Fonts: Bebas Neue, Oswald, Pacifico, Alfa Slab One, Kalam, Lobster, Shrikhand, Titan One (SIL Open Font License 1.1);
Permanent Marker, Luckiest Guy (Apache License 2.0).

## Signs
All sign artwork is drawn in code (tools/ksigns.py) with generic, unbranded wording ("HOT DOGS", "PALETAS", "TACOS", "Shave Ice",
"Fresh LEMONADE"). There are no third-party logos or trademarks.
