extends Area2D
## XP magnet drop. Collects all xp_gems on screen when picked up.

var is_collected: bool = false

func _ready() -> void:
	add_to_group("drops")
	# Cyan square visual
	var rect := ColorRect.new()
	rect.color = Color(0.0, 0.9, 1.0)
	rect.size = Vector2(10, 10)
	rect.position = Vector2(-5, -5)
	add_child(rect)
	# Collision shape
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 7.0
	col.shape = shape
	add_child(col)

func pickup(_player: Node2D) -> void:
	if is_collected:
		return
	is_collected = true
	# Collect all xp gems on screen
	var gems := get_tree().get_nodes_in_group("xp_gems")
	for gem in gems:
		if is_instance_valid(gem) and gem.has_method("collect"):
			GameManager.add_xp(gem.xp_value)
			gem.collect()
	AudioManager.play_sfx("xp_pickup")
	collect()

func collect() -> void:
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ZERO, 0.15)
	tween.tween_callback(queue_free)
