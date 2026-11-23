"""MakeHuman 2 (MPFB2, the Blender extension) run headless to make the game's people (Yasin, 24 Nov: "start the
downloads of everything you need to operate make human 2"; polygon targets in docs/ANIMATION_PLAN.md section 13).
Setup (this machine, 24 Nov): pip install --target <dir> bpy (Blender 5.3 as a Python module); MPFB2 2.0.18 from
extensions.blender.org; the asset packs from static.makehumancommunity.org (files2.makehumancommunity.org).
  PYTHONPATH=<bpy dir> python3 tools/people/mpfb/make_human.py OUT.glb gender=1 age=0.5 muscle=0.6 weight=0.5 height=0.55
Sliders are 0..1 (MakeHuman's macros: gender 0 female - 1 male, age 0.5 = 25 years, 1 = 90; height 0.5 = average);
the body gets MakeHuman's "Game engine" skeleton (one skeleton for every person) and is written as GLB in metres.
Clothes, hair, skins: to come once the asset packs are installed (HumanService.add_mhclo_asset / set_character_skin)."""
import os, sys
import bpy

MPFB_ZIP = os.environ.get("MPFB_ZIP", "/home/user/mpfb/mpfb-2.0.18.zip")
bpy.ops.extensions.package_install_files(filepath=MPFB_ZIP, repo="user_default", enable_on_install=True)
from bl_ext.user_default.mpfb.services.humanservice import HumanService
from bl_ext.user_default.mpfb.services.targetservice import TargetService


def make(out, sliders):
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o, do_unlink=True)
    macros = TargetService.get_default_macro_info_dict()
    macros.update(sliders)
    body = HumanService.create_human(macro_detail_dict=macros)
    HumanService.add_builtin_rig(body, "game_engine")
    bpy.ops.export_scene.gltf(filepath=out, export_format="GLB")
    dg = bpy.context.evaluated_depsgraph_get()
    me = body.evaluated_get(dg).to_mesh()
    zs = [(body.matrix_world @ v.co).z for v in me.vertices]
    print("MADE %s height %.2f m, %d faces" % (out, max(zs) - min(zs), len(me.polygons)))


if __name__ == "__main__":
    out = sys.argv[1]
    sliders = {k: float(v) for k, v in (a.split("=") for a in sys.argv[2:])}
    make(out, sliders)
