#!/bin/bash
# STUDY CHECK (LOCKED): SessionStart hook (startup, resume, clear, compact). Its output goes into the session's context.
HERE=$(cd "$(dirname "$0")/.." && pwd)
LAB=$(cd "$HERE/.." && pwd)
echo "=== LAB B: the study is enforced. Read this before anything else (it is printed again after every compression). ==="
cat "$HERE/RULES.md"
echo
echo "=== Gate state ==="
H=$(bash "$HERE/hooks/code_hash.sh")
echo "code hash now: $H"
for m in quick full; do
	if [ -f "$HERE/results/${m}_${H}.txt" ]; then echo "$m gate for this code: $(tail -1 "$HERE/results/${m}_${H}.txt")"
	elif [ -f "$HERE/results/last_${m}.txt" ]; then echo "last $m gate (older code): $(tail -1 "$HERE/results/last_${m}.txt")"
	else echo "no $m gate run yet in this checkout"; fi
done
echo
echo "=== STATUS.md (top) ==="
sed -n '1,25p' "$LAB/STATUS.md" 2>/dev/null
echo "=== end of the lab B reminder. The repo's CLAUDE.md (city kit) tasks do not apply to you. ==="
