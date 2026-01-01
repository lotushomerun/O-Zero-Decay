extends Node2D

@export var character: Human

func _ready() -> void:
	random_clothes()

func random_clothes() -> void:
	var shirt_instance: ClothesData = ClothesLib.generate_clothes_data(ClothesData.ClothesType.Shirt)
	var pants_instance: ClothesData = ClothesLib.generate_clothes_data(ClothesData.ClothesType.Pants)
	var socks_instance: ClothesData = ClothesLib.generate_clothes_data(ClothesData.ClothesType.Socks)
	var shoes_instance: ClothesData = ClothesLib.generate_clothes_data(ClothesData.ClothesType.Shoes)
	var bra_instance: ClothesData = ClothesLib.generate_clothes_data(ClothesData.ClothesType.Bra)
	var panties_instance: ClothesData = ClothesLib.generate_clothes_data(ClothesData.ClothesType.Panties)
	
	var to_equip: Array[ClothesData] = [bra_instance, panties_instance, shirt_instance, pants_instance, socks_instance, shoes_instance]
	for data: ClothesData in to_equip: character.rig._apply_clothes_data(data)
