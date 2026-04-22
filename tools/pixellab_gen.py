#!/usr/bin/env python3
"""
PixelLab asset generator & downloader for Wasteland Survivor.
Handles: rate limits (max 3 concurrent jobs), retries, and download.
"""
import json, time, base64, os, sys, urllib.request, urllib.error, zipfile, io
from pathlib import Path

API = "https://api.pixellab.ai/v2"
TOKEN = os.environ.get("PIXELLAB_TOKEN", "")
OUT = str((Path(__file__).resolve().parent.parent / "assets" / "generated"))
MAX_CONCURRENT = 3
POLL_INTERVAL = 15  # seconds

def api_call(method, endpoint, data=None):
    url = f"{API}{endpoint}"
    headers = {"Authorization": f"Bearer {TOKEN}", "Content-Type": "application/json"}
    if data:
        req = urllib.request.Request(url, json.dumps(data).encode(), headers, method=method)
    else:
        req = urllib.request.Request(url, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=60) as resp:
            return json.loads(resp.read())
    except urllib.error.HTTPError as e:
        body = e.read().decode()
        try:
            return json.loads(body)
        except:
            return {"error": body, "status_code": e.code}

def check_job(job_id):
    return api_call("GET", f"/background-jobs/{job_id}")

def wait_for_jobs(job_ids, label=""):
    """Wait for all jobs to complete. Returns dict of job_id -> status."""
    results = {}
    pending = set(job_ids)
    while pending:
        time.sleep(POLL_INTERVAL)
        for jid in list(pending):
            resp = check_job(jid)
            status = resp.get("status", "unknown")
            if status == "completed":
                print(f"  ✅ {label} job {jid[:8]}... completed")
                results[jid] = resp
                pending.discard(jid)
            elif status == "failed":
                err = resp.get("last_response", {}).get("error", "unknown error")
                print(f"  ❌ {label} job {jid[:8]}... failed: {err}")
                results[jid] = resp
                pending.discard(jid)
            else:
                print(f"  ⏳ {label} job {jid[:8]}... {status}")
        if pending:
            print(f"  ... {len(pending)} jobs still pending, waiting {POLL_INTERVAL}s")
    return results

def submit_characters_batch(chars, batch_size=3):
    """Submit character jobs in batches of batch_size, waiting for each batch."""
    all_results = {}
    batch = []
    for name, params in chars:
        batch.append((name, params))
        if len(batch) >= batch_size:
            all_results.update(_run_char_batch(batch))
            batch = []
    if batch:
        all_results.update(_run_char_batch(batch))
    return all_results

def _run_char_batch(batch):
    jobs = {}  # name -> (job_id, char_id)
    for name, params in batch:
        print(f"  Submitting {name}...")
        resp = api_call("POST", "/create-character-with-4-directions", params)
        job_id = resp.get("background_job_id", "")
        char_id = resp.get("character_id", "")
        status = resp.get("status", "")
        if job_id:
            print(f"    → job={job_id[:8]}... char={char_id[:8]}... ({status})")
            jobs[name] = (job_id, char_id)
        else:
            print(f"    ❌ Submit failed: {resp}")
    
    if not jobs:
        return {}
    
    # Wait for this batch
    job_ids = [jid for jid, _ in jobs.values()]
    print(f"  Waiting for {len(job_ids)} jobs...")
    wait_for_jobs(job_ids, "char")
    
    return {name: cid for name, (_, cid) in jobs.items()}

def submit_objects_batch(objects, batch_size=3):
    """Submit map object jobs in batches."""
    all_results = {}
    batch = []
    for name, params in objects:
        batch.append((name, params))
        if len(batch) >= batch_size:
            all_results.update(_run_obj_batch(batch))
            batch = []
    if batch:
        all_results.update(_run_obj_batch(batch))
    return all_results

def _run_obj_batch(batch):
    jobs = {}
    for name, params in batch:
        print(f"  Submitting {name}...")
        resp = api_call("POST", "/map-objects", params)
        job_id = resp.get("background_job_id", "")
        obj_id = resp.get("object_id", "")
        if job_id:
            print(f"    → job={job_id[:8]}... obj={obj_id[:8]}...")
            jobs[name] = (job_id, obj_id)
        else:
            print(f"    ❌ Submit failed: {resp}")
    
    if not jobs:
        return {}
    
    job_ids = [jid for jid, _ in jobs.values()]
    print(f"  Waiting for {len(job_ids)} jobs...")
    wait_for_jobs(job_ids, "obj")
    
    return {name: oid for name, (_, oid) in jobs.items()}

