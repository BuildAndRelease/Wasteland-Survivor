extends Node2D
## EMP Pulse: expanding ring centered on player, stuns and damages enemies.

var radius: float = 100.0
var stun_duration: float = 1.0
var damage: int = 15

var _expand_speed: float = 400.0
var _current_radius: float = 0.0
var _has_triggered: bool = false


func _ready() -> void:
	$PulseVisual.scale = Vector2.ZERO


func _physics_process(delta: float) -> void:
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
	# Direct distance check — no Area2D async dependency
	var enemies := get_tree().get_nodes_in_group("enemies")
	for enemy: Node2D in enemies:
		if not is_instance_valid(enemy):
			continue
		var dist: float = global_position.distance_to(enemy.global_position)
		if dist <= radius:
			if enemy.has_method("take_damage"):
				enemy.take_damage(damage)
			if enemy.has_method("apply_stun"):
				enemy.apply_stun(stun_duration)
