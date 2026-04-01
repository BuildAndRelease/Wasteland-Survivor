extends Node2D
## Electromagnetic Fortress (Combo: EMP Pulse Lv3 + Scrap Shield Lv3):
## Electric shield around player — damages, stuns and knocks back enemies on contact.

var stun_duration: float = 0.5
var knockback_force: float = 150.0
var contact_damage: int = 10
var radius: float = 60.0
var duration: float = 8.0
var tick_interval: float = 0.3

var _lifetime: float = 0.0
var _tick_timer: float = 0.0


func _ready() -> void:
	var shape: CircleShape2D = $ShieldArea/CollisionShape2D.shape
	shape.radius = radius
	$ShieldVisual.scale = Vector2(radius / 16.0, radius / 16.0)


func _physics_process(delta: float) -> void:
	_lifetime += delta
	_tick_timer -= delta

	if _tick_timer <= 0.0:
		_tick_timer = tick_interval
		_apply_shield_effects()

	# Electric pulse visual
	var pulse: float = 0.3 + 0.2 * sin(_lifetime * 10.0)
	$ShieldVisual.modulate.a = pulse

	if duration < 900.0 and _lifetime >= duration:
		queue_free()


func _apply_shield_effects() -> void:
	# Direct distance check for reliable detection
	var enemies := get_tree().get_nodes_in_group("enemies")
	for enemy: Node2D in enemies:
		if not is_instance_valid(enemy):
			continue
		if global_position.distance_to(enemy.global_position) > radius:
			continue
		if enemy.has_method("take_damage"):
			enemy.take_damage(contact_damage)
		if enemy.has_method("apply_stun"):
			enemy.apply_stun(stun_duration)
		if enemy.has_method("apply_knockback"):
			var dir := (enemy.global_position - global_position).normalized()
			enemy.apply_knockback(dir * knockback_force)
