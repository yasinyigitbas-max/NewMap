"""Superchecker: the ONE command (19 Nov 2026).
Yasin: "make a superchecker for both indoors and outdoors that changes irregularities that they find by hand and
checks that nothing else other than the irregularity was changed? THIS TOOL MUSTNT CHANGE THE ENTIRE BLOCK WITH A
GENERATOR"; "if it can prove that it is fixing things by hand, it can do all of the block at once after finding all
the faults"; "remove all of the trees in the area and fill the wells with the material surrounding it".

  python -I tools/city/super/sc.py check <piece>      find every fault of the piece (and of its rooms); change nothing
  python -I tools/city/super/sc.py fix <piece>        carry the fix list out on a COPY of the piece, prove that only
                                                      the listed items changed, check the copy again
  python -I tools/city/super/sc.py install <piece> --by=Yasin
                                                      put the proven copy in the piece's place (the old file is kept),
                                                      open and close its lock, write the log. Only on Yasin's word.

What it is made of (none of them runs a piece's building script, none decides where anything goes by a rule):
  sc_dump.gd   reads a saved scene out into numbers            sc_find.py   measures and lists the faults (outdoors)
  sc_rooms.py  the same indoors (with check_rooms.gd)          sc_fix.gd    changes the listed items; proves the rest
  sc_wells.gd  the bake's own well filler, for one well        sc_lib.py    shared reading code
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
    try:
        import sc_rooms
        sc_rooms.check_piece(piece, ctx, out=FIND, say=say)
    except ImportError:
        if say: print('  (the indoor part is not written yet)')
    return r


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
    todo.sort(key=lambda f: {'move': 0, 'remove': 1, 'remove_decal': 2, 'fill_well': 3}.get(f['op'], 9))
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
    with open(os.path.join(REVIEW, 'log.jsonl'), 'a', encoding='utf-8', newline='\n') as f: f.write(json.dumps(st) + '\n')
    print('INSTALLED %s: %d changes; the old file is kept at %s; relocked: %s' % (piece, st['changes'], os.path.relpath(keep, L.REPO), locked))


if __name__ == '__main__':
    a = [x for x in sys.argv[1:] if not x.startswith('--')]
    opt = dict(x[2:].split('=', 1) for x in sys.argv[1:] if x.startswith('--') and '=' in x)
    if len(a) < 2: sys.exit(__doc__)
    if a[0] == 'check': cmd_check(a[1])
    elif a[0] == 'fix': sys.exit(0 if cmd_fix(a[1], opt.get('fixes')) else 1)
    elif a[0] == 'install': cmd_install(a[1], opt.get('by', ''))
    else: sys.exit(__doc__)
