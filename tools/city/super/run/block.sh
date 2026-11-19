#!/bin/bash
# one piece end to end, up to (not including) its trees and install: check, decide (delete when unsure), apply, fix,
# and when the copy shows new faults, erase the moved items that caused them and fix again (at most 3 rounds)
PY=${SC_PY:-/c/Users/yasin/AppData/Local/Programs/Python/Python312/python}
P=$1; D=OUT/super/decisions/$P.txt
$PY -I tools/city/super/sc.py check $P 2>&1 | grep -E "SUPERCHECK|one right" | cut -c1-160
$PY -I tools/city/super/sc_review.py decide $P $D | tail -1
$PY -I tools/city/super/sc_review.py apply $P $D | tail -1
for round in 1 2 3; do
  OUTF=$($PY -I tools/city/super/sc.py fix $P 2>&1)
  echo "$OUTF" | grep -E "REFUSED|LEFT|PROOF RESULT|NOT DONE" | cut -c1-160
  NEW=$($PY -I tools/city/super/run/who.py $P | grep -o "(\([0-9]*\), '[a-z_0-9]*')" | sed "s/(\([0-9]*\),.*/\1/" | sort -u)
  [ -z "$NEW" ] && break
  echo "round $round: new faults from my lines: $(echo $NEW | tr '\n' ' ')"
  : > $D.more; for n in $NEW; do echo "erase $n its new place made a new fault: deleted instead" >> $D.more; done
  cat $D.more >> $D; $PY -I tools/city/super/sc_review.py apply $P $D.more | tail -1
done
$PY -I -c "
import json,os
d=json.load(open('OUT/super/find/$P.faults.json'))
t=[(f['item']['base'],[round(v,1) for v in f['at']]) for f in d['faults'] if f['kind']=='tree_out']
print('TREES that stood here: %d' % len(t), d.get('pos'))
rp='OUT/super/find/$P.rooms.json'
print('ROOMS:', ' '.join(json.load(open(rp))['rooms']) if os.path.exists(rp) else '')
"
