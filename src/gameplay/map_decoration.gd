extends Node2D
## Generates wasteland terrain using Marching Squares with the 16 tile textures.
## Noise determines terrain type at grid vertices (corners shared between tiles).
## Adjacent tiles share corner values, ensuring edge curves always connect smoothly.

@export var decoration_density: int = 20
@export var chunk_size: float = 800.0
@export var view_distance: float = 1200.0
@export var cleanup_distance: float = 2000.0
@export var obstacle_min_per_chunk: int = BalanceConfig.OBSTACLE_MIN_PER_CHUNK
@export var obstacle_max_per_chunk: int = BalanceConfig.OBSTACLE_MAX_PER_CHUNK

var player_ref: Node2D = null
var _generated_chunks: Dictionary = {}

## Tile textures indexed 0-15 (marching squares)
var _tile_textures: Array[Texture2D] = []

var _decoration_textures: Dictionary = {}
var _obstacle_textures: Dictionary = {}

## Noise for terrain
var _terrain_noise: FastNoiseLite

const TILE_SIZE: float = 32.0

## Marching Squares index → tile file mapping.
## Each tile's index is determined by its 4 corner vertices:
##   bit3=TL  bit2=TR  bit1=BR  bit0=BL   (1=water, 0=ground)
##
## Pixel-analyzed corner data (verified via PIL corner sampling):
##   tile_0  → MS  0 (0000) all ground
##   tile_1  → MS  2 (0010) BR=water
##   tile_2  → MS  1 (0001) BL=water
##   tile_3  → MS  3 (0011) BR+BL=water
##   tile_4  → MS  4 (0100) TR=water
##   tile_5  → MS  6 (0110) TR+BR=water
##   tile_6  → MS  5 (0101) TR+BL=water (saddle)
##   tile_7  → MS  7 (0111) TR+BR+BL=water
##   tile_8  → MS  8 (1000) TL=water
##   tile_9  → MS 10 (1010) TL+BR=water (saddle)
##   tile_10 → MS  9 (1001) TL+BL=water
##   tile_11 → MS 11 (1011) TL+BR+BL=water
##   tile_12 → MS 12 (1100) TL+TR=water
##   tile_13 → MS 14 (1110) TL+TR+BR=water
##   tile_14 → MS 13 (1101) TL+TR+BL=water
##   tile_15 → MS 15 (1111) all water

## Lookup: marching_squares_index → tile_file_number
## MS index:  0  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15
const MS_TO_TILE: Array = [0, 2, 1, 3, 4, 6, 5, 7, 8, 10, 9, 11, 12, 14, 13, 15]

const DECORATIONS: Array = [
	{
		"color": Color(0.3, 0.28, 0.25, 0.8),
		"min_size": Vector2(4, 4),
		"max_size": Vector2(12, 8),
		"weight": 0.5,
	},
	{
		"color": Color(0.22, 0.2, 0.2, 0.4),
		"min_size": Vector2(15, 10),
		"max_size": Vector2(40, 30),
		"weight": 0.5,
	},
]

const OBSTACLES: Array = [
	{
		"texture": "dead_tree",
		"collision_size": Vector2(34, 38),
		"sprite_scale": 1.3,
		"weight": 0.18,
	},
	{
		"texture": "metal_debris",
		"collision_size": Vector2(42, 26),
		"sprite_scale": 1.4,
		"weight": 0.17,
	},
	{
		"texture": "ruined_wall",
		"collision_size": Vector2(78, 28),
		"sprite_scale": 1.25,
		"weight": 0.24,
	},
	{
		"texture": "wrecked_car",
		"collision_size": Vector2(68, 42),
		"sprite_scale": 1.25,
		"weight": 0.19,
	},
	{
		"texture": "large_rock",
		"collision_size": Vector2(48, 48),
		"sprite_scale": 1.25,
		"weight": 0.22,
	},
]


func _ready() -> void:
	_init_noise()
	_preload_textures()


func _init_noise() -> void:
	_terrain_noise = FastNoiseLite.new()
	_terrain_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	_terrain_noise.seed = 42
	_terrain_noise.frequency = 0.008


