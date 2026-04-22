#!/bin/bash
# Download all generated PixelLab assets for Wasteland Survivor
API="https://api.pixellab.ai/v2"
TOKEN="${PIXELLAB_TOKEN:-}"
OUT="$(cd "$(dirname "$0")/.." && pwd)/assets/generated"

# Characters (use character zip export)
declare -A CHARS=(
  ["survivor"]="ca5d3790-8e43-437a-b06a-afc8f085627c"
  ["scavenger"]="7315126d-f6a5-4ee7-bd03-f6d2489c56bf"
  ["demolisher"]="dcc817a2-3eb4-41c3-940c-fb460fbcaa5e"
  ["mutant"]="90c4258a-4dbb-40be-a927-461ee84dab84"
)

declare -A ENEMIES=(
  ["walker"]="d035fa62-0bd5-4796-8bdc-a6b294a444cd"
  ["mutant_dog"]="0b1d541d-d3fa-47de-b7ec-499a058d6fae"
  ["acid_bug"]="e4a8d6b4-d3f7-4e51-a0fb-f167b3072108"
  ["iron_giant"]="b4d2ca38-c949-4d7e-9387-37d5f88e7083"
  ["exploder"]="2acbe5dd-4cda-4a05-8c3b-880dce8522c3"
  ["boss_ash_behemoth"]="dfb69d8f-ec3b-46e5-a663-f2409eecfc95"
)

declare -A OBJECTS=(
  ["ruined_wall"]="70530474-9716-49a3-aa10-912d06c4558d"
  ["wrecked_car"]="cdb710f5-2161-4ce1-b8ed-8849ca18390a"
  ["large_rock"]="15d9c805-1575-4b03-8bdc-10c1e7ccae6b"
  ["dead_tree"]="fee6315b-8878-4f96-a161-bb9c1c69b850"
  ["metal_debris"]="2a564e21-aa56-48fa-ac40-fa80c1a0ab3d"
  ["xp_gem"]="c175292f-5e78-427b-8245-cb755a19d348"
  ["scrap_coin"]="bbf06c82-8c09-4164-8f68-514b995f6d0e"
  ["health_pack"]="b4ea33ee-aa4d-4d2c-a79f-b9b2a77b657a"
)

TILESET_ID="b1a99000-29ea-4c69-93bb-4e1dff83a19c"

# Character jobs
declare -A CHAR_JOBS=(
  ["survivor"]="9696e31b-5fee-4c36-b329-82fa31df80a0"
  ["scavenger"]="4ab958c3-35c0-4b86-b4ca-ac60aab69217"
  ["demolisher"]="0b5fe5a8-cfef-473c-81da-6c922ba605f3"
  ["mutant"]="6f57a21e-ffc5-4f71-b439-763f1c4e40a1"
)

declare -A ENEMY_JOBS=(
  ["walker"]="e9915a84-7805-45c5-9acc-b95542549879"
  ["mutant_dog"]="71f099f0-9c99-4d6d-9c93-48eb5db986ef"
  ["acid_bug"]="031aece6-1951-41e8-b582-375b4500e397"
  ["iron_giant"]="44700024-3193-41dd-9d1c-8f8c88402218"
  ["exploder"]="784c8105-467b-45a7-8d9c-4a7d86cafbeb"
  ["boss_ash_behemoth"]="2d6d8654-a11e-4a1d-ad94-dbfce3b39e81"
)

declare -A OBJECT_JOBS=(
  ["ruined_wall"]="911a3745-e3a7-4942-92bb-9c431583364d"
  ["wrecked_car"]="a39802fd-1502-41f5-9697-b42088ff3403"
  ["large_rock"]="30ce6ae7-2c51-4e5b-a5c6-7498c37d3ffe"
  ["dead_tree"]="a227512a-1e9e-489b-9d38-b474bbfa7f9c"
  ["metal_debris"]="3b839f39-2729-4956-8179-668790c3cbbb"
  ["xp_gem"]="41701bc3-b849-4deb-bff6-9aebc0db4fe4"
  ["scrap_coin"]="bdeb85e1-1bc8-4edf-b609-df1929732336"
  ["health_pack"]="9fe05c3a-a216-4964-9a54-c970aa0c95d9"
)

TILESET_JOB="9666729d-3160-4131-bef7-d8e1ebbe0706"

# Check job status
check_job() {
  curl -s -H "Authorization: Bearer $TOKEN" "$API/background-jobs/$1"
}

# Download character as zip
download_char_zip() {
  local name="$1"
  local char_id="$2"
  local dest="$OUT/characters/${name}"
  mkdir -p "$dest"
  
  echo "  Downloading $name zip..."
  curl -s -H "Authorization: Bearer $TOKEN" \
    "$API/characters/${char_id}/zip" \
    -o "$dest/${name}.zip"
  
  if [ -f "$dest/${name}.zip" ] && file "$dest/${name}.zip" | grep -q "Zip"; then
    cd "$dest" && unzip -o "${name}.zip" 2>/dev/null
    echo "  ✅ $name extracted"
  else
    echo "  ⚠️  $name zip not ready or failed"
    cat "$dest/${name}.zip" 2>/dev/null | head -c 200
    echo ""
    rm -f "$dest/${name}.zip"
  fi
}

