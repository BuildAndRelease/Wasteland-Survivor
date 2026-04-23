#!/usr/bin/env python3
"""
Regenerate Level 2 enemy walk animations with improved step legibility.

Key design changes vs. first-pass:
  - Emphasise SILHOUETTE change between frames (limb swing arcs, weight shift)
  - Exaggerate stride width/height for small sprites (small size needs bigger exaggeration)
  - For quadruped (mutant_dog): explicit front/back leg anti-phase
  - For heavy (iron_giant):  explicit left-right weight shift + up-down bob
  - For circular (exploder):  explicit left-right lean / pendulum body swing
  - Acid Bug (already OK):    resubmit with same params to replace thin stripe artifacts

Outputs saved to:
  assets/generated/level2_frozen_wasteland/walk_v2/<name>/<direction>.png   (raw API strips)
  assets/sprites/themes/level2_frozen_wasteland/enemies/walk/<name>_walk_<dir>.png  (final)

Token: PIXELLAB_TOKEN env var
"""

import base64
import json
import os
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

# Force line-buffered stdout so output appears in real-time even in subprocs
sys.stdout.reconfigure(line_buffering=True)

# ── config ────────────────────────────────────────────────────────────────────
API = "https://api.pixellab.ai/v2"
TOKEN = os.environ.get("PIXELLAB_TOKEN", "")
PROJECT = Path(__file__).resolve().parents[1]
GEN_OUT = PROJECT / "assets" / "generated" / "level2_frozen_wasteland" / "walk_v2"
SPRITES_OUT = PROJECT / "assets" / "sprites" / "themes" / "level2_frozen_wasteland" / "enemies" / "walk"
POLL_INTERVAL = 15
DIRECTIONS = ["south", "north", "east", "west"]
BATCH_SIZE = 3   # stay within PixelLab concurrent job limit


# ── helpers ───────────────────────────────────────────────────────────────────
def ensure_token():
    if not TOKEN:
        raise SystemExit("Missing PIXELLAB_TOKEN env var")


def api_call(method: str, path: str, data=None):
    ensure_token()
    headers = {"Authorization": f"Bearer {TOKEN}"}
    payload = None
    if data is not None:
        headers["Content-Type"] = "application/json"
        payload = json.dumps(data).encode()
    req = urllib.request.Request(f"{API}{path}", data=payload, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=90) as resp:
            raw = resp.read()
            ctype = resp.headers.get("Content-Type", "")
            if "application/json" in ctype or raw[:1] in (b"{", b"["):
                return json.loads(raw)
            return {"raw": raw.decode("utf-8", "ignore")}
    except urllib.error.HTTPError as e:
        body = e.read().decode("utf-8", "ignore")
        try:
            return json.loads(body)
        except Exception:
            return {"error": body, "status_code": e.code}


def wait_jobs(job_map: dict, label: str) -> dict:
    """Poll until all jobs in {name: {job_id, ...}} finish. Returns completed map."""
    pending = dict(job_map)
    results = {}
    while pending:
        time.sleep(POLL_INTERVAL)
        for name, meta in list(pending.items()):
            resp = api_call("GET", f"/background-jobs/{meta['job_id']}")
            status = resp.get("status", "unknown")
            if status == "completed":
                print(f"  ✅ {label}:{name}")
                results[name] = {"meta": meta, "resp": resp}
                pending.pop(name)
            elif status == "failed":
                err = resp.get("last_response", {}).get("error") or "unknown"
                print(f"  ❌ {label}:{name} → {err}")
                results[name] = {"meta": meta, "resp": resp, "failed": True}
                pending.pop(name)
            else:
                print(f"  ⏳ {label}:{name} {status}")
        if pending:
            print(f"     waiting {POLL_INTERVAL}s …")
    return results


def download_char_zip(character_id: str, dest: Path) -> list[str]:
    """Download the 4-dir zip and extract PNGs. Returns list of extracted filenames."""
    dest.mkdir(parents=True, exist_ok=True)
    url = f"{API}/characters/{character_id}/zip"
    req = urllib.request.Request(url, headers={"Authorization": f"Bearer {TOKEN}"})
    try:
        import zipfile, io
        with urllib.request.urlopen(req, timeout=120) as resp:
            data = resp.read()
        with zipfile.ZipFile(io.BytesIO(data)) as zf:
            names = []
            for n in zf.namelist():
                if n.lower().endswith(".png"):
                    zf.extract(n, dest)
                    names.append(n)
            return names
    except Exception as e:
        print(f"    zip download error: {e}")
        return []


def save_png_from_resp(resp: dict, dest: Path, name: str) -> bool:
    """Try to pull base64 image from the completed job response."""
    last = resp.get("last_response") or {}
    # some endpoints wrap in 'frames', some in 'image'
    frames = last.get("frames") or last.get("images") or []
    if not frames:
        img = last.get("image") or {}
        b64 = img.get("base64", "")
        if b64:
            frames = [b64]
    if frames:
        dest.mkdir(parents=True, exist_ok=True)
        # frames is a list of dicts {"base64":...} or raw str
        for i, f in enumerate(frames):
            b64 = f.get("base64", f) if isinstance(f, dict) else f
            suffix = f"_{i}" if len(frames) > 1 else ""
            (dest / f"{name}{suffix}.png").write_bytes(base64.b64decode(b64))
        return True
    return False


