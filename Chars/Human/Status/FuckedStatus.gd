extends Status
class_name FuckedStatus

func _init() -> void:
	title = ["Fucked"]
	description = ["You just had sex. Cooldown period until another sex instance can happen."]
	icon = load("res://UI/Status/Icons/Virginity.png")
	seconds = 10
	color = Red_Color
