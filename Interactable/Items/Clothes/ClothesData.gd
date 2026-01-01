extends Resource
class_name ClothesData

enum ClothesType { Hat, Glasses, Mask, Shirt, Jacket, Pants, Socks, Shoes, Bra, Panties }
@export var clothes_type: ClothesType
@export var clothes_name: String = "clothes"
@export_multiline var clothes_desc: String = "Ohhh, fabric."

@export_category("Condition")
@export_range(0.0, 1.0, 0.01) var wetness: float = 0.0
@export_range(0.0, 1.0, 0.01) var dirtiness: float = 0.0

func add_wetness(n: float) -> void: wetness = clampf(wetness + n, 0.0, 1.0)
func add_dirtiness(n: float) -> void: dirtiness = clampf(dirtiness + n, 0.0, 1.0)

@export_category("Icons")
@export var discarded_icon: Texture2D
@export var boobs_icon: Texture2D
@export var no_boobs_icon: Texture2D

@export_category("Colors")
enum ClothesColor { White, Black, Dark_Grey, Grey, Red, Blue, Green }
@export var random_color: bool = false
@export var primary_color: ClothesColor = ClothesColor.White
@export var secondary_color: ClothesColor = ClothesColor.White
@export var third_color: ClothesColor = ClothesColor.White

static var clothes_color_pool := {
	ClothesColor.White: Color(1.0, 1.0, 1.0, 1.0),
	ClothesColor.Black: Color(0.13, 0.13, 0.13, 1.0),
	ClothesColor.Dark_Grey: Color(0.241, 0.241, 0.241, 1.0),
	ClothesColor.Grey: Color(0.435, 0.435, 0.435, 1.0),
	ClothesColor.Red: Color(0.7, 0.14, 0.14, 1.0),
	ClothesColor.Blue: Color(0.086, 0.287, 0.72, 1.0),
	ClothesColor.Green: Color(0.228, 0.65, 0.249, 1.0),
}
