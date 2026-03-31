extends Node2D
## EMP Pulse: expanding ring centered on player, stuns and damages enemies.

var radius: float = 100.0
var stun_duration: float = 1.0
var damage: int = 15

var _expand_speed: float = 400.0
var _current_radius: float = 0.0
var _has_triggered: bool = false
var _pulse_area: Area2D = null


func _ready() -> void:
	_pulse_area = $PulseArea
	$PulseVisual.scale = Vector2.ZERO


func _process(delta: float) -> void:
	if _has_triggered:
		# Fade out and remove
		$PulseVisual.modulate.a -= delta * 3.0
		if $PulseVisual.modulate.a <= 0:
			queue_free()
		return

	# Expand the ring
	_current_radius += _expand_speed * delta
	var scale_factor: float = _current_radius / 16.0
	$PulseVisual.scale = Vector2(scale_factor, scale_factor)

	if _current_radius >= radius:
		_trigger_pulse()
		_has_triggered = true


func _trigger_pulse() -> void:
	# Update collision shape to final radius and check overlaps
	var shape: CircleShape2D = $PulseArea/CollisionShape2D.shape
	shape.radius = radius
	# Force physics update
	_pulse_area.monitoring = false
	_pulse_area.monitoring = true
	# Wait one frame for physics to detect overlaps
	await get_tree().physics_frame
	var bodies := _pulse_area.get_overlapping_bodies()
	for body: Node2D in bodies:
		if not body.is_in_group("enemies"):
			continue
		if body.has_method("take_damage"):
			body.take_damage(damage)
		if body.has_method("apply_stun"):
			body.apply_stun(stun_duration)
