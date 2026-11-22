import os as _os
def _w(p):      # (hard links into other trees: delete, then write)
    if _os.path.exists(p): _os.remove(p)
    return open(p, 'w')

"""furniture_sets.json for every INDOORS kind (dress_as) from kinds.py (22 Nov 2026 rollout). Each kit prop is sorted
into a slot type by its manifest (mount, footprint, height) and name; a missing prop takes its stand-in (MISSING).
Slot types: counter, till (on a counter), back (behind the counter), shelf (wall stock), island (floor stock <= 1.7 x
1.0 m), big (larger floor stock), table, seat (at a table), waiting, desk, staff (the desk's user), visitor, row (rows
facing the front), front (altar / lectern / bench at the front), station (chair at a wall station), decor (wall art),
top (table-top decor), plant, bin, queue. archetype picks the layout family (layouts.py)."""
import json, glob, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from kinds import SHOPS, X, MISSING
REPO = '/workspace/NewMap'; P = REPO + '/assets/coronado_kit/props/'
man = {}
for m in glob.glob(P + 'manifest_*.json'):
    for k, v in json.load(open(m)).items(): man[k] = v
for k, d in [('vending_snack', (0.9, 0.8, 1.8)), ('vending_soda', (0.9, 0.8, 1.8)), ('ice_chest', (1.2, 0.7, 1.0))]:
    man.setdefault(k, dict(mount='ground', footprint_w=d[0], footprint_d=d[1], height=d[2], tiers={'near': 900}))
K = dict(SHOPS); K.update(X)
COUNTER = {'shop_counter', 'checkout_counter', 'bar_counter', 'laundry_counter', 'security_grille_counter', 'ticket_booth', 'bulletproof_teller_window', 'dispensary_counter_partition'}
SEAT = {'cafe_chair', 'dining_chair', 'bar_stool', 'side_chair', 'lounge_chair', 'high_chair', 'office_chair'}
WAIT = {'waiting_bench', 'sofa_3seat', 'side_chair', 'lounge_chair'}
BOOTH = {'booth_bench'}
TABLE = {'cafe_table', 'restaurant_table', 'dining_table', 'coffee_table', 'folding_table_chairs', 'side_table'}
ROWP = {'church_pew', 'lecture_seating_row', 'court_bench', 'theatre_seat', 'tablet_arm_chair', 'jury_box'}
FRONT = {'altar_table', 'lectern', 'judge_bench', 'witness_box', 'stage_platform'}
BOARD = {'whiteboard_wall', 'projector_screen', 'noticeboard_wall', 'directory_board', 'listing_board_wall', 'departure_board'}
ISLAND = {'gondola_aisle', 'mannequin', 'card_spinner', 'postcard_rack', 'display_plinth', 'bike_stand', 'surfboard_rack'}
STATION = {'barber_chair', 'nail_table', 'pedicure_chair', 'hood_dryer_chair', 'tattoo_bed_chair', 'dental_chair', 'exam_bed', 'physio_table', 'wash_basin'}
MACHINE = {'washer', 'dryer'}
DECOR_PFX = ('frame_', 'mirror_round', 'mirror_rect', 'clock_wall', 'wall_plate', 'neon_wall_sign', 'dartboard', 'gallery_frame', 'security_mirror', 'barber_pole', 'flash_art_wall')
def stand(x):
    if x in man: return x
    if x in MISSING:
        s = MISSING[x][3].split(' ')[0].strip(',')
        return s if s in man else None
    return None
def size(x): v = man[x]; return float(v.get('footprint_w', 1)), float(v.get('footprint_d', 1)), float(v.get('height', 1))
ROWSHELF = {'library': {'bookcase'}, 'books': {'bookcase'}, 'records': {'bookcase'}}
KIND = ''
def kind_of(x, core):
    if x in ROWSHELF.get(KIND, ()): return 'island'
    v = man[x]; w, d, h = size(x)
    if x in COUNTER: return 'counter'
    if x == 'cash_register': return 'till'
    if x == 'potted_plant': return 'plant'
    if x == 'indoor_bin': return 'bin'
    if x == 'stanchion': return 'queue'
    if x == 'office_desk': return 'desk'
    if x in MACHINE: return 'shelf'
    if x in ISLAND: return 'island'
    if v.get('mount') == 'wall': return 'decor' if x.startswith(DECOR_PFX) else 'shelf'
    if h < 0.5 and w < 0.6: return 'top'
    if x in TABLE: return 'table'
    if x in BOOTH: return 'booth'
    if x in SEAT: return 'seat'
    if x in WAIT: return 'waiting'
    if d <= 0.55 and h >= 1.2: return 'shelf'
    if x in ('drinks_fridge', 'chest_freezer', 'vending_snack', 'vending_soda', 'change_machine', 'mirror_station', 'kitchen_line', 'wine_backbar', 'storage_cabinet', 'filing_cabinet', 'credenza', 'sideboard', 'tv_console', 'pallet_racking', 'tire_rack', 'lumber_rack', 'garment_conveyor', 'fitting_room', 'workbench', 'workbench_garage', 'tool_chest'):
        return 'shelf'
    if w <= 1.7 and d <= 1.0: return 'island'
    return 'big'
