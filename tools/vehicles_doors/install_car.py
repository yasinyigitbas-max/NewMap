"""install_car.py <game_dir> <id> [<lod_id> ...]: a car built by zh_build.py (+ zh_post.py, cut_doors.py, cabin_cube.py)
into the game's files, through Godot (mesh_pack.gd). Writes, in vehicles/models/:
  lod/<id>_q_body.res        the body with its cabin (metas: wheels, vtex)          - traffic near, CityCar
  lod/<id>_q.res             body and wheels in one mesh                            - traffic light tier
  lod/<id>_q_w0..3.res       the wheels, each about its hub
  lod/<id>_q_body_cut.res    the body with the door openings (metas: + doors, cabin) - CityCar with real doors
  lod/<id>_q_door_l/r.res    the doors, each in its hinge frame
  cartex/<id>_veh_albedo / _normal / _orm.png, cartex/<id>_cabin.png
More lod ids after the first get copies of the meshes (stern_g drives the volt_x model; the maps stay volt_x's)."""
import sys, os, json, shutil, subprocess, tempfile
import numpy as np
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import meshio
ROOT = os.path.abspath(os.path.join(HERE, '..', '..'))
GODOT = os.environ.get('GODOT', '/opt/godot/Godot_v4.7.2-stable_linux.x86_64')
G, ID = sys.argv[1], sys.argv[2]
ALSO = sys.argv[3:]
info = json.load(open(os.path.join(G, ID + '_info.json')))
LOD = os.path.join(ROOT, 'vehicles/models/lod')
CTX = os.path.join(ROOT, 'vehicles/models/cartex')
# a throw-away Godot project to run mesh_pack.gd in
P = tempfile.mkdtemp()
open(os.path.join(P, 'project.godot'), 'w').write('config_version=5\n[application]\nconfig/name="pack"\n')
shutil.copy(os.path.join(HERE, 'mesh_pack.gd'), P)
os.makedirs(os.path.join(P, 'o'))
meta = {'vtex': True, 'wheels': info['wheels']}
mp = os.path.join(G, ID + '_meta.json')
json.dump(meta, open(mp, 'w'))


def pack(src, name, extra=()):
    r = subprocess.run([GODOT, '--headless', '--path', P, '-s', 'mesh_pack.gd', '--', src, 'res://o/' + name + '.res', *extra, '--tangents'],
                       capture_output=True, text=True, timeout=240)
    line = [l for l in r.stdout.split('\n') if 'PACKED' in l]
    if not line:
        raise SystemExit('pack failed: %s\n%s' % (name, r.stdout[-800:] + r.stderr[-800:]))
    print(line[0][:140])


# body + wheels merged (the light tier): wheels moved to their hubs
j, B, I = meshio.read(os.path.join(G, ID + '_body'))
rows = [B]
for k, w in enumerate(info['wheels']):
    _, W, _ = meshio.read(os.path.join(G, '%s_w%d' % (ID, k)))
    W = W.copy(); W[:, 0:3] += np.array(w['center'], np.float32)
    rows.append(W)
Q = np.concatenate(rows)
meshio.write(os.path.join(G, ID + '_q'), Q, np.arange(len(Q)), {'metas': {}, 'format': 0})
pack(os.path.join(G, ID + '_body'), ID + '_q_body', ['--meta=' + mp])
pack(os.path.join(G, ID + '_q'), ID + '_q', ['--meta=' + mp])
for k in range(len(info['wheels'])):
    pack(os.path.join(G, '%s_w%d' % (ID, k)), '%s_q_w%d' % (ID, k))
cut = os.path.join(G, 'cut')
if os.path.exists(os.path.join(cut, ID + '_doors.json')):
    pack(os.path.join(cut, ID + '_body'), ID + '_q_body_cut', [os.path.join(cut, ID + '_doors.json'), '--meta=' + mp])
    pack(os.path.join(cut, ID + '_door_l'), ID + '_q_door_l')
    pack(os.path.join(cut, ID + '_door_r'), ID + '_q_door_r')
for lid in [ID] + ALSO:
    for f in os.listdir(os.path.join(P, 'o')):
        shutil.copy(os.path.join(P, 'o', f), os.path.join(LOD, f.replace(ID + '_', lid + '_', 1)))
for k in ('albedo', 'normal', 'orm'):
    shutil.copy(os.path.join(G, 'tex', '%s_veh_%s.png' % (ID, k)), os.path.join(CTX, '%s_veh_%s.png' % (ID, k)))
if os.path.exists(os.path.join(cut, ID + '_cabin.png')):
    shutil.copy(os.path.join(cut, ID + '_cabin.png'), os.path.join(CTX, ID + '_cabin.png'))
shutil.rmtree(P)
print('INSTALLED', ID, ALSO)
