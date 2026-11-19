#!/bin/bash
# claim.sh <piece> <who>: claim one piece of review/superchecker/ORDER.txt before working on it, so two sessions never
# work on the same piece. Exit 0 = claimed by <who> now; exit 1 = already claimed or done by someone (stop or skip).
P=$1; WHO=$2; C=map_dc/coronado/city_kit/review/superchecker/claims/$P
git pull -q --rebase --autostash origin claude/festive-faraday-20ltx2 >/dev/null 2>&1
[ -f "$C" ] && { echo "CLAIMED ALREADY: $P by $(cat $C)"; exit 1; }
[ -f map_dc/coronado/city_kit/review/superchecker/$P.fixes.json ] && { echo "DONE ALREADY: $P"; exit 1; }
mkdir -p $(dirname $C); echo "$WHO $(date -u +%Y-%m-%dT%H:%MZ)" > $C
git add $C && git commit -q -m "superchecker: $WHO claims $P

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>" -- $C
if ! git push -q origin claude/festive-faraday-20ltx2 2>/dev/null; then
  git reset -q --soft HEAD~1; git restore --staged $C 2>/dev/null; rm -f $C
  git pull -q --rebase --autostash origin claude/festive-faraday-20ltx2 >/dev/null 2>&1
  [ -f "$C" ] && { echo "CLAIMED ALREADY: $P by $(cat $C)"; exit 1; }
  echo "PUSH REFUSED: try again"; exit 2
fi
echo "CLAIMED: $P by $WHO"
