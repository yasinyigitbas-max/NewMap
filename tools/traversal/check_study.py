#!/usr/bin/env python3
"""The study gate for the traversal work (traversal_lab/).

Why it exists (Yasin, 26 Nov 2026): the build drifted from the movement study while reports said it followed it, and
checks were loosened or invented mid-work until they passed. This tool makes three things mechanical:

  verify   every bar in traversal_lab/study/bars.json is a word-for-word quote of the study (or of its sourced
           notes) and every number of the bar is printed in that quote; the locked check files are unchanged.
  gate     run by git (commit-msg hook, .githooks/commit-msg) on any commit that touches traversal_lab/:
             - the bars must verify;
             - the locked check files (bars.json, tests/audit.gd) must match study/checks.lock, and a commit that
               changes them or the lock is refused unless its message says so and quotes Yasin's word for it;
             - a commit that touches the movement code or clips must quote the study lines it relies on
               (each checked word for word), or say the study is silent;
             - the audit must have been run on exactly the code being committed, and its true result is written
               into the commit message by this tool, so a commit cannot claim more than the audit showed.
  lock     record the present check files in study/checks.lock (only at Yasin's word: --by=Yasin --words="...").
  remind   print the study's rules and bars (used by the session hooks after a context compression).
  tree     print the hash of the audited files (what the audit stamps its result with).

Run with:  python3 -I tools/traversal/check_study.py <command>
"""
import hashlib
import json
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
LAB = "traversal_lab"
BARS = LAB + "/study/bars.json"
LOCK = LAB + "/study/checks.lock"
RESULT = LAB + "/study/audit_result.json"
LOCKED = [BARS, LAB + "/tests/audit.gd"]
AUDITED_DIRS = [LAB + "/traversal/"]
AUDITED_EXT = (".gd", ".res", ".scn", ".tscn", ".json")
SILENT = "the study is silent on this, the number is mine"
WORDS = {"one": 1, "two": 2, "three": 3, "four": 4, "five": 5}
KINDS = {"range", "single", "spread", "max", "min", "under", "ratio", "sum_range", "always", "flag", "info", "not_built"}


def norm(text):
    """Quotes are compared with markdown stars removed and all white space collapsed."""
    return re.sub(r"\s+", " ", text.replace("*", "")).strip()


def git(*args, check=True):
    r = subprocess.run(["git", "-C", ROOT] + list(args), capture_output=True)
    if check and r.returncode != 0:
        raise SystemExit("git %s failed: %s" % (" ".join(args), r.stderr.decode(errors="replace")))
    return r.stdout


def read_work(path):
    with open(os.path.join(ROOT, path), "rb") as f:
        return f.read()


def read_staged(path):
    r = subprocess.run(["git", "-C", ROOT, "show", ":" + path], capture_output=True)
    return r.stdout if r.returncode == 0 else None


def has_number(quote, token):
    """`token` (a number as printed, or a number word) stands in `quote` as a whole number, not part of a longer one."""
    return re.search(r"(?<![\d.])" + re.escape(token) + r"(?!\d|\.\d)", quote) is not None


def bounds(bar, pct):
    """The pass range of a bar as (lo, hi); None = no bound on that side or not a judged bar."""
    k = bar["kind"]
    if k == "range":
        return float(bar["lo"]), float(bar["hi"])
    if k == "single":
        v = float(bar["value"])
        return v * (1 - pct / 100.0), v * (1 + pct / 100.0)
    if k == "spread":
        v = float(bar["value"])
        sd = float(bar["sd"]) * float(bar.get("sd_scale", 1.0))
        return v - sd, v + sd
    if k == "max":
        return None, float(bar["value"])
    if k == "min":
        return float(bar["value"]), None
    if k == "under":
        return None, float(bar["value"])
    if k == "ratio":
        v = float(bar["num"]) / float(bar["den"])
        return v * (1 - pct / 100.0), v * (1 + pct / 100.0)
    if k == "sum_range":
        return sum(float(x) for x in bar["los"]), sum(float(x) for x in bar["his"])
    if k == "always":
        return 100.0 - pct, 100.0
    return None, None


