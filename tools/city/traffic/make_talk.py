"""The words people say, carried over from the old game (a tool, run by hand; nothing of it runs in the game).

  python -I tools/city/traffic/make_talk.py <the old game's project folder>

Reads the old game's talk data (map_dc/coronado/npc/talk/data/topics.json, groups.json) and writes
  map_dc/coronado/city_kit/traffic/talk.json   the lines the C++ class CityTalk uses (English + the Turkish helper)
  audio/npc/f, audio/npc/m                     the recorded clips those lines need, and no others
It writes no line of its own: every sentence is the old game's. Left out: lines about places the new map does not have
(the hotel, the ferry, the theatre, dogs), the name / home-town topic the old game had already dropped, and the 92
situations and 14 shop talks the old game never used.
"""
import hashlib, io, itertools, json, os, re, shutil, sys

OLD = sys.argv[1] if len(sys.argv) > 1 else ''
SRC = os.path.join(OLD, 'map_dc', 'coronado', 'npc', 'talk', 'data')
OUT = 'map_dc/coronado/city_kit/traffic/talk.json'
if not os.path.isfile(os.path.join(SRC, 'topics.json')):
    print('TALK ERROR give the old game\'s project folder'); sys.exit(1)

T = json.load(io.open(os.path.join(SRC, 'topics.json'), encoding='utf-8'))
G = json.load(io.open(os.path.join(SRC, 'groups.json'), encoding='utf-8'))

# which of the old conversations fit which kind of street here (ped_crowd.h: 0 quiet, 1 ordinary, 2 busy, 3 the
# promenade, 4 a main road); chosen by hand, line by line
ZONES = {
    'cv_beach_1': [3], 'cv_beach_2': [3], 'cv_beach_3': [3], 'cv_beach_4': [3], 'cv_jet': [0, 3],
    'cv_vil_1': [1, 2, 4], 'cv_vil_2': [2], 'cv_vil_3': [1, 2, 4], 'cv_vil_5': [1, 2], 'cv_ferry_3': [2],
    'cv_park_2': [0], 'cv_res_1': [0, 1], 'cv_res_2': [0, 3, 4],
    'cv_navy_1': [0, 1, 2, 3, 4], 'cv_navy_2': [0, 1, 2, 3, 4], 'cv_navy_3': [0, 1, 2, 3, 4],
    'cv_any_1': [0, 1, 2, 3, 4], 'cv_any_2': [0, 1, 2, 3, 4], 'cv_any_3': [0, 1, 2, 3, 4],
}
KINDS = {'couple': 1, 'friends': 2, 'family': 3, 'sailors': 4}

topics = {k: {kk: vv for kk, vv in T['topics'][k].items() if kk != '_doc'} for k in ['T1', 'T3', 'T4', 'T4C', 'T5', 'T5D', 'T6', 'T7']}
for k in ['say_hotel', 'say_ferry']: topics['T3'].pop(k, None)
for k in ['ferry', 'hotel', 'dog', 'work']: topics['T6'].pop(k, None)
three = {k: v for k, v in T['three'].items() if k != '_doc'}
convs = []
for c in G['conversations']:
    if c['id'] not in ZONES: continue
    convs.append({'id': c['id'], 'zones': ZONES[c['id']], 'kinds': [KINDS[k] for k in c.get('kinds', [])], 'lines': c['lines']})
data = {
    '_doc': 'Written by tools/city/traffic/make_talk.py from the old game\'s talk data: do not edit by hand.',
    'speaker': {'en': 'Passer-by', 'tr': 'Yoldan geçen'},
    'system': T['system'], 'reject': T['reject'], 'busy': T['busy'], 'cut': T['cut'],
    'private': [{'en': x['en'], 'tr': x['tr']} for x in G['private_refusals']],
    'group_reject': [{'en': x['en'], 'tr': x['tr']} for x in G['group_rejections']],
    'topics': topics, 'three': three, 'weekdays': T['weekdays'], 'conversations': convs,
}
io.open(OUT, 'w', encoding='utf-8', newline='').write(json.dumps(data, ensure_ascii=False, indent=1) + '\n')

# ---- the clips: every sentence these lines can come to, cut the way CityTalk cuts them
def slug(en):
    o = ''.join(ch if ('a' <= ch <= 'z' or '0' <= ch <= '9') else ' ' for ch in en.lower())
    s = '_'.join(o.split())
    if len(s) > 120: s = s[:48].rstrip('_') + '_' + hashlib.md5(s.encode('utf-8')).hexdigest()[:8]
    return s

DIRS = [v['en'] for v in T['topics']['T3']['dir'].values()] + [v[0] for v in T['three']['dir_go'].values()]
CLOSED = {'dir': DIRS, 'n': [str(i) for i in range(1, 91)], 'h': [str(i) for i in range(1, 13)], 'h1': [str(i) for i in range(1, 13)],
          'weekday': [w['en'] for w in T['weekdays']], 'hour': [str(i) for i in range(1, 13)]}
OPEN = re.compile(r'\[(place|npc|city|dog|name)\]')

def segments(tmpl):
    out = set()
    keys = [k for k in CLOSED if '[%s]' % k in tmpl]
    for combo in itertools.product(*[CLOSED[k] for k in keys]):
        s = tmpl
        for k, v in zip(keys, combo): s = s.replace('[%s]' % k, v)
        for sent in re.findall(r'[^.!?]+[.!?]*', s):
            for part in OPEN.split(sent)[::2]:
                part = part.strip().lstrip(',;:').strip()
                if slug(part): out.add(slug(part))
    return out

lines = []
def walk(v):
    if isinstance(v, dict):
        if 'en' in v and isinstance(v['en'], str): lines.append(v['en'])
        for x in v.values(): walk(x)
    elif isinstance(v, list):
        for x in v: walk(x)
walk({k: v for k, v in data.items() if k != '_doc'})
want = set()
whole = 0
for en in lines:
    if '[' in en: want |= segments(en)
    else: want.add(slug(en)); whole += 1
copied = {'f': 0, 'm': 0}; size = 0; missing = {'f': [], 'm': []}
for v in ['f', 'm']:
    dst = os.path.join('audio', 'npc', v)
    os.makedirs(dst, exist_ok=True)
    for old in os.listdir(dst):
        if old.endswith('.ogg') and old[:-4] not in want: os.remove(os.path.join(dst, old))
    for s in sorted(want):
        src = os.path.join(OLD, 'audio', 'npc', v, s + '.ogg')
        if os.path.isfile(src):
            shutil.copyfile(src, os.path.join(dst, s + '.ogg')); copied[v] += 1; size += os.path.getsize(src)
        else: missing[v].append(s)
print('TALK %d lines (%d conversations) -> %s' % (len(lines), len(convs), OUT))
print('TALK clips wanted %d; copied %d in the woman\'s voice, %d in the man\'s, %.1f MB' % (len(want), copied['f'], copied['m'], size / 1048576.0))
for v in ['f', 'm']:
    ms = [m for m in missing[v] if not re.fullmatch(r'(about_|it_s_about_|it_is_|is_)?\d+.*', m)]
    print('TALK no clip (%s): %d, of them not a number of minutes: %s' % (v, len(missing[v]), ', '.join(ms[:40])))
