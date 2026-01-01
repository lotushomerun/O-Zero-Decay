extends Action
class_name PickItemAction

func _action_name() -> String: return "Take"

func _execute(params: Array[Variant]) -> void:
	if params.size() < 2:
		push_warning("PickItemAction: params.size() < 2!")
		super._execute(params)
		return
		
	var _character: Char = params[0]
	var item: Item = params[1]
	
	super._execute(params) # Close context menu and stuff
	
	Chatbox.system_message("[color=info]You picked up %s.[/color]" % [item.entity_name])
	SoundManager.play_sound_2d(SoundLib.pick_sound, item.global_position, -20.0)
	if !is_instance_valid(InventoryManager.open_inventory): InventoryManager.inventory.add_item(item)
	else: InventoryManager.open_inventory.add_item(item)
	
func _valid(params: Array[Variant]) -> bool:
	var _character: Char = params[0]
	var _item: Item = params[1]
	
	var inventory: Inventory
	if is_instance_valid(InventoryManager.open_inventory): inventory = InventoryManager.open_inventory
	else: inventory = InventoryManager.inventory
	
	if inventory.items.size() >= inventory.max_size: return false
	return true
