# Level 3 — Hell Furnace Production Pack

Based on confirmed decisions:
- 1C = small mechanics enabled
- 2B = demonic foundry
- 3A = furnace titan boss
- 4A = lava-rift dominant map
- 5B = medium contrast
- 6A = shared pickups
- 7C = clearly visible demonic flavor
- Follow-up mechanic choice = **C (both)**
  - M1 Molten Ground
  - M3 Burn-tag Projectile Variant

This document is the practical production companion to:
- `LEVEL3_HELL_FURNACE_ASSET_SPEC.md`

---

## 1. Final naming set

### Enemy mapping
| Gameplay Slot | Current ID | Level 3 Name | Chinese Suggestion | Notes |
|---|---|---|---|---|
| Walker | `walker` | `cinder_thrall` | 烬火仆尸 | 廉价近战杂兵，焦黑人形 |
| Mutant Dog | `mutant_dog` | `furnace_hound` | 炉犬 | 快速扑咬单位 |
| Acid Bug | `acid_bug` | `slag_spitter` | 熔渣喷吐虫 | 远程喷吐，带灼烧感 |
| Iron Giant | `iron_giant` | `iron_warden` | 黑铁狱卫 | 重甲慢速压迫单位 |
| Exploder | `exploder` | `ember_bomber` | 余烬爆徒 | 死后留灼烧地面更合理 |
| Boss | `boss_ash_behemoth` | `inferno_titan` | 熔炉泰坦 | 最终 Boss，黑铁巨像 |

### Object mapping
| Current Slot | Level 3 Name | Chinese Suggestion | Notes |
|---|---|---|---|
| `dead_tree` | `charred_spike_tree` | 炭化尖刺枯树 | 更像地狱枯木 / 刺桩 |
| `metal_debris` | `slag_metal_debris` | 熔渣金属废堆 | 黑铁、链条、管道 |
| `ruined_wall` | `forge_ruined_wall` | 铸炉残墙 | 热损混凝土 + 黑铁 |
| `wrecked_car` | `burned_wrecked_car` | 焚毁废车 | 半熔化、焦壳感 |
| `large_rock` | `obsidian_slag_boulder` | 黑曜熔渣巨石 | 裂隙发热但别太亮 |

### Tileset label
- `hell_furnace_tileset`
- 中文：地狱熔炉地表 / 熔岩裂谷地表

---

## 2. Visual hierarchy rules
Level 3 is easy to over-design. Use these guardrails:

### Map should be darker than enemies
- ground = dark ash / black iron / cooled slag
- lava = accent lanes, not orange flood fill
- enemies = slightly brighter silhouettes with controlled hot cores

### Boss should be brightest living target on screen
- chest vent / cracks / head / weapon / shoulder fissures can glow
- but still keep most body in black iron / dark crimson

### Ranged threat readability
- `slag_spitter` must visually read as ranged from silhouette alone
- use pressure sac / open maw / nozzle / chimney-like back vent

### Exploder readability
- `ember_bomber` needs swollen unstable center mass
- silhouette should read danger before animation/VFX

---

## 3. PixelLab prompt direction

### Global prompt language to keep consistent
Use these ingredients repeatedly across the pack:
- low top-down pixel art
- readable silhouette
- demonic foundry
- black iron
- molten cracks
- scorched stone
- lava rift
- infernal forge
- chains / spikes / horn motifs
- medium contrast
- not overly noisy

Avoid adding all of these to every single prompt. Keep each prompt focused.

---

## 4. Enemy prompt drafts

### 4.1 cinder_thrall
**template suggestion:** `mannequin`

**Prompt draft**
> cinder thrall, ember-infused humanoid husk, scorched cult-forge servant, blackened skin and torn furnace rags, cracked orange ember glow in chest and limbs, demonic foundry minion, low top-down pixel art, readable humanoid melee silhouette, black iron and ash gray with molten orange accents, medium contrast, not overly detailed

**Size**
- 24x24 or 32x32

**Why this works**
- keeps humanoid clarity
- not too elite-looking
- visually belongs to demonic forge theme

---

### 4.2 furnace_hound
**template suggestion:** `dog`

**Prompt draft**
> furnace hound, infernal forge war dog, lean hellhound made of charred flesh and black iron scraps, glowing molten maw, heat cracks along spine, aggressive fast low silhouette, demonic foundry beast, low top-down pixel art, readable flanker enemy, medium contrast, not overly noisy

**Size**
- 24x24

**Why this works**
- fast readable profile
- enough infernal flavor without looking like boss material

---

### 4.3 slag_spitter
**template suggestion:** `mannequin` first try, but if too humanoid-looking, redraw toward insect/bug-beast feel

**Prompt draft**
> slag spitter, demonic furnace bug, molten artillery insect with pressure sac and nozzle maw, black iron shell, glowing lava cracks, spits burning slag and molten tar, ranged threat silhouette, infernal foundry monster, low top-down pixel art, medium contrast, readable non-melee profile

**Size**
- 32x32

**Redraw note**
- this one is high risk for prompt drift
- prepare 2-3 redraw candidates if first result feels too human or too generic beetle

---

### 4.4 iron_warden
**template suggestion:** `mannequin`

**Prompt draft**
> iron warden, hulking demonic forge guardian, black iron execution brute with furnace core in chest, heavy armor plating, thick limbs, chained pauldrons, molten seams, slow oppressive tank silhouette, infernal foundry enforcer, low top-down pixel art, medium contrast, readable bruiser enemy

**Size**
- 40x40

**Why this works**
- preserves iron giant role
- stronger world-specific identity

---

### 4.5 ember_bomber
**template suggestion:** `mannequin`

