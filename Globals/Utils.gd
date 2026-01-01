extends Node
class_name Utils

static func get_all_children(in_node, arr: Array = []) -> Array:
	arr.push_back(in_node)
	for child in in_node.get_children(): arr = get_all_children(child, arr)
	return arr

static func get_aabb_2d(node2d: Node2D) -> Vector4:
	var vec4: Vector4 = Vector4.ZERO # left, right, up, down
	for node in get_all_children(node2d):
		if node is Sprite2D:
			if node.global_position.x < vec4.x: vec4.x = node.global_position.x # Left edge
			elif node.global_position.x > vec4.y: vec4.y = node.global_position.x # Right edge
			if node.global_position.y < vec4.z: vec4.z = node.global_position.y # Upper edge
			elif node.global_position.y > vec4.w: vec4.w = node.global_position.y # Lower edge
	return vec4
	
static func is_point_inside_area(area: Area2D, point: Vector2) -> bool: # Supports RectangleShape2D and CircleShape2D
	for child in area.get_children():
		if child is CollisionShape2D and child.shape is Shape2D:
			var shape: Shape2D = child.shape
			var local_point: Vector2 = area.to_local(point)
			
			if shape is RectangleShape2D:
				var rect := Rect2(-shape.size * 0.5, shape.size)
				if rect.has_point(local_point): return true
				
			elif shape is CircleShape2D:
				if local_point.length() <= shape.radius: return true
	return false

static func raycast_2d(from: Vector2, to: Vector2, exclude: Array = [], collision_layers: Array[int] = []) -> Dictionary:
	var mask := layers_to_mask(collision_layers)
	
	var ray := RayCast2D.new()
	ray.global_position = from
	ray.target_position = to - from
	ray.collision_mask = mask
	ray.collide_with_areas = true
	ray.collide_with_bodies = true
	ray.exclude_parent = false
	ray.hit_from_inside = true
	
	for obj in exclude: ray.add_exception(obj)
	
	var tree := Engine.get_main_loop() as SceneTree
	var root := tree.current_scene
	root.add_child(ray)
	
	ray.force_raycast_update()
	var result := {}
	
	if ray.is_colliding():
		result = {
			"position": ray.get_collision_point(),
			"normal": ray.get_collision_normal(),
			"collider": ray.get_collider(),
			"rid": ray.get_collider_rid(),
			"shape": ray.get_collider_shape()
		}
		
	ray.queue_free()
	return result
	
static func layers_to_mask(layers: Array[int]) -> int:
	var mask := 0
	for layer in layers: mask |= 1 << (layer - 1)
	return mask
	
static func is_on_layer(body: PhysicsBody2D, layer_bit: int) -> bool:
	return body.collision_layer & (1 << (layer_bit - 1)) != 0
	
static func string_to_vector2(s: String) -> Vector2:
	s = s.strip_edges()
	if s.begins_with("("): s = s.substr(1, s.length() - 1)
	if s.ends_with(")"): s = s.substr(0, s.length() - 1)
	var parts = s.split(",", true, 2)
	if parts.size() != 2: return Vector2.ZERO
	var x = parts[0].to_float()
	var y = parts[1].to_float()
	return Vector2(x, y)
