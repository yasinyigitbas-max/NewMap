"""Superchecker: the ONE command (19 Nov 2026).
Yasin: "make a superchecker for both indoors and outdoors that changes irregularities that they find by hand and
checks that nothing else other than the irregularity was changed? THIS TOOL MUSTNT CHANGE THE ENTIRE BLOCK WITH A
GENERATOR"; "if it can prove that it is fixing things by hand, it can do all of the block at once after finding all
the faults"; "remove all of the trees in the area and fill the wells with the material surrounding it".

  python -I tools/city/super/sc.py check <piece>      find every fault of the piece (and of its rooms); change nothing
  python -I tools/city/super/sc.py fix <piece>        carry the fix list out on a COPY of the piece, prove that only
                                                      the listed items changed, check the copy again
  python -I tools/city/super/sc.py fix-room <room>    the same for one room (a room is its own file)
  python -I tools/city/super/sc.py shots <piece> "--cams=name:x,y,z:tx,ty,tz;..." [--top=<metres>]
                                                      the same views of the piece as it is and of the proven copy,
                                                      side by side (preview renderer, only this area loaded)
  python -I tools/city/super/sc.py trees <area>       check a hand-written tree list (zoning/trees/<area>.json) and build
                                                      it into a COPY of its piece t_<area> (sc_trees.py, sc_trees.gd)
  python -I tools/city/super/sc.py check-all [--only=<name start>]
                                                      "check" on every growth block, one after another (about a minute
                                                      each); changes nothing; the totals go to OUT/super/find/_all.txt
  python -I tools/city/super/sc.py layout             faults of the city layout file itself (rows without a file, doubles ...)
  python -I tools/city/super/sc.py look <piece> "--cams=name:x,y,z:tx,ty,tz;..."
                                                      plain views of the piece AS IT IS (only its area loaded)
  python -I tools/city/super/sc.py install-room <room> --by=Yasin    the same for one room's proven copy
  python -I tools/city/super/sc.py install <piece> --by=Yasin
                                                      put the proven copy in the piece's place (the old file is kept),
                                                      open and close its lock, write the log. Only on Yasin's word.

What it is made of (none of them runs a piece's building script, none decides where anything goes by a rule):
  sc_dump.gd   reads a saved scene out into numbers            sc_find.py   measures and lists the faults (outdoors)
  sc_rooms.py  the same indoors (with check_rooms.gd)          sc_fix.gd    changes the listed items; proves the rest
  sc_wells.gd  the bake's own well filler, for one well        sc_lib.py    shared reading code
  sc_trees.py  checks a hand-written tree list                 sc_trees.gd  builds that list into the piece t_<area>
Every change is a line of <piece>.fixes.json: the item, where it is, where it goes, why. A line whose new place has
to be chosen ("mode": "choose") is not carried out until a person fills in "to" and sets "chosen": true.
"""
import json, os, shutil, subprocess, sys, time

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import sc_lib as L
import sc_find as F

WORK = os.path.join(L.OUT, 'work'); FIND = os.path.join(L.OUT, 'find'); BACK = os.path.join(L.OUT, 'backup')
REVIEW = os.path.join(L.CK, 'review/superchecker')


def res(p):
    return 'res://' + L.fwd(os.path.relpath(p, L.REPO))


def fault_key(f):
    it = f.get('item') or {}
    return (f['kind'], it.get('base', ''), round(f['at'][0], 1), round(f['at'][2], 1))


def cmd_check(piece, say=True):
    r, ctx = F.find(piece, out=FIND, say=say)
    import sc_rooms
    sc_rooms.check_piece(piece, ctx, out=FIND, say=say)
    return r


