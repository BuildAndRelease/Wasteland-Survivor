extends Node2D
## Generates post-apocalyptic wasteland decoration around the player.
## Uses simple ColorRect/Polygon2D shapes as placeholders.
## Decorations are spawned in chunks and cleaned up when far away.

@export var decoration_density: int = 30       # Props per chunk
@export var chunk_size: float = 800.0           # Size of each decoration chunk
@export var view_distance: float = 1200.0       # How far from player to generate
@export var cleanup_distance: float = 2000.0    # How far before cleanup
@export var obstacle_min_per_chunk: int = BalanceConfig.OBSTACLE_MIN_PER_CHUNK
@export var obstacle_max_per_chunk: int = BalanceConfig.OBSTACLE_MAX_PER_CHUNK

var player_ref: Node2D = null
var _generated_chunks: Dictionary = {}  # Vector2i -> Node2D

## Decoration palette: dark muted post-apocalyptic colors.
const GROUND_COLOR := Color(0.18, 0.15, 0.12, 1.0)  # Dark brown wasteland

## Decoration types with color, size ranges, and probability weights.
const DECORATIONS: Array = [
	{  # Rubble / small rocks
		"color": Color(0.3, 0.28, 0.25, 0.8),
		"min_size": Vector2(4, 4),
		"max_size": Vector2(12, 8),
		"weight": 0.35,
	},
	{  # Concrete ruins
		"color": Color(0.4, 0.38, 0.35, 0.7),
		"min_size": Vector2(20, 15),
		"max_size": Vector2(60, 40),
		"weight": 0.1,
	},
	{  # Metal debris
		"color": Color(0.35, 0.32, 0.3, 0.6),
		"min_size": Vector2(8, 3),
		"max_size": Vector2(25, 6),
		"weight": 0.2,
	},
	{  # Dead tree stumps
		"color": Color(0.25, 0.18, 0.1, 0.9),
		"min_size": Vector2(6, 16),
		"max_size": Vector2(10, 30),
		"weight": 0.15,
	},
	{  # Ash patches
		"color": Color(0.22, 0.2, 0.2, 0.4),
		"min_size": Vector2(15, 10),
		"max_size": Vector2(40, 30),
		"weight": 0.2,
	},
]

## Obstacle types: large solid objects that block movement.
const OBSTACLES: Array = [
	{  # Ruined wall
		"color": Color(0.45, 0.40, 0.35, 0.95),
		"min_size": Vector2(60, 20),
		"max_size": Vector2(120, 30),
		"weight": 0.4,
	},
	{  # Wrecked car
		"color": Color(0.35, 0.25, 0.20, 0.9),
		"min_size": Vector2(50, 30),
		"max_size": Vector2(80, 40),
		"weight": 0.35,
	},
	{  # Large rock
		"color": Color(0.38, 0.36, 0.33, 0.95),
		"min_size": Vector2(30, 30),
		"max_size": Vector2(55, 50),
		"weight": 0.25,
	},
]

func _ready() -> void:
	# Precompute cumulative weights
	pass

func set_player(player: Node2D) -> void:
	player_ref = player

func _process(_delta: float) -> void:
	if not is_instance_valid(player_ref):
		return
	if not GameManager.is_game_active:
		return

	var player_chunk := _world_to_chunk(player_ref.global_position)

	# Generate chunks in view range
	var range_chunks: int = ceili(view_distance / chunk_size)
	for cx in range(player_chunk.x - range_chunks, player_chunk.x + range_chunks + 1):
		for cy in range(player_chunk.y - range_chunks, player_chunk.y + range_chunks + 1):
			var chunk_key := Vector2i(cx, cy)
			if not _generated_chunks.has(chunk_key):
				_generate_chunk(chunk_key)

	# Cleanup distant chunks
	var chunks_to_remove: Array[Vector2i] = []
	for chunk_key: Vector2i in _generated_chunks:
		var chunk_center := Vector2(chunk_key.x * chunk_size + chunk_size / 2.0, chunk_key.y * chunk_size + chunk_size / 2.0)
		if chunk_center.distance_to(player_ref.global_position) > cleanup_distance:
			chunks_to_remove.append(chunk_key)

	for chunk_key in chunks_to_remove:
		var chunk_node: Node2D = _generated_chunks[chunk_key]
		chunk_node.queue_free()
		_generated_chunks.erase(chunk_key)