**Prompt draft**
> ember bomber, unstable infernal suicide creature, swollen ember core, cracked shell, black ash body with bright molten center, overpressurized furnace parasite, demonic foundry exploder unit, low top-down pixel art, readable danger silhouette, medium contrast

**Size**
- 28x28 or 32x32

**Redraw goal**
- danger must read instantly
- avoid just making a normal zombie with glowing chest

---

### 4.6 inferno_titan
**template suggestion:** `mannequin`

**Prompt draft**
> inferno titan, giant furnace titan boss, towering humanoid black-iron colossus, molten lava cracks across chest and arms, horned crown silhouette, chained armor, infernal forge ruler, demonic foundry final boss, low top-down pixel art, massive oppressive silhouette, medium contrast, highly readable boss design

**Size**
- 64x64

**Redraw goal**
- must feel like a boss at first glance
- if first draft reads like elite mob, redraw immediately
- likely worth 2-3 boss candidates

---

## 5. Object prompt drafts

### 5.1 charred_spike_tree
> charred spike tree, hell-forged dead tree, carbonized trunk with sharp thorn-like branches, scorched demonic wasteland obstacle, low top-down pixel art, transparent background, black ash wood with faint ember accents, medium detail

- size: 48x64

### 5.2 burned_wrecked_car
> burned wrecked car, half-melted vehicle shell, scorched metal and broken frame, infernal wasteland car wreck, low top-down pixel art, transparent background, dark steel with subtle ember glow, medium detail

- size: 96x64

### 5.3 obsidian_slag_boulder
> obsidian slag boulder, large volcanic slag rock with black glassy crust and faint molten cracks, infernal wasteland obstacle, low top-down pixel art, transparent background, medium detail

- size: 64x64

### 5.4 forge_ruined_wall
> forge ruined wall, cracked furnace wall and black iron industrial barrier, heat-damaged concrete and demonic forge plating, low top-down pixel art, transparent background, medium detail

- size: 96x48

### 5.5 slag_metal_debris
> slag metal debris, twisted black iron scrap pile with chains, pipes and furnace fragments, infernal foundry junk obstacle, low top-down pixel art, transparent background, medium detail

- size: 64x48

---

## 6. Tileset prompt draft

### Target composition
- lower layer = dark ash / scorched ground / cooled slag
- upper layer = molten crust / lava seams / heated rock
- transition = clean lava-rift blend, stable readable edges

### Draft
**lower_description**
> dark scorched ash ground, cooled slag dust, infernal wasteland floor, black gray burnt earth with subtle texture

**upper_description**
> molten lava crust and heated black rock, glowing orange fissures, demonic furnace terrain layer, infernal rift surface

**transition_description**
> lava blending into scorched ash and black volcanic crust, stable seamless rift transitions, medium contrast, low noise, readable top-down terrain edges

### Tile settings target
- tile_size = 32x32
- view = low top-down
- shading = basic shading
- detail = low detail
- text_guidance_scale = 8
- tile_strength = 1.0
- tileset_adherence = 100.0
- tileset_adherence_freedom = 500.0
- transition_size = 0.25

---

## 7. Generation batch plan
Keep the same production pattern as Level 2.

### Batch 1 — enemies core
- cinder_thrall
- furnace_hound
- slag_spitter

### Batch 2 — enemies heavy
- iron_warden
- ember_bomber
- inferno_titan

### Batch 3 — objects A
- charred_spike_tree
- burned_wrecked_car
- obsidian_slag_boulder

### Batch 4 — objects B
- forge_ruined_wall
- slag_metal_debris

### Batch 5 — tileset
- hell_furnace_tileset

### Planned redraw priority
1. inferno_titan
2. slag_spitter
3. ember_bomber

This priority mirrors the usual failure points:
- boss not bossy enough
- ranged unit not reading as ranged
- exploder not reading as unstable danger

---

## 8. Theme integration checklist
After assets are accepted, integration likely needs:

### Data / file structure
- create `assets/generated/level3_hell_furnace/`
- create `assets/sprites/themes/level3_hell_furnace/`
- add `theme_manifest.json`

### Theme manifest mapping
- `walker` -> `cinder_thrall`
- `mutant_dog` -> `furnace_hound`
- `acid_bug` -> `slag_spitter`
- `iron_giant` -> `iron_warden`
- `exploder` -> `ember_bomber`
- `boss_ash_behemoth` -> `inferno_titan`

### Object mapping
- `dead_tree` -> `charred_spike_tree`
- `metal_debris` -> `slag_metal_debris`
- `ruined_wall` -> `forge_ruined_wall`
- `wrecked_car` -> `burned_wrecked_car`
- `large_rock` -> `obsidian_slag_boulder`

### Game integration
- add level selector option in `camp.gd`
- add localized label key
- add molten ground / burn projectile logic hooks
- verify fallback behavior when some themed assets are missing

---

## 9. Mechanics implementation notes
Because Johnson selected both M1 and M3:

### M1 molten ground
Best sources:
- `ember_bomber` death residue
- `inferno_titan` slam aftermath

Visual target:
- short-lived glowing lava patch
- clear danger border
- not too large, not too bright

### M3 burn-tag projectile
Best source:
- `slag_spitter` projectile hit / splash

Visual target:
- molten glob / slag spit projectile
- impact leaves tiny brief ember splash or burn mark
- keep gameplay readable, not VFX spammy

---

## 10. Recommendation for next action
Best next production step:
1. clone Level 2 PixelLab script into a Level 3 version
2. replace naming/prompts/output dir
3. generate first 6 enemies
4. review boss / spitter / bomber first
5. only then generate objects and tileset redraws if needed

That keeps iteration tight and avoids wasting jobs on a style direction that hasn't been visually validated yet.
