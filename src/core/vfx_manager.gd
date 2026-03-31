extends Node
## VFX Manager: spawns CPUParticles2D effects and floating damage numbers.
## All effects are one-shot and self-cleaning.

## Spawn a small burst of particles (enemy death, small impact).
func spawn_death_burst(pos: Vector2, color: Color = Color(1, 0.3, 0.2), count: int = 12) -> void:
	var particles := CPUParticles2D.new()
	particles.emitting = true
	particles.one_shot = true
	particles.amount = count
	particles.lifetime = 0.4
	particles.explosiveness = 1.0
	particles.direction = Vector2.ZERO
	particles.spread = 180.0
	particles.initial_velocity_min = 60.0
	particles.initial_velocity_max = 120.0
	particles.gravity = Vector2.ZERO
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 4.0
	particles.color = color
	particles.global_position = pos
	_add_auto_free(particles, 0.6)


## Large explosion effect (exploder detonation, boss slam).
func spawn_explosion(pos: Vector2, radius: float = 60.0, color: Color = Color(1, 0.5, 0.0)) -> void:
	var particles := CPUParticles2D.new()
	particles.emitting = true
	particles.one_shot = true
	particles.amount = 24
	particles.lifetime = 0.5
	particles.explosiveness = 1.0
	particles.direction = Vector2.ZERO
	particles.spread = 180.0
	particles.initial_velocity_min = radius * 0.8
	particles.initial_velocity_max = radius * 1.5
	particles.gravity = Vector2.ZERO
	particles.scale_amount_min = 3.0
	particles.scale_amount_max = 6.0
	particles.color = color
	# Add color ramp from bright to transparent
	var gradient := Gradient.new()
	gradient.set_color(0, color)
	gradient.set_color(1, Color(color.r, color.g, color.b, 0.0))
	particles.color_ramp = gradient
	particles.global_position = pos
	_add_auto_free(particles, 0.7)


## Shockwave ring effect (boss ground slam).
func spawn_shockwave(pos: Vector2, radius: float = 120.0) -> void:
	# Use expanding ring via multiple particle bursts
	var particles := CPUParticles2D.new()
	particles.emitting = true
	particles.one_shot = true
	particles.amount = 32
	particles.lifetime = 0.4
	particles.explosiveness = 1.0
	particles.direction = Vector2.ZERO
	particles.spread = 180.0
	particles.initial_velocity_min = radius * 2.0
	particles.initial_velocity_max = radius * 2.5
	particles.gravity = Vector2.ZERO
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 3.0
	particles.color = Color(1.0, 0.3, 0.0, 0.8)
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1.0, 0.4, 0.1, 0.8))
	gradient.set_color(1, Color(1.0, 0.2, 0.0, 0.0))
	particles.color_ramp = gradient
	particles.global_position = pos
	_add_auto_free(particles, 0.6)


## Level up celebration sparkles around a node.
func spawn_level_up(pos: Vector2) -> void:
	var particles := CPUParticles2D.new()
	particles.emitting = true
	particles.one_shot = true
	particles.amount = 20
	particles.lifetime = 0.8
	particles.explosiveness = 0.8
	particles.direction = Vector2.UP
	particles.spread = 180.0
	particles.initial_velocity_min = 40.0
	particles.initial_velocity_max = 100.0
	particles.gravity = Vector2(0, -20)
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 4.0
	particles.color = Color(1.0, 0.9, 0.2, 1.0)
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1.0, 0.9, 0.2, 1.0))
	gradient.set_color(1, Color(1.0, 0.6, 0.0, 0.0))
	particles.color_ramp = gradient
	particles.global_position = pos
	_add_auto_free(particles, 1.0)


## Skill activation flash.
func spawn_skill_flash(pos: Vector2, color: Color = Color(0.3, 0.6, 1.0)) -> void:
	var particles := CPUParticles2D.new()
	particles.emitting = true
	particles.one_shot = true
	particles.amount = 8
	particles.lifetime = 0.3
	particles.explosiveness = 1.0
	particles.direction = Vector2.ZERO
	particles.spread = 180.0
	particles.initial_velocity_min = 30.0
	particles.initial_velocity_max = 60.0
	particles.gravity = Vector2.ZERO
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 3.0
	particles.color = color
	particles.global_position = pos
	_add_auto_free(particles, 0.5)


## Charge trail particles (boss charge, player dash).
func spawn_trail(pos: Vector2, color: Color = Color(1, 0.5, 0.0)) -> void:
	var particles := CPUParticles2D.new()
	particles.emitting = true
	particles.one_shot = true
	particles.amount = 6
	particles.lifetime = 0.3
	particles.explosiveness = 0.5
	particles.direction = Vector2.ZERO
	particles.spread = 90.0
	particles.initial_velocity_min = 10.0
	particles.initial_velocity_max = 30.0
	particles.gravity = Vector2.ZERO
	particles.scale_amount_min = 1.5
	particles.scale_amount_max = 3.0
	particles.color = color
	var gradient := Gradient.new()
	gradient.set_color(0, color)
	gradient.set_color(1, Color(color.r, color.g, color.b, 0.0))
	particles.color_ramp = gradient
	particles.global_position = pos
	_add_auto_free(particles, 0.5)


## Acid splash on hit.
func spawn_acid_splash(pos: Vector2) -> void:
	spawn_death_burst(pos, Color(0.3, 0.9, 0.1), 8)


## Floating damage number.
func spawn_damage_number(pos: Vector2, amount: int, color: Color = Color(1, 1, 1)) -> void:
	var label := Label.new()
	label.text = str(amount)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	label.add_theme_constant_override("outline_size", 2)
	label.global_position = pos + Vector2(randf_range(-10, 10), -10)
	label.z_index = 100
	# Anchor center
	label.pivot_offset = label.size / 2.0
	_add_to_scene(label)
	var tween := label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 40.0, 0.6).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.6).set_delay(0.3)
	tween.set_parallel(false)
	tween.tween_callback(label.queue_free)


## Floating heal number (green).
func spawn_heal_number(pos: Vector2, amount: int) -> void:
	spawn_damage_number(pos, amount, Color(0.2, 1.0, 0.3))


func _add_auto_free(node: Node2D, delay: float) -> void:
	_add_to_scene(node)
	var tween := node.create_tween()
	tween.tween_callback(node.queue_free).set_delay(delay)


func _add_to_scene(node: Node) -> void:
	var scene := get_tree().current_scene
	if scene:
		scene.add_child(node)
	else:
		add_child(node)
