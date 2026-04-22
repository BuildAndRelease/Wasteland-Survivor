# Level 2 — Frozen Wasteland Asset Spec (Draft)

## Goal
Create a second-stage biome art pack for **Wasteland Survivor** that keeps the current gameplay archetypes unchanged, but shifts the world from **ashen wasteland** to **frozen wasteland / snowfield apocalypse**.

## Recommended strategy
Keep the existing gameplay enemy archetypes and only replace / extend the visual theme.
This minimizes code churn and lets the team ship Level 2 faster.

Existing gameplay archetypes to reskin:
- walker → slow melee chaser
- mutant_dog → fast melee chaser
- acid_bug → ranged attacker
- iron_giant → tanky slow bruiser
- exploder → suicide unit
- boss_ash_behemoth → final boss archetype

## Art direction
Base tone:
- post-apocalyptic frozen wasteland
- snow-covered ruins
- icy wind, frostbite, frozen metal, cracked blue-white ice
- low top-down pixel art
- muted palette, readable silhouettes
- avoid overly magical high-fantasy look unless explicitly requested

Palette:
- snow white / dirty white
- ice blue / pale cyan
- desaturated steel gray
- dark navy shadows
- limited accent colors for threat readability

## Proposed enemy set

### 1. Frost Walker
Role: walker replacement
Visual:
- frozen zombie / frostbitten scavenger
- ragged winter clothes
- pale blue skin, frozen limbs, dim icy eyes
- silhouette simple and readable
Suggested size: 24x24 or 32x32, 4 directions

### 2. Snowfang Hound
Role: mutant_dog replacement
Visual:
- gaunt feral snow hound / mutated arctic dog
- white-gray fur with icy spikes or frost patches
- fast aggressive profile
Suggested size: 24x24, 4 directions

### 3. Ice Spitter
Role: acid_bug replacement
Visual:
- frozen beetle / ice spitter insect / crystal-backed bug
- translucent cyan shell, cold glow, spits ice shards or freezing bile
- should read clearly as ranged threat
Suggested size: 32x32, 4 directions

### 4. Glacier Brute
Role: iron_giant replacement
Visual:
- hulking armored mutant or frozen industrial mech
- thick ice plating + rusted metal underneath
- heavy silhouette, slow unstoppable feel
Suggested size: 40x40, 4 directions

### 5. Frost Bomber
Role: exploder replacement
Visual:
- unstable frozen parasite / volatile ice core creature
- glowing cracked blue core, swelling before detonation
- readable danger silhouette
Suggested size: 28x28 or 32x32, 4 directions

### 6. Blizzard Behemoth
Role: boss replacement
Visual:
- giant horned frozen abomination / glacier titan
- cracked ice armor, frozen breath, blue-white glowing fissures
- massive silhouette, strong boss readability
Suggested size: 64x64, 4 directions (or boss front set + walk if needed)

## Proposed map object set
Keep the same count as the current stage for fast integration.

1. frozen_dead_tree
- leafless icy tree, bent by blizzard winds

2. snow_covered_wrecked_car
- half-buried wreck with snow on roof and hood

3. ice_boulder
- chunky rock with frozen crust / blue ice edges

4. ruined_wall_frost
- broken concrete wall with icicles / snow caps

5. frozen_metal_debris
- twisted metal scraps with frost and snow accumulation

## Proposed ground tileset
Type:
- 16-tile Wang tileset
- 32x32
- low top-down

Visual target:
- frozen dirt + packed snow + cracked ice transitions
- stable repetition
- low contrast
- should not overpower enemies/projectiles/UI

Suggested terrain language:
- dirty snow base
- icy seams / frozen puddles
- compacted footprints / wind-swept streaks very subtle
- avoid too much sparkle/noise

## Optional extras (only if needed)
- frozen pickup variants (xp gem / coin / health pack)
- snowdrift decals
- ice patch hazard tiles
- frozen research crate / supply cache

## Questions to confirm before generation
1. Should Level 2 keep exactly the same enemy behaviors and only swap visuals?
2. Should the tone be:
   - A. realistic frozen wasteland
   - B. mutant icy apocalypse
   - C. slightly fantastical ice monsters
3. Boss style preference:
   - A. glacier beast
   - B. frozen mech
   - C. humanoid frost titan
4. Map mood preference:
   - A. open snowfield
   - B. frozen ruins
   - C. ice lake / glacier edge
   - D. mixed
5. Do we want pickup visuals to remain shared across stages, or generate snow variants too?

## Generation notes
- Use 4 directions for stability.
- Submit in batches of <= 3 jobs due to PixelLab concurrency limit.
- Tileset and map objects should be generated separately from characters.
- Keep prompt consistency across the whole pack.
- Avoid high-detail noisy ground textures.
