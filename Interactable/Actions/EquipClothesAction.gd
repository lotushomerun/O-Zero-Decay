extends Action
class_name EquipClothesAction

func _action_name() -> String: return "Put On"

func _execute(params: Array[Variant]) -> void:
	if params.size() < 2:
		push_warning("EquipClothesAction: params.size() < 2!")
		super._execute(params)
		return
		
	var character: Char = params[0]
	var item: Item = params[1]
	
	Chatbox.system_message("[color=info]You put on %s.[/color]" % [item.entity_name])
	SoundManager.play_sound_2d(SoundLib.clothes_sounds.pick_random(), character.global_position, -20.0)
	var rig: HumanRig = character.rig as HumanRig
	var clothes_item: ClothesItem = item as ClothesItem
	
	# Pick it up
	if !InventoryManager.inventory.items.has(item): InventoryManager.inventory.add_item(item)
	clothes_item.is_equipped = true
	
	# Apply shit
	rig.put_on_clothes(clothes_item)
	super._execute(params)
	
func _valid(params: Array[Variant]) -> bool:
	var character: Char = params[0]
	var item: Item = params[1]
	
	var rig: HumanRig = character.rig as HumanRig
	var clothes_item: ClothesItem = item as ClothesItem
	var inventory: Inventory = InventoryManager.inventory
	
	if rig._is_already_wearing(clothes_item.clothes_data.clothes_type): return false
	if inventory.items.size() >= inventory.max_size && !inventory.items.has(clothes_item): return false
	
	return true
