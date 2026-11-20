"""Point every kiosk glb at the shared kiosk page (external PNGs, ../tex/) with ONE material:
near = colour + normal + ORM (occlusion = ORM, AO in R); mid/far = colour only. Names fixed."""
import sys, os, glob
import pygltflib as G
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TEX = 'kiosks_%s.png'
def fix(path):
    g = G.GLTF2().load(path)
    tier = path.rsplit('_', 1)[1][:-4]
    if tier == 'col':
        g.materials = []
        for me in g.meshes:
            me.name = 'col'
            for p in me.primitives:
                p.material = None
                for att in ('NORMAL', 'TANGENT', 'TEXCOORD_0'): setattr(p.attributes, att, None)
        for n in g.nodes: n.name = 'col'
        g.save(path); return
    full = tier == 'near'
    g.samplers = [G.Sampler(magFilter=9729, minFilter=9987, wrapS=33071, wrapT=33071)]
    g.images = [G.Image(uri=TEX % 'color')]
    g.textures = [G.Texture(source=0, sampler=0)]
    if full:
        g.images += [G.Image(uri=TEX % 'normal'), G.Image(uri=TEX % 'orm')]
        g.textures += [G.Texture(source=1, sampler=0), G.Texture(source=2, sampler=0)]
        mat = G.Material(name='kiosks', alphaMode='OPAQUE', doubleSided=False,
                         pbrMetallicRoughness=G.PbrMetallicRoughness(baseColorTexture=G.TextureInfo(index=0), metallicRoughnessTexture=G.TextureInfo(index=2),
                                                                     metallicFactor=1.0, roughnessFactor=1.0),
                         normalTexture=G.NormalMaterialTexture(index=1, scale=1.0), occlusionTexture=G.OcclusionTextureInfo(index=2, strength=1.0))
    else:
        mat = G.Material(name='kiosks_lod', alphaMode='OPAQUE', doubleSided=False,
                         pbrMetallicRoughness=G.PbrMetallicRoughness(baseColorTexture=G.TextureInfo(index=0), metallicFactor=0.0, roughnessFactor=0.6))
    g.materials = [mat]
    for me in g.meshes:
        for p in me.primitives: p.material = 0
    for n in g.nodes:
        if n.mesh is not None:
            n.name = os.path.basename(path)[:-4]; g.meshes[n.mesh].name = n.name
    g.save(path)
for f in sorted(glob.glob(ROOT+'/glb/*.glb')): fix(f)
print('fixed', len(glob.glob(ROOT+'/glb/*.glb')))
