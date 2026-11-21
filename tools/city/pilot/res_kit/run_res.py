import sys, os, json
os.environ["KIT_ATLAS"]="city"
sys.path.insert(0,os.path.dirname(os.path.abspath(__file__)))
only=sys.argv[1:]; sys.argv=[sys.argv[0],'urban']
import make_modular as MM, mod_res, mod_phased
def _cat(g):
    b=mod_res.brk_front_res_t(3); b.name='urb_brk_front_6m_3sty_res'
    return [('urban',b),('urban',mod_res.brk_front_walkup_t(3))]
MM.MP.catalogue=_cat
MM.run(None)
