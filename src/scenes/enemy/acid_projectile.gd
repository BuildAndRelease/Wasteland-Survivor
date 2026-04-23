extends Area2D
## Acid projectile fired by Acid Bug enemies toward the player.
## Damages player on contact and despawns.

@export var speed: float = 200.0
@export var damage: int = 12
@export var lifetime: float = 3.0
@export var burn_damage_per_tick: int = 0
@export var burn_tick_interval: float = 0.4
@export var burn_duration: float = 0.0
@export var projectile_color: Color = Color(0.3, 0.9, 0.1, 0.9)

var direction: Vector2 = Vector2.RIGHT
var time_alive: float = 0.0

func _ready() -> void:
	collision_layer = 16  # Layer 5: enemy projectile
	collision_mask = 1     # Layer 1: player
	body_entered.connect(_on_body_entered)

	# Visual: small colored square
	var sprite := ColorRect.new()
	sprite.color = projectile_color
	sprite.offset_left = -4.0
	sprite.offset_top = -4.0
	sprite.offset_right = 4.0
	sprite.offset_bottom = 4.0
	add_child(sprite)

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 5.0
	shape.shape = circle
	add_child(shape)

func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	time_alive += delta
	if time_alive >= lifetime:
		call_deferred("queue_free")

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(damage, null)
		if burn_damage_per_tick > 0 and burn_duration > 0.0 and body.has_method("apply_dot"):
			body.apply_dot(burn_damage_per_tick, burn_tick_interval, burn_duration)
	if GameManager.is_theme_active(GameManager.THEME_HELL_FURNACE):
		VfxManager.spawn_acid_splash(global_position, Color(1.0, 0.45, 0.1, 1.0))
	else:
		VfxManager.spawn_acid_splash(global_position)
	call_deferred("queue_free")
