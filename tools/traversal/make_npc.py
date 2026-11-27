# The NPC recipe on Meshy (Yasin, 27 Nov: "can we make the new models from there so they will be a standard?").
# No key is in this file: the cloud proxy puts it on requests to api.meshy.ai.
# usage: python3 -I tools/traversal/make_npc.py <name> <height m> <description of the person>
import sys, json, base64, time, os, urllib.request, subprocess
name, height, who = sys.argv[1], float(sys.argv[2]), sys.argv[3]
REPO = '/home/user/NewMap'
out = f'{REPO}/assets/people/meshy/{name}'
os.makedirs(out, exist_ok=True)
API = 'https://api.meshy.ai/openapi/v1/'
def call(path, body=None):
    cmd = ['curl', '-s', '-m', '180', '-H', 'Authorization: Bearer dummy']
    if body is not None:
        open(f'{out}/_req.json', 'w').write(json.dumps(body))
        cmd += ['-H', 'Content-Type: application/json', '-d', f'@{out}/_req.json']
    r = subprocess.run(cmd + [API + path], capture_output=True, text=True).stdout
    return json.loads(r)
def wait(path, tid):
    while True:
        time.sleep(6)
        try:
            d = call(f'{path}/{tid}')
        except Exception as e:
            continue
        if d.get('status') in ('SUCCEEDED', 'FAILED', 'CANCELED'):
            print(name, path, d['status'], d.get('task_error'), d.get('consumed_credits'), flush=True)
            if d['status'] != 'SUCCEEDED': sys.exit(1)
            return d
def get(url, to):
    subprocess.run(['curl', '-s', '-m', '300', '-o', to, url], check=True)
img = base64.b64encode(open(f'{REPO}/assets/people/meshy/player_v4/concept.png', 'rb').read()).decode()
prompt = ("Redraw this picture as a full-body character reference of a DIFFERENT person, front view, on the same plain grey background. "
  "Keep exactly the same pose, the same framing and the same lighting, the head at the same place at the top of the frame and the feet at the same place at the bottom. "
  + who +
  " The person stands upright in a T-pose, the arms raised higher than in the picture: fully horizontal at shoulder height, so that both arms form one straight horizontal line from hand to hand, with a wide clear gap of background visible between each arm and the body and under each armpit, palms down, fingers apart, feet shoulder-width apart, legs straight and apart so that the legs do not touch, whole body from head to feet in frame.")
# (arms held lower fused the sleeve with the side of the shirt on the first woman, 27 Nov: the shirt stretched out behind her arm when she ran)
tasks = {}
t = call('image-to-image', {"ai_model": "nano-banana-2", "prompt": prompt, "reference_image_urls": ["data:image/png;base64," + img]})['result']
d = wait('image-to-image', t)
get(d['image_urls'][0], f'{out}/concept.png')
tasks['i2i.json'] = {k: d.get(k) for k in ['id', 'type', 'status', 'created_at', 'consumed_credits', 'ai_model', 'prompt']}
tasks['i2i.json']['reference'] = 'assets/people/meshy/player_v4/concept.png'
req3 = {"ai_model": "latest", "pose_mode": "t-pose", "should_remesh": True, "topology": "triangle", "target_polycount": 5000, "should_texture": True, "target_formats": ["glb"]}
t3 = call('image-to-3d', dict(req3, input_task_id=t))['result']
d = wait('image-to-3d', t3)
get(d['model_urls']['glb'], f'{out}/image3d.glb'); get(d['thumbnail_url'], f'{out}/thumb.png')
tasks['i3d.json'] = {k: d.get(k) for k in ['id', 'type', 'status', 'created_at', 'consumed_credits']}; tasks['i3d.json']['request'] = req3
reqr = {"height_meters": height, "skeleton_template": "mixamo", "include_fingers": True}
tr = call('rigging', dict(reqr, input_task_id=t3))['result']
d = wait('rigging', tr)
get(d['result']['rigged_character_glb_url'], f'{out}/rigged_meshy_mixamo.glb')
tasks['rig.json'] = {k: d.get(k) for k in ['id', 'type', 'status', 'created_at', 'consumed_credits']}; tasks['rig.json']['request'] = reqr
json.dump(tasks, open(f'{out}/tasks.json', 'w'), indent=1)
os.remove(f'{out}/_req.json'); open(f'{out}/.gdignore', 'w').close()
print(name, 'done', flush=True)