def chunks(seq, n):
    batch = []
    for item in seq:
        batch.append(item)
        if len(batch) >= n:
            yield batch
            batch = []
    if batch:
        yield batch


# ── enemy walk definitions ────────────────────────────────────────────────────
#
# Design notes (per Johnson's analysis + ART_PIPELINE_EXPERIENCE §12 principles):
#   1. Small sprite → exaggerate ALL limb swings; conservative = invisible at game scale
#   2. Lead with SILHOUETTE change: limbs must cross outside the body mass each frame
#   3. Quadruped: opposite front/back legs must move in anti-phase
#   4. Heavy biped: lateral weight shift + vertical compression at ground-strike
#   5. Round/blob: pendulum-lean left-right to convey direction, not internal flash

ENEMIES = {
    "walker": {
        # 36×36 sprite — very small, MUST over-exaggerate
        # Problems: looked like "standing jitter", silhouette not changing
        "description": (
            "ice zombie walker, frostbitten humanoid shuffling forward, "
            "ragged winter coat, pale icy skin, post-apocalyptic snow mutant; "
            "WALK CYCLE: 6-frame walk, exaggerated bipedal stride — "
            "legs swing wide apart at peak extension (silhouette clearly wider than idle), "
            "clear left-right alternation of leading leg, "
            "arms counter-swing opposite to legs (left arm forward when right leg forward), "
            "body bobs DOWN by 2px on ground-strike frame, UP by 1px on mid-swing, "
            "overall silhouette changes noticeably each frame; "
            "low top-down perspective, muted blue-white gray palette, thin outline"
        ),
        "image_size": {"width": 36, "height": 36},
        "frame_count": 6,
    },
    "mutant_dog": {
        # 36×36, quadruped — looked like a jittering white blob
        # Key fix: front/back leg anti-phase must be unmistakable
        "description": (
            "mutant ice hound, four-legged post-apocalyptic mutant dog, "
            "lean muscular frame, frost-white fur, pale blue glowing eyes; "
            "WALK CYCLE: 6-frame quadruped gallop — "
            "front-left and back-right legs extend forward SIMULTANEOUSLY while "
            "front-right and back-left legs push back (classic diagonal gait), "
            "body stretches long when all four legs are extended, "
            "body compresses when legs gather under torso, "
            "head bobs forward on each powerful stride, "
            "clear silhouette difference between 'legs open' and 'legs gathered' frames; "
            "low top-down perspective, icy palette, visible paw shapes"
        ),
        "image_size": {"width": 36, "height": 36},
        "frame_count": 6,
    },
    "iron_giant": {
        # 56×56 — slow heavy biped, felt too static
        # Key fix: lateral body rock + vertical ground-strike compression
        "description": (
            "iron giant, massive armored humanoid, heavy mech-soldier construct, "
            "rusty icy metal plates, glowing blue eyes, "
            "slow thundering walk, immense weight; "
            "WALK CYCLE: 6-frame heavy bipedal stomp — "
            "each step: body rocks LEFT 2px when left foot plants, RIGHT 2px when right foot plants "
            "(side-to-side weight shift clearly visible in outline), "
            "body compresses DOWN 2px at foot-plant (absorbing weight), "
            "rises UP 1px at mid-swing, "
            "massive arms swing in opposition to feet (wide pendulum arc), "
            "legs have exaggerated high-knee lift before plant; "
            "low top-down perspective, cold grey-blue metal palette, heavy outline"
        ),
        "image_size": {"width": 56, "height": 56},
        "frame_count": 6,
    },
    "exploder": {
        # 48×48 round shape — silhouette barely changes, looked like hovering ball
        # Key fix: lean direction of travel, make the circular mass shift
        "description": (
            "exploder zombie, bloated round humanoid, "
            "unstable glowing core, bulging torso, short stubby legs; "
            "WALK CYCLE: 6-frame waddle — "
            "body leans LEFT when left foot steps, leans RIGHT when right foot steps "
            "(exaggerated side-to-side pendulum, lean angle clearly visible), "
            "stubby legs clearly alternate stepping with wide outward arcs, "
            "unstable glowing belly pulses subtly, "
            "OVERALL SHAPE shifts noticeably left and right each frame so silhouette changes; "
            "low top-down perspective, sickly purple-green glow palette, round outline"
        ),
        "image_size": {"width": 48, "height": 48},
        "frame_count": 6,
    },
    "acid_bug": {
        # 48×48 — already relatively readable; resubmit with stricter multi-leg clarity
        "description": (
            "acid bug, large insectoid mutant, six-legged crawling creature, "
            "segmented exoskeleton, dripping acid glands, toxic green bioluminescence; "
            "WALK CYCLE: 6-frame insect crawl — "
            "middle and front legs on one side move forward while rear and middle on other side push back "
            "(alternating tripod gait), "
            "body sways left-right slightly with each tripod plant, "
            "antennae bob rhythmically, "
            "individual leg shapes clearly readable against the body mass; "
            "low top-down perspective, dark chitinous body, acid-green glow, thin legs"
        ),
        "image_size": {"width": 48, "height": 48},
        "frame_count": 6,
    },
}

