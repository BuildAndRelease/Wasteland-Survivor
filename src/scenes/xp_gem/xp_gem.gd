extends Area2D
## XP gem dropped by enemies. Collected by player within pickup range.

@export var xp_value: int = 5

var is_collected: bool = false

func _ready() -> void:
	add_to_group("xp_gems")

func collect() -> void:
	if is_collected:
		return
	is_collected = true
	# Quick shrink animation then free
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ZERO, 0.15)
	tween.tween_callback(queue_free)