def verify_bars(data, texts):
    """Returns a list of faults (empty = every quote and number is in the files)."""
    faults = []
    quotes = data.get("quotes", {})
    for key, (which, text) in quotes.items():
        if which not in texts:
            faults.append("quote %s: unknown file '%s'" % (key, which))
        elif norm(text) not in texts[which]:
            faults.append("quote %s is NOT word for word in %s: \"%s\"" % (key, data["files"][which], text))
    seen = set()
    for bar in data.get("bars", []):
        bid = bar.get("id", "?")
        if bid in seen:
            faults.append("bar %s: listed twice" % bid)
        seen.add(bid)
        if bar.get("kind") not in KINDS:
            faults.append("bar %s: unknown kind %s" % (bid, bar.get("kind")))
            continue
        if bar.get("q") not in quotes:
            faults.append("bar %s: no quote '%s'" % (bid, bar.get("q")))
            continue
        q = norm(quotes[bar["q"]][1])
        q2 = norm(quotes[bar["q2"]][1]) if bar.get("q2") in quotes else ""
        if "q2" in bar and not q2:
            faults.append("bar %s: no quote '%s'" % (bid, bar.get("q2")))
        if "q_also" in bar and bar["q_also"] not in quotes:
            faults.append("bar %s: no quote '%s'" % (bid, bar["q_also"]))

        def need(field, where, label):
            token = bar.get(field + "_text", bar.get(field))
            if token is None:
                faults.append("bar %s: missing %s" % (bid, field))
                return
            if field + "_text" in bar and WORDS.get(bar[field + "_text"]) != float(bar[field]):
                faults.append("bar %s: '%s' is not the number %s" % (bid, bar[field + "_text"], bar[field]))
            if not has_number(where, str(token)):
                faults.append("bar %s: its %s '%s' is not printed in its %s" % (bid, field, token, label))

        k = bar["kind"]
        if k == "range":
            need("lo", q, "quote")
            need("hi", q, "quote")
        elif k in ("single", "max", "min", "under"):
            need("value", q, "quote")
        elif k == "spread":
            need("value", q, "quote")
            need("sd", q2, "second quote")
        elif k == "ratio":
            need("num", q, "quote")
            need("den", q, "quote")
        elif k == "sum_range":
            for tok in bar.get("los", []) + bar.get("his", []):
                if not has_number(q, tok):
                    faults.append("bar %s: '%s' is not printed in its quote" % (bid, tok))
    return faults


def load_texts(data, reader):
    texts = {}
    for which, path in data["files"].items():
        raw = reader(path)
        if raw is None:
            raise SystemExit("cannot read " + path)
        texts[which] = norm(raw.decode("utf-8"))
    return texts


def sha(blob):
    return hashlib.sha256(blob).hexdigest()


def tree_hash(reader, names):
    """One hash over the audited files: the movement code and clips, the bars and the audit itself."""
    h = hashlib.sha256()
    for name in sorted(names):
        blob = reader(name)
        if blob is None:
            continue
        h.update(("%s %s\n" % (name[len(LAB) + 1:], sha(blob))).encode())
    return h.hexdigest()


def audited_names(listing):
    out = [n for n in listing if any(n.startswith(d) for d in AUDITED_DIRS) and n.endswith(AUDITED_EXT)]
    return out + LOCKED


def work_listing():
    out = []
    for d in AUDITED_DIRS:
        for base, _dirs, files in os.walk(os.path.join(ROOT, d)):
            for f in files:
                out.append(os.path.relpath(os.path.join(base, f), ROOT).replace(os.sep, "/"))
    return out


def lock_state(reader):
    """(faults, lock) for the locked check files as `reader` sees them."""
    raw = reader(LOCK)
    if raw is None:
        return ["no lock file (%s): the checks have never been locked" % LOCK], {}
    lock = json.loads(raw.decode("utf-8"))
    faults = []
    for path in LOCKED:
        blob = reader(path)
        if blob is None:
            faults.append("locked check file missing: " + path)
        elif lock.get("files", {}).get(path) != sha(blob):
            faults.append("locked check file CHANGED since it was locked: " + path)
    return faults, lock