func _preload_textures() -> void:
	for i in range(16):
		var path := "res://assets/sprites/tileset/tile_%d.png" % i
		if ResourceLoader.exists(path):
			_tile_textures.append(load(path))
		else:
			_tile_textures.append(null)

	var deco_names := []
	for dname in deco_names:
		var path := "res://assets/sprites/objects/%s.png" % dname
		if ResourceLoader.exists(path):
			_decoration_textures[dname] = load(path)

	var obs_names := ["dead_tree", "metal_debris", "ruined_wall", "wrecked_car", "large_rock"]
	for oname in obs_names:
		var path := "res://assets/sprites/objects/%s.png" % oname
		if ResourceLoader.exists(path):
			_obstacle_textures[oname] = load(path)


func set_player(player: Node2D) -> void:
	player_ref = player


func _process(_delta: float) -> void:
	if not is_instance_valid(player_ref):
		return
	if not GameManager.is_game_active:
		return

	var player_chunk := _world_to_chunk(player_ref.global_position)
	var range_chunks: int = ceili(view_distance / chunk_size)
	for cx in range(player_chunk.x - range_chunks, player_chunk.x + range_chunks + 1):
		for cy in range(player_chunk.y - range_chunks, player_chunk.y + range_chunks + 1):
			var chunk_key := Vector2i(cx, cy)
			if not _generated_chunks.has(chunk_key):
				_generate_chunk(chunk_key)

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


## Sample the noise at a grid vertex. Returns true if water.
## Vertices are at tile corners, so vertex (vx, vy) is at world position
## (vx * TILE_SIZE, vy * TILE_SIZE) — the top-left corner of tile (vx, vy).
func _is_water_vertex(vx: int, vy: int) -> bool:
	var world_x: float = vx * TILE_SIZE
	var world_y: float = vy * TILE_SIZE
	return _terrain_noise.get_noise_2d(world_x, world_y) < -0.05


## Get the Marching Squares tile index for tile at grid (gx, gy).
## The tile occupies the area from vertex (gx,gy) to vertex (gx+1,gy+1).
## Four corners: TL=(gx,gy), TR=(gx+1,gy), BR=(gx+1,gy+1), BL=(gx,gy+1)
func _get_tile_index(gx: int, gy: int) -> int:
	var tl: int = 1 if _is_water_vertex(gx, gy) else 0
	var tr: int = 1 if _is_water_vertex(gx + 1, gy) else 0
	var br: int = 1 if _is_water_vertex(gx + 1, gy + 1) else 0
	var bl: int = 1 if _is_water_vertex(gx, gy + 1) else 0

	# Marching squares index: bit3=TL, bit2=TR, bit1=BR, bit0=BL
	var ms_index: int = (tl << 3) | (tr << 2) | (br << 1) | bl

	# Map to tile file number
	return MS_TO_TILE[ms_index]


## Check if tile center is water (for decoration/obstacle placement)
func _is_water_at(world_x: float, world_y: float) -> bool:
	return _terrain_noise.get_noise_2d(world_x, world_y) < -0.05


