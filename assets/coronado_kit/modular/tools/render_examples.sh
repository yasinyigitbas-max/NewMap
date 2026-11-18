#!/bin/bash
# near-tier close-ups of the example assemblies (one Blender at a time)
K=/workspace/coronado_kit_v2; BL=/workspace/tools/blender/blender; E=$K/modular/examples; O=$K/modular/previews/closeups
mkdir -p $O; cd $K/tools
r(){ while pgrep -f 'blender/blender' >/dev/null; do sleep 5; done   # one Blender at a time (other jobs share the box)
  DIAG_SAMPLES=64 DIAG_EYE=$3 DIAG_TGT=$4 DIAG_LENS=$5 timeout 600 $BL -b -P render_diag.py -- $O/$1_$2.png $E/$1/mod_$1_near.glb cam >/dev/null 2>&1; echo "$(date +%H:%M) $1_$2" >> $K/modular/logs/render.log; }
mkdir -p $K/modular/logs
ONLY=${ONLY:-all}
if [ "$ONLY" != shops ]; then
for h in ex_house_ranch_stucco ex_house_garage_siding ex_house_cottage_clay; do
  r $h front34 -8,-11,3.4 0.5,0,2.2 32
  r $h entry 3.2,-8.6,2.3 0,-3.75,1.9 30
  r $h back34 9,9,3.6 0,0,2.2 32
done
fi
if [ "$ONLY" != houses ]; then
r ex_shop_row_cafe_books front34 -10,-17,4.2 0,-3,2.6 30
r ex_shop_row_cafe_books storefront 0.5,-12.5,2.3 -3,-6,2.4 28
r ex_shop_row_cafe_books back34 11,14,5 0,0,2.6 30
r ex_shop_corner_bakery front34 -8,-14,4 0,-2,2.6 30
r ex_shop_corner_bakery storefront 2.5,-11,2.2 0,-6,2.4 28
fi
echo RENDER_DONE >> $K/modular/logs/render.log
