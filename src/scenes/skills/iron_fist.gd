extends Node2D
## Iron Fist: visual cone attack effect in front of the player.
## Actual damage/knockback/stun is handled by skill_manager._trigger_iron_fist().

var cone_angle: float = 60.0
var attack_range: float = 80.0
var direction: Vector2 = Vector2.RIGHT
var _lifetime: float = 0.0


func _ready() -> void:
	rotation = direction.angle()
	$FistVisual.modulate = Color(0.6, 0.4, 0.2, 0.8)
	$FistVisual.scale = Vector2(attack_range / 16.0, cone_angle / 32.0)


func _process(delta: float) -> void:
	_lifetime += delta

	# Quick swing and fade
	$FistVisual.modulate.a = clampf(1.0 - _lifetime / 0.4, 0.0, 0.8)

	if _lifetime >= 0.4:
		queue_free()