def cmd_check_all(only=''):
    """the check on every growth block of the layout; no piece is changed; needs nobody watching"""
    import sc_rooms
    rows = L.load_layout(); pieces = []
    for r in rows:
        if r.frm.startswith('grow_') and r.piece not in pieces and r.piece.startswith(only): pieces.append(r.piece)
    os.makedirs(FIND, exist_ok=True); out = os.path.join(FIND, '_all.txt'); tot = {}; modes = {'auto': 0, 'choose': 0, 'report': 0}; lines = []; bad = []
    t0 = time.time()
    for k, p in enumerate(pieces):
        try:
            res, ctx = F.find(p, out=FIND, say=False)
            rooms = sc_rooms.check_piece(p, ctx, out=FIND, say=False)
        except Exception as e:
            bad.append((p, str(e)[:160])); print('%3d/%d %-26s STOPPED: %s' % (k + 1, len(pieces), p, str(e)[:100]), flush=True); continue
        c = dict(res['counts'])
        for rr in rooms:
            for kk, v in rr['counts'].items(): c['room:' + kk] = c.get('room:' + kk, 0) + v
        m = {'auto': 0, 'choose': 0, 'report': 0}
        for f in res['faults'] + [f for rr in rooms for f in rr['faults']]: m[f['mode']] = m.get(f['mode'], 0) + 1
        for kk, v in c.items(): tot[kk] = tot.get(kk, 0) + v
        for kk in modes: modes[kk] += m.get(kk, 0)
        line = '%-26s %4d findings (%d one right answer, %d a place to choose, %d reported), %d rooms' % (p, sum(m.values()), m['auto'], m['choose'], m['report'], len(rooms))
        lines.append(line); print('%3d/%d %s  [%.0f min]' % (k + 1, len(pieces), line, (time.time() - t0) / 60), flush=True)
    with open(out, 'w', encoding='utf-8') as f:
        f.write('Superchecker, every growth block, %s. Nothing was changed.\n' % time.strftime('%Y-%m-%d %H:%M'))
        f.write('%d blocks checked, %d stopped with an error.\n' % (len(lines), len(bad)))
        f.write('Findings: %d with one right answer, %d that need a place chosen by hand, %d reported only.\n\nBY KIND\n' % (modes['auto'], modes['choose'], modes['report']))
        for kk, v in sorted(tot.items(), key=lambda kv: -kv[1]): f.write('  %-28s %6d\n' % (kk, v))
        f.write('\nBY BLOCK\n' + '\n'.join(lines) + '\n')
        if bad: f.write('\nSTOPPED\n' + '\n'.join('%s: %s' % b for b in bad) + '\n')
    print('CHECK-ALL done: %d blocks in %.0f min; the totals are in %s' % (len(lines), (time.time() - t0) / 60, os.path.relpath(out, L.REPO)))


