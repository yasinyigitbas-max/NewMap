"""Superchecker, indoors (19 Nov 2026): the rooms of one piece, or one room.

It measures and lists; it changes nothing. Two layers:
  1. the indoor checker that exists (interiors/rooms/check_rooms.gd: overlap, floating, wall, door, reach, hidden,
     window, wallover, ceiling, behind, deco, repeat, lone, face, seat, outseat, binshop, bare, sparse, pot, unheld,
     doorway, stack, offwall, squeeze) is run on the room and its lines are taken over as they are. Its NOTE lines
     for locked rooms are COUNTED here (it prints them and leaves them out of its total).
  2. new checks from the room's own numbers (sc_dump.gd): what a customer meets, in Yasin's order - the doors and
     windows first, then every prop against them, then whether the shop works:
       entry_blocked / door_blocked   a floor prop in the first 1.5 m inside the entrance / in front of another door
       window_blocked                 something tall right behind a window
       no_counter / counter_hidden    no service point, or none in view from the door
       queue_blocked / counter_faces_wall   no room to stand in front of a counter; a counter turned to a wall
       till_backwards / till_alone    a till or coffee machine turned with its staff side to the customer; on no counter
       faces_wall                     a fridge, shelf, washer or mirror turned to a wall (its front is not reachable)
       table_no_seat / bar_no_stool / mirror_no_chair
       shop_lacks / shop_odd          what that kind of shop needs / what does not belong (a DRAFT list, by eye too)
       no_light / many_lights / low_light / light_in_prop
       same_layout                    another room with the same things in the same places
       room_outside                   the room's floor reaches outside its building's footprint
       thin_wall / shows_through      (Yasin 19 Nov: "many walls indoors are very thin and the next shops props can show
                                      on the other side") the wall between two shops of one building, measured from
                                      both rooms' own built faces, is thinner than 10 cm; a prop reaches through it
                                      into the next shop
Fix lines are the fixer's own kinds (move / remove), in the ROOM's frame.

  python -I tools/city/super/sc_rooms.py <room name> | --piece=<piece>
"""
import json, math, os, sys
import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import sc_lib as L
import sc_more

CUSTOMER_FRONT = ('prop_shop_counter', 'prop_bar_counter', 'prop_pastry_case', 'prop_gelato_case', 'prop_glass_display_case')     # customer side = +Z
STAFF_FRONT = ('prop_checkout_counter', 'prop_laundry_counter')                                                                   # staff side = +Z
SERVICE = CUSTOMER_FRONT + STAFF_FRONT + ('prop_office_desk', 'prop_nail_table', 'prop_kitchen_line')
ON_COUNTER = ('prop_cash_register', 'prop_espresso_machine', 'prop_beer_taps')
FRONTED = ('prop_drinks_fridge', 'prop_bakery_shelf', 'prop_bookcase', 'prop_grocery_shelf', 'prop_pharmacy_shelf', 'prop_wall_shelf', 'prop_pegboard_wall', 'prop_shoe_wall',
           'prop_salon_product_shelf', 'prop_cigarette_cabinet', 'prop_vending_', 'prop_washer', 'prop_dryer', 'prop_wine_backbar', 'prop_mirror_station', 'prop_brochure_rack')
