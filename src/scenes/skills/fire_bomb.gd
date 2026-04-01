extends Node2D
## Fire Bomb: thrown toward target, creates a burning area on landing.
## Deals damage-over-time to enemies in the burn zone.

var target_position: Vector2 = Vector2.ZERO
var duration: float = 3.0
var radius: float = 60.0
var damage_per_tick: int = 5
var tick_interval: float = 0.5

var _travel_speed: float = 300.0
var _arrived: bool = false
var _lifetime: float = 0.0
var _tick_timer: float = 0.0
var _burn_area: Area2D = null


func _ready() -> void:
	_burn_area = $BurnArea
	_burn_area.monitoring = false
	$BurnVisual.visible = false
	# Set collision shape radius
	var shape: CircleShape2D = $BurnArea/CollisionShape2D.shape
	shape.radius = radius
	# Scale visual to match radius
	$BurnVisual.scale = Vector2(radius / 16.0, radius / 16.0)


func _physics_process(delta: float) -> void:
	if not _arrived:
		# Fly toward target
		var dir := (target_position - global_position).normalized()
		global_position += dir * _travel_speed * delta
		if global_position.distance_to(target_position) < 10.0:
			_arrived = true
			_burn_area.monitoring = true
			$BurnVisual.visible = true
			$ProjectileVisual.visible = false
		return

	# Burn phase
	_lifetime += delta
	_tick_timer -= delta

	if _tick_timer <= 0.0:
		_tick_timer = tick_interval
		_apply_burn_damage()

	# Fade out near end
	var alpha: float = clampf(1.0 - (_lifetime / duration), 0.2, 1.0)
	$BurnVisual.modulate.a = alpha

	if _lifetime >= duration:
		queue_free()


func _apply_burn_damage() -> void:
	var bodies := _burn_area.get_overlapping_bodies()
	for body: Node2D in bodies:
		if body.is_in_group("enemies") and body.has_method("take_damage"):
			body.take_damage(damage_per_tick)
