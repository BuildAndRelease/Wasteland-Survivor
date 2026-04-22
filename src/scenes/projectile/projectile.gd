extends Area2D
## Projectile fired by the player toward enemies.
## Supports lifesteal via Berserker Blood combo.

@export var speed: float = 400.0
@export var damage: int = 10
@export var lifetime: float = 2.0

var direction: Vector2 = Vector2.RIGHT
var time_alive: float = 0.0

# Berserker Blood lifesteal (set by player when firing)
var lifesteal_percent: float = 0.0
var lifesteal_target: Node2D = null

func _ready() -> void:
	# Connect to body_entered for detecting enemies
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	time_alive += delta
	if time_alive >= lifetime:
		call_deferred("queue_free")

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		body.take_damage(damage)
		# Berserker Blood: heal player on hit
		if lifesteal_percent > 0.0 and is_instance_valid(lifesteal_target) and lifesteal_target.has_method("heal"):
			lifesteal_target.heal(damage * lifesteal_percent)
		call_deferred("queue_free")