SEATS = ('prop_cafe_chair', 'prop_side_chair', 'prop_booth_bench', 'prop_bar_stool', 'prop_office_chair', 'prop_waiting_bench', 'prop_shoe_bench')
FLAT = ('prop_rug', 'prop_mat')
# what a shop of a kind needs (any ONE of each group) and what does not belong. A DRAFT by the 19 Nov PC session
# (the skill's "What a shop needs"); Yasin has not approved it: its findings are "look", never changed by the tool.
FOOD = ('cafe', 'coffee', 'bakery', 'panaderia', 'ice_cream', 'fast_food', 'takeout', 'diner', 'restaurant', 'taqueria', 'pizza', 'canteen', 'drive_thru', 'fish_counter')
NEEDS = {
    'cafe': [('prop_shop_counter', 'prop_pastry_case', 'prop_bar_counter'), ('prop_cafe_table', 'prop_restaurant_table'), ('prop_cafe_chair', 'prop_side_chair', 'prop_booth_bench'), ('prop_menu_board',), ('prop_indoor_bin',)],
    'coffee': [('prop_shop_counter', 'prop_pastry_case', 'prop_bar_counter'), ('prop_espresso_machine',), ('prop_cafe_table',), ('prop_menu_board',)],
    'bakery': [('prop_pastry_case', 'prop_bakery_shelf'), ('prop_shop_counter', 'prop_checkout_counter'), ('prop_cash_register',)],
    'panaderia': [('prop_pastry_case', 'prop_bakery_shelf'), ('prop_shop_counter', 'prop_checkout_counter'), ('prop_cash_register',)],
    'ice_cream': [('prop_gelato_case', 'prop_chest_freezer', 'prop_pastry_case'), ('prop_shop_counter', 'prop_checkout_counter'), ('prop_menu_board',)],
    'fast_food': [('prop_shop_counter', 'prop_checkout_counter'), ('prop_menu_board',), ('prop_booth_bench', 'prop_cafe_table', 'prop_restaurant_table'), ('prop_kitchen_line',), ('prop_indoor_bin',)],
    'takeout': [('prop_shop_counter', 'prop_checkout_counter'), ('prop_menu_board',), ('prop_kitchen_line',)],
    'diner': [('prop_shop_counter', 'prop_bar_counter'), ('prop_booth_bench', 'prop_restaurant_table'), ('prop_menu_board',), ('prop_kitchen_line',)],
    'restaurant': [('prop_restaurant_table', 'prop_cafe_table'), ('prop_side_chair', 'prop_cafe_chair', 'prop_booth_bench'), ('prop_shop_counter', 'prop_bar_counter', 'prop_checkout_counter')],
    'taqueria': [('prop_shop_counter', 'prop_checkout_counter'), ('prop_menu_board',), ('prop_restaurant_table', 'prop_cafe_table', 'prop_booth_bench')],
    'pizza': [('prop_shop_counter', 'prop_checkout_counter'), ('prop_menu_board',), ('prop_kitchen_line',)],
    'bar': [('prop_bar_counter',), ('prop_bar_stool',), ('prop_wine_backbar', 'prop_beer_taps', 'prop_drinks_fridge'), ('prop_cafe_table', 'prop_restaurant_table', 'prop_booth_bench')],
    'taproom': [('prop_bar_counter',), ('prop_bar_stool',), ('prop_beer_taps', 'prop_wine_backbar')],
    'grocery': [('prop_checkout_counter', 'prop_shop_counter'), ('prop_cash_register',), ('prop_grocery_shelf', 'prop_gondola_aisle'), ('prop_drinks_fridge', 'prop_chest_freezer'), ('prop_produce_stand',)],
    'corner_shop': [('prop_checkout_counter', 'prop_shop_counter'), ('prop_cash_register',), ('prop_grocery_shelf', 'prop_gondola_aisle'), ('prop_drinks_fridge',)],
    'bodega': [('prop_checkout_counter', 'prop_shop_counter'), ('prop_cash_register',), ('prop_grocery_shelf', 'prop_gondola_aisle'), ('prop_drinks_fridge',)],
    'liquor': [('prop_checkout_counter', 'prop_shop_counter'), ('prop_cash_register',), ('prop_drinks_fridge', 'prop_wine_backbar', 'prop_grocery_shelf')],
    'laundry': [('prop_washer',), ('prop_dryer',), ('prop_waiting_bench', 'prop_side_chair'), ('prop_laundry_counter', 'prop_display_table')],
    'laundromat': [('prop_washer',), ('prop_dryer',), ('prop_waiting_bench', 'prop_side_chair'), ('prop_laundry_counter', 'prop_display_table')],
    'cleaners': [('prop_laundry_counter', 'prop_shop_counter'), ('prop_garment_rail', 'prop_clothes_rack'), ('prop_cash_register',)],
    'dry_cleaner': [('prop_laundry_counter', 'prop_shop_counter'), ('prop_garment_rail', 'prop_clothes_rack'), ('prop_cash_register',)],
    'salon': [('prop_mirror_station',), ('prop_barber_chair',), ('prop_waiting_bench', 'prop_side_chair'), ('prop_shop_counter', 'prop_office_desk')],
    'barber': [('prop_mirror_station',), ('prop_barber_chair',), ('prop_waiting_bench', 'prop_side_chair')],
    'nails': [('prop_nail_table',), ('prop_side_chair', 'prop_office_chair'), ('prop_shop_counter', 'prop_office_desk')],
    'pawn': [('prop_glass_display_case',), ('prop_wall_shelf', 'prop_pegboard_wall'), ('prop_cash_register',)],
    'thrift': [('prop_clothes_rack', 'prop_garment_rail'), ('prop_display_table', 'prop_wall_shelf'), ('prop_shop_counter', 'prop_checkout_counter')],
    'books': [('prop_bookcase',), ('prop_shop_counter', 'prop_checkout_counter'), ('prop_display_table',), ('prop_side_chair', 'prop_waiting_bench')],
    'clothes': [('prop_clothes_rack', 'prop_garment_rail'), ('prop_mannequin',), ('prop_shop_counter', 'prop_checkout_counter'), ('prop_fitting_room', 'prop_mirror_station')],
    'shoes': [('prop_shoe_wall',), ('prop_shoe_bench',), ('prop_shop_counter', 'prop_checkout_counter')],
    'pharmacy': [('prop_pharmacy_shelf',), ('prop_shop_counter', 'prop_checkout_counter'), ('prop_cash_register',), ('prop_waiting_bench', 'prop_side_chair')],
    'jewelry': [('prop_glass_display_case',), ('prop_cash_register',)],
    'office': [('prop_office_desk',), ('prop_office_chair',), ('prop_filing_cabinet',), ('prop_waiting_bench', 'prop_side_chair')],
    'tax': [('prop_office_desk',), ('prop_office_chair',), ('prop_filing_cabinet',), ('prop_waiting_bench', 'prop_side_chair')],
    'cash': [('prop_shop_counter', 'prop_checkout_counter'), ('prop_cash_register',), ('prop_waiting_bench', 'prop_side_chair')],
    'bank': [('prop_shop_counter', 'prop_checkout_counter', 'prop_office_desk'), ('prop_waiting_bench', 'prop_side_chair'), ('prop_stanchion', 'prop_brochure_rack')],
    'parts': [('prop_shop_counter', 'prop_checkout_counter'), ('prop_wall_shelf', 'prop_pegboard_wall', 'prop_gondola_aisle'), ('prop_cash_register',), ('prop_waiting_bench', 'prop_side_chair')],
    'auto_parts': [('prop_shop_counter', 'prop_checkout_counter'), ('prop_wall_shelf', 'prop_pegboard_wall', 'prop_gondola_aisle'), ('prop_cash_register',)],
    'tyres': [('prop_shop_counter',), ('prop_waiting_bench', 'prop_side_chair'), ('prop_wall_shelf', 'prop_pegboard_wall')],
    'tyre': [('prop_shop_counter',), ('prop_waiting_bench', 'prop_side_chair'), ('prop_wall_shelf', 'prop_pegboard_wall')],
    'lube': [('prop_shop_counter',), ('prop_waiting_bench', 'prop_side_chair')],
    'gym': [('prop_weight_bench',), ('prop_shop_counter', 'prop_office_desk'), ('prop_mirror_station', 'prop_waiting_bench', 'prop_shoe_bench')],
    'clinic': [('prop_shop_counter', 'prop_office_desk'), ('prop_waiting_bench', 'prop_side_chair'), ('prop_brochure_rack',)],
    'dentist': [('prop_shop_counter', 'prop_office_desk'), ('prop_waiting_bench', 'prop_side_chair')],
    'motel_office': [('prop_shop_counter', 'prop_office_desk'), ('prop_side_chair', 'prop_waiting_bench'), ('prop_brochure_rack',)],
    'sport': [('prop_shop_counter', 'prop_checkout_counter'), ('prop_surfboard_rack', 'prop_bike_stand', 'prop_clothes_rack', 'prop_wall_shelf')],
    'gallery': [('prop_gallery_frame',), ('prop_shop_counter', 'prop_office_desk', 'prop_display_table')],
    'store': [('prop_shop_counter', 'prop_checkout_counter'), ('prop_cash_register',)],
}
ODD = {
    'cafe': ('prop_gondola_aisle', 'prop_grocery_shelf'), 'coffee': ('prop_gondola_aisle', 'prop_grocery_shelf'), 'diner': ('prop_gondola_aisle', 'prop_grocery_shelf', 'prop_clothes_rack'),
    'fast_food': ('prop_gondola_aisle', 'prop_grocery_shelf', 'prop_clothes_rack'), 'restaurant': ('prop_gondola_aisle', 'prop_grocery_shelf', 'prop_vending_'),
    'bar': ('prop_vending_', 'prop_gondola_aisle', 'prop_grocery_shelf'), 'taproom': ('prop_vending_', 'prop_gondola_aisle'),
    'laundry': ('prop_grocery_shelf', 'prop_gondola_aisle', 'prop_clothes_rack'), 'laundromat': ('prop_grocery_shelf', 'prop_gondola_aisle', 'prop_clothes_rack'),
    'books': ('prop_drinks_fridge', 'prop_chest_freezer'), 'office': ('prop_drinks_fridge', 'prop_gondola_aisle', 'prop_grocery_shelf'), 'tax': ('prop_drinks_fridge', 'prop_gondola_aisle'),
    'motel_office': ('prop_vending_',), 'clinic': ('prop_gondola_aisle', 'prop_grocery_shelf', 'prop_clothes_rack'), 'gym': ('prop_gondola_aisle', 'prop_grocery_shelf'),
    'salon': ('prop_gondola_aisle', 'prop_grocery_shelf', 'prop_drinks_fridge'), 'barber': ('prop_gondola_aisle', 'prop_grocery_shelf'),
}


