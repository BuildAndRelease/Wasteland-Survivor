# Level 3 — Hell Furnace Asset Spec (Confirmed Draft)

## Confirmed direction
Johnson confirmed the current production direction as:
- **1C** — introduce a small amount of new Level 3 mechanics
- **2B** — overall tone = **Demonic Foundry / 恶魔熔炉**
- **3A** — boss direction = **Furnace Titan / 熔炉泰坦**
- **4A** — map mood = **lava rift dominant / 熔岩裂谷为主**
- **5B** — color intensity = **medium contrast / 中等对比**
- **6A** — pickups remain **shared**
- **7C** — demonic / religious flavor can be **clearly present**

## Goal
Create a third-stage biome art pack for **Wasteland Survivor** with the theme **Hell Furnace / Infernal Foundry / Doomsday Smelter**.

Target: keep the current gameplay production-efficient while giving the game a clearly stronger late-stage visual escalation than:
- Level 1: ash wasteland
- Level 2: frozen wasteland
- Level 3: hell furnace

---

## Recommended strategy
**Confirmed direction: keep the existing enemy archetype structure, but allow a small amount of Level 3-exclusive mechanic seasoning.**

Recommended scope boundary:
- keep the same 5 standard enemy slots + 1 boss slot
- keep the same core spawn structure and balance framework
- allow **light theme-linked mechanics / hazards / VFX behaviors** that do not require a full enemy-system rewrite
- prefer changes that improve stage identity without exploding QA scope

Good examples of “1C small mechanics”:
- lava fissure hazard decals / periodic damage zones
- boss slam leaving temporary molten ground
- ranged enemy projectile applying brief burn / zone denial feel
- exploder leaving a short-lived ember pool after detonation
- map vents occasionally pulsing heat for visual danger signaling

Avoid for now:
- whole new enemy roster outside the 5+1 structure
- deep elemental status system rework
- fully dynamic environmental simulation
- complicated pathfinding hazards that would destabilize the run

Existing gameplay archetypes to reskin:
- `walker` → slow melee chaser
- `mutant_dog` → fast melee chaser
- `acid_bug` → ranged attacker
- `iron_giant` → tanky slow bruiser
- `exploder` → suicide unit
- `boss_ash_behemoth` → final boss archetype

---

## Theme positioning
Working fantasy: **demonic foundry / infernal furnace**, with **clearly visible demonic flavor**, not just industrial wasteland.

Core mood:
- molten metal
- black iron
- scorched stone
- lava rifts and magma seams
- sacrificial forge shapes / infernal altars / chained furnace architecture
- spikes, chains, horn silhouettes, riveted demonic metalwork
- smoke, ash, sparks, ember glow
- oppressive heat and ritual-industrial menace

Tone options (decision recorded):
- A. Industrial Inferno
- **B. Demonic Foundry** ✅ selected
- C. Apocalyptic Smelter
- D. Mixed

Chosen interpretation:
- demonic imagery is allowed to be obvious
- however, readability still beats ornamentation
- keep it infernal-industrial rather than turning into pure spell-fantasy purple hell

---

## Art direction
### Visual language
- top-down readable pixel art
- strong silhouette separation
- hot-core / dark-shell contrast
- bright orange-red used selectively for threat readability
- avoid turning the whole map into full-bright lava noise
- the environment should feel dangerous, but enemies/projectiles/UI must stay readable

### Palette
Base colors:
- charcoal black
- furnace iron / dark steel
- ash gray
- burnt umber
- deep crimson

Accent colors:
- molten orange
- lava yellow-orange
- ember red
- occasional toxic sulfur yellow or infernal green only if needed for ranged readability

Avoid:
- oversaturated everywhere
- too much pure red across all enemies
- overly magical purple spell look unless explicitly desired

---

## Proposed enemy set

### 1. Cinder Thrall
**Role:** walker replacement  
**Visual:** burned worker / slag zombie / ember-infused husk  
**Read:** disposable melee grunt  
**Suggested size:** 24x24 or 32x32, 4 directions

Key traits:
- cracked skin or armor seams with ember glow
- furnace soot, ash, ragged industrial scraps
- simple readable humanoid silhouette

---

### 2. Furnace Hound
**Role:** mutant_dog replacement  
**Visual:** lean hellhound / molten scrap dog / chained foundry beast  
**Read:** fast aggressive flanker  
**Suggested size:** 24x24, 4 directions

Key traits:
- low fast silhouette
- glowing maw / back vents / heat cracks
- should feel feral and fast, not tanky

---

### 3. Slag Spitter
**Role:** acid_bug replacement  
**Visual:** furnace beetle / slag injector / molten artillery bug  
**Read:** ranged threat  
**Suggested size:** 28x28 or 32x32, 4 directions

Key traits:
- obvious ranged anatomy: nozzle, maw, furnace sack, or pressure chamber
- can spit molten slag, burning tar, or fire blobs
- silhouette should not read as melee beetle only

---