def cmd_fix(piece, fixes_path=None):
    os.makedirs(WORK, exist_ok=True)
    before = json.load(open(os.path.join(FIND, piece + '.faults.json'), encoding='utf-8')) if os.path.exists(os.path.join(FIND, piece + '.faults.json')) else cmd_check(piece, say=False)
    src = os.path.join(L.PIECES, piece + '.scn')
    if before.get('sha256') != L.sha_file(src): before = cmd_check(piece, say=False)
    fx = json.load(open(fixes_path or os.path.join(FIND, piece + '.fixes.json'), encoding='utf-8'))
    todo = []; held = 0
    for f in fx['fixes']:
        if f.get('mode') == 'choose' and not f.get('chosen'): held += 1; continue
        todo.append(f)
    # removals last within their kind is not needed (items are found by place, not by number), but wells must come
    # after their trees: the well filler looks for the well of a trunk position, the tree itself may still stand
    seen = set(); uniq = []
    for f in todo:          # one item listed by two checks (a wear mark off its surface AND oil with no car): carry it out once
        k = (f['op'], f.get('base', ''), f.get('wear', ''), f.get('surface', 0), tuple(round(float(v), 3) for v in f['at']))
        if k in seen: continue
        seen.add(k); uniq.append(f)
    todo = uniq
    todo.sort(key=lambda f: {'add_collider': 0, 'move': 1, 'remove': 2, 'remove_decal': 3, 'fill_well': 4, 'add_box': 5}.get(f['op'], 9))
    lst = os.path.join(WORK, piece + '.todo.json'); json.dump({'scene': piece, 'fixes': todo}, open(lst, 'w'), indent=1)
    out = os.path.join(WORK, piece + '.scn'); applied = os.path.join(WORK, piece + '.applied.json')
    for p in (out, applied):
        if os.path.exists(p): os.remove(p)
    print('FIX %s: %d lines to carry out, %d held back (a place must be chosen by hand)' % (piece, len(todo), held))
    lines = L.godot('sc_fix.gd', ['--apply', '--in=' + res(src), '--fixes=' + res(lst), '--out=' + res(out), '--applied=' + res(applied)])
    for l in lines:
        if l.startswith('SC-FIX'): print('  ' + l)
    if not os.path.exists(out) or not os.path.exists(applied): print('FIX %s: NOT DONE (see above)' % piece); return False
    proof = L.godot('sc_fix.gd', ['--prove', '--old=' + res(src), '--new=' + res(out), '--fixes=' + res(applied)])
    ptxt = [l for l in proof if l.startswith('PROOF') or l.startswith('   ')]
    open(os.path.join(WORK, piece + '.proof.txt'), 'w', encoding='utf-8').write('\n'.join(ptxt) + '\n')
    passed = any(l.strip() == 'PROOF RESULT PASS' for l in proof)
    for l in ptxt:
        if 'PROOF change' in l or 'PROOF note' in l: continue
        print('  ' + l)
    n_ch = sum(1 for l in ptxt if 'PROOF change' in l)
    print('  (%d changes, one line each, in %s)' % (n_ch, os.path.relpath(os.path.join(WORK, piece + '.proof.txt'), L.REPO)))
    if not passed: print('FIX %s: THE PROOF FAILED: the copy is not to be used' % piece); return False
    # the copy, checked again
    dd = os.path.join(WORK, 'dump'); os.makedirs(dd, exist_ok=True)
    L.godot('sc_dump.gd', ['--out=' + L.fwd(dd), '--models=' + L.fwd(L.MODELS), '--files=' + res(out)])
    after, _ = F.find(piece, dump_dir=dd, out=os.path.join(WORK, 'find'), say=False)
    kb = {}; ka = {}
    for f in before['faults']: kb[fault_key(f)] = kb.get(fault_key(f), 0) + 1
    for f in after['faults']: ka[fault_key(f)] = ka.get(fault_key(f), 0) + 1
    new = [k for k in ka if ka[k] > kb.get(k, 0)]
    kinds = sorted(set(list(before['counts']) + list(after['counts'])))
    print('  the copy checked again (faults before -> after):')
    for k in kinds:
        b = before['counts'].get(k, 0); a = after['counts'].get(k, 0)
        if a != b: print('    %-18s %4d -> %d' % (k, b, a))
    same = sum(1 for k in kinds if before['counts'].get(k, 0) == after['counts'].get(k, 0) and before['counts'].get(k, 0))
    if same: print('    unchanged kinds: ' + ', '.join('%s %d' % (k, before['counts'][k]) for k in kinds if before['counts'].get(k, 0) == after['counts'].get(k, 0) and before['counts'].get(k, 0)))
    if new:
        print('  !! %d faults in the copy that the piece did not have:' % len(new))
        for k in new[:12]: print('     ', k)
    stamp = {'piece': piece, 'old_sha256': L.sha_file(src), 'new_sha256': L.sha_file(out), 'changes': n_ch, 'held': held, 'proof': 'PASS', 'new_faults': len(new), 'when': time.strftime('%Y-%m-%d %H:%M')}
    json.dump(stamp, open(os.path.join(WORK, piece + '.stamp.json'), 'w'), indent=1)
    print('FIX %s: proof PASS, %d changes on the COPY %s; the piece itself is untouched' % (piece, n_ch, os.path.relpath(out, L.REPO)))
    return True


