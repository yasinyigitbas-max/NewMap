"""The main character (Yasin, 25 Nov: "make a model for our main character in mhfb2 ... a muscular male with fade hair and
tattoos"). MakeHuman 2 (MPFB2) headless, its packs unpacked into its data folder (~/.config/blender/<ver>/mpfb/data):
  PYTHONPATH=<bpy dir> python3 -I tools/people/mpfb/make_hero.py characters/mpfb/hero.glb
Body: male, 25-30, muscular, a little heavy, 1.83 m; skin hero_tattooed_skin (hero_skin.py: ken1138_caucasian_male_tattooed_skin, CC0,
 with knotwork sleeves on the forearms; an eagle "love /
hate" on the chest, pieces on the arms, a skull on the thigh, a stubbled scalp - the fade's sides); hair short01 on top;
a plain t-shirt (toigo_basic_tucked_t-shirt) so the arms show, classic jeans, sneakers; eyes, brows, lashes; the "Game engine" skeleton."""
import os, sys
import bpy

bpy.ops.extensions.package_install_files(filepath=os.environ.get("MPFB_ZIP", "/home/user/mpfb/mpfb-2.0.18.zip"), repo="user_default", enable_on_install=True)
from bl_ext.user_default.mpfb.services.humanservice import HumanService
from bl_ext.user_default.mpfb.services.targetservice import TargetService
from bl_ext.user_default.mpfb.services.locationservice import LocationService

D = LocationService.get_user_data()
def P(*a): return os.path.join(D, *a)

def fade_cut(body):
    """A FADE: the hair mesh kept on top, cut away over the ears and round the back - the skin's own stubbled scalp shows
    there (the faded sides). A cut line from the crown: kept where it is within 5.5 cm of the hair's top at the sides,
    sloping down to the forehead in front (the fringe kept)."""
    import bmesh
    hair = next(o for o in bpy.data.objects if o.type == "MESH" and o.name.endswith(".short01"))
    bm = bmesh.new(); bm.from_mesh(hair.data)
    zs = [v.co.z for v in bm.verts]; ys = [v.co.y for v in bm.verts]; xs = [v.co.x for v in bm.verts]
    top, front, back = max(zs), min(ys), max(ys)   # (MakeHuman's base mesh in Blender: z up, -y forward)
    cx = (max(xs) + min(xs)) * 0.5
    cut = []
    for v in bm.verts:
        f = (back - v.co.y) / max(back - front, 1e-4)          # 0 at the back, 1 at the front
        keep_drop = 0.045 + 0.05 * max(0.0, f - 0.55) / 0.45   # (how far under the top it stays: deeper toward the fringe)
        side = abs(v.co.x - cx)
        if top - v.co.z > keep_drop or side > 0.065: cut.append(v)
    bmesh.ops.delete(bm, geom=cut, context="VERTS")
    bm.to_mesh(hair.data); bm.free()
    print("FADE cut %d of %d hair vertices" % (len(cut), len(zs)))

def hide_under_clothes(body, names, gap=0.012):
    """The skin hidden where it lies right under a garment: a muscular body broke through the shirt at the shoulders.
    A body vertex goes when the garment's nearest face is over it (the vertex under that face, not beside its edge - the
    skin just past a sleeve stays) and less than `gap` under it, or out through it. Added to MakeHuman's own way of
    hiding the body under clothes (a vertex group and a mask)."""
    from mathutils.bvhtree import BVHTree
    dg = bpy.context.evaluated_depsgraph_get()
    trees = []
    for o in bpy.data.objects:
        if o.type == "MESH" and any(o.name.endswith("." + n) for n in names):
            me = o.evaluated_get(dg).to_mesh()
            trees.append(BVHTree.FromPolygons([o.matrix_world @ v.co for v in me.vertices], [tuple(p.vertices) for p in me.polygons]))
    saved = [(m, m.show_viewport) for m in body.modifiers]
    for m, _ in saved: m.show_viewport = False
    dg.update()
    bme = body.evaluated_get(dg).to_mesh()
    cos = [body.matrix_world @ v.co for v in bme.vertices]
    for m, v in saved: m.show_viewport = v
    hide = []
    for i, c in enumerate(cos):
        for t in trees:
            loc, n, fi, d = t.find_nearest(c, 0.04)
            if loc is None: continue
            off = c - loc
            along = off.dot(n)
            if (off - n * along).length < 0.004 and along > -gap: hide.append(i); break
    g = body.vertex_groups.new(name="Delete.under_clothes"); g.add(hide, 1.0, "REPLACE")
    m = body.modifiers.new("Hide under clothes", "MASK"); m.vertex_group = g.name; m.invert_vertex_group = True
    print("HIDDEN %d body vertices under %s" % (len(hide), names))

def make(out, sliders, skin, hair, clothes, shoes, shirt=None, brows="eyebrow001", lashes="eyelashes01", fade=True):
    for o in list(bpy.data.objects): bpy.data.objects.remove(o, do_unlink=True)
    macros = TargetService.get_default_macro_info_dict(); macros.update(sliders)
    body = HumanService.create_human(macro_detail_dict=macros)
    HumanService.add_builtin_rig(body, "game_engine")
    HumanService.set_character_skin(P("skins", skin, skin + ".mhmat"), body, skin_type="GAMEENGINE")
    for kind, f in (("Eyes", P("eyes", "low-poly", "low-poly.mhclo")), ("Eyebrows", P("eyebrows", brows, brows + ".mhclo")),
                    ("Eyelashes", P("eyelashes", lashes, lashes + ".mhclo")), ("Hair", P("hair", hair, hair + ".mhclo")),
                    ("Clothes", P("clothes", clothes, clothes + ".mhclo")), ("Clothes", P("clothes", shoes, shoes + ".mhclo"))) + \
                   ((("Clothes", P("clothes", shirt, shirt + ".mhclo")),) if shirt else ()):
        try:
            HumanService.add_mhclo_asset(f, body, asset_type=kind, subdiv_levels=0, material_type="GAMEENGINE")
            print("ADDED", kind, os.path.basename(f))
        except Exception as e:
            print("FAILED", kind, f, repr(e))
    if fade: fade_cut(body)
    hide_under_clothes(body, [clothes, shirt] if shirt else [clothes])
    bpy.ops.export_scene.gltf(filepath=out, export_format="GLB", export_apply=True)
    tris = 0
    dg = bpy.context.evaluated_depsgraph_get()
    for o in bpy.data.objects:
        if o.type == "MESH" and o.visible_get():
            me = o.evaluated_get(dg).to_mesh(); me.calc_loop_triangles(); tris += len(me.loop_triangles); print("  mesh", o.name, len(me.loop_triangles))
    print("MADE %s, %d triangles" % (out, tris))

if __name__ == "__main__":
    make(sys.argv[1], dict(gender=1.0, age=0.45, muscle=1.0, weight=0.68, height=0.62, proportions=0.9),
         skin="hero_tattooed_skin", hair="short01", clothes="punkduck_male_classic_jeans", shoes="culturalibre_sneakers", shirt="toigo_basic_tucked_t-shirt")
