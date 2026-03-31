class_name BalanceConfig
extends RefCounted
## Centralized balance tuning knobs for easy adjustment.
## All gameplay-affecting values that need frequent tuning live here.

# --- Player ---
const PLAYER_BASE_HP: int = 100
const PLAYER_BASE_SPEED: float = 200.0
const PLAYER_BASE_ATTACK: int = 10
const PLAYER_BASE_ATTACK_RANGE: float = 150.0
const PLAYER_BASE_ATTACK_INTERVAL: float = 1.0
const PLAYER_BASE_XP_RANGE: float = 50.0
const PLAYER_DODGE_SPEED_MULT: float = 3.0
const PLAYER_DODGE_DURATION: float = 0.2
const PLAYER_DODGE_COOLDOWN: float = 2.0

# --- XP Curve ---
## XP required = XP_BASE + (level - 1) * XP_PER_LEVEL
const XP_BASE: int = 20
const XP_PER_LEVEL: int = 15

# --- Wave Timing ---
const WAVE_DURATION: float = 180.0  # 3 min per wave
const MAX_WAVES: int = 5

# --- Enemy Scaling Per Wave ---
## Applied as multipliers to base enemy stats.
const WAVE_HP_MULTS: Array[float] = [1.0, 1.2, 1.4, 1.6, 1.8]
const WAVE_SPEED_MULTS: Array[float] = [1.0, 1.1, 1.15, 1.2, 1.25]
const WAVE_DAMAGE_MULTS: Array[float] = [1.0, 1.1, 1.2, 1.3, 1.4]
const WAVE_SPAWN_INTERVALS: Array[float] = [1.5, 1.2, 1.0, 0.5, 0.4]

# --- Scrap Coin Rewards ---
const SCRAP_PER_WAVE: int = 20
const SCRAP_PER_KILL: float = 0.5
const SCRAP_BOSS_BONUS: int = 200
const SCRAP_VICTORY_BONUS: int = 100

# --- Pickup ---
const XP_GEM_MAGNET_BASE: float = 50.0

# --- Boss ---
const BOSS_HP: int = 2000
const BOSS_SPEED: float = 55.0
const BOSS_CONTACT_DAMAGE: int = 30
const BOSS_SLAM_DAMAGE: int = 40
const BOSS_SLAM_RADIUS: float = 120.0
const BOSS_SLAM_COOLDOWN: float = 5.0
const BOSS_CHARGE_DAMAGE: int = 50
const BOSS_CHARGE_SPEED: float = 300.0
const BOSS_CHARGE_COOLDOWN: float = 8.0
const BOSS_SUMMON_COUNT: int = 4
const BOSS_SUMMON_COOLDOWN: float = 12.0
const BOSS_STUN_RESISTANCE: float = 0.5
const BOSS_KNOCKBACK_RESISTANCE: float = 0.3

# --- Skill Cooldowns ---
const FIRE_BOMB_COOLDOWN: float = 5.0
const POISON_GAS_COOLDOWN: float = 6.0
const EMP_PULSE_COOLDOWN: float = 8.0
const SPIKE_TRAP_COOLDOWN: float = 7.0
const RAGE_INJECTION_COOLDOWN: float = 12.0
const IRON_FIST_COOLDOWN: float = 4.0

# --- Combo Multipliers ---
const FIRESTORM_RANGE_MULT: float = 2.0
const FIRESTORM_DAMAGE_MULT: float = 2.0
const BERSERKER_MAX_ATTACK_BONUS: float = 1.0
const BERSERKER_LIFESTEAL_PERCENT: float = 0.1

# --- Screen Shake ---
const SHAKE_PLAYER_HIT_INTENSITY: float = 4.0
const SHAKE_PLAYER_HIT_DURATION: float = 0.15
const SHAKE_BOSS_SLAM_INTENSITY: float = 8.0
const SHAKE_BOSS_SLAM_DURATION: float = 0.3
const SHAKE_EXPLOSION_INTENSITY: float = 6.0
const SHAKE_EXPLOSION_DURATION: float = 0.2