def cmd_fix_room(room, fixes_path=None):
    import sc_rooms as R
    os.makedirs(WORK, exist_ok=True)
    src = os.path.join(L.ROOMS, room + '.scn')
    L.ensure_dumps([room], folder=L.ROOMS, out=L.RDUMP, say=False)
    old = (R.old_checker([room]) or {}).get(room)
    fpath = fixes_path or os.path.join(FIND, room + '.fixes.json')
    keep_dec = os.path.exists(fpath)          # a fix list already there carries the decisions made on it: never overwrite it
    before = R.check_room(room, os.path.join(WORK, 'find_before') if keep_dec else FIND, old=old, say=False)
    fx = json.load(open(fpath, encoding='utf-8'))
    todo = [f for f in fx['fixes'] if not (f.get('mode') == 'choose' and not f.get('chosen'))]; held = len(fx['fixes']) - len(todo)
    seen = set(); uniq = []
    for f in todo:          # one item named by two checks: carry it out once (a remove wins over a move)
        k = (f.get('base', ''), f.get('wear', ''), tuple(round(float(v), 3) for v in f['at']))
        if k in seen: continue
        seen.add(k); uniq.append(f)
    todo = sorted(uniq, key=lambda f: 0 if f['op'] == 'remove' else 1)
    lst = os.path.join(WORK, room + '.todo.json'); json.dump({'scene': room, 'fixes': todo}, open(lst, 'w'), indent=1)
    out = os.path.join(WORK, room + '.scn'); applied = os.path.join(WORK, room + '.applied.json')
    for p in (out, applied):
        if os.path.exists(p): os.remove(p)
    print('FIX ROOM %s: %d lines to carry out, %d held back (a place must be chosen by hand)' % (room, len(todo), held))
    if not todo: print('  nothing to carry out'); return True
    for l in L.godot('sc_fix.gd', ['--apply', '--in=' + res(src), '--fixes=' + res(lst), '--out=' + res(out), '--applied=' + res(applied)]):
        if l.startswith('SC-FIX'): print('  ' + l)
    if not os.path.exists(out) or not os.path.exists(applied): print('FIX ROOM %s: NOT DONE' % room); return False
    proof = L.godot('sc_fix.gd', ['--prove', '--old=' + res(src), '--new=' + res(out), '--fixes=' + res(applied)])
    ptxt = [l for l in proof if l.startswith('PROOF') or l.startswith('   ')]
    open(os.path.join(WORK, room + '.proof.txt'), 'w', encoding='utf-8').write('\n'.join(ptxt) + '\n')
    for l in ptxt: print('  ' + l)
    if not any(l.strip() == 'PROOF RESULT PASS' for l in proof): print('FIX ROOM %s: THE PROOF FAILED: the copy is not to be used' % room); return False
    dd = os.path.join(WORK, 'dump_rooms'); os.makedirs(dd, exist_ok=True)
    L.godot('sc_dump.gd', ['--out=' + L.fwd(dd), '--models=' + L.fwd(L.MODELS), '--files=' + res(out)])
    after = R.check_room(room, os.path.join(WORK, 'find'), dump_dir=dd, say=False)
    kinds = sorted(k for k in set(list(before['counts']) + list(after['counts'])) if not k.startswith('old_') and k != 'same_layout')
    print('  the copy checked again by the new indoor checks (before -> after): ' + ', '.join('%s %d -> %d' % (k, before['counts'].get(k, 0), after['counts'].get(k, 0)) for k in kinds))
    print('  (the old indoor checker reads rooms from their folder: it sees the copy only after it is put in place)')
    n_ch = sum(1 for l in ptxt if 'PROOF change' in l)
    json.dump({'room': room, 'old_sha256': L.sha_file(src), 'new_sha256': L.sha_file(out), 'changes': n_ch, 'held': held, 'proof': 'PASS', 'when': time.strftime('%Y-%m-%d %H:%M')}, open(os.path.join(WORK, room + '.stamp.json'), 'w'), indent=1)
    print('FIX ROOM %s: proof PASS, %d changes on the COPY; the room itself is untouched' % (room, n_ch))
    return True


