#!/usr/bin/env python3
"""
Generate proper walk animations for Level 2 enemies using /characters/animations endpoint.

API response shape: {"background_job_ids": [...], "directions": [...], "status": "processing"}
One background job per direction. We poll all jobs, then download spritesheets.
"""
import sys
sys.stdout.reconfigure(line_buffering=True)

import base64
import io
import json
import os
import shutil
import time
import urllib.error
import urllib.request
import zipfile
from pathlib import Path
from typing import Optional

API = "https://api.pixellab.ai/v2"
TOKEN = os.environ.get("PIXELLAB_TOKEN", "")
PROJECT = Path(__file__).resolve().parents[1]
SPRITES_OUT = PROJECT / "assets" / "sprites" / "themes" / "level2_frozen_wasteland" / "enemies" / "walk"
GEN_OUT = PROJECT / "assets" / "generated" / "level2_frozen_wasteland" / "walk_anim_v2"
POLL_INTERVAL = 20
BATCH_SIZE = 1   # 1 enemy at a time = 4 direction jobs; stay under concurrent limit


ENEMIES = {
    "walker": {
        "character_id": "2fa3226f-3422-446f-b183-3ebbdbe852fd",
        "action_description": (
            "bipedal walk — legs swing wide apart with exaggerated stride, "
            "clear left-right leg alternation, arms counter-swing opposite to legs, "
            "body bobs down 2px on ground-strike and up 1px on mid-swing, "
            "silhouette changes clearly each frame, shuffling zombie gait"
        ),
    },
    "mutant_dog": {
        "character_id": "5624c384-b0cf-4d2e-bb75-1e25f30b8097",
        "action_description": (
            "quadruped gallop — diagonal gait: front-left and back-right extend forward "
            "while front-right and back-left push back, "
            "body stretches when legs open and compresses when gathered, "
            "head bobs forward each stride"
        ),
    },
    "iron_giant": {
        "character_id": "d14c2797-9818-4c69-acbc-89d237486cad",
        "action_description": (
            "heavy stomping walk — body rocks side-to-side 2px each foot plant, "
            "body compresses 2px down on foot-strike and rises 1px at mid-swing, "
            "arms swing in wide pendulum arcs opposite to feet, high knee lift before plant"
        ),
    },
    "exploder": {
        "character_id": "36a916f2-ec99-4100-a2de-35bba71f69db",
        "action_description": (
            "waddling walk — body leans left when left foot steps, right when right steps, "
            "exaggerated pendulum side-to-side motion clearly visible in outline, "
            "stubby legs alternate with wide outward arcs"
        ),
    },
    "acid_bug": {
        "character_id": "a904cc77-8809-4716-beb8-6abce951fb4a",
        "action_description": (
            "six-legged insect crawl — alternating tripod gait, "
            "body sways left-right each tripod plant, antennae bob rhythmically, "
            "individual leg shapes clearly visible"
        ),
    },
}

# Jobs from previous (already submitted) walker + mutant_dog runs
PENDING_JOBS = {
    "walker": {
        "character_id": "2fa3226f-3422-446f-b183-3ebbdbe852fd",
        "anim_name": "walk_v2_walker",
        "job_ids": {
            "south": "e056d899-30de-481d-8ab1-925e4b7e0da2",
            "north": "d1a0fcd1-e87e-4c34-921c-fffc369ac5e3",
            "east":  "6b3dc0a2-10d9-46c4-acac-e0cb099dd108",
            "west":  "325557a1-04b1-4d73-a338-087ac5ebf39b",
        }
    },
    "mutant_dog": {
        "character_id": "5624c384-b0cf-4d2e-bb75-1e25f30b8097",
        "anim_name": "walk_v2_mutant_dog",
        "job_ids": {
            "south": "b9ec841b-5c17-4d48-bcd4-787d1313271a",
            "north": "dc6c52f4-31a5-430b-9fcf-aa916badbc59",
            "east":  "f059a251-d8d9-459c-8a99-9e0fbaa10c51",
            "west":  "a35676c5-f753-4c1d-af62-8c7e1e536d92",
        }
    },
}

# Enemies still to submit
REMAINING_ENEMIES = {k: v for k, v in ENEMIES.items() if k not in PENDING_JOBS}


def ensure_token():
    if not TOKEN:
        raise SystemExit("Missing PIXELLAB_TOKEN")


def api_call(method, path, data=None):
    ensure_token()
    headers = {"Authorization": f"Bearer {TOKEN}"}
    payload = None
    if data is not None:
        headers["Content-Type"] = "application/json"
        payload = json.dumps(data).encode()
    req = urllib.request.Request(f"{API}{path}", data=payload, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=90) as r:
            raw = r.read()
            ctype = r.headers.get("Content-Type", "")
            if "application/json" in ctype or raw[:1] in (b"{", b"["):
                return json.loads(raw)
            return {"raw": raw.decode("utf-8", "ignore")}
    except urllib.error.HTTPError as e:
        body = e.read().decode("utf-8", "ignore")
        try:
            return json.loads(body)
        except Exception:
            return {"error": body, "status_code": e.code}


def wait_direction_jobs(enemy_name: str, job_ids: dict) -> dict:
    """
    Poll all direction jobs for one enemy.
    job_ids: {"south": "uuid", "north": "uuid", ...}
    Returns: {"south": resp, "north": resp, ...}
    """
    pending = dict(job_ids)
    results = {}
    while pending:
        time.sleep(POLL_INTERVAL)
        for direction, jid in list(pending.items()):
            resp = api_call("GET", f"/background-jobs/{jid}")
            status = resp.get("status", "unknown")
            if status == "completed":
                print(f"  ✅ {enemy_name}/{direction}")
                results[direction] = resp
                pending.pop(direction)
            elif status == "failed":
                err = resp.get("last_response", {}).get("error") or "unknown"
                print(f"  ❌ {enemy_name}/{direction} → {err}")
                results[direction] = {"failed": True, "resp": resp}
                pending.pop(direction)
            else:
                print(f"  ⏳ {enemy_name}/{direction} {status}")
        if pending:
            print(f"     waiting {POLL_INTERVAL}s …")
    return results


