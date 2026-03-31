extends Node2D
## Death Trap Field (Combo: Spike Trap Lv3 + Rust Bullet Lv3):
## Trap that auto-fires rust bullets at nearby enemies.

var damage: int = 20
var slow_amount: float = 0.5
var slow_duration: float = 2.0
var duration: float = 10.0
var fire_interval: float = 0.8
var bullet_damage: int = 10

var _lifetime: float = 0.0
var _fire_timer: float = 0.0
var _trap_area: Area2D = null
var _projectile_scene: PackedScene = null


func _ready() -> void:
	_trap_area = $TrapArea
	_projectile_scene = preload("res://src/scenes/projectile/projectile.tscn")


func _process(delta: float) -> void:
	_lifetime += delta
	_fire_timer -= delta

	if _fire_timer <= 0.0:
		_fire_timer = fire_interval
		_auto_fire()

	# Check for enemies stepping on trap for initial hit
	_check_trap_trigger()

	# Visual pulse
	var pulse: float = 0.6 + 0.2 * sin(_lifetime * 4.0)
	$TrapVisual.modulate.a = pulse

	if _lifetime >= duration:
		queue_free()


func _check_trap_trigger() -> void:
	var bodies := _trap_area.get_overlapping_bodies()
	for body: Node2D in bodies:
		if not body.is_in_group("enemies"):
			continue
		if body.has_method("take_damage"):
			body.take_damage(damage)
		if body.has_method("apply_slow"):
			body.apply_slow(slow_amount, slow_duration)
		# Only hit once per check
		break


func _auto_fire() -> void:
	# Find nearest enemy within range
	var enemies := get_tree().get_nodes_in_group("enemies")
	var nearest: Node2D = null
	var nearest_dist: float = 200.0  # Max fire range

	for enemy: Node2D in enemies:
		if not is_instance_valid(enemy):
			continue
		var dist: float = global_position.distance_to(enemy.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = enemy

	if nearest and _projectile_scene:
		var proj := _projectile_scene.instantiate()
		proj.global_position = global_position
		proj.direction = (nearest.global_position - global_position).normalized()
		proj.damage = bullet_damage
		get_tree().current_scene.add_child(proj)
