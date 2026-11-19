#!/bin/bash
# phase B for one piece, on Yasin's word of 19 Nov ("run it yourself ... fix everything"): install the proven piece, its
# tree piece and every proven room copy, lock test, commit, push. $2 = the commit message's first line.
PY=${SC_PY:-/c/Users/yasin/AppData/Local/Programs/Python/Python312/python}
P=$1
$PY -I tools/city/super/sc.py install $P --by=Yasin 2>&1 | grep -E "INSTALLED|trees:|needs|changed|no proven" || exit 1
for r in $($PY -I -c "import json,os; p='OUT/super/find/$P.rooms.json'; print(' '.join(json.load(open(p))['rooms']) if os.path.exists(p) else '')"); do
  [ -f OUT/super/work/$r.stamp.json ] && $PY -I tools/city/super/sc.py install-room $r --by=Yasin 2>&1 | grep -E "INSTALLED|changed"
done
R=$(timeout 900 ${SC_GODOT_HEADLESS:-/c/Users/yasin/Godot_v4.7.2-stable_win64.exe --headless} --path . -s res://tests/city_kit/test_locked_pieces.gd 2>&1 | grep -a "RESULT")
echo "lock test: $R"
case "$R" in *PASS*) ;; *) echo "LOCK TEST NOT PASS: nothing committed"; exit 1;; esac
git add map_dc/coronado/city_kit/pieces/$P.scn 'map_dc/coronado/city_kit/pieces/t_*.scn' map_dc/coronado/city_kit/city_grid_layout.json map_dc/coronado/city_kit/locked.json 'map_dc/coronado/city_kit/interiors/rooms/*.scn' map_dc/coronado/city_kit/review/superchecker map_dc/coronado/city_kit/zoning/trees tools/city/super
git commit -q -F - <<MSG
$2

Every change is a line of review/superchecker/$P.fixes.json (and of each room's), with its reason and its proof
(PROOF RESULT PASS) beside it. Yasin's word for this run: "run it yourself ... make judgement calls and fix
everything ... when in doubt erase problematic props". Lock test RESULT PASS.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
MSG
# pull and push, keeping both sessions' entries when they installed at the same time (resolve.py); up to 6 tries
for t in 1 2 3 4 5 6; do
  if ! git pull -q --rebase origin claude/festive-faraday-20ltx2 >/dev/null 2>&1; then
    $PY -I tools/city/super/run/resolve.py || { echo "CONFLICT NOT RESOLVED: stopped"; exit 1; }
    GIT_EDITOR=true git rebase --continue >/dev/null 2>&1 || { echo "REBASE NOT FINISHED: stopped"; exit 1; }
  fi
  git push -q origin HEAD:claude/festive-faraday-20ltx2 2>/dev/null && break
  sleep 4
done
git status -sb | head -1 | grep -q ahead && echo "NOT PUSHED"
git log --oneline -1 | cut -c1-110
