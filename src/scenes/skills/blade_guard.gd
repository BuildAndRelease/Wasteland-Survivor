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
var _blade_visuals: Array[ColorRect] = []

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
		_blade_visuals.append(visual)

		# Area2D for hit detection
		var area := Area2D.new()
		area.collision_layer = 0
		area.collision_mask = 2  # enemies layer
		area.monitoring = true
		area.monitorable = false
		var col := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = BLADE_SIZE
		col.shape = shape
		area.add_child(col)
		pivot.add_child(area)
		_blade_areas.append(area)


func _process(delta: float) -> void:
	_lifetime += delta
	if _lifetime >= duration:
		queue_free()
		return

	# Rotate all blades around origin
	rotation += rotation_speed * delta

	# Damage tick
	_tick_timer -= delta
	if _tick_timer <= 0.0:
		_tick_timer = tick_interval
		_deal_damage()

	# Fade out in last 0.5s
	if _lifetime > duration - 0.5:
		var fade: float = (duration - _lifetime) / 0.5
		modulate.a = fade


func _deal_damage() -> void:
	for area: Area2D in _blade_areas:
		var bodies := area.get_overlapping_bodies()
		for body: Node2D in bodies:
			if not body.is_in_group("enemies"):
				continue
			if body.has_method("take_damage"):
				body.take_damage(damage)