def archetype(k, names):
    s = set(names)
    if s & ROWP: return 'rows'
    if s & STATION and k not in ('gym', 'rec_center'): return 'stations'
    if s & MACHINE and k in ('laundromat', 'laundry', 'cleaners', 'uniform'): return 'machines'
    if 'office_desk' in s and not (s & COUNTER - {'shop_counter'}) and k not in ('cash', 'print', 'library'): return 'office'
    if s & TABLE and (s & SEAT or s & BOOTH) and k not in ('library', 'community', 'hall', 'books'): return 'seating'
    if 'gondola_aisle' in s: return 'aisles'
    return 'retail'
sets = {}
for k, (core, stock, decor, miss, note) in sorted(K.items()):
    KIND = k
    raw = [x.split(' ')[0] for x in core + stock + decor if not x.startswith('rug_')]
    names = []; subs = {}
    for x in raw + [x.split(' ')[0] for x in miss if x.split(' ')[0] in FRONT | ROWP | STATION | BOARD]:
        if x in ROWP: t = 'row'
        elif x in FRONT: t = 'front'
        elif x in BOARD: t = 'board'
        elif x in STATION and x != 'wash_basin': t = 'station'
        else: t = None
        s = stand(x)
        if s is None: continue
        if s != x: subs[x] = s
        if s not in names or t: names.append((s, t) if t else s)
    st = {}
    for n in names:
        if isinstance(n, tuple): s, t = n
        else: s = n; t = kind_of(s, core)
        if t in ('shelf', 'island', 'big') and s in [stand(c.split(' ')[0]) for c in core] and s not in ('filing_cabinet', 'gondola_aisle', 'glass_display_case'): t = 'back'
        st.setdefault(t, [])
        if s not in st[t]: st[t].append(s)
    if 'desk' in st:
        st['staff'] = ['office_chair']
        st['visitor'] = [x for x in st.get('seat', []) + st.get('waiting', []) if x in ('side_chair', 'dining_chair')][:1] or ['side_chair']
        st.get('seat', []) and st['seat'].remove('office_chair') if 'office_chair' in st.get('seat', []) else None
        if not st.get('seat'): st.pop('seat', None)
    if 'station' in st and 'seat' not in st: pass
    if 'table' in st and 'seat' not in st and 'booth' not in st and 'folding_table_chairs' not in st['table']: st['seat'] = ['cafe_chair']
    if 'counter' not in st and 'desk' not in st and 'front' not in st: st['counter'] = ['shop_counter']
    arch = archetype(k, raw + [x.split(' ')[0] for x in miss])
    req = [t for t in ('counter', 'desk', 'front', 'row', 'station', 'table') if t in st]
    st = {t: v for t, v in st.items() if v}
    sets[k] = dict(st, archetype=arch, required=req, desk_users=['office_chair'], stand_ins=subs, note=note)
old = json.load(open(REPO + '/map_dc/coronado/city_kit/interiors/builtin/furniture_sets.json'))
# (22 Nov: the pilot's hand-made bank lists are retired with its hand-placed slots: bank is generated like every kind;
#  it keeps the office layout family - teller counter in front, officer desks behind)
sets['bank']['archetype'] = 'office'
doc = ('Per INDOORS kind: which kit prop fills each slot type of the bay templates (no fallback filler).' +
       ' 22 Nov rollout: one set per INDOORS kind (dress_as), generated by tools/city/rooms/builtin/indoors/make_sets.py from kinds.py; a missing prop is its MISSING stand-in (stand_ins). archetype = layout family (layouts.py).')
json.dump({'_doc': doc, 'sets': sets}, _w(REPO + '/map_dc/coronado/city_kit/interiors/builtin/furniture_sets.json'), indent=1)
import collections
print(len(sets), collections.Counter(v['archetype'] for v in sets.values()))
for k in ('cafe', 'grocery', 'church', 'office', 'salon', 'laundromat', 'court', 'clothes', 'bank', 'lecture'): print(k, {t: v for t, v in sets[k].items() if t not in ('note', 'desk_users')})
