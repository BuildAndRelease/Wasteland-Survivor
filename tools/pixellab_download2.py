#!/usr/bin/env python3
"""Download all completed PixelLab assets via background job results."""
import json, base64, os, urllib.request, urllib.error
from pathlib import Path

API = "https://api.pixellab.ai/v2"
TOKEN = os.environ.get("PIXELLAB_TOKEN", "")
OUT = str((Path(__file__).resolve().parent.parent / "assets" / "generated"))

def api_get(endpoint):
    url = f"{API}{endpoint}"
    req = urllib.request.Request(url, headers={"Authorization": f"Bearer {TOKEN}"})
    with urllib.request.urlopen(req, timeout=60) as resp:
        return json.loads(resp.read())

def download_url(url, path):
    req = urllib.request.Request(url)
    with urllib.request.urlopen(req, timeout=30) as resp:
        data = resp.read()
        with open(path, "wb") as f:
            f.write(data)
        return len(data)

def save_b64(b64_str, path):
    data = base64.b64decode(b64_str)
    with open(path, "wb") as f:
        f.write(data)
    return len(data)

# --- Object jobs (from first run, all completed) ---
OBJECT_JOBS = {
    "ruined_wall": "911a3745-e3a7-4942-92bb-9c431583364d",
    "wrecked_car": "a39802fd-1502-41f5-9697-b42088ff3403",
    "large_rock": "30ce6ae7-2c51-4e5b-a5c6-7498c37d3ffe",
    "dead_tree": "a227512a-1e9e-489b-9d38-b474bbfa7f9c",
    "metal_debris": "3b839f39-2729-4956-8179-668790c3cbbb",
    "xp_gem": "41701bc3-b849-4deb-bff6-9aebc0db4fe4",
    "scrap_coin": "bdeb85e1-1bc8-4edf-b609-df1929732336",
    "health_pack": "9fe05c3a-a216-4964-9a54-c970aa0c95d9",
}

TILESET_ID = "b1a99000-29ea-4c69-93bb-4e1dff83a19c"

print("=== Downloading Objects from Background Jobs ===\n")

for name, job_id in OBJECT_JOBS.items():
    dest_dir = os.path.join(OUT, "pickups" if name in ("xp_gem", "scrap_coin", "health_pack") else "objects")
    os.makedirs(dest_dir, exist_ok=True)
    
    resp = api_get(f"/background-jobs/{job_id}")
    status = resp.get("status", "unknown")
    
    if status != "completed":
        print(f"  ⚠️  {name}: status={status}")
        continue
    
    lr = resp.get("last_response", {})
    b64 = lr.get("image", "")
    url = lr.get("storage_url", "")
    
    path = os.path.join(dest_dir, f"{name}.png")
    
    if b64:
        sz = save_b64(b64, path)
        print(f"  ✅ {name}: saved from base64 ({sz} bytes)")
    elif url:
        try:
            sz = download_url(url, path)
            print(f"  ✅ {name}: saved from URL ({sz} bytes)")
        except Exception as e:
            print(f"  ❌ {name}: URL failed: {e}")
    else:
        print(f"  ⚠️  {name}: no image data")

print("\n=== Downloading Tileset ===")
ts_dir = os.path.join(OUT, "tileset")
os.makedirs(ts_dir, exist_ok=True)
resp = api_get(f"/tilesets/{TILESET_ID}")
tileset = resp.get("tileset", {})
tiles = tileset.get("tiles", [])
count = 0
for tile in tiles:
    tid = tile.get("id", str(count))
    img = tile.get("image", {})
    b64 = img.get("base64", "")
    if b64:
        path = os.path.join(ts_dir, f"tile_{tid}.png")
        save_b64(b64, path)
        count += 1
print(f"  ✅ Tileset: {count} tiles saved")

# Check character jobs from first run (they all failed due to concurrent limit)
print("\n=== Checking Character Jobs (first run - expected failures) ===")
CHAR_JOBS_FIRST = {
    "survivor": "9696e31b-5fee-4c36-b329-82fa31df80a0",
    "scavenger": "4ab958c3-35c0-4b86-b4ca-ac60aab69217",
    "demolisher": "0b5fe5a8-cfef-473c-81da-6c922ba605f3",
    "mutant": "6f57a21e-ffc5-4f71-b439-763f1c4e40a1",
    "walker": "e9915a84-7805-45c5-9acc-b95542549879",
    "mutant_dog": "71f099f0-9c99-4d6d-9c93-48eb5db986ef",
    "acid_bug": "031aece6-1951-41e8-b582-375b4500e397",
    "iron_giant": "44700024-3193-41dd-9d1c-8f8c88402218",
    "exploder": "784c8105-467b-45a7-8d9c-4a7d86cafbeb",
    "boss_ash_behemoth": "2d6d8654-a11e-4a1d-ad94-dbfce3b39e81",
}
for name, job_id in CHAR_JOBS_FIRST.items():
    resp = api_get(f"/background-jobs/{job_id}")
    status = resp.get("status", "unknown")
    print(f"  {name}: {status}")

print("\n=== Balance ===")
bal = api_get("/balance")
print(f"  Generations: {bal.get('subscription', {}).get('generations', '?')}")
print("\nDone!")