def has(base, names):
    return any(base.startswith(n) for n in names)


def assignments():
    out = {}
    d = os.path.join(L.CK, 'interiors')
    for f in sorted(os.listdir(d)):
        if not (f.startswith('assignment_') and f.endswith('.json')): continue
        try: j = json.load(open(os.path.join(d, f), encoding='utf-8'))
        except Exception: continue
        rooms = j.get('rooms') if isinstance(j, dict) else None
        if not isinstance(rooms, list): continue
        for r in rooms:
            if not isinstance(r, dict) or 'piece' not in r or 'id' not in r: continue
            for cand in (r.get('built') or '', 'g_' + str(r['id']), str(r['id'])):
                if cand and os.path.exists(os.path.join(L.ROOMS, cand + '.scn')): out[cand] = r; break
    return out


def rooms_of_piece(piece):
    return sorted(n for n, r in assignments().items() if r.get('piece') == piece)


class Room:
    def __init__(self, name, dump_dir=None):
        self.name = name; self.dump = L.Dump(name, folder=dump_dir or L.RDUMP)
        m = self.dump.meta
        self.floors = [[float(v) for v in f] for f in (m.get('floors') or [])]
        self.solids = [[float(v) for v in f] for f in (m.get('solids') or [])]
        self.entr = m.get('entrances') or []
        self.open = m.get('openings') or []
        self.shop = m.get('shop') or {}
        self.inst = L.Inst(0, name)
        self.items = L.items_of(self.dump, self.inst, tier='')
        self.cx = float(np.mean([(f[0] + f[2]) / 2 for f in self.floors])) if self.floors else 0.0
        self.cz = float(np.mean([(f[1] + f[3]) / 2 for f in self.floors])) if self.floors else 0.0

    def inside(self, x, z, margin=0.0):
        ok = any(f[0] + margin <= x <= f[2] - margin and f[1] + margin <= z <= f[3] - margin for f in self.floors)
        return ok and not any(s[0] <= x <= s[2] and s[1] <= z <= s[3] for s in self.solids)

    def zone(self, o, deep):
        """the rectangle [4, 2] inside the room in front of an opening / entrance [axis, plane, a0, a1, ...]"""
        ax = o[0]; p = float(o[1]); a0 = float(o[2]); a1 = float(o[3])
        if ax == 'z':
            s = -1.0 if p > self.cz else 1.0
            return np.array([[a0, p], [a1, p], [a1, p + s * deep], [a0, p + s * deep]]), np.array([(a0 + a1) / 2, p + s * 1.0])
        s = -1.0 if p > self.cx else 1.0
        return np.array([[p, a0], [p, a1], [p + s * deep, a1], [p + s * deep, a0]]), np.array([p + s * 1.0, (a0 + a1) / 2])


