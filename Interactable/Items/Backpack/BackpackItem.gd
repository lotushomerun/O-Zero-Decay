extends Item
class_name BackpackItem

@export_group("Nodes")
@export var sprite2d: Sprite2D
@export var inventory_container: InventoryContainer

@export_group("Info")
@export var primary_name: String = "entity"
@export var primary_color: ClothesData.ClothesColor = ClothesData.ClothesColor.Dark_Grey

#region Save/Load
func get_save_data() -> Dictionary:
	var dict: Dictionary = super.get_save_data()
	dict["primary_name"] = primary_name
	dict["primary_color"] = ClothesData.ClothesColor.keys()[primary_color]
	
	if is_instance_valid(inventory_container):
		var items: Array = []
		for item: Item in inventory_container.items: if is_instance_valid(item): items.append(item.get_save_data())
		dict["items"] = items
		dict["max_size"] = inventory_container.max_size
		
	return dict

func load_save_data(data: Dictionary) -> void:
	super.load_save_data(data)
	primary_name = data["primary_name"]
	primary_color = ClothesData.ClothesColor[data["primary_color"]]
	
	var items: Array = data["items"]
	if items.size() > 0:
		
		# Spawn items from saved inventory data
		for item_data: Dictionary in items:
			var parent_scene_path: String = item_data["parent_scene"]
			var parent_instance: Node = load(parent_scene_path).instantiate()
			get_tree().current_scene.add_child(parent_instance)
			
			var item_ref: Item
			for node: Node in parent_instance.get_children():
				if node is Item:
					item_ref = node
					break
					
			item_ref.load_save_data(item_data)
			inventory_container._force_add_item(parent_instance)
	
	_apply_data()
#endregion

func _ready() -> void:
	super._ready()
	actions.append(EquipBackpackAction.new())
	_apply_data()
	
func _apply_data() -> void:
	var color_name: String = ClothesData.ClothesColor.keys()[primary_color]
	entity_name = "%s %s" % [color_name.capitalize().to_lower(), primary_name]
	
	var shadermat: ShaderMaterial = sprite2d.material as ShaderMaterial
	var _primary_color: Color = ClothesData.clothes_color_pool[primary_color]
	shadermat.set_shader_parameter("target_color", _primary_color)

func _equip(rig: HumanRig) -> void:
	if !rig || !rig.backpack_node || !rig.backpack_node.material: return
	
	var shadermat: ShaderMaterial = rig.backpack_node.material as ShaderMaterial
	var _primary_color: Color = ClothesData.clothes_color_pool[primary_color]
	rig.backpack_node.texture = sprite2d.texture
	shadermat.set_shader_parameter("target_color", _primary_color)
	
func _unequip(rig: HumanRig) -> void:
	if !rig || !rig.backpack_node: return
	rig.backpack_node.texture = null

func _on_add_to_inventory(_inventory: Inventory) -> void:
	super._on_add_to_inventory(_inventory)
	remove_action("EquipBackpackAction")
	actions.append(UnequipBackpackAction.new())

func _on_remove_from_inventory(_inventory: Inventory) -> void:
	super._on_remove_from_inventory(_inventory)
	remove_action("UnequipBackpackAction")
	actions.append(EquipBackpackAction.new())
