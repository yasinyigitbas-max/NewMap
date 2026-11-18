#!/usr/bin/env python3
"""Streaming health check of a phone rig run: PASS or FAIL against the streaming budget, with the reasons.

    python tools/city/rig/health.py map_dc/coronado/city_kit/review/phone/stream_own.txt [more runs ...]

The budget (18 Nov 2026, Redmi, 3D at 720p). A run passes when, in every drive:
  - no cell is late (nothing missing within 220 m, nothing within 60 m), no collision late within 40 m;
  - no frame over 100 ms, at most MAX_OVER_50 frames over 50 ms, at most MAX_OVER_33_SHARE of the frames over 33 ms;
  - a teleport is ready within MAX_TELEPORT_MS and no frame while it loads is over MAX_TELEPORT_FRAME_MS;
  - a collision body is in the world within MAX_BODY_WAIT_MS of its cell's arrival;
  - the log has no error.
phone_rig.sh prints this after every run. Change a limit here, with a line in docs/RUNTIME_BAKE.md saying why.
"""
import re, sys

MAX_OVER_100 = 0
MAX_OVER_50 = 0
MAX_OVER_33_SHARE = 0.002          # 0.2 % of a drive's frames (60 fps: about 7 a minute)
MAX_TELEPORT_MS = 3000
MAX_TELEPORT_FRAME_MS = 50
MAX_BODY_WAIT_MS = 3000


def check(path):
    drives, cur, problems, errors = {}, None, [], 0
    for l in open(path, encoding='utf-8', errors='replace'):
        m = re.match(r'RIG drive (\S+) .*frames=(\d+) .*worst=(\d+) \| over16.7=[\d.]+% over33=(\d+) over50=(\d+) over100=(\d+)', l)
        if m:
            cur = m.group(1)
            drives[cur] = dict(frames=int(m.group(2)), worst=int(m.group(3)), o33=int(m.group(4)), o50=int(m.group(5)), o100=int(m.group(6)))
            continue
        m = re.match(r'RIG   stream (\S+) start_ready_ms=(\d+)(?: \(worst frame meanwhile (\d+) ms\))?.*late frames: 220m=(\d+).*60m=(\d+).*bodies late=(\d+)', l)
        if m and m.group(1) in drives:
            drives[m.group(1)].update(tp=int(m.group(2)), tpw=int(m.group(3) or 0), l220=int(m.group(4)), l60=int(m.group(5)), blate=int(m.group(6)))
            continue
        m = re.match(r'RIG   collision (\S+) .*waited at most (\d+) ms', l)
        if m and m.group(1) in drives:
            drives[m.group(1)]['bwait'] = int(m.group(2))
            continue
        if ('ERROR' in l or 'SCRIPT ERROR' in l) and not l.startswith('#'):
            errors += 1
    if not drives:
        return ['no drive in the file (the app did not get to the end of one)']
    for name, d in drives.items():
        def bad(msg): problems.append('%s: %s' % (name, msg))
        if d.get('l220', 0) or d.get('l60', 0): bad('late cells (220 m: %d frames, 60 m: %d frames)' % (d.get('l220', 0), d.get('l60', 0)))
        if d.get('blate', 0): bad('collision late within 40 m (%d frames)' % d['blate'])
        if d['o100'] > MAX_OVER_100: bad('%d frames over 100 ms (worst %d ms)' % (d['o100'], d['worst']))
        elif d['o50'] > MAX_OVER_50: bad('%d frames over 50 ms (worst %d ms)' % (d['o50'], d['worst']))
        if d['o33'] > max(1, int(d['frames'] * MAX_OVER_33_SHARE)): bad('%d of %d frames over 33 ms' % (d['o33'], d['frames']))
        if d.get('tp', 0) > MAX_TELEPORT_MS: bad('teleport ready after %d ms' % d['tp'])
        if d.get('tpw', 0) > MAX_TELEPORT_FRAME_MS: bad('a %d ms frame while the teleport loaded' % d['tpw'])
        if d.get('bwait', 0) > MAX_BODY_WAIT_MS: bad('a collision body waited %d ms' % d['bwait'])
    if errors: problems.append('%d error lines in the log' % errors)
    return problems


if __name__ == '__main__':
    rc = 0
    for p in sys.argv[1:]:
        pr = check(p)
        print('STREAM HEALTH %s  %s' % ('PASS' if not pr else 'FAIL', p.replace('\\', '/').split('/')[-1]))
        for x in pr: print('   - ' + x)
        rc |= 1 if pr else 0
    sys.exit(rc)
