"""wallcheck on page-W quay pieces: smooth-wall mask = cast-concrete tiles (tw_conc_top wall band, tw_conc capping beam),
judged only on the water-facing sides (backs are buried in fill, snap ends are open)"""
import sys, os, json
os.environ.setdefault('DIAG_MIN_ORTHO','7.0')   # judge every piece at the metric scale of a 6 m module (the tool's blur is relative to frame width)
os.environ['WC_RECTS']='0.758,0.859,0.633,0.742;0.258,0.359,0.883,0.992'
sys.path.insert(0,os.path.dirname(os.path.abspath(__file__))); import wallcheck as WC
TAG=''
if os.environ.get('DIAG_NOSHADOW'): TAG='_noshadow'
K='/workspace/coronado_kit_v2/_staging/waterfront'
SIDES={'quay_straight':('front',),'quay_straight_bollards':('front',),'quay_stair':('front',),'quay_corner_out':('front','right'),'quay_corner_in':('front','left')}
allr={}
for n in sys.argv[1:]:
    r=WC.check(f'{K}/kit/props/waterfront/quay/prop_{n}_clean_near.glb',f'{K}/reports/wallcheck/{n}{TAG}',SIDES[n]); allr[n]=r
    print(n,json.dumps(r),flush=True)
json.dump(allr,open(f'{K}/reports/wallcheck_'+os.environ.get('WC_GROUP','quay')+TAG+'.json','w'),indent=1)