def seg_hits_quad(a, b, q):
    """the segment a-b crosses the convex quad q"""
    if L.in_quad(q, a) or L.in_quad(q, b): return True
    def cross(p1, p2, p3, p4):
        d1 = p2 - p1; d2 = p4 - p3; den = d1[0] * d2[1] - d1[1] * d2[0]
        if abs(den) < 1e-12: return False
        t = ((p3[0] - p1[0]) * d2[1] - (p3[1] - p1[1]) * d2[0]) / den; u = ((p3[0] - p1[0]) * d1[1] - (p3[1] - p1[1]) * d1[0]) / den
        return 0 <= t <= 1 and 0 <= u <= 1
    return any(cross(np.asarray(a, float), np.asarray(b, float), q[k], q[(k + 1) % 4]) for k in range(4))


class RoomFinder(sc_more.RoomMore):
    def __init__(self, room):
        self.r = room; self.faults = []; self.counts = {}

    def add(self, kind, text, at, item=None, fix=None, mode='report', sure='rule', amount=None):
        f = {'n': len(self.faults) + 1, 'kind': kind, 'text': text, 'at': [round(float(v), 3) for v in at], 'mode': mode, 'sure': sure}
        if amount is not None: f['amount'] = round(float(amount), 3)
        if item is not None: f['item'] = {'base': item.base, 'cond': item.cond, 'batch': item.bpath, 'index': item.idx, 'local': [round(float(v), 5) for v in item.local[9:12]]}
        if fix is not None: f['fix'] = fix
        self.faults.append(f); self.counts[kind] = self.counts.get(kind, 0) + 1

    def fix_move(self, it, turn=0.0, about_centre=False):
        a = it.local[9:12]; to = a.copy()
        if about_centre:      # turned about the middle of its footprint, so it stays where it stands
            c = np.array([it.ctr[0], a[1], it.ctr[1]]); to = 2 * c - a; to[1] = a[1]
        f = {'op': 'move', 'base': it.base, 'cond': it.cond, 'at': [float(v) for v in a], 'to': [float(v) for v in to]}
        if abs(turn) > 1e-6: f['turn'] = float(turn)
        return f

    def floor_items(self):
        return [it for it in self.r.items if it.mount != 'wall' and not has(it.base, FLAT) and it.y0 < 0.3]

    def run(self):
        r = self.r; fl = self.floor_items()
        # ---- doors and windows first
        ent_planes = set((e[0], round(float(e[1]), 2), round(float(e[2]), 2)) for e in r.entr)
        doors = [o for o in r.open if o[-1] == 'door']
        if not r.open: doors = [list(e[:4]) + [0.0, 2.2, 'door'] for e in r.entr]
        for o in doors:
            is_ent = (o[0], round(float(o[1]), 2), round(float(o[2]), 2)) in ent_planes
            z, _ = r.zone(o, 1.5 if is_ent else 1.0)
            for it in fl:
                if L.quad_hit(it.quad, z, 0.98):
                    self.add('entry_blocked' if is_ent else 'door_blocked', '%s stands %s' % (it.base, 'in the first 1.5 m inside the entrance' if is_ent else 'in front of a %.1f m wide door (a back or side door)' % abs(float(o[3]) - float(o[2]))),
                             it.pos, it, mode='choose', fix=self.fix_move(it))
        for o in r.open:
            if o[-1] != 'window': continue
            z, _ = r.zone(o, 0.7)
            for it in fl:
                if it.y1 - it.y0 >= 1.3 and it.y1 > float(o[4]) + 0.6 and L.quad_hit(it.quad, z, 0.98):
                    self.add('window_blocked', '%s (%.1f m tall) stands right behind a window' % (it.base, it.y1 - it.y0), it.pos, it, mode='choose', fix=self.fix_move(it), sure='rule: "nothing tall right behind the glass"')
        # ---- the service point
        serv = [it for it in fl if has(it.base, SERVICE)]
        kind = str(r.shop.get('kind', ''))
        if not serv and kind not in ('gallery', 'laundry', 'laundromat', 'gym', 'venue'):
            self.add('no_counter', 'no counter, desk or till point in this room', (r.cx, 0, r.cz), sure='look')
        if serv and r.entr:
            seen = False
            for e in r.entr:
                _, eye = r.zone(e, 1.0)
                for s in serv:
                    blocked = any(seg_hits_quad(eye, s.ctr, np.array([[q[0], q[1]], [q[2], q[1]], [q[2], q[3]], [q[0], q[3]]])) for q in r.solids)
                    if not blocked:
                        blocked = any(o is not s and (o.y1 - o.y0) >= 1.5 and not has(o.base, SERVICE) and seg_hits_quad(eye, s.ctr, o.quad) for o in fl)
                    if not blocked: seen = True; break
                if seen: break
            if not seen:
                self.add('counter_hidden', 'no counter or desk is in view from the door (a partition or something tall stands between)', serv[0].pos, serv[0], sure='rule: "enter and see the service point"')
        for s in serv:
            if not (has(s.base, CUSTOMER_FRONT) or has(s.base, STAFF_FRONT)): continue
            f = s.front() * (1.0 if has(s.base, CUSTOMER_FRONT) else -1.0)
            ax = s.along(); edge = s.ctr + f * s.half[1]
            zone = np.array([edge - ax * s.half[0], edge + ax * s.half[0], edge + ax * s.half[0] + f * 1.0, edge - ax * s.half[0] + f * 1.0])
            mid = edge + f * 0.5
            if not r.inside(mid[0], mid[1]):
                back = s.ctr - f * (s.half[1] + 0.5)
                self.add('counter_faces_wall', '%s has its customer side to a wall' % s.base, s.pos, s, mode='auto' if r.inside(back[0], back[1]) else 'choose',
                         fix=self.fix_move(s, turn=180.0, about_centre=True) if r.inside(back[0], back[1]) else self.fix_move(s), sure='look: a counter set into a partition may be meant so')
                continue
            for it in fl:
                if it is s or has(it.base, SERVICE) or it.base in ('prop_bar_stool', 'prop_stanchion') or it.base.startswith('prop_potted') and False: continue
                if L.quad_hit(it.quad, zone, 0.95) and L.in_quad(zone, it.ctr):
                    self.add('queue_blocked', '%s stands in the queue space in front of %s' % (it.base, s.base), it.pos, it, mode='choose', fix=self.fix_move(it))
        # ---- tills and machines on counters
        tops = [it for it in r.items if has(it.base, SERVICE) or it.base in ('prop_display_table', 'prop_workbench', 'prop_cafe_table', 'prop_restaurant_table')]
        for it in r.items:
            if not has(it.base, ON_COUNTER): continue
            under = next((s for s in tops if L.in_quad(s.quad, it.ctr)), None)
            if under is None:
                self.add('till_alone', '%s stands on no counter' % it.base, it.pos, it, mode='choose', fix=self.fix_move(it)); continue
            if has(under.base, CUSTOMER_FRONT) or has(under.base, STAFF_FRONT):
                want = -under.front() if has(under.base, CUSTOMER_FRONT) else under.front()      # the staff side of the thing looks at the staff
                dot = float(it.front() @ want)
                if dot < -0.7:
                    self.add('till_backwards', '%s on %s shows its staff side to the customer' % (it.base, under.base), it.pos, it, mode='auto', fix=self.fix_move(it, turn=180.0, about_centre=True))
                elif dot < 0.7:
                    self.add('till_sideways', '%s on %s is turned sideways' % (it.base, under.base), it.pos, it, mode='report', sure='look')
        # ---- things with a front must show it to the room
        for it in fl:
            if not has(it.base, FRONTED): continue
            f = it.front(); p = it.ctr + f * (it.half[1] + 0.45); b = it.ctr - f * (it.half[1] + 0.45)
            if r.inside(p[0], p[1]): continue
            okb = r.inside(b[0], b[1])
            self.add('faces_wall', '%s is turned to a wall: its front cannot be reached' % it.base, it.pos, it, mode='auto' if okb else 'choose',
                     fix=self.fix_move(it, turn=180.0, about_centre=True) if okb else self.fix_move(it))
        # ---- pairs
        def near(it, names, d):
            return any(has(o.base, names) and np.hypot(*(o.ctr - it.ctr)) < d + max(it.half) for o in fl if o is not it)
        for it in fl:
            if it.base in ('prop_cafe_table', 'prop_restaurant_table') and not near(it, ('prop_cafe_chair', 'prop_side_chair', 'prop_booth_bench', 'prop_bar_stool', 'prop_waiting_bench'), 0.9):
                self.add('table_no_seat', '%s has no seat at it' % it.base, it.pos, it, sure='rule')
            if it.base == 'prop_bar_counter' and not near(it, ('prop_bar_stool',), 1.0) and str(r.shop.get('kind', '')) in ('bar', 'taproom', 'diner'):
                self.add('bar_no_stool', 'the bar has no stool at it', it.pos, it, sure='look')
            if it.base == 'prop_mirror_station' and not near(it, ('prop_barber_chair', 'prop_side_chair', 'prop_office_chair'), 1.0):
                self.add('mirror_no_chair', 'a mirror station with no chair in front of it', it.pos, it, sure='rule')
        # ---- does the shop have what that kind of shop needs (DRAFT list)
        bases = set(it.base for it in r.items)
        for grp in NEEDS.get(kind, []):
            if not any(has(b, grp) for b in bases):
                self.add('shop_lacks', 'a %s (%s) has none of: %s' % (kind, r.shop.get('name', ''), ', '.join(g.replace('prop_', '').rstrip('_') for g in grp)), (r.cx, 0, r.cz), sure='look: a draft list of what a shop needs, not approved by Yasin')
        for it in r.items:
            if has(it.base, ODD.get(kind, ())):
                self.add('shop_odd', '%s does not belong in a %s' % (it.base.replace('prop_', ''), kind), it.pos, it, sure='look: a draft list, not approved by Yasin')
        if kind and kind not in NEEDS: self.add('shop_kind_unlisted', 'no list of needs for a "%s": by eye' % kind, (r.cx, 0, r.cz), sure='look')
        # ---- lights
        lights = r.dump.j.get('lights', [])
        if not lights: self.add('no_light', 'the room has no light', (r.cx, 2.5, r.cz))
        if len(lights) > 6: self.add('many_lights', '%d lights (the budget is 4-6 a room)' % len(lights), (r.cx, 2.5, r.cz), amount=len(lights))
        for l in lights:
            p = np.array(l['xf'][9:12])
            if p[1] < 1.85 and r.inside(p[0], p[2]) and not any(L.in_quad(o.quad, p[[0, 2]]) for o in r.items):
                self.add('low_light', 'a light hangs %.2f m over walkable floor' % p[1], p, amount=p[1], sure='look: the light itself has no model, its fitting may be higher')
            for o in r.items:
                if o.y0 < p[1] < o.y1 - 0.02 and L.in_quad(o.quad, p[[0, 2]]) and o.mount != 'wall':
                    self.add('light_in_prop', 'a light sits inside %s' % o.base, p, o); break
        # ---- the room against its building
        a = assignments().get(r.name)
        if a:
            st = L.Kit.stats(str(a.get('model', '')))
            fw = st.get('footprint_wd')
            if fw:
                for f in r.floors:
                    over = max(-fw[0] / 2 - f[0], f[2] - fw[0] / 2, -fw[1] / 2 - f[1], f[3] - fw[1] / 2)
                    if over > 0.05: self.add('room_outside', 'the room\'s floor reaches %.2f m outside its building\'s footprint' % over, (r.cx, 0, r.cz), amount=over); break
        self.party_walls()
        try: self.more_rooms()
        except Exception as e:
            self.add('check_error', 'the newer indoor checks stopped with an error and are NOT in this result: %s' % str(e)[:140], (r.cx, 0, r.cz), sure='a fault of the tool')
        return self.faults

    def wall_face(self, room, axis, plane, toward):
        """where a room's own big upright face stands near `plane`: of its faces there, the one furthest toward the
        other room (toward = +1 / -1 along the axis), or None"""
        T = room.dump.shell()
        if not len(T): return None
        n = np.cross(T[:, 1] - T[:, 0], T[:, 2] - T[:, 0]); ln = np.linalg.norm(n, axis=1)
        k = 0 if axis == 'x' else 2
        m = (ln > 1e-6) & (np.abs(n[:, k]) > 0.9 * np.maximum(ln, 1e-12))
        pos = T[m][:, :, k].mean(1); area = 0.5 * ln[m]
        near = np.abs(pos - plane) < 0.45
        if not near.any(): return None
        best = {}
        for q, a in zip(np.round(pos[near], 2), area[near]): best[float(q)] = best.get(float(q), 0.0) + float(a)
        big = [q for q, a in best.items() if a > 4.0]
        if not big: return None
        return max(big) if toward > 0 else min(big)

    def party_walls(self):
        r = self.r; A = assignments(); me = A.get(r.name)
        if not me or not r.floors: return
        fb = lambda rm: (min(f[0] for f in rm.floors), min(f[1] for f in rm.floors), max(f[2] for f in rm.floors), max(f[3] for f in rm.floors))
        a = fb(r)
        for n, o in A.items():
            if n == r.name or o.get('piece') != me.get('piece') or o.get('label') != me.get('label'): continue
            if np.hypot(o['pos'][0] - me['pos'][0], o['pos'][2] - me['pos'][2]) > 0.05: continue
            try: other = Room(n)
            except Exception: continue
            if not other.floors: continue
            b = fb(other)
            for axis, lo, hi, olo, ohi, s0, s1, t0, t1 in (('x', a[0], a[2], b[0], b[2], a[1], a[3], b[1], b[3]), ('z', a[1], a[3], b[1], b[3], a[0], a[2], b[0], b[2])):
                if min(s1, t1) - max(s0, t0) < 1.0: continue                      # they do not lie side by side on this axis
                if abs(hi - olo) <= 0.6: side = 1.0; plane = (hi + olo) / 2          # the other room lies on the + side
                elif abs(lo - ohi) <= 0.6: side = -1.0; plane = (lo + ohi) / 2
                else: continue
                mine = self.wall_face(r, axis, plane, side); theirs = self.wall_face(other, axis, plane, -side)
                if mine is None or theirs is None: continue
                thick = (theirs - mine) * side
                k = 0 if axis == 'x' else 1
                mid = (max(s0, t0) + min(s1, t1)) / 2
                at = (plane, 1.5, mid) if axis == 'x' else (mid, 1.5, plane)
                if thick < 0.10:
                    txt = ('the wall to the next shop (%s) has no thickness: one sheet with a face on each side' % n) if thick < 0.01 else ('the wall to the next shop (%s) is only %.0f cm thick' % (n, thick * 100))
                    self.add('thin_wall', txt, at, amount=thick, sure="measured from both rooms' own faces; mending it is the rooms' build, not one item")
                for it in r.items:
                    ext = float((it.quad[:, k] * side).max()) * side                 # its far reach toward the other room
                    through = (ext - mine) * side
                    if through > 0.004 and min(s1, t1) >= it.ctr[1 - k] >= max(s0, t0):
                        fx = self.fix_move(it)
                        fx['to'] = [fx['at'][0] - (side * (through + 0.02) if axis == 'x' else 0.0), fx['at'][1], fx['at'][2] - (side * (through + 0.02) if axis == 'z' else 0.0)]
                        seen = ' and shows in the next shop' if through > thick + 0.002 else ''
                        self.add('shows_through', '%s reaches %.1f cm into the wall to the next shop%s' % (it.base, through * 100, seen), it.pos, it, amount=through, mode='auto', fix=fx,
                                 sure="rule: it is drawn back to 2 cm inside this room's own wall face")