def download_character_zip(name, char_id, dest_dir):
    """Download character as zip and extract."""
    os.makedirs(dest_dir, exist_ok=True)
    url = f"{API}/characters/{char_id}/zip"
    headers = {"Authorization": f"Bearer {TOKEN}"}
    req = urllib.request.Request(url, headers=headers)
    try:
        with urllib.request.urlopen(req, timeout=60) as resp:
            data = resp.read()
            ct = resp.headers.get("Content-Type", "")
            if "zip" in ct or data[:4] == b'PK\x03\x04':
                zf = zipfile.ZipFile(io.BytesIO(data))
                zf.extractall(dest_dir)
                print(f"  ✅ {name}: extracted {len(zf.namelist())} files to {dest_dir}")
                return True
            else:
                # Might be JSON error
                try:
                    err = json.loads(data)
                    print(f"  ⚠️  {name}: {err}")
                except:
                    # Save raw anyway
                    with open(os.path.join(dest_dir, f"{name}.zip"), "wb") as f:
                        f.write(data)
                    print(f"  ⚠️  {name}: saved raw ({len(data)} bytes)")
                return False
    except urllib.error.HTTPError as e:
        body = e.read().decode()
        print(f"  ⚠️  {name}: HTTP {e.code} - {body[:200]}")
        return False

def download_object_image(name, obj_id, dest_dir):
    """Download object image via API."""
    os.makedirs(dest_dir, exist_ok=True)
    resp = api_call("GET", f"/objects/{obj_id}")
    
    # Try rotation_urls first
    rotation_urls = resp.get("rotation_urls", {})
    south_url = rotation_urls.get("south")
    if south_url:
        try:
            req = urllib.request.Request(south_url)
            with urllib.request.urlopen(req, timeout=30) as r:
                data = r.read()
                path = os.path.join(dest_dir, f"{name}.png")
                with open(path, "wb") as f:
                    f.write(data)
                print(f"  ✅ {name}: saved from URL ({len(data)} bytes)")
                return True
        except Exception as e:
            print(f"  ⚠️  {name}: URL download failed: {e}")
    
    # Try images array
    images = resp.get("images", [])
    if images:
        for i, img in enumerate(images):
            b64 = img.get("base64", "") or img.get("image", {}).get("base64", "")
            if b64:
                suffix = f"_{i}" if i > 0 else ""
                path = os.path.join(dest_dir, f"{name}{suffix}.png")
                with open(path, "wb") as f:
                    f.write(base64.b64decode(b64))
                print(f"  ✅ {name}: saved image {i}")
                return True
    
    print(f"  ⚠️  {name}: no image available yet - {str(resp)[:200]}")
    return False

def download_tileset(ts_id, dest_dir):
    """Download tileset tiles."""
    os.makedirs(dest_dir, exist_ok=True)
    resp = api_call("GET", f"/tilesets/{ts_id}")
    
    tileset = resp.get("tileset", {})
    tiles = tileset.get("tiles", [])
    count = 0
    for tile in tiles:
        tid = tile.get("id", str(count))
        img = tile.get("image", {})
        b64 = img.get("base64", "")
        if b64:
            path = os.path.join(dest_dir, f"tile_{tid}.png")
            with open(path, "wb") as f:
                f.write(base64.b64decode(b64))
            count += 1
    
    if count:
        print(f"  ✅ Tileset: saved {count} tiles")
    else:
        print(f"  ⚠️  Tileset: no tiles found - {str(resp)[:300]}")
    return count

# ============================================================
# MAIN
# ============================================================

