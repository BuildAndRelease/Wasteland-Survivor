extends Area2D
## Projectile fired by the player toward enemies.

@export var speed: float = 400.0
@export var damage: int = 10
@export var lifetime: float = 2.0

var direction: Vector2 = Vector2.RIGHT
var time_alive: float = 0.0

func _ready() -> void:
	# Connect to body_entered for detecting enemies
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	time_alive += delta
	if time_alive >= lifetime:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		body.take_damage(damage)
		queue_free()
