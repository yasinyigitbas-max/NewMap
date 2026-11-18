# Review brief: Coronado city plan (Plan D) tiles

You are checking a generated 2D city plan of Coronado, California, for a game. Each tile image is two panels side by side:
LEFT = the plan (4 px per metre), RIGHT = the real aerial photo of the same ground (USGS NAIP, 1 m, upscaled).
Tile file names are `s_<x>_<z>.png`: x east / z south in metres of the tile's top-left corner; each tile covers 200 x 200 m,
so a pixel (px, py) in the LEFT panel is at x + px/4, z + py/4.

Plan colours: dark grey-blue = road; light grey ring = kerb; grey = pavement (walk); darker green strip = grass verge;
green = lawn; beige / pink / lilac = buildings (house / apartment / shop); greyish-pink = hero buildings; mid grey = alley;
dark grey = car park; light concrete = plaza / path / drive; blue-green = sport court; white stripes = zebra crossings;
yellow / white lines = road paint; small dark-red ovals = parked cars; thin circle with a brown dot = a tree (crown ring
+ trunk); small coloured dots = lamps (yellow), hydrants, signs, bins; thin white lines in lawns = lot fences.
The navy base (North Island, north-west) and the Silver Strand amphibious base (south-east) are NOT planned on purpose.
Plain uniform dark areas outside the town are open land / road background on purpose.

Report ONLY concrete defects you can point at, each with tile name + pixel position in the LEFT panel + one line.
Defect types the owner cares about (in order):
1. Half kerbs: a kerb or pavement that stops in the middle of nowhere, a kerb ring that does not close, a pavement piece
   floating in the road, a kerb crossing a road.
2. Zebra crossings that do not span the full road from kerb to kerb, or that do not line up with the pavement / kerb
   ramps on both ends, or crossings on top of each other.
3. Road lines (centre / edge / lane lines) that stop halfway along a straight street with no junction, or that run
   onto a kerb, pavement or building.
4. Jagged patches: stair-stepped or zig-zag edges on any surface, slivers, tiny orphan patches of one surface inside
   another (e.g. a scrap of lawn in asphalt), odd meaningless shapes.
5. Roads or alleys that connect to nowhere (stop short of the street, end in a lawn), driveways that cross a building.
6. Trees on roads, on fences, inside buildings, on car parks, or anywhere odd; trees standing in a pavement must sit in a
   round dark tree well centred on the trunk.
7. Big empty green areas where the photo clearly shows buildings or paving (compare with the RIGHT panel), or buildings
   where the photo shows open ground.
8. Anything else that looks broken or obviously unreal.

Do not report: colours, the lack of 3D, small position offsets under ~2 m against the photo, the navy bases, things that
are correct but merely simplified. Be specific and honest; if a tile is clean, say "clean". Finish with a list of all
defects found, grouped by type, then a count per type.