def cmd_trees(area):
    import sc_trees as T
    j = T.load(area)
    fixed = os.path.join(WORK, 'dump', j['piece'] + '.json')
    ok = T.check(area, dump_dir=os.path.join(WORK, 'dump') if os.path.exists(fixed) else None)
    if os.path.exists(fixed): print('  (checked against the FIXED copy of %s: its builder trees are out)' % j['piece'])
    if not ok: print('TREES %s: the list is not clean: nothing built' % area); return False
    os.makedirs(WORK, exist_ok=True); out = os.path.join(WORK, 't_' + area + '.scn')
    lines = L.godot('sc_trees.gd', ['--list=' + res(os.path.join(T.TREES, area + '.json')), '--out=' + res(out)])
    for l in lines:
        if l.startswith('SC-TREES') or 'MISSING PROP' in l: print('  ' + l)
    if not os.path.exists(out): print('TREES %s: NOT BUILT' % area); return False
    # read the built piece back: it must hold exactly the list's trees, each at its line's place
    dd = os.path.join(WORK, 'dump'); os.makedirs(dd, exist_ok=True)
    L.godot('sc_dump.gd', ['--out=' + L.fwd(dd), '--models=' + L.fwd(L.MODELS), '--files=' + res(out)])
    d = L.Dump('t_' + area, folder=dd); got = []
    for b, X in d.batches():
        if b['tier'] == 'near': got += [(b['base'], round(float(x[9]), 2), round(float(x[11]), 2)) for x in X]
    want = sorted((t['base'], round(float(t['at'][0]), 2), round(float(t['at'][2]), 2)) for t in j['trees'])
    same = sorted(got) == want
    print('  the built piece read back: %d trees, %s' % (len(got), 'each one a line of the list, nothing else' if same else 'NOT the list: ' + str(sorted(got))[:200]))
    print('TREES %s: %s; the map is untouched (the piece is a copy at %s)' % (area, 'built' if same else 'WRONG', os.path.relpath(out, L.REPO)))
    return same


def land_files():
    """the land for the preview tool: heights .f32 and sea .u8 beside a small json, from zoning/terrain_grid.npz"""
    import numpy as np
    d = os.path.join(L.OUT, 'land'); os.makedirs(d, exist_ok=True); j = os.path.join(d, 'terrain_grid.json')
    if os.path.exists(j) and os.path.getmtime(j) >= os.path.getmtime(L.LAND): return j
    t = np.load(L.LAND); H = t['heights'].astype('<f4'); ny, nx = H.shape
    H.tofile(os.path.join(d, 'terrain_grid.f32')); t['sea'].astype('u1').tofile(os.path.join(d, 'terrain_sea.u8'))
    json.dump({'u0': float(t['u0']), 'v0': float(t['v0']), 'step': float(t['step']), 'nx': nx, 'ny': ny}, open(j, 'w'))
    return j


