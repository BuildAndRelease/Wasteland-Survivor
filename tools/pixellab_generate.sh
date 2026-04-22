#!/bin/bash
# PixelLab batch asset generator for Wasteland Survivor
# Generates characters, enemies, tileset, and map objects

API="https://api.pixellab.ai/v2"
TOKEN="${PIXELLAB_TOKEN:-}"
OUT="$(cd "$(dirname "$0")/.." && pwd)/assets/generated"

# Helper: create character with 4 directions (returns background_job_id)
create_char_4dir() {
  local desc="$1"
  local w="$2"
  local h="$3"
  local template="${4:-mannequin}"
  local view="${5:-low top-down}"
  local outline="${6:-thin}"
  local detail="${7:-medium}"
  
  curl -s -X POST "$API/create-character-with-4-directions" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "{
      \"description\": \"$desc\",
      \"image_size\": {\"width\": $w, \"height\": $h},
      \"template_id\": \"$template\",
      \"view\": \"$view\",
      \"outline\": \"$outline\",
      \"shading\": \"soft\",
      \"detail\": \"$detail\",
      \"async_mode\": true
    }"
}

# Helper: create tileset
create_tileset() {
  local desc="$1"
  local tile_size="$2"
  
  curl -s -X POST "$API/create-tileset" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "{
      \"description\": \"$desc\",
      \"tile_size\": $tile_size
    }"
}

# Helper: create map object
create_map_object() {
  local desc="$1"
  local w="$2"
  local h="$3"
  
  curl -s -X POST "$API/create-map-object" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "{
      \"description\": \"$desc\",
      \"image_size\": {\"width\": $w, \"height\": $h}
    }"
}

# Helper: check background job status
check_job() {
  local job_id="$1"
  curl -s -H "Authorization: Bearer $TOKEN" "$API/background-jobs/$job_id"
}

echo "=== Wasteland Survivor Asset Generation ==="
echo "Available generations: 1634"
echo ""

# --- PHASE 1: Player Characters (4 directions, 32x32, humanoid) ---
echo "--- Phase 1: Player Characters ---"

echo "[1/4] Survivor (balanced warrior)..."
SURVIVOR_RESP=$(create_char_4dir \
  "post-apocalyptic wasteland survivor, green military jacket, brown boots, carrying a rusty gun, dark muted colors, tough all-rounder fighter" \
  32 32 mannequin "low top-down" "thin" "medium")
echo "  Response: $SURVIVOR_RESP"
SURVIVOR_JOB=$(echo "$SURVIVOR_RESP" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('background_job_id',''))" 2>/dev/null)
echo "  Job ID: $SURVIVOR_JOB"

echo "[2/4] Scavenger (pickup specialist)..."
SCAVENGER_RESP=$(create_char_4dir \
  "post-apocalyptic scavenger, long green coat with large backpack full of junk, goggles on forehead, resourceful looter, dark muted wasteland colors" \
  32 32 mannequin "low top-down" "thin" "medium")
echo "  Response: $SCAVENGER_RESP"
SCAVENGER_JOB=$(echo "$SCAVENGER_RESP" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('background_job_id',''))" 2>/dev/null)
echo "  Job ID: $SCAVENGER_JOB"

echo "[3/4] Demolisher (AoE heavy)..."
DEMOLISHER_RESP=$(create_char_4dir \
  "post-apocalyptic demolisher, heavy orange-red armor plates, bulky build, carrying explosives, fire details on armor, dark wasteland colors" \
  32 32 mannequin "low top-down" "thin" "medium")
echo "  Response: $DEMOLISHER_RESP"
DEMOLISHER_JOB=$(echo "$DEMOLISHER_RESP" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('background_job_id',''))" 2>/dev/null)
echo "  Job ID: $DEMOLISHER_JOB"

echo "[4/4] Mutant (high attack glass cannon)..."
MUTANT_RESP=$(create_char_4dir \
  "post-apocalyptic mutant humanoid, pale purple skin with glowing red eyes, torn dark clothes, visible veins and mutations, eerie and dangerous" \
  32 32 mannequin "low top-down" "thin" "medium")
echo "  Response: $MUTANT_RESP"
MUTANT_JOB=$(echo "$MUTANT_RESP" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('background_job_id',''))" 2>/dev/null)
echo "  Job ID: $MUTANT_JOB"

# --- PHASE 2: Enemies ---
echo ""
echo "--- Phase 2: Enemies ---"

echo "[1/6] Walker (slow zombie)..."
WALKER_RESP=$(create_char_4dir \
  "wasteland zombie walker, decayed flesh, tattered rags, shambling undead, yellow glowing eyes, dark red and brown colors" \
  24 24 mannequin "low top-down" "thin" "low")
echo "  Response: $WALKER_RESP"
WALKER_JOB=$(echo "$WALKER_RESP" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('background_job_id',''))" 2>/dev/null)
echo "  Job ID: $WALKER_JOB"

echo "[2/6] Mutant Dog (fast quadruped)..."
MDOG_RESP=$(create_char_4dir \
  "mutated wasteland dog, mangy orange-brown fur, red glowing eyes, sharp teeth, aggressive feral beast" \
  24 24 dog "low top-down" "thin" "low")
echo "  Response: $MDOG_RESP"
MDOG_JOB=$(echo "$MDOG_RESP" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('background_job_id',''))" 2>/dev/null)
echo "  Job ID: $MDOG_JOB"

echo "[3/6] Acid Bug (ranged insect)..."
ABUG_RESP=$(create_char_4dir \
  "giant mutated acid bug insect, bright green glowing body, yellow eyes, dripping acid, six legs, small but dangerous" \
  20 20 mannequin "low top-down" "thin" "low")
