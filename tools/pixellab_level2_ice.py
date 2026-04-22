#!/usr/bin/env python3
"""
PixelLab generator for Wasteland Survivor Level 2 art pack.
Theme: frozen wasteland / snowfield apocalypse

Outputs to:
  assets/generated/level2_frozen_wasteland/

Token handling:
  Reads PIXELLAB_TOKEN from environment only.
  Never hardcode the token into this file.
"""
import json
import time
import base64
import os
import sys
import io
import zipfile
import urllib.request
import urllib.error
from pathlib import Path

API = "https://api.pixellab.ai/v2"
TOKEN = os.environ.get("PIXELLAB_TOKEN", "")
OUT = Path(__file__).resolve().parent.parent / "assets" / "generated" / "level2_frozen_wasteland"
POLL_INTERVAL = 15


def ensure_token() -> None:
    if not TOKEN:
        raise SystemExit("Missing PIXELLAB_TOKEN environment variable")


def api_call(method: str, endpoint: str, data=None):
    ensure_token()
    url = f"{API}{endpoint}"
    headers = {"Authorization": f"Bearer {TOKEN}"}
    payload = None
    if data is not None:
        headers["Content-Type"] = "application/json"
        payload = json.dumps(data).encode("utf-8")
    req = urllib.request.Request(url, data=payload, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=90) as resp:
            raw = resp.read()
            ctype = resp.headers.get("Content-Type", "")
            if "application/json" in ctype or raw[:1] in (b"{", b"["):
                return json.loads(raw)
            return {"raw": raw.decode("utf-8", "ignore"), "status_code": resp.status}
    except urllib.error.HTTPError as e:
        body = e.read().decode("utf-8", "ignore")
        try:
            return json.loads(body)
        except Exception:
            return {"error": body, "status_code": e.code}


def check_job(job_id: str):
    return api_call("GET", f"/background-jobs/{job_id}")


def wait_for_jobs(job_map: dict, label: str):
    pending = dict(job_map)
    results = {}
    while pending:
        time.sleep(POLL_INTERVAL)
        for name, meta in list(pending.items()):
            job_id = meta["job_id"]
            resp = check_job(job_id)
            status = resp.get("status", "unknown")
            if status == "completed":
                print(f"  ✅ {label}:{name} completed")
                results[name] = resp
                pending.pop(name, None)
            elif status == "failed":
                err = resp.get("last_response", {}).get("error") or resp.get("error") or "unknown error"
                print(f"  ❌ {label}:{name} failed: {err}")
                results[name] = resp
                pending.pop(name, None)
            else:
                print(f"  ⏳ {label}:{name} {status}")
        if pending:
            print(f"  ... waiting {POLL_INTERVAL}s for {len(pending)} pending job(s)")
    return results


def save_json(path: Path, data) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")


def download_character_zip(name: str, character_id: str, dest_dir: Path) -> bool:
    ensure_token()
    dest_dir.mkdir(parents=True, exist_ok=True)
    url = f"{API}/characters/{character_id}/zip"
    req = urllib.request.Request(url, headers={"Authorization": f"Bearer {TOKEN}"})
    try:
        with urllib.request.urlopen(req, timeout=120) as resp:
            data = resp.read()
        if data[:4] == b"PK\x03\x04":
            zf = zipfile.ZipFile(io.BytesIO(data))
            zf.extractall(dest_dir)
            print(f"  ✅ downloaded {name} zip -> {dest_dir}")
            return True
        print(f"  ⚠️  {name}: zip export not ready / unexpected response")
        return False
    except urllib.error.HTTPError as e:
        body = e.read().decode("utf-8", "ignore")
        print(f"  ⚠️  {name}: zip HTTP {e.code} {body[:180]}")
        return False


def _save_object_from_job_response(name: str, job_resp: dict, dest_path: Path) -> bool:
    last = job_resp.get("last_response", {}) if isinstance(job_resp, dict) else {}
    b64 = last.get("image", "")
    url = last.get("storage_url", "")
    if b64:
        dest_path.write_bytes(base64.b64decode(b64))
        print(f"  ✅ saved {name} from background job image")
        return True
    if url:
        try:
            with urllib.request.urlopen(url, timeout=60) as resp:
                dest_path.write_bytes(resp.read())
            print(f"  ✅ saved {name} from storage URL")
            return True
        except Exception as e:
            print(f"  ⚠️  {name}: storage URL failed: {e}")
    return False


