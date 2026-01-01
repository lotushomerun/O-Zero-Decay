extends Action
class_name DropItemAction

func _action_name() -> String: return "Drop"

func _execute(params: Array[Variant]) -> void:
	if params.size() < 2:
		push_warning("DropItemAction: params.size() < 2!")
		super._execute(params)
		return
		
	var character: Char = params[0]
	var item: Item = params[1]
	
	if character == Player.this.character:
		Chatbox.system_message("[color=info]You dropped %s.[/color]" % [item.entity_name])
		InventoryManager.open_inventory.remove_item(item)
	
	var hit: Dictionary = Utils.raycast_2d(character.global_position, character.global_position + Vector2(0.0, 64.0), [], [2])
	if !hit.is_empty():
		var hit_pos: Vector2 = hit["position"]
		item.get_parent().global_position = hit_pos
		SoundManager.play_sound_2d(SoundLib.drop_sound, item.global_position, -20.0)
	else: push_warning("DropItemAction: raycast failed!")
	
	super._execute(params)
