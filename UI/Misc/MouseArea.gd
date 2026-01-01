extends Area2D

func _process(_delta: float) -> void:
	global_position = get_global_mouse_position()
	
	var mouse_areas: Array = get_overlapping_areas()
	var current_mouse_area: Interactable = null

	if mouse_areas.size() > 0:
		for area: Area2D in mouse_areas:
			if !area.monitorable: continue # Shouldn't be possible but oh well here we are
			if current_mouse_area: # If this is not the only intersecting area
				var dist_to_old: float = global_position.distance_to(current_mouse_area.global_position)
				var dist_to_new: float = global_position.distance_to(area.global_position)
				if dist_to_new < dist_to_old: current_mouse_area = area # Assign the closest one
			else: current_mouse_area = area # If it's the first area being checked, simply assign it
			
	if is_instance_valid(current_mouse_area) && !current_mouse_area.hovered: current_mouse_area._on_mouse_entered()
	
	elif !is_instance_valid(current_mouse_area) && Player.interactable != null:
		
		if Player.interactable is Item:
			var item: Item = Player.interactable
			if item.in_inventory: return
			
		Player.interactable._on_mouse_exited()
