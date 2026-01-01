extends Status
class_name HungryStatus

func _init() -> void:
	title = ["Hungry", "Very Hungry", "Starving!"]
	description = ["You are hungry", "Weak with hunger", "Just a crumb, a berry, a cockroach, anything..."]
	icon = load("res://UI/Status/Icons/Tall.png")
	infinite = true
	color = Red_Color