def cmd_verify():
    data = json.loads(read_work(BARS).decode("utf-8"))
    faults = verify_bars(data, load_texts(data, read_work))
    judged = [b for b in data["bars"] if b["kind"] not in ("info", "not_built")]
    print("%d bars (%d judged, %d information only, %d for stages not built), %d quotes" % (
        len(data["bars"]), len(judged), sum(b["kind"] == "info" for b in data["bars"]),
        sum(b["kind"] == "not_built" for b in data["bars"]), len(data["quotes"])))
    for f in faults:
        print("FAULT  " + f)
    lock_faults, lock = lock_state(lambda p: read_work(p) if os.path.exists(os.path.join(ROOT, p)) else None)
    for f in lock_faults:
        print("LOCK   " + f)
    if not lock_faults:
        print("locked by %s: \"%s\"" % (lock.get("by", "?"), lock.get("words", "")))
    print("RESULT " + ("PASS" if not faults and not lock_faults else "FAIL"))
    return 1 if faults or lock_faults else 0


def cmd_lock(args):
    by = ""
    words = ""
    for a in args:
        if a.startswith("--by="):
            by = a[5:]
        if a.startswith("--words="):
            words = a[8:]
    if by != "Yasin" or not words:
        print("The checks are locked and unlocked only at Yasin's word:  lock --by=Yasin --words=\"<what he said>\"")
        return 1
    data = json.loads(read_work(BARS).decode("utf-8"))
    faults = verify_bars(data, load_texts(data, read_work))
    if faults:
        for f in faults:
            print("FAULT  " + f)
        print("not locked: the bars do not verify against the study")
        return 1
    lock = {"by": by, "words": words, "files": {p: sha(read_work(p)) for p in LOCKED}}
    with open(os.path.join(ROOT, LOCK), "w", newline="\n") as f:
        json.dump(lock, f, indent=2)
        f.write("\n")
    print("locked: " + ", ".join(LOCKED))
    return 0


def cmd_tree():
    print(tree_hash(read_work, audited_names(work_listing())))
    return 0


def cmd_gate(msg_path):
    staged = git("diff", "--cached", "--name-only").decode().split("\n")
    staged = [s for s in staged if s]
    if not any(s.startswith(LAB + "/") for s in staged):
        return 0
    with open(msg_path, encoding="utf-8") as f:
        msg = f.read()
    body = "\n".join(line for line in msg.split("\n") if not line.startswith("#"))
    refuse = []
    notes = []

    # 1. the bars are the study's own words
    raw = read_staged(BARS)
    if raw is None:
        refuse.append("%s is not in the commit" % BARS)
        data = None
    else:
        data = json.loads(raw.decode("utf-8"))
        for f in verify_bars(data, load_texts(data, read_staged)):
            refuse.append(f)

    # 2. the locked checks
    lock_faults, _lock = lock_state(read_staged)
    refuse.extend(lock_faults)
    changed = [p for p in LOCKED + [LOCK] if p in staged]
    if changed:
        says = re.search(r"^Checks-changed: .+", body, re.M)
        word = re.search(r"^Yasin: \".+\"", body, re.M)
        if not says or not word:
            refuse.append("this commit CHANGES THE CHECKS (%s). The checks are locked. A change needs, in the message,"
                          " a line 'Checks-changed: <what and why>' and a line 'Yasin: \"<his words allowing it>\"'."
                          " Do not change a check to make it pass." % ", ".join(changed))
        else:
            notes.append("*** THE CHECKS CHANGED IN THIS COMMIT: %s ***" % ", ".join(changed))

    # 3. movement code or clips: quote the study, or say it is silent
    moves = [s for s in staged if s.startswith(LAB + "/traversal/")]
    if moves and data is not None:
        texts = load_texts(data, read_staged)
        quotes = re.findall(r"^Study: \"(.+)\"\s*$", body, re.M)
        silent = re.search(r"^Study: " + re.escape(SILENT), body, re.M)
        if not quotes and not silent:
            refuse.append("this commit changes the movement code or clips. Its message must carry one or more lines"
                          " 'Study: \"<a sentence of the study this change follows, word for word>\"', or the line"
                          " 'Study: %s'." % SILENT)
        for q in quotes:
            if not any(norm(q) in t for t in texts.values()):
                refuse.append("not word for word in the study or its notes: \"%s\"" % q)

    # 4. the audit, run on exactly this code, and its true result
    names = audited_names(git("ls-files", "-c", "--", *AUDITED_DIRS).decode().split("\n"))
    want = tree_hash(read_staged, [n for n in names if n])
    res_raw = read_staged(RESULT)
    if moves or changed:
        if res_raw is None:
            refuse.append("no audit result in the commit (%s): run the audit first" % RESULT)
        else:
            res = json.loads(res_raw.decode("utf-8"))
            if res.get("tree") != want:
                refuse.append("the audit was not run on the code being committed (its stamp %s..., this code %s...)."
                              " Run:  godot --headless --fixed-fps 60 --path traversal_lab -s res://tests/audit.gd"
                              "  and add %s" % (str(res.get("tree"))[:10], want[:10], RESULT))
            else:
                fails = res.get("fails", [])
                line = "Audit (written by the gate, not by hand): %d of %d study lines FAIL" % (len(fails), res.get("judged", 0))
                if fails:
                    line += ": " + ", ".join(fails)
                if res.get("outside_off"):
                    line += ". Outside the study, off our own figure: " + ", ".join(res["outside_off"])
                notes.append(line + ".")

    if refuse:
        sys.stderr.write("\nSTUDY GATE: commit refused.\n")
        for r in refuse:
            sys.stderr.write("  - " + r + "\n")
        sys.stderr.write("(tools/traversal/check_study.py; the rules are in traversal_lab/study/README.md)\n\n")
        return 1
    if notes:
        lines = msg.rstrip("\n").split("\n")
        # keep git trailers (Co-Authored-By and the like) last
        cut = len(lines)
        while cut > 0 and re.match(r"^[A-Za-z-]+: \S", lines[cut - 1]) and not lines[cut - 1].startswith(("Study:", "Yasin:", "Checks-changed:")):
            cut -= 1
        lines[cut:cut] = notes + ([""] if cut < len(lines) else [])
        with open(msg_path, "w", encoding="utf-8", newline="\n") as f:
            f.write("\n".join(lines) + "\n")
    return 0