_sig = None
def signatures():
    global _sig
    if _sig is None:
        _sig = {}
        for f in sorted(os.listdir(L.RDUMP)):
            if not f.endswith('.json'): continue
            n = f[:-5]
            try: d = L.Dump(n, folder=L.RDUMP)
            except Exception: continue
            rows = []
            for b, X in d.batches():
                for x in X: rows.append((b['base'], round(abs(float(x[9])) * 2) / 2, round(float(x[11]) * 2) / 2))
            if len(rows) >= 6: _sig.setdefault(tuple(sorted(rows)), []).append(n)
    return _sig


def old_checker(names):
    """the existing indoor checker's lines for these rooms: {room: [(kind, message, 'CHECK' | 'NOTE')]}"""
    out = {n: [] for n in names}
    if not names: return out
    cmd = [L.GODOT, '--path', L.REPO, '--rendering-method', 'mobile', '--resolution', '320x180', '-s', 'res://map_dc/coronado/city_kit/interiors/rooms/check_rooms.gd', '--', '--only=' + ','.join(names)]
    import subprocess
    try: txt = subprocess.run(cmd, capture_output=True, text=True, timeout=900, errors='replace').stdout or ''
    except Exception: return None
    if 'CHECKS' not in txt: return None
    for l in txt.splitlines():
        tag = l[:5].strip()
        if tag not in ('CHECK', 'NOTE') or len(l) < 16 or l.startswith('CHECKS'): continue
        rest = l[6:].strip(); kind = rest.split()[0]; body = rest[len(kind):].strip()
        room = body.split(':', 1)[0].replace('(locked)', '').strip(); msg = body.split(':', 1)[1].strip() if ':' in body else body
        if room in out: out[room].append((kind, msg, tag))
    return out