echo "  Response: $ABUG_RESP"
ABUG_JOB=$(echo "$ABUG_RESP" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('background_job_id',''))" 2>/dev/null)
echo "  Job ID: $ABUG_JOB"

echo "[4/6] Iron Giant (tank)..."
IGIANT_RESP=$(create_char_4dir \
  "massive iron giant robot, heavy steel grey armor with rust patches, red glowing eyes, slow but powerful, bulky mechanical body" \
  40 40 mannequin "low top-down" "thin" "medium")
echo "  Response: $IGIANT_RESP"
IGIANT_JOB=$(echo "$IGIANT_RESP" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('background_job_id',''))" 2>/dev/null)
echo "  Job ID: $IGIANT_JOB"

echo "[5/6] Exploder (suicide bomber bug)..."
EXPLODER_RESP=$(create_char_4dir \
  "small explosive mutant bug, bright orange-red glowing body about to explode, pulsating, unstable, fast-moving" \
  18 18 mannequin "low top-down" "thin" "low")
echo "  Response: $EXPLODER_RESP"
EXPLODER_JOB=$(echo "$EXPLODER_RESP" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('background_job_id',''))" 2>/dev/null)
echo "  Job ID: $EXPLODER_JOB"

echo "[6/6] Ash Behemoth Boss (64x64)..."
BOSS_RESP=$(create_char_4dir \
  "ash behemoth, massive dark crimson beast boss monster, rocky armored body, glowing orange cracks, horned head, terrifying wasteland abomination" \
  64 64 mannequin "low top-down" "thin" "high")
echo "  Response: $BOSS_RESP"
BOSS_JOB=$(echo "$BOSS_RESP" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('background_job_id',''))" 2>/dev/null)
echo "  Job ID: $BOSS_JOB"

# --- PHASE 3: Tileset ---
echo ""
echo "--- Phase 3: Tileset ---"

echo "[1/1] Wasteland ground tileset..."
TILESET_RESP=$(create_tileset \
  "post-apocalyptic wasteland ground, cracked dry earth, dark brown dirt with ash patches, scattered rubble and debris" \
  32)
echo "  Response: $TILESET_RESP"
TILESET_JOB=$(echo "$TILESET_RESP" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('background_job_id',''))" 2>/dev/null)
echo "  Job ID: $TILESET_JOB"

# --- PHASE 4: Map Objects ---
echo ""
echo "--- Phase 4: Map Objects ---"

echo "[1/5] Ruined wall..."
WALL_RESP=$(create_map_object \
  "ruined concrete wall, post-apocalyptic, crumbling brick and concrete, dark grey and brown, top-down view" \
  64 32)
echo "  Response: $WALL_RESP"
WALL_JOB=$(echo "$WALL_RESP" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('background_job_id',''))" 2>/dev/null)
echo "  Job ID: $WALL_JOB"

echo "[2/5] Wrecked car..."
CAR_RESP=$(create_map_object \
  "wrecked abandoned car, rusted, broken windows, post-apocalyptic wasteland, top-down view, dark brown and grey" \
  64 40)
echo "  Response: $CAR_RESP"
CAR_JOB=$(echo "$CAR_RESP" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('background_job_id',''))" 2>/dev/null)
echo "  Job ID: $CAR_JOB"

echo "[3/5] Large rock..."
ROCK_RESP=$(create_map_object \
  "large boulder rock, grey stone with moss, wasteland environment, top-down view" \
  48 48)
echo "  Response: $ROCK_RESP"
ROCK_JOB=$(echo "$ROCK_RESP" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('background_job_id',''))" 2>/dev/null)
echo "  Job ID: $ROCK_JOB"

echo "[4/5] Dead tree..."
TREE_RESP=$(create_map_object \
  "dead burnt tree stump, charred bark, post-apocalyptic wasteland, top-down view, dark brown" \
  32 48)
echo "  Response: $TREE_RESP"
TREE_JOB=$(echo "$TREE_RESP" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('background_job_id',''))" 2>/dev/null)
echo "  Job ID: $TREE_JOB"

echo "[5/5] Metal debris pile..."
DEBRIS_RESP=$(create_map_object \
  "pile of scrap metal debris, rusty iron parts, nuts bolts pipes, post-apocalyptic junk pile, top-down view" \
  40 32)
echo "  Response: $DEBRIS_RESP"
DEBRIS_JOB=$(echo "$DEBRIS_RESP" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('background_job_id',''))" 2>/dev/null)
echo "  Job ID: $DEBRIS_JOB"

# --- Save all job IDs ---
echo ""
echo "=== All Jobs Submitted ==="
cat > "$OUT/job_ids.json" << EOF
{
  "characters": {
    "survivor": "$SURVIVOR_JOB",
    "scavenger": "$SCAVENGER_JOB",
    "demolisher": "$DEMOLISHER_JOB",
    "mutant": "$MUTANT_JOB"
  },
  "enemies": {
    "walker": "$WALKER_JOB",
    "mutant_dog": "$MDOG_JOB",
    "acid_bug": "$ABUG_JOB",
    "iron_giant": "$IGIANT_JOB",
    "exploder": "$EXPLODER_JOB",
    "boss_ash_behemoth": "$BOSS_JOB"
  },
  "tileset": {
    "wasteland_ground": "$TILESET_JOB"
  },
  "objects": {
    "ruined_wall": "$WALL_JOB",
    "wrecked_car": "$CAR_JOB",
    "large_rock": "$ROCK_JOB",
    "dead_tree": "$TREE_JOB",
    "metal_debris": "$DEBRIS_JOB"
  }
}
EOF

echo "Job IDs saved to $OUT/job_ids.json"
echo ""
echo "Wait 2-5 minutes, then run the download script to fetch results."
