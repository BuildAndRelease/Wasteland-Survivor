class_name BalanceConfig
extends RefCounted
## Centralized balance tuning knobs for easy adjustment.
## All gameplay-affecting values that need frequent tuning live here.

# --- Player ---
const PLAYER_BASE_HP: int = 100
const PLAYER_BASE_SPEED: float = 200.0
const PLAYER_BASE_ATTACK: int = 15
const PLAYER_BASE_ATTACK_RANGE: float = 150.0
const PLAYER_BASE_ATTACK_INTERVAL: float = 1.0
const PLAYER_BASE_XP_RANGE: float = 50.0
const PLAYER_DODGE_SPEED_MULT: float = 3.0
const PLAYER_DODGE_DURATION: float = 0.2
const PLAYER_DODGE_COOLDOWN: float = 2.0

# --- Level-up stat growth ---
const ATTACK_PER_LEVEL: int = 2
const HP_PER_LEVEL: int = 5

# --- XP Curve (power function) ---
## XP required = XP_BASE * level ^ XP_EXPONENT
const XP_BASE: int = 15
const XP_EXPONENT: float = 1.35
const PLAYER_MAX_LEVEL: int = 50

# --- Wave Timing ---
const WAVE_DURATION: float = 180.0  # 3 min per wave
const MAX_WAVES: int = 5

# --- Enemy Scaling Per Wave ---
## Applied as multipliers to base enemy stats.
const WAVE_HP_MULTS: Array[float] = [1.0, 1.5, 2.5, 4.0, 6.0]
const WAVE_SPEED_MULTS: Array[float] = [1.0, 1.1, 1.2, 1.35, 1.5]
const WAVE_DAMAGE_MULTS: Array[float] = [1.0, 1.3, 1.8, 2.5, 3.5]
const WAVE_SPAWN_INTERVALS: Array[float] = [0.7, 0.5, 0.35, 0.2, 0.12]

# --- Scrap Coin Rewards ---
const SCRAP_PER_WAVE: int = 20
const SCRAP_PER_KILL: float = 0.5
const SCRAP_BOSS_BONUS: int = 200
const SCRAP_VICTORY_BONUS: int = 100

# --- Pickup ---
const XP_GEM_MAGNET_BASE: float = 50.0

# --- Monster Drops ---
const COIN_DROP_RATE: float = 0.04
const XP_MAGNET_DROP_RATE: float = 0.015
const HEALTH_PACK_DROP_RATE: float = 0.025
const COIN_DROP_VALUE: int = 10
const HEALTH_PACK_HEAL_PERCENT: float = 0.25

# --- Boss ---
const BOSS_HP: int = 5000
const BOSS_SPEED: float = 60.0
const BOSS_CONTACT_DAMAGE: int = 50
const BOSS_SLAM_DAMAGE: int = 60
const BOSS_SLAM_RADIUS: float = 130.0
const BOSS_SLAM_COOLDOWN: float = 4.0
const BOSS_CHARGE_DAMAGE: int = 70
const BOSS_CHARGE_SPEED: float = 350.0
const BOSS_CHARGE_COOLDOWN: float = 7.0
const BOSS_SUMMON_COUNT: int = 6
const BOSS_SUMMON_COOLDOWN: float = 10.0
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

# --- Map Obstacles ---
const OBSTACLE_MIN_PER_CHUNK: int = 2
const OBSTACLE_MAX_PER_CHUNK: int = 5

# --- Screen Shake ---
const SHAKE_PLAYER_HIT_INTENSITY: float = 4.0
const SHAKE_PLAYER_HIT_DURATION: float = 0.15
const SHAKE_BOSS_SLAM_INTENSITY: float = 8.0
const SHAKE_BOSS_SLAM_DURATION: float = 0.3
const SHAKE_EXPLOSION_INTENSITY: float = 6.0
const SHAKE_EXPLOSION_DURATION: float = 0.2