# Base PixelLab params shared by all enemies
BASE_PARAMS = {
    "template_id": "mannequin",
    "view": "low top-down",
    "outline": "thin",
    "shading": "soft",
    "detail": "low",
    "text_guidance_scale": 9,
    "async_mode": True,
}


# ── main ──────────────────────────────────────────────────────────────────────
def submit_walk_batch(items: list[tuple]) -> dict:
    """Submit a batch of (key, dir, params) tuples. Returns job_map."""
    jobs = {}
    for key, direction, params in items:
        label = f"{key}_{direction}"
        print(f"  → submitting {label} …")
        resp = api_call("POST", "/create-character-with-4-directions", params)
        job_id = resp.get("background_job_id", "")
        char_id = resp.get("character_id", "")
        if job_id and char_id:
            jobs[label] = {"job_id": job_id, "char_id": char_id, "key": key, "direction": direction}
            print(f"     job={job_id[:8]} char={char_id[:8]}")
        else:
            print(f"     ❌ failed: {resp}")
    return jobs


def process_results(results: dict):
    """Download zips and copy walk-direction PNGs to final sprite dir."""
    for label, info in results.items():
        if info.get("failed"):
            continue
        meta = info["meta"]
        char_id = meta.get("char_id", "")
        key = meta["key"]
        direction = meta["direction"]

        raw_dest = GEN_OUT / key / direction
        raw_dest.mkdir(parents=True, exist_ok=True)

        extracted = download_char_zip(char_id, raw_dest)
        print(f"  📦 {label}: extracted {len(extracted)} file(s)")

        # The zip contains files like south.png / north.png / east.png / west.png
        # We want only the matching direction
        SPRITES_OUT.mkdir(parents=True, exist_ok=True)
        for fname in extracted:
            stem = Path(fname).stem.lower()
            # match e.g. "south", "walk_south", "south_walk"
            if direction in stem:
                src = raw_dest / fname
                dst = SPRITES_OUT / f"{key}_walk_{direction}.png"
                import shutil
                shutil.copy2(str(src), str(dst))
                print(f"     ✅ saved → {dst.name}")
                break
        else:
            # fallback: copy all extracted PNGs with index suffix
            for i, fname in enumerate(extracted):
                if fname.lower().endswith(".png"):
                    src = raw_dest / fname
                    dst = SPRITES_OUT / f"{key}_walk_{direction}_{i}.png"
                    import shutil
                    shutil.copy2(str(src), str(dst))
                    print(f"     ⚠️  fallback saved → {dst.name}")


def main():
    ensure_token()
    GEN_OUT.mkdir(parents=True, exist_ok=True)
    SPRITES_OUT.mkdir(parents=True, exist_ok=True)

    bal = api_call("GET", "/balance")
    print("=== Level 2 Walk Animation V2 Generator ===")
    print(f"Balance: {bal}")

    # Build all (key, direction, params) tuples
    all_jobs: list[tuple] = []
    for key, enemy in ENEMIES.items():
        params = {**BASE_PARAMS,
                  "description": enemy["description"],
                  "image_size": enemy["image_size"]}
        # We generate one full 4-direction character per enemy (API handles directions)
        # Use direction=south as canonical; zip contains all 4 directions
        # So we only need 1 submission per enemy, not 4
        # (The /create-character-with-4-directions endpoint returns all 4 dirs in zip)
        all_jobs.append((key, "all_dirs", params))

    print(f"\nTotal enemies to regenerate: {len(all_jobs)}")
    print(f"Batch size: {BATCH_SIZE}\n")

    all_results = {}
    for batch in chunks(all_jobs, BATCH_SIZE):
        print(f"--- Submitting batch of {len(batch)} ---")
        job_map = submit_walk_batch(batch)
        print(f"  Waiting for {len(job_map)} job(s)…")
        results = wait_jobs(job_map, "walk_v2")
        all_results.update(results)
        print()

    print("=== Downloading & saving results ===")
    process_results(all_results)

    # Summary
    ok = [k for k, v in all_results.items() if not v.get("failed")]
    fail = [k for k, v in all_results.items() if v.get("failed")]
    print(f"\n✅ Success: {len(ok)} / {len(all_results)}")
    if fail:
        print(f"❌ Failed: {fail}")
    print(f"\nSprites saved to: {SPRITES_OUT}")


if __name__ == "__main__":
    main()
