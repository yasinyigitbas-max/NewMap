import sys, os, json
os.environ["KIT_ATLAS"]="city"
sys.path.insert(0,os.path.dirname(os.path.abspath(__file__)))
sys.argv=[sys.argv[0],'urban']
import make_modular as MM, mod_res
MM.MP.catalogue=lambda g: [('urban',mod_res.brk_front_res_b(3)),('urban',mod_res.brk_front_walkup_b(3))]
MM.run(None)
