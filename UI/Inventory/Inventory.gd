extends Button
class_name Inventory

@export var normal_style: StyleBoxFlat
@export var pressed_style: StyleBoxFlat

#region Items
var items: Array[Item] = []
var max_size: int = 5

func add_item(item: Item) -> void:
	if item.in_inventory: # If it's already in some inventory - transfer this bitch instead
		var inventories: Array[Inventory] = [InventoryManager.inventory, InventoryManager.backpack, InventoryManager.storage]
		for inventory: Inventory in inventories:
			if inventory.items.has(item):
				inventory.transfer_item(item, self)
				return
	
	_add_item(item)
	item.monitorable = false
	item.hovered = false
	item.get_parent().hide()
	if is_instance_valid(InventoryManager.open_inventory): InventoryManager.show_entries(self)

func remove_item(item: Item) -> void:
	_remove_item(item)
	item.monitorable = true
	item.get_parent().show()
	if is_instance_valid(InventoryManager.open_inventory): InventoryManager.show_entries(self)
	
func transfer_item(item: Item, new_inventory: Inventory) -> void:
	if new_inventory.items.size() >= new_inventory.max_size:
		Chatbox.warning_message("[color=danger]No space.[/color]")
		return
		
	if item is BackpackItem && new_inventory != InventoryManager.inventory:
		Chatbox.warning_message("[color=danger]You can't fit it...[/color]")
		return
	
	SoundManager.play_sound_ui(SoundLib.inventory_sounds.pick_random(), -25.0)
	_remove_item(item)
	new_inventory._add_item(item)
	InventoryManager.show_entries(self)
	
func _add_item(item: Item) -> void:
	if !item: return
	
	var current_level: Level = get_tree().current_scene as Level
	if item.entity_id.length() > 0 && item.entity_id != "no_id" && current_level.static_entity_ids.has(item.entity_id):
		SaveState.remember_moved_item(get_tree().current_scene.get_scene_file_path(), item.entity_id)
		
	items.append(item)
	item._on_add_to_inventory(self)

func _remove_item(item: Item) -> void:
	if !item: return
	
	var current_level: Level = get_tree().current_scene as Level
	if item.entity_id.length() > 0 && item.entity_id != "no_id" && current_level.static_entity_ids.has(item.entity_id):
		SaveState.forget_moved_item(get_tree().current_scene.get_scene_file_path(), item.entity_id)
	
	items.erase(item)
	item._on_remove_from_inventory(self)
	
	# Take off clothes if you remove them
	if (item is ClothesItem) && item.is_equipped && self == InventoryManager.inventory:
		var human_rig: HumanRig = Player.this.character.rig as HumanRig
		human_rig.take_off_clothes(item as ClothesItem)
#endregion

#region Helpers
func rename(n: String) -> void: text = n.capitalize()
func resize(n: int) -> void: max_size = n
		
func _on_label_pressed() -> void:
	SoundManager.play_sound_ui(SoundLib.ui_click_sound, -20.0)
	if InventoryManager.open_inventory == self: InventoryManager.hide_entries()
	else: InventoryManager.show_entries(self)

func _on_label_mouse_entered() -> void: SoundManager.play_sound_ui(SoundLib.ui_hover_sound, -10.0)
#endregion
