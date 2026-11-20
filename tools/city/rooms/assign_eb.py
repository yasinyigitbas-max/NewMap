"""eb fill (claude/fill-high-street, 20 Nov): which business or service is behind which shop door of the eb
pieces (n_eb_*), the east shore beyond the ring (copy of assign_fe.py). A hand list, one line per walk-in place, with the reason; the bay split comes from the building's
contract (room_contracts.json, the same rule as every other shop of the map: assign_all.bays). Writes
interiors/assignment_eb.json in assignment_all.json's format, for tools/city/rooms/room_gen_hp.gd
(--assign=assignment_eb.json --report=rooms_eb_report.json). The shared assignment files are not touched.
Run from the repo root: python3 -I tools/city/rooms/assign_eb.py
"""
import json, os, sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", ".."))
IN = os.path.join(ROOT, "map_dc/coronado/city_kit/interiors")
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from assign_all import bays

# piece, label, model, local pos, yaw, door index, kind, name, sign style, pad (the piece's layout row height), why
SHOPS = [
    ("n_eb_ne", "kiosk", "commercial/com_kiosk", (1050.0, 3.3556, -1032.0), 90.0, 0, "cafe", "Bridge Beach Snack Shack", "", 0.0,
     "the walk-up counter of Bridge Beach: cold drinks, ice cream and hot dogs for the families on the sand north of the bridge"),
    ("n_eb_me", "cafe", "commercial/com_cafe_seaside", (1178.0, 3.0997, -722.0), 90.0, 0, "cafe", "Bayshore Beach Cafe", "", 0.0,
     "the beach park's cafe in the middle of the shore: coffee, lunch and ice tea, its terrace on the promenade"),
    ("n_eb_se", "hire", "commercial/com_surf_shop", (1138.0, 3.0389, -630.0), 90.0, 0, "sport", "Bayshore Paddle Hire", "", 0.0,
     "kayaks, paddle boards and wetsuits to hire on the widest beach, at the end of the Glorietta Walk"),
]


def main():
    rc = json.load(open(os.path.join(IN, "room_contracts.json")))["models"]
    rc.update(json.load(open(os.path.join(IN, "room_contracts_hp.json")))["models"])
    out = []
    for piece, label, model, pos, yaw, di, kind, name, style, pad, why in SHOPS:
        c = rc[model]
        bl = bays(c)
        if not bl:
            # the walk-up kiosk (com_kiosk): its one front door is a "residential" kind in its contract, so bays() finds no
            # shop door; the whole floor is the room behind it (as the waterfront's and the campus's kiosks)
            fl = c["floors"][0]; e0 = [x for x in c["entrances"] if x["facade"] == "front"][0]
            bl = [(0, e0, float(fl["box_min"][0]), float(fl["box_max"][0]))]
        i, e, a, b = bl[di]
        boards = []
        if style:
            for sg in c.get("signs", []):
                if sg["facade"] == "front" and a - 0.05 <= sg["along"] <= b + 0.05: boards.append(sg)
                elif sg["facade"] == "left" and i == 0: boards.append(sg)
                elif sg["facade"] == "right" and b >= float(c["floors"][0]["box_max"][0]) - 0.05: boards.append(sg)
        rid = "%s_%s_%s_%d" % (piece[2:4], piece[5:], label, i)
        out.append({"id": rid, "piece": piece, "label": label, "model": model, "pos": [pos[0], pos[1] + pad, pos[2]], "yaw": yaw,
                    "door_index": i, "door_along": e["along"], "door_w": e["w"], "bay": [round(a, 3), round(b, 3)],
                    "kind": kind, "name": name, "style": style or "green", "font": "Overpass", "built": "", "why": why,
                    "signs": [{"facade": x["facade"], "along": x["along"], "w": x["w"]} for x in boards]})
    json.dump({"_doc": __doc__.strip().split("\n")[0], "count": len(out), "rooms": out}, open(os.path.join(IN, "assignment_eb.json"), "w"), indent=1)
    print("assignment_eb.json: %d rooms" % len(out))
    for r in out:
        print("  %-34s %-10s %-30s bay %s signs %d" % (r["id"], r["kind"], r["name"], r["bay"], len(r["signs"])))


if __name__ == "__main__":
    main()