def cmd_remind():
    subjects = git("log", "-8", "--format=%s", check=False).decode().split("\n")
    if "--always" not in sys.argv and not any(s.startswith("trav") for s in subjects):
        return 0
    study = read_work("reports/Hybrid character traversal study.md").decode("utf-8")
    print("=== TRAVERSAL WORK: THE STUDY IS THE AUTHORITY (Yasin, 26 Nov: 'follow it like the holy book') ===")
    print("Your memory of the study is gone after a compression. Before ANY step on traversal_lab/: open and read")
    print("reports/Hybrid character traversal study.md again with the Read tool (all 810 lines), then")
    print("traversal_lab/study/README.md. The checks are LOCKED: never change a bar or a check to make it pass.")
    print()
    data = json.loads(read_work(BARS).decode("utf-8"))
    pct = float(data["margin_rule"]["single_percent"])
    print("--- The audit's bars (traversal_lab/study/bars.json), each one a quote of the study ---")
    for bar in data["bars"]:
        lo, hi = bounds(bar, pct)
        rng = ""
        if lo is not None and hi is not None:
            rng = "%g to %g" % (round(lo, 3), round(hi, 3))
        elif hi is not None:
            rng = ("under %g" if bar["kind"] == "under" else "at most %g") % hi
        elif lo is not None:
            rng = "at least %g" % lo
        print("%-22s %-10s %-18s %s" % (bar["id"], bar["kind"], rng, bar.get("unit", "")))
    part1 = study[study.index("### 1. A walking body moves very little"):study.index("### 3. A Mixamo clip is hip movement")]
    part2 = study[study.index("## Part 2. Recommendation"):study.index("## Part 3. Your Mixamo clips, measured")]
    print()
    print("--- The study, Part 1 sections 1 and 2 (how people move), word for word ---")
    print(part1)
    print("--- The study, Part 2 (the design and the build order), word for word ---")
    print(part2)
    return 0


def main():
    cmd = sys.argv[1] if len(sys.argv) > 1 else "verify"
    if cmd == "verify":
        return cmd_verify()
    if cmd == "lock":
        return cmd_lock(sys.argv[2:])
    if cmd == "tree":
        return cmd_tree()
    if cmd == "gate":
        return cmd_gate(sys.argv[2])
    if cmd == "remind":
        return cmd_remind()
    print(__doc__)
    return 1


if __name__ == "__main__":
    sys.exit(main())