func _generate_chunk(chunk_key: Vector2i) -> void:
	var chunk_node := Node2D.new()
	chunk_node.name = "Chunk_%d_%d" % [chunk_key.x, chunk_key.y]
	var chunk_origin := Vector2(chunk_key.x * chunk_size, chunk_key.y * chunk_size)

	var rng := RandomNumberGenerator.new()
	rng.seed = hash(chunk_key)

	# --- Terrain tiles using Marching Squares ---
	var tiles_per_side: int = ceili(chunk_size / TILE_SIZE)
	var grid_origin_x: int = floori(chunk_origin.x / TILE_SIZE)
	var grid_origin_y: int = floori(chunk_origin.y / TILE_SIZE)

	for tx in range(tiles_per_side):
		for ty in range(tiles_per_side):
			var gx: int = grid_origin_x + tx
			var gy: int = grid_origin_y + ty
			var tile_file_idx: int = _get_tile_index(gx, gy)

			if tile_file_idx >= 0 and tile_file_idx < _tile_textures.size() and _tile_textures[tile_file_idx] != null:
				var sprite := Sprite2D.new()
				sprite.texture = _tile_textures[tile_file_idx]
				sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				sprite.centered = false
				sprite.position = Vector2(gx * TILE_SIZE, gy * TILE_SIZE)
				chunk_node.add_child(sprite)

	# --- Decorations ---
	for i in range(decoration_density):
		var deco_type: Dictionary = _pick_weighted(DECORATIONS, rng)
		var pos := chunk_origin + Vector2(
			rng.randf_range(20.0, chunk_size - 20.0),
			rng.randf_range(20.0, chunk_size - 20.0)
		)

		if _is_water_at(pos.x, pos.y):
			continue

		if deco_type.has("texture") and _decoration_textures.has(deco_type.texture):
			var sprite := Sprite2D.new()
			sprite.texture = _decoration_textures[deco_type.texture]
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			var s: float = rng.randf_range(deco_type.get("min_scale", 0.5), deco_type.get("max_scale", 1.0))
			sprite.scale = Vector2(s, s)
			sprite.position = pos
			sprite.rotation = rng.randf_range(-0.2, 0.2)
			chunk_node.add_child(sprite)
		else:
			var rect := ColorRect.new()
			rect.color = deco_type.get("color", Color(0.3, 0.28, 0.25, 0.6))
			var w: float = rng.randf_range(deco_type.get("min_size", Vector2(4, 4)).x, deco_type.get("max_size", Vector2(12, 8)).x)
			var h: float = rng.randf_range(deco_type.get("min_size", Vector2(4, 4)).y, deco_type.get("max_size", Vector2(12, 8)).y)
			rect.size = Vector2(w, h)
			rect.position = pos
			rect.rotation = rng.randf_range(-0.3, 0.3)
			rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			chunk_node.add_child(rect)

	# --- Obstacles ---
	var obstacle_count: int = rng.randi_range(obstacle_min_per_chunk, obstacle_max_per_chunk)
	for i in range(obstacle_count):
		var obs_type: Dictionary = _pick_weighted(OBSTACLES, rng)
		var col_size: Vector2 = obs_type.get("collision_size", Vector2(50, 30))
		var pos := chunk_origin + Vector2(
			rng.randf_range(col_size.x, chunk_size - col_size.x),
			rng.randf_range(col_size.y, chunk_size - col_size.y)
		)

		if _is_water_at(pos.x, pos.y):
			continue

		var body := StaticBody2D.new()
		body.position = pos
		body.collision_layer = 4
		body.collision_mask = 0

		var tex_name: String = obs_type.get("texture", "")
		if _obstacle_textures.has(tex_name):
			var sprite := Sprite2D.new()
			sprite.texture = _obstacle_textures[tex_name]
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			var sprite_scale: float = obs_type.get("sprite_scale", 1.0)
			sprite.scale = Vector2(sprite_scale, sprite_scale)
			body.add_child(sprite)
		else:
			var visual := ColorRect.new()
			visual.color = Color(0.4, 0.35, 0.3, 0.9)
			visual.size = col_size
			visual.position = -col_size / 2.0
			body.add_child(visual)

		var shape := CollisionShape2D.new()
		var rect_shape := RectangleShape2D.new()
		rect_shape.size = col_size
		shape.shape = rect_shape
		body.add_child(shape)

		body.z_index = -5
		chunk_node.add_child(body)

	chunk_node.z_index = -10
	add_child(chunk_node)
	_generated_chunks[chunk_key] = chunk_node


func _pick_weighted(items: Array, rng: RandomNumberGenerator) -> Dictionary:
	var total_weight: float = 0.0
	for item in items:
		total_weight += item.get("weight", 1.0)
	var roll: float = rng.randf() * total_weight
	var cumulative: float = 0.0
	for item in items:
		cumulative += item.get("weight", 1.0)
		if roll <= cumulative:
			return item
	return items[-1]
