extends Node2D
## Poison Gas: area that slows and damages enemies over time.

var duration: float = 4.0
var radius: float = 70.0
var slow_amount: float = 0.5
var damage_per_tick: int = 3
var tick_interval: float = 0.5

var _lifetime: float = 0.0
var _tick_timer: float = 0.0
var _gas_area: Area2D = null


func _ready() -> void:
	_gas_area = $GasArea
	var shape: CircleShape2D = $GasArea/CollisionShape2D.shape
	shape.radius = radius
	# Scale visual to match
	$GasVisual.scale = Vector2(radius / 16.0, radius / 16.0)


func _physics_process(delta: float) -> void:
	_lifetime += delta
	_tick_timer -= delta

	if _tick_timer <= 0.0:
		_tick_timer = tick_interval
		_apply_gas_effects()

	# Fade out near end
	var alpha: float = clampf(1.0 - (_lifetime / duration), 0.2, 1.0)
	$GasVisual.modulate.a = alpha

	if _lifetime >= duration:
		queue_free()


func _apply_gas_effects() -> void:
	var bodies := _gas_area.get_overlapping_bodies()
	for body: Node2D in bodies:
		if not body.is_in_group("enemies"):
			continue
		if body.has_method("take_damage"):
			body.take_damage(damage_per_tick)
		if body.has_method("apply_slow"):
			body.apply_slow(slow_amount, tick_interval + 0.1)
