extends Action
class_name UnequipBackpackAction

func _action_name() -> String: return "Take Off"

func _execute(params: Array[Variant]) -> void:
	if params.size() < 2:
		push_warning("UnequipBackpackAction: params.size() < 2!")
		super._execute(params)
		return
		
	var character: Char = params[0]
	var item: Item = params[1]
	
	Chatbox.system_message("[color=info]You take off %s.[/color]" % [item.entity_name])
	SoundManager.play_sound_2d(SoundLib.equip_sounds.pick_random(), character.global_position, -20.0)
	var rig: HumanRig = character.rig as HumanRig
	var backpack_item: BackpackItem = item as BackpackItem
	
	InventoryManager.open_inventory.remove_item(item)
	var hit: Dictionary = Utils.raycast_2d(character.global_position, character.global_position + Vector2(0.0, 64.0), [], [2])
	if !hit.is_empty():
		var hit_pos: Vector2 = hit["position"]
		item.get_parent().global_position = hit_pos
	else: push_warning("UnequipBackpackAction: raycast failed!")
	
	# Apply shit
	backpack_item._unequip(rig)
	backpack_item.inventory_container._get_items(InventoryManager.backpack)
	InventoryManager.hide_inventory(InventoryManager.backpack)
	super._execute(params)
