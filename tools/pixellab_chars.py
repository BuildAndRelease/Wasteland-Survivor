#!/usr/bin/env python3
"""Download completed characters and resubmit failed ones."""
import json, base64, os, time, urllib.request, urllib.error, zipfile, io
from pathlib import Path

API = "https://api.pixellab.ai/v2"
TOKEN = os.environ.get("PIXELLAB_TOKEN", "")
OUT = str((Path(__file__).resolve().parent.parent / "assets" / "generated"))

def api_get(endpoint):
    url = f"{API}{endpoint}"
    req = urllib.request.Request(url, headers={"Authorization": f"Bearer {TOKEN}"})
    with urllib.request.urlopen(req, timeout=60) as resp:
        return json.loads(resp.read())

def api_post(endpoint, data):
    url = f"{API}{endpoint}"
    headers = {"Authorization": f"Bearer {TOKEN}", "Content-Type": "application/json"}
    req = urllib.request.Request(url, json.dumps(data).encode(), headers, method="POST")
    try:
        with urllib.request.urlopen(req, timeout=60) as resp:
            return json.loads(resp.read())
    except urllib.error.HTTPError as e:
        body = e.read().decode()
        try:
            return json.loads(body)
        except:
            return {"error": body, "status_code": e.code}

def download_char_zip(name, char_id, dest):
    os.makedirs(dest, exist_ok=True)
    url = f"{API}/characters/{char_id}/zip"
    req = urllib.request.Request(url, headers={"Authorization": f"Bearer {TOKEN}"})
    try:
        with urllib.request.urlopen(req, timeout=60) as resp:
            data = resp.read()
            if data[:4] == b'PK\x03\x04':
                zf = zipfile.ZipFile(io.BytesIO(data))
                zf.extractall(dest)
                print(f"  ✅ {name}: {len(zf.namelist())} files")
                for f in zf.namelist():
                    print(f"     - {f}")
                return True
            else:
                print(f"  ⚠️  {name}: not a zip ({data[:100]})")
                return False
    except urllib.error.HTTPError as e:
        body = e.read().decode()
        print(f"  ⚠️  {name}: HTTP {e.code} - {body[:200]}")
        return False

def wait_job(job_id, name, timeout=300):
    start = time.time()
    while time.time() - start < timeout:
        resp = api_get(f"/background-jobs/{job_id}")
        status = resp.get("status", "unknown")
        if status == "completed":
            print(f"  ✅ {name} job completed")
            return resp
        elif status == "failed":
            err = resp.get("last_response", {}).get("error", "unknown")
            print(f"  ❌ {name} job failed: {err}")
            return resp
        print(f"  ⏳ {name}: {status}...")
        time.sleep(15)
    print(f"  ⚠️  {name}: timeout after {timeout}s")
    return None

# ==========================================
# Step 1: Download completed characters
# ==========================================
COMPLETED_CHARS = {
    "survivor": "ca5d3790-8e43-437a-b06a-afc8f085627c",
    "scavenger": "7315126d-f6a5-4ee7-bd03-f6d2489c56bf",
    "demolisher": "dcc817a2-3eb4-41c3-940c-fb460fbcaa5e",
}

print("=== Downloading Completed Characters ===\n")
for name, char_id in COMPLETED_CHARS.items():
    download_char_zip(name, char_id, os.path.join(OUT, "characters", name))

# ==========================================
# Step 2: Resubmit failed characters (batch of 3)
# ==========================================
FAILED_CHARS = [
    ("mutant", {
        "description": "post-apocalyptic mutant humanoid, pale purple skin with glowing red eyes, torn dark clothes, visible veins and mutations, eerie and dangerous",
        "image_size": {"width": 32, "height": 32},
        "template_id": "mannequin", "view": "low top-down",
        "outline": "thin", "shading": "soft", "detail": "medium"
    }),
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
]

FAILED_CHARS_2 = [
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
        "description": "small explosive mutant creature, bright orange-red glowing body, pulsating and unstable, about to explode",
        "image_size": {"width": 32, "height": 32},
        "template_id": "mannequin", "view": "low top-down",
        "outline": "thin", "shading": "soft", "detail": "low"
    }),
]

FAILED_CHARS_3 = [
    ("boss_ash_behemoth", {
        "description": "ash behemoth boss, massive dark crimson beast, rocky armored body, glowing orange cracks, horned head, terrifying wasteland abomination",
        "image_size": {"width": 64, "height": 64},
        "template_id": "mannequin", "view": "low top-down",
        "outline": "thin", "shading": "soft", "detail": "high"
    }),
]

def submit_and_wait_batch(batch, category):
    jobs = {}
    for name, params in batch:
        print(f"\n  Submitting {name}...")
        resp = api_post("/create-character-with-4-directions", params)
        job_id = resp.get("background_job_id", "")
        char_id = resp.get("character_id", "")
        if job_id:
            print(f"    job={job_id[:12]}... char={char_id[:12]}...")
            jobs[name] = (job_id, char_id)
        else:
            print(f"    ❌ Failed: {resp}")
    
    if not jobs:
        return
    
    # Wait for all jobs in batch
    print(f"\n  Waiting for batch ({len(jobs)} jobs)...")
    for name, (job_id, char_id) in jobs.items():
        wait_job(job_id, name)
    
    # Download
    print(f"\n  Downloading batch...")
    for name, (_, char_id) in jobs.items():
        dest = os.path.join(OUT, category, name)
        download_char_zip(name, char_id, dest)

print("\n=== Batch 1: mutant + walker + mutant_dog ===")
submit_and_wait_batch(FAILED_CHARS, "characters" if FAILED_CHARS[0][0] == "mutant" else "enemies")

# mutant goes to characters, walker and mutant_dog go to enemies — handle manually
# Actually let me just put them all in the right dirs after download

print("\n=== Batch 2: acid_bug + iron_giant + exploder ===")
submit_and_wait_batch(FAILED_CHARS_2, "enemies")

print("\n=== Batch 3: boss_ash_behemoth ===")
submit_and_wait_batch(FAILED_CHARS_3, "enemies")

# Move mutant to correct dir
mutant_wrong = os.path.join(OUT, "characters", "mutant")
# Actually the submit function already handles dirs correctly

print("\n=== Final Balance ===")
bal = api_get("/balance")
print(f"  Generations: {bal.get('subscription', {}).get('generations', '?')}")
print("\n🎉 All done!")