### 4. Iron Warden
**Role:** iron_giant replacement  
**Visual:** black-iron execution construct / forge golem / armored furnace brute  
**Read:** heavy bruiser / tank  
**Suggested size:** 40x40, 4 directions

Key traits:
- broad shoulders, thick limbs, heavy plating
- core glow visible through vents or chest seam
- should feel slow and unstoppable

---

### 5. Ember Bomber
**Role:** exploder replacement  
**Visual:** unstable coal imp / explosive ember sac / overpressurized furnace crawler  
**Read:** suicide unit / immediate danger  
**Suggested size:** 24x24 or 28x28, 4 directions

Key traits:
- swollen explosive core
- clear danger before detonation
- stronger visual warning than normal melee units

---

### 6. Inferno Behemoth
**Role:** boss replacement  
**Visual:** **Furnace Titan** first, giant black-iron humanoid with molten fissures and infernal forge anatomy  
**Read:** final boss, massive oppressive silhouette  
**Suggested size:** 64x64, 4 directions

Boss direction options:
- **A. Furnace Titan** — humanoid black-iron giant with lava cracks ✅ selected
- B. Forge Beast — horned quadruped / beast-like infernal engine
- C. Smelter Mech — industrial war machine / walking furnace
- D. Hybrid Colossus — industrial titan with monster features

Boss art notes under selected direction:
- prioritize towering humanoid titan silhouette
- chest / mouth / shoulder vents can expose furnace glow
- optional horns / crown / chained pauldrons welcome
- should feel like a forged ruler / executioner of the furnace realm

---

## Proposed map object set
Keep the same obstacle count / replacement mapping as the current implementation for fast integration.

Current object mapping needed by code:
- `dead_tree`
- `metal_debris`
- `ruined_wall`
- `wrecked_car`
- `large_rock`

### Proposed Level 3 replacements

1. **charred_spike_tree**
- replacement for `dead_tree`
- burnt ironwood / carbonized spike trunk / furnace-scorched dead growth

2. **slag_metal_debris**
- replacement for `metal_debris`
- twisted black steel, pipes, chains, broken furnace plating

3. **forge_ruined_wall**
- replacement for `ruined_wall`
- cracked refractory wall / industrial barrier / heat-damaged concrete + iron

4. **burned_wrecked_car**
- replacement for `wrecked_car`
- half-melted vehicle shell with scorched plating and ember glow

5. **obsidian_slag_boulder**
- replacement for `large_rock`
- lava rock / obsidian chunk / cooling slag mound

Recommendation:
- keep object footprint readable and collision-compatible with existing obstacle sizes
- emphasize dark forms with small hot accents rather than full glowing objects

---

## Proposed ground tileset
### Required format
- 16-tile Wang / Marching Squares tileset
- 32x32
- low top-down
- must remain stable in repetition

### Visual target
- **lava rift dominant** battlefield language
- scorched earth + black iron plating + ash + molten seams
- lava should read as major cracks/channels/rift networks, not random orange noise
- some tiles can suggest heat vents, ritual furnace floor plating, or sacrificial forge circles

### Terrain language
Recommended composition:
- dark ash ground base
- cracked heated stone
- cooled slag patches
- faint molten fissures
- occasional industrial plating fragments

Avoid:
- high-frequency texture noise
- super bright molten edges on every tile
- visual clutter that competes with bullets, drops, and enemies

---

## Pickups / VFX / projectile variants
### Default recommendation
Keep shared pickups unless you specifically want stronger stage identity.

Shared-by-default:
- XP gem
- scrap coin
- health pack

Optional variants:
- ember XP shard
- furnace coin / heated scrap token
- red-hot med crate

Optional projectile/VFX variants:
- molten spit projectile for `acid_bug` replacement
- ember burst / slag splash for `exploder` replacement
- boss slam crack decal with lava glow
- heat haze / spark particle overlays

My recommendation:
- **must-have:** enemy + object + tileset pack
- **nice-to-have:** projectile skin for ranged enemy, boss impact decal
- **optional later:** pickup variants

---

## UI / level identity suggestions
If we want Level 3 to feel more complete, optional extras could include:
- level preview thumbnail for camp selector
- localized level name
- boss intro title card variant
- settlement/result screen background accent
- ambient audio concept: furnace rumble, chain drag, steam burst, lava pops

Proposed level name candidates:
- Hell Furnace
- Infernal Foundry
- Doomforge
- Furnace of Ruin
- Smelter Abyss

My recommendation: **Infernal Foundry** in English, **地狱熔炉** in Chinese.

---

## Asset production checklist
### Must-have
#### Enemies (6)
- cinder_thrall
- furnace_hound
- slag_spitter
- iron_warden
- ember_bomber
- inferno_behemoth

#### Objects (5)
- charred_spike_tree
- slag_metal_debris
- forge_ruined_wall
- burned_wrecked_car
- obsidian_slag_boulder

#### Tileset (1)
- 16-tile 32x32 hell furnace terrain set