# Download object image from details
download_object() {
  local name="$1"
  local obj_id="$2"
  local dest_dir="$3"
  mkdir -p "$dest_dir"
  
  echo "  Fetching $name details..."
  local resp
  resp=$(curl -s -H "Authorization: Bearer $TOKEN" "$API/objects/${obj_id}")
  
  # Extract image from response
  echo "$resp" | python3 -c "
import sys, json, base64
data = json.load(sys.stdin)
images = data.get('images', [])
if images:
    for i, img in enumerate(images):
        b64 = img.get('base64', '') or img.get('image', {}).get('base64', '')
        fmt = img.get('format', 'png') or img.get('image', {}).get('format', 'png')
        if b64:
            with open('$dest_dir/${name}' + (f'_{i}' if i > 0 else '') + '.' + fmt, 'wb') as f:
                f.write(base64.b64decode(b64))
            print(f'  ✅ ${name} image {i} saved')
    if not any(img.get('base64') or img.get('image', {}).get('base64') for img in images):
        print(f'  ⚠️  ${name} no image data in response')
        print(str(data)[:300])
else:
    print(f'  ⚠️  ${name} no images yet')
    print(str(data)[:300])
" 2>&1
}

# Download tileset
download_tileset() {
  local ts_id="$1"
  local dest="$OUT/tileset"
  mkdir -p "$dest"
  
  echo "  Fetching tileset..."
  local resp
  resp=$(curl -s -H "Authorization: Bearer $TOKEN" "$API/tilesets/${ts_id}")
  
  echo "$resp" | python3 -c "
import sys, json, base64
data = json.load(sys.stdin)
# Save the tileset image
if 'tileset_image' in data:
    img = data['tileset_image']
    b64 = img.get('base64', '')
    if b64:
        with open('$dest/wasteland_ground.png', 'wb') as f:
            f.write(base64.b64decode(b64))
        print('  ✅ tileset saved')
    else:
        print('  ⚠️  no base64 in tileset_image')
elif 'images' in data:
    for i, img in enumerate(data['images']):
        b64 = img.get('base64', '')
        if b64:
            with open(f'$dest/tile_{i}.png', 'wb') as f:
                f.write(base64.b64decode(b64))
            print(f'  ✅ tile {i} saved')
else:
    print('  ⚠️  tileset data structure:')
    print(str(data)[:500])
" 2>&1
}

echo "=== Checking Job Status ==="
echo ""

# Check a sample job
echo "--- Sample job status ---"
check_job "${CHAR_JOBS[survivor]}" | python3 -m json.tool 2>/dev/null
echo ""

READY=true

echo "--- Character Jobs ---"
for name in survivor scavenger demolisher mutant; do
  STATUS=$(check_job "${CHAR_JOBS[$name]}" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('status','unknown'))" 2>/dev/null)
  echo "  $name: $STATUS"
  if [ "$STATUS" != "completed" ]; then READY=false; fi
done

echo "--- Enemy Jobs ---"
for name in walker mutant_dog acid_bug iron_giant exploder boss_ash_behemoth; do
  STATUS=$(check_job "${ENEMY_JOBS[$name]}" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('status','unknown'))" 2>/dev/null)
  echo "  $name: $STATUS"
  if [ "$STATUS" != "completed" ]; then READY=false; fi
done

echo "--- Object Jobs ---"
for name in ruined_wall wrecked_car large_rock dead_tree metal_debris xp_gem scrap_coin health_pack; do
  STATUS=$(check_job "${OBJECT_JOBS[$name]}" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('status','unknown'))" 2>/dev/null)
  echo "  $name: $STATUS"
  if [ "$STATUS" != "completed" ]; then READY=false; fi
done

echo "--- Tileset Job ---"
STATUS=$(check_job "$TILESET_JOB" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('status','unknown'))" 2>/dev/null)
echo "  wasteland_ground: $STATUS"
if [ "$STATUS" != "completed" ]; then READY=false; fi

echo ""

if [ "$READY" = false ]; then
  echo "⏳ Some jobs still processing. Run this script again in 1-2 minutes."
  echo ""
fi

echo "=== Downloading Available Assets ==="
echo ""

echo "--- Characters ---"
for name in survivor scavenger demolisher mutant; do
  download_char_zip "$name" "${CHARS[$name]}"
done

echo ""
echo "--- Enemies ---"
for name in walker mutant_dog acid_bug iron_giant exploder boss_ash_behemoth; do
  download_char_zip "$name" "${ENEMIES[$name]}"
done

echo ""
echo "--- Objects ---"
for name in ruined_wall wrecked_car large_rock dead_tree metal_debris; do
  download_object "$name" "${OBJECTS[$name]}" "$OUT/objects"
done

echo ""
echo "--- Pickups ---"
for name in xp_gem scrap_coin health_pack; do
  download_object "$name" "${OBJECTS[$name]}" "$OUT/pickups"
done

echo ""
echo "--- Tileset ---"
download_tileset "$TILESET_ID"

echo ""
echo "=== Done ==="
echo "Check $OUT for all downloaded assets"
