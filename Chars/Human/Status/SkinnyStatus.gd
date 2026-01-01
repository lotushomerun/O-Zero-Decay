extends Status
class_name SkinnyStatus

func _init() -> void:
	title = ["Skinny"]
	description = ["You're underweight! It's easier to throw you around!"]
	icon = load("res://UI/Status/Icons/Skinny.png")
	infinite = true
	color = Red_Color
