extends Node
class_name InventoryContainer

@export var max_size: int = 10
var items: Array[Item] = []

func _force_add_item(item_instance: Area2D) -> void:
	var item: Item
	for node: Node in item_instance.get_children():
		if node is Item:
			item = node
			break
	
	item._on_add_to_inventory(null)
	items.append(item)
	item.monitorable = false
	item_instance.hide()
	
	#_give_items(InventoryManager.backpack)

func _give_items(inventory: Inventory) -> void:
	inventory.max_size = max_size
	inventory.items = items

func _get_items(inventory: Inventory) -> void:
	items = inventory.items