def cmd_shots(piece, cams, top=None, out=None):
    from PIL import Image, ImageDraw
    rows = L.load_layout(); me = [r for r in rows if r.piece == piece][0]
    ctx = F.Ctx(rows, me, reach=40.0)
    out = out or os.path.join(WORK, 'shots', piece); os.makedirs(out, exist_ok=True)
    new = os.path.join(WORK, piece + '.scn'); tmp_name = 'zz_sc_' + piece; tmp = os.path.join(L.PIECES, tmp_name + '.scn')
    if not os.path.exists(new): sys.exit('no fixed copy of %s: run fix first' % piece)
    def area(name_for_me):
        return {'instances': [{'piece': name_for_me if r.id == me.id else r.piece, 'pos': [float(v) for v in r.pos], 'yaw': r.yaw} for r in [me] + ctx.neigh]}
    lb = os.path.join(WORK, piece + '.area_before.json'); la = os.path.join(WORK, piece + '.area_after.json')
    # the hand-placed trees of this piece (built copies of t_<area>) stand in the "after" view
    import sc_trees as T
    extra = []
    for ar in T.lists_of_piece(piece):
        tp = os.path.join(WORK, 't_' + ar + '.scn')
        if os.path.exists(tp): extra.append(('zz_sc_t_' + ar, tp))
    after = area(tmp_name)
    for nm, _ in extra: after['instances'].append({'piece': nm, 'pos': [0, 0, 0], 'yaw': 0})
    json.dump(area(piece), open(lb, 'w')); json.dump(after, open(la, 'w'))
    env = dict(os.environ, CITYKIT_LAYOUT_ONLY='1', TERRAIN=L.fwd(land_files()), CARS='0')
    views = [c for c in cams.split(';') if c.strip()] if cams else []
    if top: views.append('TOP')
    shutil.copy2(new, tmp)
    for nm, tp in extra: shutil.copy2(tp, os.path.join(L.PIECES, nm + '.scn'))
    made = []
    try:
        for v in views:
            name = 'top' if v == 'TOP' else v.split(':')[0]
            pair = []
            for tag, lay in (('before', lb), ('after', la)):
                e = dict(env, CITYKIT_LAYOUT_EXTRA=L.fwd(lay)); od = os.path.join(out, tag)
                if v == 'TOP':
                    c = (ctx.lo + ctx.hi) / 2; e['TOPVIEW'] = str(top)
                    cam = 'top:%.1f,300,%.1f:%.1f,0,%.1f' % (c[0], c[1], c[0], c[1] - 1.0)
                else: cam = v
                subprocess.run([L.GODOT, '--path', L.REPO, '--rendering-method', 'mobile', '--resolution', '1280x720', '-s', 'res://tools/city/pilot/preview/shots.gd', '--', '--out=' + L.fwd(od), '--cams=' + cam],
                               env=e, capture_output=True, timeout=600)
                f = next((os.path.join(od, name + x) for x in ('.png', '.jpg') if os.path.exists(os.path.join(od, name + x))), None)
                pair.append(f)
            if not all(pair): print('  shot %s: a picture is missing %s' % (name, pair)); continue
            a = Image.open(pair[0]).convert('RGB'); b = Image.open(pair[1]).convert('RGB')
            w, h = a.size; im = Image.new('RGB', (w * 2 + 8, h), (255, 255, 255)); im.paste(a, (0, 0)); im.paste(b, (w + 8, 0))
            dr = ImageDraw.Draw(im)
            for x, t in ((10, 'AS IT IS'), (w + 18, 'THE FIXED COPY')):
                dr.rectangle([x - 4, 6, x + 150, 26], fill=(0, 0, 0)); dr.text((x, 10), t, fill=(255, 255, 255))
            import numpy as np
            diff = int((np.abs(np.asarray(a).astype(int) - np.asarray(b).astype(int)).max(2) > 24).sum())
            fo = os.path.join(out, '%s_%s.jpg' % (piece, name)); im.save(fo, quality=88); made.append(fo)
            print('  shot %s: %s (%d pixels differ between the two)' % (name, os.path.relpath(fo, L.REPO), diff))
    finally:
        if os.path.exists(tmp): os.remove(tmp)
        for nm, tp in extra:
            if os.path.exists(os.path.join(L.PIECES, nm + '.scn')): os.remove(os.path.join(L.PIECES, nm + '.scn'))
    return made


