extends Action
class_name EquipBackpackAction

func _action_name() -> String: return "Put On"

func _execute(params: Array[Variant]) -> void:
	if params.size() < 2:
		push_warning("EquipBackpackAction: params.size() < 2!")
		super._execute(params)
		return
		
	var character: Char = params[0]
	var item: Item = params[1]
	
	Chatbox.system_message("[color=info]You put on %s.[/color]" % [item.entity_name])
	SoundManager.play_sound_2d(SoundLib.equip_sounds.pick_random(), character.global_position, -20.0)
	var rig: HumanRig = character.rig as HumanRig
	var backpack_item: BackpackItem = item as BackpackItem
	
	# Pick it up
	if !InventoryManager.inventory.items.has(item): InventoryManager.inventory.add_item(item)
	backpack_item.is_equipped = true
	
	# Apply shit
	backpack_item._equip(rig)
	backpack_item.inventory_container._give_items(InventoryManager.backpack)
	InventoryManager.show_inventory(InventoryManager.backpack)
	super._execute(params)
	
func _valid(params: Array[Variant]) -> bool:
	var _character: Char = params[0]
	var _item: Item = params[1]
	var inventory: Inventory = InventoryManager.inventory
	for i: Item in inventory.items: if i is BackpackItem: return false
	if inventory.items.size() >= inventory.max_size: return false
	return true
