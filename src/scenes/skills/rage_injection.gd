extends Node2D
## Rage Injection: visual effect on player showing the buff is active.
## Actual buff logic is handled in player.gd via apply_rage().

var duration: float = 5.0
var _lifetime: float = 0.0


func _ready() -> void:
	$BuffVisual.modulate = Color(0.9, 0.2, 0.2, 0.6)


func _process(delta: float) -> void:
	_lifetime += delta

	# Pulsing effect
	var pulse: float = 0.4 + 0.2 * sin(_lifetime * 6.0)
	$BuffVisual.modulate.a = pulse

	if _lifetime >= duration:
		queue_free()
