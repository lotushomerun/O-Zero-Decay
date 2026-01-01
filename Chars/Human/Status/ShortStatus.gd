extends Status
class_name ShortStatus

func _init() -> void:
	title = "Short"
	description = "You'll never reach the top shelf..."
	icon = load("res://UI/Status/Icons/Short.png")
	infinite = true
	color = Red_Color
