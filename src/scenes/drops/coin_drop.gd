extends Area2D
## Gold coin drop. Awards run_coins when collected by the player.

var is_collected: bool = false

func _ready() -> void:
	add_to_group("drops")
	# Gold square visual
	var rect := ColorRect.new()
	rect.color = Color(1.0, 0.84, 0.0)
	rect.size = Vector2(8, 8)
	rect.position = Vector2(-4, -4)
	add_child(rect)
	# Collision shape
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 6.0
	col.shape = shape
	add_child(col)

func pickup(_player: Node2D) -> void:
	if is_collected:
		return
	is_collected = true
	GameManager.run_coins += BalanceConfig.COIN_DROP_VALUE
	AudioManager.play_sfx("coin_earned", -5.0)
	collect()

func collect() -> void:
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ZERO, 0.15)
	tween.tween_callback(queue_free)