def download_object_image(name: str, object_id: str, job_id: str, dest_dir: Path) -> bool:
    dest_dir.mkdir(parents=True, exist_ok=True)
    dest_path = dest_dir / f"{name}.png"

    if object_id:
        resp = api_call("GET", f"/objects/{object_id}")
        rotation_urls = resp.get("rotation_urls", {}) if isinstance(resp, dict) else {}
        south_url = rotation_urls.get("south")
        if south_url:
            try:
                with urllib.request.urlopen(south_url, timeout=60) as r:
                    dest_path.write_bytes(r.read())
                print(f"  ✅ saved {name} from object south rotation")
                return True
            except Exception as e:
                print(f"  ⚠️  {name}: south rotation download failed: {e}")

        images = resp.get("images", []) if isinstance(resp, dict) else []
        for idx, img in enumerate(images):
            b64 = img.get("base64", "") or img.get("image", {}).get("base64", "")
            if b64:
                path = dest_dir / (f"{name}_{idx}.png" if idx else f"{name}.png")
                path.write_bytes(base64.b64decode(b64))
                print(f"  ✅ saved {name} from object images")
                return True

    job_resp = check_job(job_id)
    if _save_object_from_job_response(name, job_resp, dest_path):
        return True

    print(f"  ⚠️  {name}: no downloadable image found")
    return False


def download_tileset(name: str, tileset_id: str, dest_dir: Path) -> int:
    dest_dir.mkdir(parents=True, exist_ok=True)
    resp = api_call("GET", f"/tilesets/{tileset_id}")
    tileset = resp.get("tileset", {}) if isinstance(resp, dict) else {}
    tiles = tileset.get("tiles", [])
    count = 0
    for idx, tile in enumerate(tiles):
        tid = tile.get("id", str(idx))
        img = tile.get("image", {})
        b64 = img.get("base64", "")
        if b64:
            path = dest_dir / f"tile_{count:02d}_{tid}.png"
            path.write_bytes(base64.b64decode(b64))
            count += 1
    print(f"  ✅ {name}: saved {count} tile(s)")
    return count


def submit_characters_batch(items):
    jobs = {}
    for name, params in items:
        payload = dict(params)
        payload.setdefault("async_mode", True)
        print(f"  submitting character {name}...")
        resp = api_call("POST", "/create-character-with-4-directions", payload)
        job_id = resp.get("background_job_id", "")
        character_id = resp.get("character_id", "")
        if job_id and character_id:
            jobs[name] = {"job_id": job_id, "character_id": character_id, "submit_response": resp}
            print(f"    → job={job_id[:8]} char={character_id[:8]}")
        else:
            print(f"    ❌ submit failed: {resp}")
            jobs[name] = {"job_id": "", "character_id": "", "submit_response": resp}
    return jobs


def submit_objects_batch(items):
    jobs = {}
    for name, params in items:
        print(f"  submitting object {name}...")
        resp = api_call("POST", "/map-objects", params)
        job_id = resp.get("background_job_id", "")
        object_id = resp.get("object_id", "")
        if job_id:
            jobs[name] = {"job_id": job_id, "object_id": object_id, "submit_response": resp}
            print(f"    → job={job_id[:8]} obj={object_id[:8] if object_id else 'n/a'}")
        else:
            print(f"    ❌ submit failed: {resp}")
            jobs[name] = {"job_id": "", "object_id": object_id, "submit_response": resp}
    return jobs


def submit_tileset(name: str, params: dict):
    print(f"  submitting tileset {name}...")
    resp = api_call("POST", "/tilesets", params)
    job_id = resp.get("background_job_id", "")
    tileset_id = resp.get("tileset_id", "") or resp.get("id", "")
    print(f"    → job={job_id[:8] if job_id else 'n/a'} tileset={tileset_id[:8] if tileset_id else 'n/a'}")
    return {name: {"job_id": job_id, "tileset_id": tileset_id, "submit_response": resp}}


def chunks(seq, n):
    batch = []
    for item in seq:
        batch.append(item)
        if len(batch) >= n:
            yield batch
            batch = []
    if batch:
        yield batch


