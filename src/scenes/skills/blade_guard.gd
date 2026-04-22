extends Node2D
## Blade Guard: spinning blades orbit the player, dealing damage to nearby enemies.

var blade_count: int = 2
var damage: int = 8
var orbit_radius: float = 80.0
var duration: float = 5.0
var tick_interval: float = 0.5
var rotation_speed: float = 3.0  # radians per second

var _lifetime: float = 0.0
var _tick_timer: float = 0.0
var _blade_areas: Array[Area2D] = []

# Track which enemies each blade is currently overlapping for continuous damage
var _overlapping_enemies: Dictionary = {}  # area -> Array[Node2D]

const BLADE_COLOR := Color(0.6, 0.65, 0.7, 0.9)
const BLADE_SIZE := Vector2(20, 8)


func _ready() -> void:
	_build_blades()


func _build_blades() -> void:
	for i in range(blade_count):
		var angle: float = (TAU / blade_count) * i

		# Visual
		var visual := ColorRect.new()
		visual.color = BLADE_COLOR
		visual.size = BLADE_SIZE
		visual.position = -BLADE_SIZE / 2.0
		visual.pivot_offset = BLADE_SIZE / 2.0

		# Container to position + rotate
		var pivot := Node2D.new()
		pivot.position = Vector2(cos(angle), sin(angle)) * orbit_radius
		pivot.rotation = angle
		pivot.add_child(visual)
		add_child(pivot)

		# Area2D for hit detection
		var area := Area2D.new()
		area.collision_layer = 0
		area.collision_mask = 2  # enemies layer
		area.monitoring = true
		area.monitorable = false
		var col := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = BLADE_SIZE * 2.0  # larger hitbox than visual
		col.shape = shape
		area.add_child(col)
		pivot.add_child(area)
		_blade_areas.append(area)

		# Connect signals for reliable overlap detection
		area.body_entered.connect(_on_blade_body_entered.bind(area))
		area.body_exited.connect(_on_blade_body_exited.bind(area))
		_overlapping_enemies[area] = []


func _on_blade_body_entered(body: Node2D, area: Area2D) -> void:
	if body.is_in_group("enemies") and body not in _overlapping_enemies[area]:
		_overlapping_enemies[area].append(body)
		# Deal damage immediately on contact
		if body.has_method("take_damage"):
			body.take_damage(damage)


func _on_blade_body_exited(body: Node2D, area: Area2D) -> void:
	if area in _overlapping_enemies:
		_overlapping_enemies[area].erase(body)


func _physics_process(delta: float) -> void:
	_lifetime += delta
	if _lifetime >= duration:
		queue_free()
		return

	# Rotate all blades around origin
	rotation += rotation_speed * delta

	# Periodic damage tick for enemies that stay overlapping
	_tick_timer -= delta
	if _tick_timer <= 0.0:
		_tick_timer = tick_interval
		_deal_tick_damage()

	# Fade out in last 0.5s
	if _lifetime > duration - 0.5:
		var fade: float = (duration - _lifetime) / 0.5
		modulate.a = fade


func _deal_tick_damage() -> void:
	for area: Area2D in _blade_areas:
		# Clean up invalid refs
		var enemies: Array = _overlapping_enemies.get(area, [])
		for enemy: Node2D in enemies:
			if is_instance_valid(enemy) and enemy.has_method("take_damage"):
				enemy.take_damage(damage)
		# Also check get_overlapping_bodies as fallback
		var bodies := area.get_overlapping_bodies()
		for body: Node2D in bodies:
			if not body.is_in_group("enemies"):
				continue
			if body not in enemies and body.has_method("take_damage"):
				body.take_damage(damage)