def main():
    mode = sys.argv[1] if len(sys.argv) > 1 else "all"
    
    # Check balance
    bal = api_call("GET", "/balance")
    gens = bal.get("subscription", {}).get("generations", 0)
    print(f"=== PixelLab Wasteland Survivor Asset Generator ===")
    print(f"Remaining generations: {gens}")
    print()
    
    # Already-completed assets from first run
    EXISTING_OBJECTS = {
        "ruined_wall": "70530474-9716-49a3-aa10-912d06c4558d",
        "wrecked_car": "cdb710f5-2161-4ce1-b8ed-8849ca18390a",
        "large_rock": "15d9c805-1575-4b03-8bdc-10c1e7ccae6b",
        "dead_tree": "fee6315b-8878-4f96-a161-bb9c1c69b850",
        "metal_debris": "2a564e21-aa56-48fa-ac40-fa80c1a0ab3d",
        "xp_gem": "c175292f-5e78-427b-8245-cb755a19d348",
        "scrap_coin": "bbf06c82-8c09-4164-8f68-514b995f6d0e",
        "health_pack": "b4ea33ee-aa4d-4d2c-a79f-b9b2a77b657a",
    }
    EXISTING_TILESET = "b1a99000-29ea-4c69-93bb-4e1dff83a19c"
    
    if mode in ("all", "characters"):
        print("=== Phase 1: Player Characters (4 × 32px, 4-direction) ===")
        player_chars = [
            ("survivor", {
                "description": "post-apocalyptic wasteland survivor, green military jacket, brown boots, carrying a rusty gun, tough all-rounder fighter, dark muted colors",
                "image_size": {"width": 32, "height": 32},
                "template_id": "mannequin", "view": "low top-down",
                "outline": "thin", "shading": "soft", "detail": "medium"
            }),
            ("scavenger", {
                "description": "post-apocalyptic scavenger, long green coat with large backpack, goggles on forehead, resourceful looter, dark muted wasteland colors",
                "image_size": {"width": 32, "height": 32},
                "template_id": "mannequin", "view": "low top-down",
                "outline": "thin", "shading": "soft", "detail": "medium"
            }),
            ("demolisher", {
                "description": "post-apocalyptic demolisher, heavy orange-red armor plates, bulky build, carrying explosives, fire details on armor",
                "image_size": {"width": 32, "height": 32},
                "template_id": "mannequin", "view": "low top-down",
                "outline": "thin", "shading": "soft", "detail": "medium"
            }),
            ("mutant", {
                "description": "post-apocalyptic mutant humanoid, pale purple skin with glowing red eyes, torn dark clothes, visible veins and mutations, eerie and dangerous",
                "image_size": {"width": 32, "height": 32},
                "template_id": "mannequin", "view": "low top-down",
                "outline": "thin", "shading": "soft", "detail": "medium"
            }),
        ]
        char_ids = submit_characters_batch(player_chars, batch_size=3)
        
        # Download character zips
        print("\n--- Downloading Player Characters ---")
        for name, cid in char_ids.items():
            download_character_zip(name, cid, os.path.join(OUT, "characters", name))
        print()
    
    if mode in ("all", "enemies"):
        print("=== Phase 2: Enemies (6 units, 4-direction) ===")
        enemies = [
            ("walker", {
                "description": "wasteland zombie walker, decayed flesh, tattered rags, shambling undead, yellow glowing eyes, dark red and brown",
                "image_size": {"width": 24, "height": 24},
                "template_id": "mannequin", "view": "low top-down",
                "outline": "thin", "shading": "soft", "detail": "low"
            }),
            ("mutant_dog", {
                "description": "mutated wasteland dog, mangy orange-brown fur, red glowing eyes, sharp teeth, aggressive feral beast",
                "image_size": {"width": 24, "height": 24},
                "template_id": "dog", "view": "low top-down",
                "outline": "thin", "shading": "soft", "detail": "low"
            }),
            ("acid_bug", {
                "description": "giant mutated acid bug insect, bright green glowing body, yellow eyes, dripping acid, six legs, small but dangerous",
                "image_size": {"width": 32, "height": 32},
                "template_id": "mannequin", "view": "low top-down",
                "outline": "thin", "shading": "soft", "detail": "low"
            }),
            ("iron_giant", {
                "description": "massive iron giant robot, heavy steel grey armor with rust patches, red glowing eyes, slow but powerful, bulky mechanical body",
                "image_size": {"width": 40, "height": 40},
                "template_id": "mannequin", "view": "low top-down",
                "outline": "thin", "shading": "soft", "detail": "medium"
            }),
            ("exploder", {
                "description": "small explosive mutant creature, bright orange-red glowing body about to explode, pulsating, unstable",
                "image_size": {"width": 32, "height": 32},
                "template_id": "mannequin", "view": "low top-down",
                "outline": "thin", "shading": "soft", "detail": "low"
            }),
            ("boss_ash_behemoth", {
                "description": "ash behemoth boss, massive dark crimson beast, rocky armored body, glowing orange cracks, horned head, terrifying wasteland abomination",
                "image_size": {"width": 64, "height": 64},
                "template_id": "mannequin", "view": "low top-down",
                "outline": "thin", "shading": "soft", "detail": "high"
            }),
        ]
        enemy_ids = submit_characters_batch(enemies, batch_size=3)
        
        print("\n--- Downloading Enemies ---")
        for name, cid in enemy_ids.items():
            download_character_zip(name, cid, os.path.join(OUT, "enemies", name))
        print()
    
    if mode in ("all", "objects"):
        print("=== Phase 3: Download Existing Objects & Tileset ===")
        
        print("--- Objects ---")
        for name, oid in EXISTING_OBJECTS.items():
            if name in ("xp_gem", "scrap_coin", "health_pack"):
                download_object_image(name, oid, os.path.join(OUT, "pickups"))
            else:
                download_object_image(name, oid, os.path.join(OUT, "objects"))
        
        print("\n--- Tileset ---")
        download_tileset(EXISTING_TILESET, os.path.join(OUT, "tileset"))
        print()
    
    # Final balance
    bal = api_call("GET", "/balance")
    gens = bal.get("subscription", {}).get("generations", 0)
    print(f"\n=== Done! Remaining generations: {gens} ===")
    print(f"Assets in: {OUT}")

if __name__ == "__main__":
    main()