### Nice-to-have
- boss redraw candidates x2-3
- spitter redraw candidates x2-3
- bomber redraw candidates x2-3
- object review sheet
- enemy review sheet
- tileset review sheet

### Optional polish
- themed projectile
- themed pickup variants
- theme manifest
- level selector entry
- preview art / key art

---

## Proposed theme integration structure
### Theme ID
Recommended id:
- `level3_hell_furnace`

### Generated output directory
Recommended:
- `assets/generated/level3_hell_furnace/`

### Theme sprite directory
Recommended:
- `assets/sprites/themes/level3_hell_furnace/`

### Mapping plan
Enemy mapping would mirror current archetypes:
- `walker` -> `cinder_thrall`
- `mutant_dog` -> `furnace_hound`
- `acid_bug` -> `slag_spitter`
- `iron_giant` -> `iron_warden`
- `exploder` -> `ember_bomber`
- `boss_ash_behemoth` -> `inferno_behemoth`

Object mapping would mirror current obstacle slots:
- `dead_tree` -> `charred_spike_tree`
- `metal_debris` -> `slag_metal_debris`
- `ruined_wall` -> `forge_ruined_wall`
- `wrecked_car` -> `burned_wrecked_car`
- `large_rock` -> `obsidian_slag_boulder`

---

## Generation notes
- use **4 directions** for stability
- keep behavior archetypes unchanged unless you explicitly want Level 3 to introduce mechanics
- submit in small batches if using PixelLab, same as Level 2
- generate characters, objects, and tileset separately
- keep prompt consistency across the whole pack
- prioritize silhouette readability over decorative detail
- for redraws, focus first on:
  1. boss
  2. ranged unit
  3. exploder

---

## Small mechanics recommendations (for chosen 1C scope)
Status: **confirmed = C (both M1 and M3)**

To match the selected direction, I recommend **only 1-2 of these for v1**:

### Option M1 — Molten Ground ✅ selected
- certain boss slams / exploder deaths leave a short-lived ember pool
- gameplay value: clearer area denial, stronger stage identity
- implementation risk: low to medium
- recommendation: **strong yes**

### Option M2 — Lava Rift Hazard Tiles
- rare map fissure decals pulse and damage briefly when active
- gameplay value: makes Level 3 feel like a place, not just a skin
- implementation risk: medium
- recommendation: **yes, if we want one environment mechanic**

### Option M3 — Burn-tag Projectile Variant ✅ selected
- `slag_spitter` projectile applies a short burn / damage-over-time impression
- gameplay value: ranged enemy becomes more theme-authentic
- implementation risk: low
- recommendation: **strong yes**

### Option M4 — Furnace Vent Telegraphs
- some ground vents flash before releasing heat burst / sparks
- gameplay value: visual drama and dodge moments
- implementation risk: medium
- recommendation: maybe later

### Confirmed v1 mechanic package
Johnson selected **C = both** from the follow-up mechanic choice.

So the current Level 3 mechanic package is:
- **M1 Molten Ground**
- **M3 Burn-tag Projectile Variant**

Practical mapping:
- `ember_bomber` death can leave a short-lived molten patch
- `inferno_behemoth` slam can leave temporary lava cracks / burning ground
- `slag_spitter` projectile can apply brief burn / lava splash pressure

This gives Level 3 a distinct mechanical identity without turning into a full combat-system rewrite.

---

## Questions to confirm before production
Status: **resolved by Johnson on 2026-04-22**

1. **Gameplay scope**
   - A. only换皮，不改玩法
   - B. 小改表现（弹道/VFX换主题）
   - **C. 第三关加少量新机制** ✅

2. **整体风格**
   - A. 工业炼狱
   - **B. 恶魔熔炉** ✅
   - C. 废土炼钢厂失控
   - D. 工业 + 恶魔混合

3. **Boss方向**
   - **A. 熔炉泰坦** ✅
   - B. 铸炉巨兽
   - C. 熔炼机甲
   - D. 混合型巨像

4. **地图气质占比**
   - **A. 熔岩裂谷为主** ✅
   - B. 黑铁工厂为主
   - C. 焦土废墟为主
   - D. 混合

5. **颜色强度**
   - A. 偏暗克制，亮点少
   - **B. 中等，对比明确** ✅
   - C. 高燃高亮，更张扬

6. **拾取物处理**
   - **A. 继续共用** ✅
   - B. 只改 XP gem
   - C. 全部做地狱熔炉版

7. **你想不想让第三关更“宗教/恶魔”一点？**
   - A. 不要，尽量工业
   - B. 可以一点点
   - **C. 可以明显一些** ✅

---

## Current recommended execution set
Based on Johnson's confirmed choices, the recommended production path is now:
- keep shared enemy roster structure, but add **light Level 3 mechanics**
- tone = **Demonic Foundry**
- boss = **Furnace Titan**
- map mood = **lava-rift dominant**
- contrast = **medium**
- pickups = **shared**
- demonic flavor = **clearly visible**

This version should produce a Level 3 that feels meaningfully more dangerous and memorable than Level 2 without requiring a full combat-system redesign.
