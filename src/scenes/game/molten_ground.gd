extends Area2D
## Molten ground hazard used by Level 3 hell furnace theme.
## Damages the player periodically while standing inside.
## Optionally damages enemies too.

@export var radius: float = 90.0
@export var duration: float = 4.0
@export var damage_per_tick: int = 6
@export var tick_interval: float = 0.4
@export var affects_enemies: bool = false

var _elapsed: float = 0.0
var _tick_timer: float = 0.0
var _tracked_bodies: Dictionary = {}
var _base: ColorRect = null
var _inner: ColorRect = null

func _ready() -> void:
	monitoring = true
	monitorable = false
	collision_layer = 0
	collision_mask = 1 if not affects_enemies else 3
	process_mode = Node.PROCESS_MODE_ALWAYS
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_build_visuals()
	_build_collision()

func configure(new_radius: float, new_duration: float, new_damage: int, new_affects_enemies: bool = false) -> void:
	radius = new_radius
	duration = new_duration
	damage_per_tick = new_damage
	affects_enemies = new_affects_enemies
	collision_mask = 1 if not affects_enemies else 3

func _process(delta: float) -> void:
	_elapsed += delta
	_tick_timer -= delta

	var fade_ratio := clampf((duration - _elapsed) / maxf(duration, 0.01), 0.0, 1.0)
	if _base:
		_base.modulate.a = lerpf(0.10, 0.55, fade_ratio)
	if _inner:
		_inner.modulate.a = lerpf(0.08, 0.38, fade_ratio)

	if _tick_timer <= 0.0:
		_tick_timer = tick_interval
		_apply_tick_damage()

	if _elapsed >= duration:
		queue_free()

func _build_visuals() -> void:
	_base = ColorRect.new()
	_base.name = "Base"
	_base.size = Vector2(radius * 2.0, radius * 2.0)
	_base.position = -_base.size / 2.0
	_base.color = Color(1.0, 0.28, 0.05, 0.38)
	_base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_base)

	_inner = ColorRect.new()
	_inner.name = "Inner"
	_inner.size = Vector2(radius * 1.2, radius * 1.2)
	_inner.position = -_inner.size / 2.0
	_inner.color = Color(1.0, 0.72, 0.15, 0.30)
	_inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_inner)

	var pulse := create_tween()
	pulse.set_loops()
	pulse.tween_property(_base, "modulate:a", 0.65, 0.35)
	pulse.tween_property(_base, "modulate:a", 0.35, 0.35)

func _build_collision() -> void:
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = radius
	collision.shape = shape
	add_child(collision)

func _on_body_entered(body: Node2D) -> void:
	if not _should_affect_body(body):
		return
	_tracked_bodies[str(body.get_instance_id())] = body

func _on_body_exited(body: Node2D) -> void:
	_tracked_bodies.erase(str(body.get_instance_id()))

func _should_affect_body(body: Node2D) -> bool:
	if not is_instance_valid(body):
		return false
	if body.is_in_group("player"):
		return true
	if affects_enemies and body.is_in_group("enemies"):
		return true
	return false

func _apply_tick_damage() -> void:
	for key in _tracked_bodies.keys():
		var body: Node2D = _tracked_bodies[key]
		if not is_instance_valid(body):
			_tracked_bodies.erase(key)
			continue
		if body.is_in_group("player"):
			if body.has_method("take_damage"):
				body.take_damage(damage_per_tick, null)
		elif affects_enemies and body.is_in_group("enemies"):
			if body.has_method("take_damage"):
				body.take_damage(damage_per_tick)
