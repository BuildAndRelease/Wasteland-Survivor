extends Node2D
## Electromagnetic Fortress (Combo: EMP Pulse Lv3 + Scrap Shield Lv3):
## Electric shield around player — stuns and knocks back enemies on contact.

var stun_duration: float = 0.5
var knockback_force: float = 150.0
var radius: float = 60.0
var duration: float = 8.0
var tick_interval: float = 0.3

var _lifetime: float = 0.0
var _tick_timer: float = 0.0
var _shield_area: Area2D = null


func _ready() -> void:
	_shield_area = $ShieldArea
	var shape: CircleShape2D = $ShieldArea/CollisionShape2D.shape
	shape.radius = radius
	$ShieldVisual.scale = Vector2(radius / 16.0, radius / 16.0)


func _process(delta: float) -> void:
	_lifetime += delta
	_tick_timer -= delta

	if _tick_timer <= 0.0:
		_tick_timer = tick_interval
		_apply_shield_effects()

	# Electric pulse visual
	var pulse: float = 0.3 + 0.2 * sin(_lifetime * 10.0)
	$ShieldVisual.modulate.a = pulse

	if _lifetime >= duration:
		queue_free()


func _apply_shield_effects() -> void:
	var bodies := _shield_area.get_overlapping_bodies()
	for body: Node2D in bodies:
		if not body.is_in_group("enemies"):
			continue
		if body.has_method("apply_stun"):
			body.apply_stun(stun_duration)
		if body.has_method("apply_knockback"):
			var dir := (body.global_position - global_position).normalized()
			body.apply_knockback(dir * knockback_force)
