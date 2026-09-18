#!/usr/bin/env python3
"""Generate the 8 World-1 exercise item icons with PixelLab (pixflux) and
install them at godot/assets/ui/items/<id>.png (32x32, transparent bg).

Usage: PIXELLAB_KEY=... python3 scripts/gen-item-icons.py [ids...]
"""
import base64, json, os, sys, time, urllib.request, urllib.error, pathlib

KEY = os.environ.get("PIXELLAB_KEY") or sys.exit("PIXELLAB_KEY missing")
ROOT = pathlib.Path(__file__).resolve().parent.parent
OUT = ROOT / "godot/assets/ui/items"
OUT.mkdir(parents=True, exist_ok=True)

STYLE = ("cute pixel art game item icon, single object centered, top-down 3/4 view, "
         "clean black outline, soft cel shading, warm farm palette, no text, no background")
ITEMS = {
    "egg":      "a single white chicken egg with a light brown speckle",
    "carrot":   "a single orange carrot with green leafy top",
    "hay-bale": "a small rectangular golden hay bale tied with two brown strings",
    "chick":    "a single fluffy yellow baby chick facing front",
    "bandage":  "a single rolled white medical bandage with a pink cross sticker",
    "tomato":   "a single ripe red tomato with a green stem",
    "nail":     "a single grey iron nail, slightly angled",
    "key":      "a single old brass skeleton key",
}

def gen(desc, seed):
    body = json.dumps({
        "description": f"{desc}, {STYLE}",
        "image_size": {"width": 32, "height": 32},
        "no_background": True,
        "outline": "single color black outline",
        "shading": "basic shading",
        "detail": "medium detail",
        "view": "high top-down",
        "text_guidance_scale": 8,
        "seed": seed,
    }).encode()
    req = urllib.request.Request("https://api.pixellab.ai/v2/create-image-pixflux", data=body,
        headers={"Authorization": f"Bearer {KEY}", "Content-Type": "application/json"})
    for attempt in range(4):
        try:
            with urllib.request.urlopen(req, timeout=180) as r:
                d = json.load(r)
            b64 = d["image"]["base64"].split(",", 1)[-1]
            return base64.b64decode(b64), d.get("usage")
        except urllib.error.HTTPError as e:
            msg = e.read().decode()[:300]
            if e.code in (429, 503, 529) and attempt < 3:
                time.sleep(8 * (attempt + 1)); continue
            raise SystemExit(f"{e.code}: {msg}")
    raise SystemExit("gave up")

ids = sys.argv[1:] or list(ITEMS)
for i, item in enumerate(ids):
    png, usage = gen(ITEMS[item], 1000 + i)
    (OUT / f"{item}.png").write_bytes(png)
    print(f"ok {item:9s} {len(png):6d} B  usage={usage}")
