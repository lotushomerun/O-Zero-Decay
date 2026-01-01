extends Projectile

@export var cum_splat_scene: PackedScene

func _ready() -> void:
	super._ready()
	hit_signal.connect(self._on_hit)
	
func _on_hit(target) -> void:
	if target is StaticBody2D:
		var from := global_position
		var to := global_position + velocity.normalized() * 5.0
		var hit := Utils.raycast_2d(from, to, [], [2, 3])
		if hit.is_empty(): return
		spawn_splat(hit)
		queue_free()
		
func spawn_splat(hit: Dictionary) -> void:
	SoundManager.play_sound_2d(SoundLib.cum_collide_sound, global_position, -15.0)
	var splat: Sprite2D = cum_splat_scene.instantiate()
	get_tree().current_scene.add_child(splat)

	var hit_pos: Vector2 = hit["position"]
	var collider: StaticBody2D = hit["collider"]
	var offset: Vector2 = splat.texture.get_size() * splat.scale * 0.5

	splat.global_position = hit_pos
	if Utils.is_on_layer(collider, 2): # Ground
		splat.global_position.y -= offset.y
			
	elif Utils.is_on_layer(collider, 3): # Wall
		var right_wall: bool = velocity.x > 0.0
		splat.global_position.x += (-offset.y if right_wall else offset.y)
		splat.rotation_degrees = -90.0 if right_wall else 90.0
	
	get_tree().create_timer(0.1).timeout.connect(func(): # Lambda for a small animation
		if is_instance_valid(splat): splat.region_rect = Rect2(Vector2(splat.region_rect.size.x, 0), splat.region_rect.size)
	)