def plan_png(room, faults, path, px=60.0):
    try: from PIL import Image, ImageDraw
    except Exception: return False
    if not room.floors: return False
    lo = np.array([min(f[0] for f in room.floors), min(f[1] for f in room.floors)]) - 0.8; hi = np.array([max(f[2] for f in room.floors), max(f[3] for f in room.floors)]) + 0.8
    W = int((hi[0] - lo[0]) * px); H = int((hi[1] - lo[1]) * px)
    im = Image.new('RGB', (W, H), (60, 60, 64)); dr = ImageDraw.Draw(im)
    def xy(p): return ((p[0] - lo[0]) * px, (p[1] - lo[1]) * px)
    for f in room.floors: dr.rectangle([xy((f[0], f[1])), xy((f[2], f[3]))], fill=(222, 214, 198))
    for s in room.solids: dr.rectangle([xy((s[0], s[1])), xy((s[2], s[3]))], fill=(110, 104, 98))
    for o in room.open:
        z, _ = room.zone(o, 0.12); dr.polygon([xy(q) for q in z], fill=(70, 150, 230) if o[-1] == 'window' else (230, 140, 40))
    for it in room.items:
        c = (150, 90, 160) if it.mount == 'wall' else ((60, 140, 70) if 'plant' in it.base else (60, 80, 150))
        dr.polygon([xy(q) for q in it.quad], outline=c)
        f = it.front(); a = xy(it.ctr); b = xy(it.ctr + f * 0.3); dr.line([a, b], fill=c, width=2)
        dr.text((a[0] + 3, a[1] + 2), it.base.replace('prop_', '')[:12], fill=(40, 40, 40))
    for f in faults:
        x, y = xy((f['at'][0], f['at'][2])); c2 = (210, 30, 30) if f['mode'] != 'report' else (200, 110, 0)
        dr.ellipse([x - 9, y - 9, x + 9, y + 9], outline=c2, width=2); dr.text((x + 10, y - 12), str(f['n']), fill=c2)
    im.save(path)
    return True


