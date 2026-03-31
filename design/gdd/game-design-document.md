# 废土幸存者 (Wasteland Survivor) - Game Design Document

## 1. Overview

- **Game Name:** Wasteland Survivor (废土幸存者)
- **Genre:** Roguelike + Auto-Shooter + Survival (Vampire Survivors-like)
- **Perspective:** Top-down 2D
- **Platform:** Web-first (HTML5), expandable to mobile/PC
- **Engine:** Godot 4 (GDScript)
- **Session Length:** 10-15 minutes
- **Core Loop:** Move → Auto-attack → Collect XP → Level up & pick skills → Survive

## 2. Core Gameplay

### Controls (Web)
- **Movement:** WASD / Arrow Keys
- **Attack:** Fully automatic, no manual aiming
- **Level Up:** 3-choice skill selection panel on each level up
- **Dodge:** Spacebar triggers a roll (2s cooldown)

### Base Character Stats
- Health: 100
- Move Speed: 200
- Attack Power: 10
- Attack Range: 150
- Attack Interval: 1.0s
- XP Pickup Range: 50

### Session Flow
1. Select character (unlockable)
2. Enter wasteland map
3. Enemies swarm from all directions
4. Kill → Drop XP → Level up → Pick skill
5. Wave every 3 minutes, 5 waves total
6. Final Boss fight
7. Settlement: earn Scrap Coins (permanent currency)

## 3. Skill System

### 10 Base Skills

| Skill | Type | Lv1 | Lv2 | Lv3 |
|-------|------|-----|-----|-----|
| Rust Bullet (锈弹射击) | Active-Ranged | Fire rust bullet every 1s | Fire rate +50% | Double shot |
| Fire Bomb (燃烧弹) | Active-AoE | Throw molotov, burns 3s | Range +50% | Ground fire 5s |
| Poison Gas (毒雾罐) | Active-Control | Release poison fog, slow enemies | Damage +100% | Fog lasts 8s |
| EMP Pulse (电磁脉冲) | Active-AoE | Ring shock, stun 1s | Range +50% | Stun 2s |
| Scrap Shield (废铁护盾) | Passive-Defense | -10% damage taken | -20% damage taken | Reflect melee damage |
| Scavenger Instinct (拾荒本能) | Passive-Utility | XP pickup range +30% | +50% | Auto-collect all screen XP |
| Spike Trap (钢刺陷阱) | Active-Trap | Place trap, damage + slow | Place 2 at once | Traps explode |
| Mutant Regen (变异再生) | Passive-Survival | Regen 1% HP/s | 2% | Below 30% HP: regen ×3 |
| Rage Injection (狂暴注射) | Active-Buff | Attack speed +30% for 5s | +50% | Immune to CC during |
| Iron Fist (铁拳冲击) | Active-Melee | Cone heavy hit | Knockback +100% | Add stun |

### 5 Combo Skills

| Combo Skill | Requirements | Effect |
|-------------|-------------|--------|
| Firestorm (烈焰风暴) | Fire Bomb Lv3 + Poison Gas Lv3 | Poison fog becomes burning fog, range + damage doubled |
| Electromagnetic Fortress (电磁铁壁) | EMP Pulse Lv3 + Scrap Shield Lv3 | Shield electrified, knockback + stun enemies |
| Death Trap Field (死亡陷阵) | Spike Trap Lv3 + Rust Bullet Lv3 | Traps auto-fire rust bullets |
| Berserker Blood (狂战之血) | Rage Injection Lv3 + Mutant Regen Lv3 | Lower HP = higher attack + lifesteal |
| Iron Fist Barrage (铁拳轰炸) | Iron Fist Lv3 + Fire Bomb Lv3 | Punches cause explosions |

## 4. Enemy Design

### Enemy Types

| Enemy | Trait | HP | Speed | Damage |
|-------|-------|-----|-------|--------|
| Wasteland Walker (废土行尸) | Slow, weak | Low | Slow | Low |
| Mutant Dog (变异犬) | Fast | Low | Fast | Medium |
| Acid Bug (酸液虫) | Ranged | Low | Medium | Medium |
| Iron Giant (铁甲巨人) | Tank | High | Slow | High |
| Exploder (爆炸虫) | Suicide bomber | Low | Fast | High (AoE) |

### Wave Design

| Wave | Time | Enemies |
|------|------|---------|
| Wave 1 | 0-3 min | Wasteland Walkers only |
| Wave 2 | 3-6 min | + Mutant Dogs, Acid Bugs |
| Wave 3 | 6-9 min | + Iron Giants, Exploders |
| Wave 4 | 9-12 min | All types mixed, density doubled |
| Final | 12-15 min | Boss "Ash Behemoth" (灰烬巨兽) + full screen swarm |

## 5. Camp System (Meta Progression)

### Currency
- **Scrap Coins (废铁币):** Earned per session, used for permanent upgrades

### Upgrades

| Upgrade | Cost | Effect |
|---------|------|--------|
| Health Boost I-V | 100-500 | Permanent +10%~50% max HP |
| Attack Boost I-V | 100-500 | Permanent +10%~50% attack |
| Speed Boost I-III | 200-600 | Permanent +5%~15% move speed |
| Unlock: Scavenger | 1000 | Starts with Scavenger Instinct, larger pickup range |
| Unlock: Demolisher | 1500 | Starts with Fire Bomb, stronger AoE |
| Unlock: Mutant | 2000 | Starts with Mutant Regen, low HP high attack |

## 6. Technical Requirements

### Target Performance
- 60 FPS on modern browsers (Chrome, Firefox, Safari)
- Support 200+ enemies on screen simultaneously
- Responsive design for different screen sizes
- HTML5 export via Godot

### Architecture
- Component-based entity system
- Object pooling for enemies and projectiles
- Data-driven skill/enemy configuration (JSON/Resource files)
- State machine for game flow (Menu → Game → Pause → GameOver → Settlement)

## 7. Development Phases

| Phase | Content | Timeline |
|-------|---------|----------|
| P1 Prototype | Character movement, auto-attack, enemy AI, XP system, level-up skill selection | PRIORITY - Do this first |
| P2 Skills | 10 base skills + 5 combo skills | After P1 |
| P3 Content | 5 enemy types, Boss, wave system, map decoration | |
| P4 Progression | Camp system, permanent upgrades, character unlock | |
| P5 Polish | SFX, particle effects, UI polish, balance tuning | |

## 8. Art Direction

- Post-apocalyptic wasteland theme
- Simple 2D sprites (placeholder-friendly for prototype)
- Dark, muted color palette with vibrant skill effects
- Minimal UI: HP bar, XP bar, skill icons, wave indicator
