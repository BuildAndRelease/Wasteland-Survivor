extends Node2D
## Firestorm (Combo: Fire Bomb Lv3 + Poison Gas Lv3):
## Burning fog — doubled range and damage from poison gas, with fire visuals.

var duration: float = 8.0
var radius: float = 140.0
var damage_per_tick: int = 12
var tick_interval: float = 0.5
var slow_amount: float = 0.5

var _lifetime: float = 0.0
var _tick_timer: float = 0.0
var _storm_area: Area2D = null


func _ready() -> void:
	_storm_area = $StormArea
	var shape: CircleShape2D = $StormArea/CollisionShape2D.shape
	shape.radius = radius
	$StormVisual.scale = Vector2(radius / 16.0, radius / 16.0)


func _process(delta: float) -> void:
	_lifetime += delta
	_tick_timer -= delta

	if _tick_timer <= 0.0:
		_tick_timer = tick_interval
		_apply_storm_effects()

	# Flickering fire-fog effect
	var flicker: float = 0.3 + 0.15 * sin(_lifetime * 8.0)
	$StormVisual.modulate.a = clampf(flicker * (1.0 - _lifetime / duration), 0.1, 0.5)

	if _lifetime >= duration:
		queue_free()


func _apply_storm_effects() -> void:
	var bodies := _storm_area.get_overlapping_bodies()
	for body: Node2D in bodies:
		if not body.is_in_group("enemies"):
			continue
		if body.has_method("take_damage"):
			body.take_damage(damage_per_tick)
		if body.has_method("apply_slow"):
			body.apply_slow(slow_amount, tick_interval + 0.1)