def check_room(name, out, dump_dir=None, old=None, say=True):
    room = Room(name, dump_dir=dump_dir)
    F = RoomFinder(room); F.run()
    for sig, names in signatures().items():
        if name in names and len(names) > 1 and dump_dir is None:
            F.add('same_layout', 'the same things in the same places as %s' % ', '.join(n for n in names if n != name)[:160], (room.cx, 0, room.cz), sure='rule: "i want the shops to look different"')
    for kind, msg, tag in (old or []):
        F.add('old_' + kind, msg + (' (a locked room: the old checker prints this as a note and does not count it)' if tag == 'NOTE' else ''), (room.cx, 0, room.cz), sure='the existing indoor checker')
    fixes = []
    for f in F.faults:
        if 'fix' in f:
            line = dict(f['fix']); line['n'] = f['n']; line['kind'] = f['kind']; line['mode'] = f['mode']; line['reason'] = f['text']; fixes.append(line)
    os.makedirs(out, exist_ok=True)
    res = {'room': name, 'shop': room.shop, 'sha256': room.dump.j.get('sha256'), 'props': len(room.items), 'counts': F.counts, 'faults': F.faults}
    json.dump(res, open(os.path.join(out, name + '.faults.json'), 'w', encoding='utf-8'), indent=1)
    json.dump({'scene': name, 'fixes': fixes}, open(os.path.join(out, name + '.fixes.json'), 'w', encoding='utf-8'), indent=1)
    plan_png(room, F.faults, os.path.join(out, name + '.plan.png'))
    if say:
        modes = {}
        for f in F.faults: modes[f['mode']] = modes.get(f['mode'], 0) + 1
        print('  ROOM %s (%s "%s"): %d props; %s' % (name, room.shop.get('kind', '?'), room.shop.get('name', ''), len(room.items), ', '.join('%s %d' % kv for kv in sorted(F.counts.items())) or 'nothing found'))
        if F.faults: print('       one right answer: %d; a place to be chosen by hand: %d; reported only: %d' % (modes.get('auto', 0), modes.get('choose', 0), modes.get('report', 0)))
    return res