func _world_to_chunk(world_pos: Vector2) -> Vector2i:
	return Vector2i(floori(world_pos.x / chunk_size), floori(world_pos.y / chunk_size))

func _generate_chunk(chunk_key: Vector2i) -> void:
	var chunk_node := Node2D.new()
	chunk_node.name = "Chunk_%d_%d" % [chunk_key.x, chunk_key.y]
	var chunk_origin := Vector2(chunk_key.x * chunk_size, chunk_key.y * chunk_size)

	# Ground tile (dark wasteland)
	var ground := ColorRect.new()
	ground.color = GROUND_COLOR
	ground.position = chunk_origin
	ground.size = Vector2(chunk_size, chunk_size)
	chunk_node.add_child(ground)

	# Use deterministic seed per chunk for consistency
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(chunk_key)

	for i in range(decoration_density):
		var deco_type: Dictionary = _pick_decoration(rng)
		var rect := ColorRect.new()
		rect.color = deco_type.color
		# Randomize within range
		var w: float = rng.randf_range(deco_type.min_size.x, deco_type.max_size.x)
		var h: float = rng.randf_range(deco_type.min_size.y, deco_type.max_size.y)
		rect.size = Vector2(w, h)
		rect.position = chunk_origin + Vector2(
			rng.randf_range(0, chunk_size - w),
			rng.randf_range(0, chunk_size - h)
		)
		rect.rotation = rng.randf_range(-0.3, 0.3)
		chunk_node.add_child(rect)

	# --- Spawn obstacles (StaticBody2D with collision) ---
	var obstacle_count: int = rng.randi_range(obstacle_min_per_chunk, obstacle_max_per_chunk)
	for i in range(obstacle_count):
		var obs_type: Dictionary = _pick_obstacle(rng)
		var w: float = rng.randf_range(obs_type.min_size.x, obs_type.max_size.x)
		var h: float = rng.randf_range(obs_type.min_size.y, obs_type.max_size.y)
		var pos := chunk_origin + Vector2(
			rng.randf_range(w, chunk_size - w),
			rng.randf_range(h, chunk_size - h)
		)

		var body := StaticBody2D.new()
		body.position = pos

		# Visual
		var visual := ColorRect.new()
		visual.color = obs_type.color
		visual.size = Vector2(w, h)
		visual.position = -Vector2(w, h) / 2.0
		body.add_child(visual)

		# Collision
		var shape := CollisionShape2D.new()
		var rect_shape := RectangleShape2D.new()
		rect_shape.size = Vector2(w, h)
		shape.shape = rect_shape
		body.add_child(shape)

		body.z_index = -5  # Above ground deco (-10) but below entities
		chunk_node.add_child(body)

	# Render behind everything (z_index = -10)
	chunk_node.z_index = -10
	add_child(chunk_node)
	_generated_chunks[chunk_key] = chunk_node

func _pick_obstacle(rng: RandomNumberGenerator) -> Dictionary:
	var total_weight: float = 0.0
	for obs in OBSTACLES:
		total_weight += obs.weight
	var roll: float = rng.randf() * total_weight
	var cumulative: float = 0.0
	for obs in OBSTACLES:
		cumulative += obs.weight
		if roll <= cumulative:
			return obs
	return OBSTACLES[-1]

func _pick_decoration(rng: RandomNumberGenerator) -> Dictionary:
	var total_weight: float = 0.0
	for deco in DECORATIONS:
		total_weight += deco.weight
	var roll: float = rng.randf() * total_weight
	var cumulative: float = 0.0
	for deco in DECORATIONS:
		cumulative += deco.weight
		if roll <= cumulative:
			return deco
	return DECORATIONS[-1]
