extends Node2D
## Chainsaw Storm (Combo: Blade Guard Lv3 + Iron Fist Lv3):
## Massive chainsaws orbit the player — higher damage, faster spin,
## and pull enemies toward the player (vacuum effect).

var blade_count: int = 6
var damage: int = 20  # base damage * combo mult applied by skill_manager
var orbit_radius: float = 110.0
var duration: float = 10.0
var tick_interval: float = 0.3
var rotation_speed: float = 5.0  # faster than normal blades
var pull_force: float = 120.0

var _lifetime: float = 0.0
var _tick_timer: float = 0.0
var _blade_areas: Array[Area2D] = []

const SAW_COLOR := Color(0.8, 0.15, 0.1, 0.95)
const SAW_SIZE := Vector2(30, 14)


func _ready() -> void:
	_build_chainsaws()


func _build_chainsaws() -> void:
	for i in range(blade_count):
		var angle: float = (TAU / blade_count) * i

		# Visual — larger, blood red
		var visual := ColorRect.new()
		visual.color = SAW_COLOR
		visual.size = SAW_SIZE
		visual.position = -SAW_SIZE / 2.0
		visual.pivot_offset = SAW_SIZE / 2.0

		# Container
		var pivot := Node2D.new()
		pivot.position = Vector2(cos(angle), sin(angle)) * orbit_radius
		pivot.rotation = angle
		pivot.add_child(visual)
		add_child(pivot)

		# Area2D for hit detection
		var area := Area2D.new()
		area.collision_layer = 0
		area.collision_mask = 2
		area.monitoring = true
		area.monitorable = false
		var col := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = SAW_SIZE
		col.shape = shape
		area.add_child(col)
		pivot.add_child(area)
		_blade_areas.append(area)


func _process(delta: float) -> void:
	_lifetime += delta
	if _lifetime >= duration:
		queue_free()
		return

	# Fast rotation
	rotation += rotation_speed * delta

	# Damage + pull tick
	_tick_timer -= delta
	if _tick_timer <= 0.0:
		_tick_timer = tick_interval
		_deal_damage_and_pull()

	# Pulsing red glow
	var pulse: float = 0.7 + 0.3 * sin(_lifetime * 8.0)
	modulate = Color(1.0, pulse, pulse, 1.0)

	# Fade out in last 0.5s
	if _lifetime > duration - 0.5:
		var fade: float = (duration - _lifetime) / 0.5
		modulate.a = fade


func _deal_damage_and_pull() -> void:
	# Also pull enemies within a larger radius toward center
	var pull_radius: float = orbit_radius + 60.0
	var scene_root := get_tree().current_scene
	if not scene_root:
		return

	# Damage from blade hits
	for area: Area2D in _blade_areas:
		var bodies := area.get_overlapping_bodies()
		for body: Node2D in bodies:
			if not body.is_in_group("enemies"):
				continue
			if body.has_method("take_damage"):
				body.take_damage(damage)

	# Vacuum pull — attract enemies in range toward player
	var enemies := get_tree().get_nodes_in_group("enemies")
	for enemy: Node2D in enemies:
		if not is_instance_valid(enemy):
			continue
		var to_center: Vector2 = global_position - enemy.global_position
		var dist: float = to_center.length()
		if dist < pull_radius and dist > 10.0:
			if enemy.has_method("apply_knockback"):
				enemy.apply_knockback(to_center.normalized() * pull_force)