def submit_one_enemy(enemy_name: str, config: dict) -> Optional[dict]:
    """Submit animation for one enemy (4 directions). Returns job_ids dict or None."""
    char_id = config["character_id"]
    action = config["action_description"]
    anim_name = f"walk_v2_{enemy_name}"
    payload = {
        "character_id": char_id,
        "animation_name": anim_name,
        "action_description": action,
        "mode": "v3",
        "frame_count": 8,
        "directions": ["south", "north", "east", "west"],
        "async_mode": True,
    }
    print(f"  → submitting {enemy_name} (char {char_id[:8]}) …")
    resp = api_call("POST", "/characters/animations", payload)

    job_ids_list = resp.get("background_job_ids", [])
    directions = resp.get("directions", ["south", "north", "east", "west"])

    if not job_ids_list:
        print(f"     ❌ submit failed: {resp}")
        return None

    job_ids = dict(zip(directions, job_ids_list))
    print(f"     jobs: {', '.join(f'{d}={j[:8]}' for d, j in job_ids.items())}")
    return {
        "character_id": char_id,
        "anim_name": anim_name,
        "job_ids": job_ids,
    }


def save_frames_from_job(resp: dict, dest: Path, direction: str) -> bool:
    """Extract per-frame RGBA bytes from job response, stitch into spritesheet, save."""
    last = resp.get("last_response") or {}
    dest.mkdir(parents=True, exist_ok=True)

    images = last.get("images") or []
    if not images:
        print(f"     ⚠️  no images in job response (keys: {list(last.keys())})")
        return False

    try:
        from PIL import Image as PILImage
        frames = []
        for img_data in images:
            b64 = img_data.get("base64", "")
            w = img_data.get("width")
            h = img_data.get("height")
            if not b64 or not w or not h:
                continue
            raw = base64.b64decode(b64)
            frame = PILImage.frombytes("RGBA", (w, h), raw)
            frames.append(frame)

        if not frames:
            print(f"     ⚠️  no valid frames decoded")
            return False

        fw, fh = frames[0].size
        sheet = PILImage.new("RGBA", (fw * len(frames), fh), (0, 0, 0, 0))
        for i, f in enumerate(frames):
            sheet.paste(f, (i * fw, 0))

        out = dest / f"{direction}.png"
        sheet.save(str(out))
        print(f"     📸 {direction}: {len(frames)} frames → {fw*len(frames)}x{fh} spritesheet")
        return True

    except ImportError:
        # PIL not available — save raw bytes per frame
        saved_any = False
        for i, img_data in enumerate(images):
            b64 = img_data.get("base64", "")
            w = img_data.get("width")
            h = img_data.get("height")
            if not b64 or not w or not h:
                continue
            raw = base64.b64decode(b64)
            # save as raw RGBA (can be converted later)
            (dest / f"{direction}_frame{i:02d}.raw").write_bytes(raw)
            saved_any = True
        return saved_any


def process_enemy(enemy_name: str, char_id: str, anim_name: str, direction_results: dict):
    """Save per-direction spritesheets to final sprites dir."""
    raw_dest = GEN_OUT / enemy_name
    raw_dest.mkdir(parents=True, exist_ok=True)
    SPRITES_OUT.mkdir(parents=True, exist_ok=True)

    for direction, resp in direction_results.items():
        if resp.get("failed"):
            continue
        saved = save_frames_from_job(resp, raw_dest, direction)
        if saved:
            src = raw_dest / f"{direction}.png"
            if src.exists():
                dst = SPRITES_OUT / f"{enemy_name}_walk_{direction}.png"
                shutil.copy2(str(src), str(dst))
                print(f"     ✅ saved {dst.name}")


def main():
    ensure_token()
    GEN_OUT.mkdir(parents=True, exist_ok=True)

    bal = api_call("GET", "/balance")
    print("=== Level 2 Walk Animation (v2 - correct API) ===")
    print(f"Balance: {bal}\n")

    # ── Step 1: wait for already-submitted jobs ────────────────────────────
    if PENDING_JOBS:
        print(f"=== Waiting for {len(PENDING_JOBS)} already-submitted enemies ===")
        for enemy_name, meta in PENDING_JOBS.items():
            print(f"\n[{enemy_name}] polling {len(meta['job_ids'])} direction jobs …")
            dir_results = wait_direction_jobs(enemy_name, meta["job_ids"])
            process_enemy(enemy_name, meta["character_id"], meta["anim_name"], dir_results)

    # ── Step 2: submit remaining enemies one at a time ─────────────────────
    if REMAINING_ENEMIES:
        print(f"\n=== Submitting {len(REMAINING_ENEMIES)} remaining enemies ===")
        for enemy_name, config in REMAINING_ENEMIES.items():
            # Wait until concurrent jobs are below limit
            while True:
                resp = api_call("GET", "/balance")
                # No direct "active jobs" endpoint; just try and handle 429
                break

            result = submit_one_enemy(enemy_name, config)
            if result is None:
                continue

            print(f"  Waiting for {enemy_name} direction jobs …")
            dir_results = wait_direction_jobs(enemy_name, result["job_ids"])
            process_enemy(enemy_name, result["character_id"], result["anim_name"], dir_results)
            print()

    print(f"\nAll done. Sprites: {SPRITES_OUT}")


if __name__ == "__main__":
    main()
