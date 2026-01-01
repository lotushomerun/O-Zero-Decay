extends Item
class_name FoodItem

@export_group("Nodes")
@export var sprite2d: Sprite2D

@export_group("Food")
@export var satiation: float = 60.0 # How much seconds worth of food it gives us

func _ready() -> void:
	super._ready()
	actions.append(EatFoodAction.new())
