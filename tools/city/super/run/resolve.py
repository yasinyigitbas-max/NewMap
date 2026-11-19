"""Resolve the conflicts two superchecker sessions make when both install pieces at the same time (19 Nov 2026).
They change DIFFERENT pieces, so the right result always keeps both sides' entries:
  locked.json                    every entry the other side changed, plus every entry this side changed (by key)
  review/superchecker/log.jsonl  every line of both sides, each once
  city_grid_layout.json          every row of both sides, each once (tree pieces are appended at the end)
Then checks that each locked entry's sha256 matches its file on disk. Run inside a stopped rebase; it stages the files.
"""
import hashlib, json, os, subprocess, sys

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '../../../..'))
CK = 'map_dc/coronado/city_kit/'


def stage(n, path):
    r = subprocess.run(['git', 'show', ':%d:%s' % (n, path)], cwd=ROOT, capture_output=True)
    return r.stdout.decode('utf-8') if r.returncode == 0 else None


def conflicted():
    r = subprocess.run(['git', 'diff', '--name-only', '--diff-filter=U'], cwd=ROOT, capture_output=True, text=True)
    return [l for l in r.stdout.splitlines() if l]


def merge_dict(base, a, b):
    out = dict(a)
    for k, v in b.items():
        if base.get(k) != v: out[k] = v
    for k in base:
        if k not in b and k in out and base[k] == out[k]: out.pop(k)      # removed on this side, untouched on the other
    return out


def main():
    left = conflicted(); done = []
    for path in left:
        if path == CK + 'locked.json':
            base = json.loads(stage(1, path) or '{}'); a = json.loads(stage(2, path)); b = json.loads(stage(3, path))
            res = dict(a)
            for sec in ('pieces', 'files'):
                res[sec] = merge_dict(base.get(sec, {}), a.get(sec, {}), b.get(sec, {}))
            with open(os.path.join(ROOT, path), 'w', encoding='utf-8', newline='\n') as f:
                json.dump(res, f, indent=1); f.write('\n')
            bad = []
            for k, e in res['pieces'].items():
                p = os.path.join(ROOT, CK + 'pieces', k + '.scn')
                if os.path.exists(p) and hashlib.sha256(open(p, 'rb').read()).hexdigest() != e['sha256']: bad.append(k)
            for k, e in res.get('files', {}).items():
                p = os.path.join(ROOT, k)
                if os.path.exists(p) and hashlib.sha256(open(p, 'rb').read()).hexdigest() != (e['sha256'] if isinstance(e, dict) else e): bad.append(k)
            if bad: print('RESOLVE locked.json: entries that do not match their file:', bad[:8]); sys.exit(1)
        elif path.endswith('log.jsonl'):
            seen = [];
            for t in (stage(2, path) or '', stage(3, path) or ''):
                for l in t.splitlines():
                    if l.strip() and l not in seen: seen.append(l)
            open(os.path.join(ROOT, path), 'w', encoding='utf-8', newline='\n').write('\n'.join(seen) + '\n')
        elif path == CK + 'city_grid_layout.json':
            a = json.loads(stage(2, path)); b = json.loads(stage(3, path)); rows = list(a['instances'])
            for r in b['instances']:
                if r not in rows: rows.append(r)
            a['instances'] = rows
            json.dump(a, open(os.path.join(ROOT, path), 'w'), indent=1)
        else:
            print('RESOLVE: a conflict in %s is not one this tool knows: resolve it by hand' % path); sys.exit(1)
        subprocess.run(['git', 'add', path], cwd=ROOT, check=True); done.append(path)
    print('RESOLVE kept both sides in: %s' % ', '.join(done))


if __name__ == '__main__':
    main()
