extends Area2D
## Health pack drop. Heals the player by a percentage of max HP.

var is_collected: bool = false

func _ready() -> void:
	add_to_group("drops")
	# Green square visual
	var rect := ColorRect.new()
	rect.color = Color(0.2, 0.9, 0.2)
	rect.size = Vector2(10, 10)
	rect.position = Vector2(-5, -5)
	add_child(rect)
	# Collision shape
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 7.0
	col.shape = shape
	add_child(col)

func pickup(player: Node2D) -> void:
	if is_collected:
		return
	is_collected = true
	if player.has_method("heal"):
		var heal_amount: float = player.max_hp * BalanceConfig.HEALTH_PACK_HEAL_PERCENT
		player.heal(heal_amount)
	AudioManager.play_sfx("xp_pickup")
	collect()

func collect() -> void:
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ZERO, 0.15)
	tween.tween_callback(queue_free)
