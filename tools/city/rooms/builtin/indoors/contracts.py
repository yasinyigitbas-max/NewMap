"""All room contracts, merged as the bake merges them (interiors/room_contracts*.json, sorted, the first file's model wins)."""
import json, glob, os
def load(R):
    out = {}
    for f in sorted(glob.glob(os.path.join(R, 'room_contracts*.json'))):
        for m, c in json.load(open(f)).get('models', {}).items(): out.setdefault(m, c)
    return out
