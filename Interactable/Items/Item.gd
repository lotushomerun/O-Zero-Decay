extends Interactable
class_name Item

@export var can_take: bool = true
var in_inventory: bool = false
var is_equipped: bool = false # For backpacks and clothes

#region Save/Load
func get_save_data() -> Dictionary:
	return {
		"entity_id": entity_id,
		"parent_scene": get_parent().scene_file_path,
		"parent_position": get_parent().global_position,
		"is_equipped": is_equipped,
	}

func load_save_data(data: Dictionary) -> void:
	is_equipped = data.get("is_equipped", false)
	entity_id = data.get("entity_id", "no_id")
	get_parent().global_position = Utils.string_to_vector2(data.get("parent_position", get_parent().global_position))
	
func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		if SaveState.unloading_level || SaveState.loading_level: pass
		else:
			if entity_id.length() > 0 && entity_id != "no_id":
				var current_scene: Node = SaveState.get_tree().current_scene
				if !current_scene:
					push_warning("%s is a static item freed during runtime, but current_scene couldn't be located, can't remember this..." % entity_name)
					pass
				
				print("%s is a static item freed during runtime, remembering this..." % entity_name)
				SaveState.remember_destroyed_entity(current_scene.get_scene_file_path(), entity_id)
#endregion

func _ready() -> void:
	super._ready()
	add_to_group("SaveableItems")
	get_parent().z_as_relative = false
	get_parent().z_index = Layering.Item_Index
	
	if can_take:
		var pick_item_action := PickItemAction.new()
		primary_action = pick_item_action
		actions.append(pick_item_action)
	#if entity_id.length() > 0: print(entity_id)
	
func remove_action(action_class: String) -> void:
	for i in range(actions.size()):
		var a = actions[i]
		if a && str(a.get_script().get_global_name()) == action_class:
			actions.remove_at(i)
			break
			
func _on_add_to_inventory(_inventory: Inventory) -> void:
	in_inventory = true
	remove_action("PickItemAction")
	if can_take: actions.append(DropItemAction.new())
	
func _on_remove_from_inventory(_inventory: Inventory) -> void:
	in_inventory = false
	remove_action("DropItemAction")
	if can_take: actions.append(PickItemAction.new())
