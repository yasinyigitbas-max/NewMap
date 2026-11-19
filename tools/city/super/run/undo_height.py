"""Undo the height moves the superchecker made on props that already stood on their foot (19 Nov 2026, evening).

The 'in_air' / 'sunk' check measured under the middle of a prop's outline. For a signal mast (arm over the road), a
storm-drain grate or a kerb inlet beside a 15 cm kerb, that middle met the other level, so masts were pushed 15 cm into
the pavement and grates / inlets lifted 10 cm off the gutter. The check now trusts the ground under the origin (the
kit's foot). This puts each wrongly moved item back where it stood, one line per item (a move from where the fix put it
back to where it was), carried out on a copy and proved like every other fix.

  python -I tools/city/super/run/undo_height.py list            the items, from OUT/super/wrong_height_moves.json
  python -I tools/city/super/run/undo_height.py fix <piece>     build the undo list, fix on a copy, prove
After `sc.py install <piece> --by=Yasin` (Yasin's word for this run covers fixing the run's own mistakes), run
  python -I tools/city/super/run/undo_height.py records <piece>
which keeps the piece's first record as it was and files this one beside it as <piece>.undo_height.fixes.json / .proof.txt.
"""
import json, os, shutil, sys
sys.path.insert(0, 'tools/city/super')
import sc

R = 'map_dc/coronado/city_kit/review/superchecker/'
SAFE = 'OUT/super/undo_height'


def undo_list(piece):
    ns = set(json.load(open('OUT/super/wrong_height_moves.json'))[piece])
    first = json.load(open(R + piece + '.fixes.json'))
    out = []
    for f in first['fixes']:
        if f['n'] not in ns: continue
        out.append({'n': len(out) + 1, 'kind': 'undo_height', 'op': 'move', 'base': f['base'], 'cond': f.get('cond', 'normal'),
                    'at': f['to'], 'to': f['at'], 'mode': 'auto',
                    'reason': 'put back where it stood: the first run moved it %s (fix #%d, "%s") although its foot stood on the ground '
                              '(the check measured under its outline, which reaches over the kerb or the road)' % (
                                  'down' if f['kind'] == 'in_air' else 'up', f['n'], f.get('reason', '')[:80])})
    return out


def main():
    a = sys.argv[1:]
    if a[0] == 'list':
        d = json.load(open('OUT/super/wrong_height_moves.json'))
        print(' '.join(d)); return
    piece = a[1]
    if a[0] == 'fix':
        os.makedirs(SAFE, exist_ok=True)
        shutil.copy2(R + piece + '.fixes.json', os.path.join(SAFE, piece + '.fixes.json'))
        shutil.copy2(R + piece + '.proof.txt', os.path.join(SAFE, piece + '.proof.txt'))
        p = os.path.join(SAFE, piece + '.undo.json'); json.dump({'scene': piece, 'fixes': undo_list(piece)}, open(p, 'w'), indent=1)
        sc.cmd_fix(piece, p)
    elif a[0] == 'records':
        shutil.move(R + piece + '.fixes.json', R + piece + '.undo_height.fixes.json')
        shutil.move(R + piece + '.proof.txt', R + piece + '.undo_height.proof.txt')
        shutil.copy2(os.path.join(SAFE, piece + '.fixes.json'), R + piece + '.fixes.json')
        shutil.copy2(os.path.join(SAFE, piece + '.proof.txt'), R + piece + '.proof.txt')
        print('RECORDS %s: the first record kept, the undo filed beside it' % piece)


if __name__ == '__main__':
    main()