def main():
    ensure_token()
    OUT.mkdir(parents=True, exist_ok=True)
    manifest = {
        "theme": "level2_frozen_wasteland",
        "generated_at": time.strftime("%Y-%m-%d %H:%M:%S"),
        "decisions": {
            "behavior_change": "1A keep gameplay archetypes unchanged",
            "tone": "2B ice/snow mutant apocalypse",
            "boss": "3A glacier beast",
            "map_mood": "4D mixed snowfield + frozen ruins",
            "pickups": "5A shared pickups, no new pickup generation",
        },
        "enemies": {},
        "objects": {},
        "tileset": {},
    }

    balance = api_call("GET", "/balance")
    save_json(OUT / "balance_before.json", balance)
    print("=== PixelLab Level 2 Frozen Wasteland Generator ===")
    print(json.dumps(balance, ensure_ascii=False, indent=2)[:1200])

    enemies = [
        (
            "frost_walker",
            {
                "description": "frozen wasteland walker, frostbitten mutant scavenger, ragged winter coat, pale icy skin, dim cyan glowing eyes, post-apocalyptic snow zombie, readable silhouette, muted blue white and dirty gray palette",
                "image_size": {"width": 24, "height": 24},
                "template_id": "mannequin",
                "view": "low top-down",
                "outline": "thin",
                "shading": "soft",
                "detail": "low",
                "text_guidance_scale": 8,
            },
        ),
        (
            "snowfang_hound",
            {
                "description": "mutated arctic hound, gaunt feral snow dog, white gray fur with frost patches and icy spikes, glowing blue eyes, aggressive fast silhouette, post-apocalyptic frozen wasteland creature",
                "image_size": {"width": 24, "height": 24},
                "template_id": "dog",
                "view": "low top-down",
                "outline": "thin",
                "shading": "soft",
                "detail": "low",
                "text_guidance_scale": 8,
            },
        ),
        (
            "ice_spitter",
            {
                "description": "frozen mutant insect, ice spitter bug with translucent cyan shell, crystal back, cold glow, spits ice shards or freezing bile, six legged ranged threat, frozen apocalypse monster",
                "image_size": {"width": 32, "height": 32},
                "template_id": "mannequin",
                "view": "low top-down",
                "outline": "thin",
                "shading": "soft",
                "detail": "low",
                "text_guidance_scale": 8,
            },
        ),
        (
            "glacier_brute",
            {
                "description": "hulking glacier brute, frozen industrial mutant with heavy ice armor and rusted metal underneath, massive slow bruiser, broad silhouette, cold blue cracks, post-apocalyptic snow biome tank enemy",
                "image_size": {"width": 40, "height": 40},
                "template_id": "mannequin",
                "view": "low top-down",
                "outline": "thin",
                "shading": "soft",
                "detail": "medium",
                "text_guidance_scale": 8,
            },
        ),
        (
            "frost_bomber",
            {
                "description": "volatile frost bomber creature, unstable frozen parasite with cracked glowing blue core, swollen icy body, about to detonate, readable danger silhouette, snow apocalypse exploder enemy",
                "image_size": {"width": 32, "height": 32},
                "template_id": "mannequin",
                "view": "low top-down",
                "outline": "thin",
                "shading": "soft",
                "detail": "low",
                "text_guidance_scale": 8,
            },
        ),
        (
            "blizzard_behemoth",
            {
                "description": "blizzard behemoth boss, giant horned glacier beast, cracked ice armor, blue white glowing fissures, massive frozen apocalypse abomination, intimidating silhouette, final boss for snowfield ruins",
                "image_size": {"width": 64, "height": 64},
                "template_id": "mannequin",
                "view": "low top-down",
                "outline": "thin",
                "shading": "soft",
                "detail": "high",
                "text_guidance_scale": 8,
            },
        ),
    ]

    objects = [
        (
            "frozen_dead_tree",
            {
                "description": "leafless frozen dead tree, wind-bent trunk, ice crust and snow buildup, post-apocalyptic frozen wasteland obstacle, low top-down pixel art, transparent background",
                "image_size": {"width": 48, "height": 64},
                "view": "low top-down",
                "outline": "single color outline",
                "shading": "basic shading",
                "detail": "medium detail",
                "text_guidance_scale": 8,
            },
        ),
        (
            "snow_covered_wrecked_car",
            {
                "description": "wrecked abandoned car half buried in snow, rusted metal, broken windows, icy roof and hood, frozen wasteland ruin obstacle, low top-down pixel art, transparent background",
                "image_size": {"width": 96, "height": 64},
                "view": "low top-down",
                "outline": "single color outline",
                "shading": "basic shading",
                "detail": "medium detail",
                "text_guidance_scale": 8,
            },
        ),
        (
            "ice_boulder",
            {
                "description": "large boulder with frozen crust, blue ice edges and snow dust, cold wasteland rock obstacle, low top-down pixel art, transparent background",
                "image_size": {"width": 64, "height": 64},
                "view": "low top-down",
                "outline": "single color outline",
                "shading": "basic shading",
                "detail": "medium detail",
                "text_guidance_scale": 8,
            },
        ),
        (
            "ruined_wall_frost",
            {
                "description": "broken concrete wall from frozen ruins, snow caps and icicles, cracked gray slab with frost, post-apocalyptic ice biome obstacle, low top-down pixel art, transparent background",
                "image_size": {"width": 96, "height": 48},
                "view": "low top-down",
                "outline": "single color outline",
                "shading": "basic shading",
                "detail": "medium detail",
                "text_guidance_scale": 8,
            },
        ),
        (
            "frozen_metal_debris",
            {
                "description": "twisted metal debris pile covered with frost and snow, rusted pipes and scrap, frozen ruin junk obstacle, low top-down pixel art, transparent background",
                "image_size": {"width": 64, "height": 48},
                "view": "low top-down",
                "outline": "single color outline",
                "shading": "basic shading",
                "detail": "medium detail",
                "text_guidance_scale": 8,
            },
        ),
    ]

    tileset_params = {
        "lower_description": "dirty compacted snow, windswept frozen wasteland ground, muted blue white with gray grime, subtle snowfield texture",
        "upper_description": "cracked blue ice and frozen crust, cold apocalypse terrain layer, desaturated cyan icy surface",
        "transition_description": "snow blending into cracked ice with subtle slush and frost seams, stable seamless transitions, low noise",
        "tile_size": {"width": 32, "height": 32},
        "view": "low top-down",
        "shading": "basic shading",
        "detail": "low detail",
        "text_guidance_scale": 8,
        "tile_strength": 1.0,
        "tileset_adherence": 100.0,
        "tileset_adherence_freedom": 500.0,
        "transition_size": 0.25,
    }

    print("\n=== Phase 1: Enemies ===")
    for batch_idx, batch in enumerate(chunks(enemies, 3), start=1):
        print(f"--- enemy batch {batch_idx} ---")
        submitted = submit_characters_batch(batch)
        save_json(OUT / f"enemy_batch_{batch_idx}_submitted.json", submitted)
        valid = {k: v for k, v in submitted.items() if v.get("job_id")}
        results = wait_for_jobs(valid, f"enemy-b{batch_idx}") if valid else {}
        for name, meta in submitted.items():
            manifest["enemies"][name] = {
                **meta,
                "job_result": results.get(name, {}),
            }
            cid = meta.get("character_id")
            if cid and results.get(name, {}).get("status") == "completed":
                download_character_zip(name, cid, OUT / "enemies" / name)
        save_json(OUT / f"enemy_batch_{batch_idx}_results.json", results)
        save_json(OUT / "manifest.partial.json", manifest)

    print("\n=== Phase 2: Map Objects ===")
    for batch_idx, batch in enumerate(chunks(objects, 3), start=1):
        print(f"--- object batch {batch_idx} ---")
        submitted = submit_objects_batch(batch)
        save_json(OUT / f"object_batch_{batch_idx}_submitted.json", submitted)
        valid = {k: v for k, v in submitted.items() if v.get("job_id")}
        results = wait_for_jobs(valid, f"object-b{batch_idx}") if valid else {}
        for name, meta in submitted.items():
            manifest["objects"][name] = {
                **meta,
                "job_result": results.get(name, {}),
            }
            oid = meta.get("object_id")
            jid = meta.get("job_id")
            if jid and results.get(name, {}).get("status") == "completed":
                download_object_image(name, oid, jid, OUT / "objects")
        save_json(OUT / f"object_batch_{batch_idx}_results.json", results)
        save_json(OUT / "manifest.partial.json", manifest)

    print("\n=== Phase 3: Tileset ===")
    submitted_tileset = submit_tileset("frozen_wasteland_tileset", tileset_params)
    save_json(OUT / "tileset_submitted.json", submitted_tileset)
    valid_tileset = {k: v for k, v in submitted_tileset.items() if v.get("job_id")}
    tileset_results = wait_for_jobs(valid_tileset, "tileset") if valid_tileset else {}
    for name, meta in submitted_tileset.items():
        manifest["tileset"][name] = {
            **meta,
            "job_result": tileset_results.get(name, {}),
        }
        tsid = meta.get("tileset_id")
        if tsid and tileset_results.get(name, {}).get("status") == "completed":
            download_tileset(name, tsid, OUT / "tileset")
    save_json(OUT / "tileset_results.json", tileset_results)

    balance_after = api_call("GET", "/balance")
    save_json(OUT / "balance_after.json", balance_after)
    manifest["balance_after"] = balance_after
    save_json(OUT / "manifest.json", manifest)
    print("\n=== Done ===")
    print(f"Output: {OUT}")


if __name__ == "__main__":
    main()
