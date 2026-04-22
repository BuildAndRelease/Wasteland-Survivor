extends Node2D
## Spike Trap: placed on ground, damages and slows enemies that walk over it.
## Can optionally explode when triggered (Lv3).

var damage: int = 20
var slow_amount: float = 0.5
var slow_duration: float = 2.0
var duration: float = 6.0
var should_explode: bool = false

var _lifetime: float = 0.0
var _triggered: bool = false
var _trap_area: Area2D = null
var _explode_radius: float = 80.0
var _explode_damage: int = 30


func _ready() -> void:
	_trap_area = $TrapArea


func _physics_process(delta: float) -> void:
	_lifetime += delta

	if _lifetime >= duration:
		if should_explode and not _triggered:
			_explode()
		queue_free()
		return

	# Check for enemies stepping on trap
	if not _triggered:
		var bodies := _trap_area.get_overlapping_bodies()
		for body: Node2D in bodies:
			if body.is_in_group("enemies"):
				_trigger_trap(body)
				break


func _trigger_trap(target: Node2D) -> void:
	_triggered = true
	if target.has_method("take_damage"):
		target.take_damage(damage)
	if target.has_method("apply_slow"):
		target.apply_slow(slow_amount, slow_duration)

	if should_explode:
		_explode()
	else:
		# Visual feedback: flash and fade
		$TrapVisual.modulate = Color(1, 0, 0, 1)
		var tween := create_tween()
		tween.tween_property($TrapVisual, "modulate:a", 0.0, 0.5)
		tween.tween_callback(queue_free)


func _explode() -> void:
	# Damage all enemies in explosion radius
	var enemies := get_tree().get_nodes_in_group("enemies")
	for enemy: Node2D in enemies:
		if not is_instance_valid(enemy):
			continue
		if global_position.distance_to(enemy.global_position) <= _explode_radius:
			if enemy.has_method("take_damage"):
				enemy.take_damage(_explode_damage)
			if enemy.has_method("apply_knockback"):
				var dir := (enemy.global_position - global_position).normalized()
				enemy.apply_knockback(dir * 200.0)

	# Visual: flash white then remove
	$TrapVisual.modulate = Color.WHITE
	$TrapVisual.scale *= 2.0
	var tween := create_tween()
	tween.tween_property($TrapVisual, "modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)