def cmd_look(piece, cams, out=None):
    rows = L.load_layout(); me = [r for r in rows if r.piece == piece][0]
    ctx = F.Ctx(rows, me, reach=40.0)
    out = out or os.path.join(WORK, 'look', piece); os.makedirs(out, exist_ok=True)
    lay = os.path.join(WORK, piece + '.area_before.json')
    json.dump({'instances': [{'piece': r.piece, 'pos': [float(v) for v in r.pos], 'yaw': r.yaw} for r in [me] + ctx.neigh]}, open(lay, 'w'))
    env = dict(os.environ, CITYKIT_LAYOUT_ONLY='1', CITYKIT_LAYOUT_EXTRA=L.fwd(lay), TERRAIN=L.fwd(land_files()), CARS='0')
    made = []
    for v in [c for c in cams.split(';') if c.strip()]:
        subprocess.run([L.GODOT, '--path', L.REPO, '--rendering-method', 'mobile', '--resolution', '1280x720', '-s', 'res://tools/city/pilot/preview/shots.gd', '--', '--out=' + L.fwd(out), '--cams=' + v],
                       env=env, capture_output=True, timeout=600)
        name = v.split(':')[0]
        f = next((os.path.join(out, name + x) for x in ('.png', '.jpg') if os.path.exists(os.path.join(out, name + x))), None)
        print('  view %s: %s' % (name, os.path.relpath(f, L.REPO) if f else 'MISSING')); made.append(f)
    return made


def add_layout_row(piece, path=None):
    """one more row in the city layout for a whole-area piece built in the grid frame (as integrate.py writes them)"""
    path = path or L.LAYOUT
    lay = json.load(open(path, encoding='utf-8'))
    if any(r['piece'] == piece for r in lay['instances']): return False
    lay['instances'].append({'piece': piece, 'pos': [0.0, 0.0, 0.0], 'yaw': 0.0, 'from': 'trees'})
    json.dump(lay, open(path, 'w'), indent=1)          # the same call integrate.py makes (CRLF on the PC, no last newline)
    return True


def cmd_install_room(room, by):
    if by != 'Yasin': sys.exit('install-room needs --by=Yasin: his word, given in the chat')
    stamp_p = os.path.join(WORK, room + '.stamp.json')
    if not os.path.exists(stamp_p): sys.exit('no proven copy of %s: run fix-room first' % room)
    st = json.load(open(stamp_p)); src = os.path.join(L.ROOMS, room + '.scn'); new = os.path.join(WORK, room + '.scn')
    if st['proof'] != 'PASS' or L.sha_file(src) != st['old_sha256'] or L.sha_file(new) != st['new_sha256']:
        sys.exit('the room or the copy changed since the proof: run fix-room again')
    os.makedirs(BACK, exist_ok=True); os.makedirs(REVIEW, exist_ok=True)
    keep = os.path.join(BACK, '%s.%s.scn' % (room, st['old_sha256'][:10])); shutil.copy2(src, keep)
    rel = L.fwd(os.path.relpath(src, L.REPO)); lock = os.path.join(L.REPO, 'tools/city/pilot/lock.py')
    locked = rel in json.load(open(os.path.join(L.CK, 'locked.json'), encoding='utf-8')).get('files', {})
    if locked: subprocess.run([sys.executable, '-I', lock, 'unlockfile', rel, '--by=Yasin'], cwd=L.REPO, check=True)
    shutil.copy2(new, src)
    if locked: subprocess.run([sys.executable, '-I', lock, 'lockfile', rel, '--by=Yasin'], cwd=L.REPO, check=True)
    shutil.copy2(os.path.join(WORK, room + '.applied.json'), os.path.join(REVIEW, room + '.fixes.json'))
    shutil.copy2(os.path.join(WORK, room + '.proof.txt'), os.path.join(REVIEW, room + '.proof.txt'))
    with open(os.path.join(REVIEW, 'log.jsonl'), 'a', encoding='utf-8', newline='\n') as f: f.write(json.dumps(st) + '\n')
    print('INSTALLED ROOM %s: %d changes; the old file is kept at %s; relocked: %s' % (room, st['changes'], os.path.relpath(keep, L.REPO), locked))


