extends Item
class_name ClothesItem

@export var sprite2d: Sprite2D
@export var clothes_data: ClothesData

#region Save/Load
func get_save_data() -> Dictionary:
	var dict: Dictionary = super.get_save_data()
	if clothes_data != null:
		dict["clothes_type"] = ClothesData.ClothesType.keys()[clothes_data.clothes_type]
		dict["clothes_name"] = clothes_data.clothes_name
		dict["clothes_desc"] = clothes_data.clothes_desc
		dict["wetness"] = clothes_data.wetness
		dict["dirtiness"] = clothes_data.dirtiness
		dict["discarded_icon_path"] = clothes_data.discarded_icon.resource_path
		dict["boobs_icon_path"] = clothes_data.boobs_icon.resource_path
		dict["no_boobs_icon_path"] = clothes_data.no_boobs_icon.resource_path
		dict["primary_color"] = ClothesData.ClothesColor.keys()[clothes_data.primary_color]
		dict["secondary_color"] = ClothesData.ClothesColor.keys()[clothes_data.secondary_color]
		dict["third_color"] = ClothesData.ClothesColor.keys()[clothes_data.third_color]
	return dict

func load_save_data(data: Dictionary) -> void:
	super.load_save_data(data)
	clothes_data = ClothesData.new()
	clothes_data.clothes_type = ClothesData.ClothesType[data["clothes_type"]]
	clothes_data.clothes_name = data["clothes_name"]
	clothes_data.clothes_desc = data["clothes_desc"]
	clothes_data.wetness = data["wetness"]
	clothes_data.dirtiness = data["dirtiness"]
	clothes_data.discarded_icon = load(data["discarded_icon_path"])
	clothes_data.boobs_icon = load(data["boobs_icon_path"])
	clothes_data.no_boobs_icon = load(data["no_boobs_icon_path"])
	clothes_data.primary_color = ClothesData.ClothesColor[data["primary_color"]]
	clothes_data.secondary_color = ClothesData.ClothesColor[data["secondary_color"]]
	clothes_data.third_color = ClothesData.ClothesColor[data["third_color"]]
	_apply_clothes_data()
#endregion

func _ready() -> void:
	super._ready()
	_apply_clothes_data()
	actions.append(EquipClothesAction.new())
	
func _process(delta: float) -> void:
	super._process(delta)
	if clothes_data != null: clothes_data.add_wetness(-delta * 0.01)
		
func _apply_clothes_data() -> void:
	if clothes_data == null: return
	
	if sprite2d != null:
		var color: Color = ClothesData.clothes_color_pool[clothes_data.primary_color]
		sprite2d.modulate = color
	
	var color_name: String = ClothesData.ClothesColor.keys()[clothes_data.primary_color]
	entity_name = "%s %s" % [color_name.capitalize().to_lower(), clothes_data.clothes_name]
	entity_desc = clothes_data.clothes_desc
	
