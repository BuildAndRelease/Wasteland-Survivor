extends Node2D
## Iron Fist Barrage explosion (Combo: Iron Fist Lv3 + Fire Bomb Lv3):
## Explosion created on punch hit — damages all enemies in radius.

var explosion_radius: float = 60.0
var explosion_damage: int = 15

var _lifetime: float = 0.0


func _ready() -> void:
	$ExplosionVisual.scale = Vector2(explosion_radius / 16.0, explosion_radius / 16.0)
	# Apply explosion damage immediately
	_apply_explosion()


func _process(delta: float) -> void:
	_lifetime += delta
	$ExplosionVisual.modulate.a = clampf(1.0 - _lifetime / 0.4, 0.0, 0.8)
	if _lifetime >= 0.4:
		queue_free()


func _apply_explosion() -> void:
	var enemies := get_tree().get_nodes_in_group("enemies")
	for enemy: Node2D in enemies:
		if not is_instance_valid(enemy):
			continue
		if global_position.distance_to(enemy.global_position) <= explosion_radius:
			if enemy.has_method("take_damage"):
				enemy.take_damage(explosion_damage)
			if enemy.has_method("apply_knockback"):
				var dir := (enemy.global_position - global_position).normalized()
				enemy.apply_knockback(dir * 150.0)