def piece_rooms_faults(piece, ctx):
    """buildings with a shop door and no room; rooms with no building; rooms listed but not built: [(kind, text, at)]"""
    out = []; A = [r for r in all_assigned() if r.get('piece') == piece]
    for b in ctx.my_blds:
        con = b.open
        if not con or b.kit.startswith(('houses/', 'garages/')): continue      # a house's front door is no shop door
        shops = [e for e in con.get('entrances', []) if e.get('kind') == 'shop' and int(e.get('floor', 0)) == 0]
        if shops and not any(str(a.get('label')) == b.name for a in A):
            out.append(('no_room', '%s has %d shop door(s) and no room behind any of them' % (b.name, len(shops)), b.pos))
    for a in A:
        if not any(b.name == str(a.get('label')) and np.hypot(b.pos[0] - a['pos'][0], b.pos[2] - a['pos'][2]) < 1.5 for b in ctx.my_blds):
            out.append(('room_no_building', 'the room %s is listed for the building "%s", which does not stand where the list says' % (a.get('id'), a.get('label')), a['pos']))
        if not any(os.path.exists(os.path.join(L.ROOMS, c + '.scn')) for c in (a.get('built') or '', 'g_' + str(a['id']), str(a['id'])) if c):
            out.append(('room_not_built', 'the room %s ("%s") is listed and has no file' % (a.get('id'), a.get('name', '')), a['pos']))
    return out


def all_assigned():
    out = []
    d = os.path.join(L.CK, 'interiors')
    for f in sorted(os.listdir(d)):
        if f.startswith('assignment_') and f.endswith('.json'):
            try: j = json.load(open(os.path.join(d, f), encoding='utf-8'))
            except Exception: continue
            rooms = j.get('rooms') if isinstance(j, dict) else None
            if isinstance(rooms, list): out += [r for r in rooms if isinstance(r, dict) and 'piece' in r and 'id' in r and 'pos' in r]
    return out


def check_piece(piece, ctx=None, out=None, say=True):
    names = rooms_of_piece(piece)
    out = out or os.path.join(L.OUT, 'find')
    if ctx is not None:
        pf = piece_rooms_faults(piece, ctx)
        if say:
            for kind, text, at in pf: print('  %-18s %s' % (kind, text))
        json.dump([{'kind': k, 'text': t, 'at': [float(v) for v in a]} for k, t, a in pf], open(os.path.join(out, piece + '.rooms_of_piece.json'), 'w'), indent=1)
    if not names:
        if say: print('  no rooms belong to %s' % piece)
        return []
    L.ensure_dumps(names, folder=L.ROOMS, out=L.RDUMP, say=False)
    old = old_checker(names)
    if old is None and say: print('  !! the existing indoor checker did not run: its lines are missing below')
    res = [check_room(n, out, old=(old or {}).get(n), say=say) for n in names]
    json.dump({'piece': piece, 'rooms': names}, open(os.path.join(out, piece + '.rooms.json'), 'w'), indent=1)
    return res


if __name__ == '__main__':
    a = [x for x in sys.argv[1:] if not x.startswith('--')]
    opt = dict(x[2:].split('=', 1) for x in sys.argv[1:] if x.startswith('--') and '=' in x)
    if 'piece' in opt: check_piece(opt['piece'])
    elif a:
        L.ensure_dumps(a, folder=L.ROOMS, out=L.RDUMP, say=False)
        old = old_checker(a) or {}
        for n in a: check_room(n, os.path.join(L.OUT, 'find'), old=old.get(n))
    else: sys.exit(__doc__)