def cmd_install(piece, by):
    stamp_p = os.path.join(WORK, piece + '.stamp.json')
    if by != 'Yasin': sys.exit('install needs --by=Yasin: a locked piece changes only with his word, given in the chat')
    if not os.path.exists(stamp_p): sys.exit('no proven copy of %s: run fix first' % piece)
    st = json.load(open(stamp_p)); src = os.path.join(L.PIECES, piece + '.scn'); new = os.path.join(WORK, piece + '.scn')
    if st['proof'] != 'PASS' or L.sha_file(src) != st['old_sha256'] or L.sha_file(new) != st['new_sha256']:
        sys.exit('the piece or the copy changed since the proof: run fix again')
    os.makedirs(BACK, exist_ok=True); os.makedirs(REVIEW, exist_ok=True)
    keep = os.path.join(BACK, '%s.%s.scn' % (piece, st['old_sha256'][:10])); shutil.copy2(src, keep)
    lock = os.path.join(L.REPO, 'tools/city/pilot/lock.py')
    locked = piece in json.load(open(os.path.join(L.CK, 'locked.json'), encoding='utf-8')).get('pieces', {})
    if locked: subprocess.run([sys.executable, '-I', lock, 'unlock', piece, '--by=Yasin'], cwd=L.REPO, check=True)
    shutil.copy2(new, src)
    if locked: subprocess.run([sys.executable, '-I', lock, 'lock', piece, '--by=Yasin'], cwd=L.REPO, check=True)
    shutil.copy2(os.path.join(WORK, piece + '.applied.json'), os.path.join(REVIEW, piece + '.fixes.json'))
    shutil.copy2(os.path.join(WORK, piece + '.proof.txt'), os.path.join(REVIEW, piece + '.proof.txt'))
    # the hand-placed trees of this piece: their built copy becomes the piece t_<area>, with its layout row
    import sc_trees as T
    for ar in T.lists_of_piece(piece):
        tp = os.path.join(WORK, 't_' + ar + '.scn')
        if os.path.exists(tp):
            shutil.copy2(tp, os.path.join(L.PIECES, 't_' + ar + '.scn')); new_row = add_layout_row('t_' + ar)
            print('  trees: t_%s put in place (%d trees)%s' % (ar, len(T.load(ar)['trees']), ', one row added to the city layout' if new_row else ''))
        else: print('  trees: the list %s is not built: run "trees %s" first' % (ar, ar))
    with open(os.path.join(REVIEW, 'log.jsonl'), 'a', encoding='utf-8', newline='\n') as f: f.write(json.dumps(st) + '\n')
    print('INSTALLED %s: %d changes; the old file is kept at %s; relocked: %s' % (piece, st['changes'], os.path.relpath(keep, L.REPO), locked))


if __name__ == '__main__':
    a = [x for x in sys.argv[1:] if not x.startswith('--')]
    opt = dict(x[2:].split('=', 1) for x in sys.argv[1:] if x.startswith('--') and '=' in x)
    if len(a) < 2 and not (a and a[0] in ('layout', 'check-all')): sys.exit(__doc__)
    if a[0] in ('layout', 'check-all'): a.append('')
    if a[0] == 'check-all': cmd_check_all(opt.get('only', '')); sys.exit(0)
    if a[0] == 'check': cmd_check(a[1])
    elif a[0] == 'fix': sys.exit(0 if cmd_fix(a[1], opt.get('fixes')) else 1)
    elif a[0] == 'fix-room': sys.exit(0 if cmd_fix_room(a[1], opt.get('fixes')) else 1)
    elif a[0] == 'trees': sys.exit(0 if cmd_trees(a[1]) else 1)
    elif a[0] == 'layout':
        import sc_more
        fl = sc_more.layout_faults()
        for k, t in fl: print('  %-16s %s' % (k, t))
        print('LAYOUT %d faults in %s' % (len(fl), os.path.relpath(L.LAYOUT, L.REPO)))
    elif a[0] == 'look': cmd_look(a[1], opt.get('cams', ''))
    elif a[0] == 'shots': cmd_shots(a[1], opt.get('cams', ''), opt.get('top'))
    elif a[0] == 'install': cmd_install(a[1], opt.get('by', ''))
    elif a[0] == 'install-room': cmd_install_room(a[1], opt.get('by', ''))
    else: sys.exit(__doc__)
