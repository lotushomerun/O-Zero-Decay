extends Node
class_name ClothesLib

static var clothes_item: PackedScene = load("res://Interactable//Items/Clothes/ClothesItem.tscn")

#region Hats
static var baseball_cap: ClothesData = load("res://Interactable//Items/Clothes/Cap/Cap.tres")
static var all_hats: Array[ClothesData] = [baseball_cap]
#endregion

#region Glasses
#endregion

#region Masks
#endregion

#region Shirts
static var t_shirt: ClothesData = load("res://Interactable//Items/Clothes/TShirt/TShirt.tres")
static var all_shirts: Array[ClothesData] = [t_shirt]
#endregion

#region Jackets
#endregion

#region Pants
static var pants: ClothesData = load("res://Interactable//Items/Clothes/Pants/Pants.tres")
static var all_pants: Array[ClothesData] = [pants]
#endregion

#region Socks
static var socks: ClothesData = load("res://Interactable//Items/Clothes/Socks/Socks.tres")
static var all_socks: Array[ClothesData] = [socks]
#endregion

#region Shoes
static var sneakers: ClothesData = load("res://Interactable//Items/Clothes/Sneakers/Sneakers.tres")
static var all_shoes: Array[ClothesData] = [sneakers]
#endregion

#region Bras
static var plain_bra: ClothesData = load("res://Interactable//Items/Clothes/PlainBra/PlainBra.tres")
static var all_bras: Array[ClothesData] = [plain_bra]
#endregion

#region Panties
static var plain_panties: ClothesData = load("res://Interactable//Items/Clothes/PlainPanties/PlainPanties.tres")
static var all_panties: Array[ClothesData] = [plain_panties]
#endregion

#region Backpacks
static var backpack: PackedScene = load("res://Interactable//Items/Backpack/BackpackItem.tscn")
#endregion

#region Generation
static func create_clothes_item(t: ClothesData.ClothesType) -> Area2D:
	var clothes_instance: Area2D = clothes_item.instantiate() as Area2D
	var tree := Engine.get_main_loop() as SceneTree
	tree.current_scene.add_child(clothes_instance)
	
	var item: ClothesItem = clothes_instance.get_node("ClothesItem") as ClothesItem
	item.clothes_data = generate_clothes_data(t)
	item._apply_clothes_data()
	
	return clothes_instance

static func generate_clothes_data(t: ClothesData.ClothesType) -> ClothesData:
	var data: ClothesData
	
	match t:
		ClothesData.ClothesType.Hat: data = ClothesLib.all_hats.pick_random().duplicate()
		ClothesData.ClothesType.Shirt: data = ClothesLib.all_shirts.pick_random().duplicate()
		ClothesData.ClothesType.Pants: data = ClothesLib.all_pants.pick_random().duplicate()
		ClothesData.ClothesType.Socks: data = ClothesLib.all_socks.pick_random().duplicate()
		ClothesData.ClothesType.Shoes: data = ClothesLib.all_shoes.pick_random().duplicate()
		ClothesData.ClothesType.Bra: data = ClothesLib.all_bras.pick_random().duplicate()
		ClothesData.ClothesType.Panties: data = ClothesLib.all_panties.pick_random().duplicate()
	
	data.primary_color = randi_range(0, ClothesData.ClothesColor.size() - 1) as ClothesData.ClothesColor
	data.secondary_color = randi_range(0, ClothesData.ClothesColor.size() - 1) as ClothesData.ClothesColor
	data.third_color = randi_range(0, ClothesData.ClothesColor.size() - 1) as ClothesData.ClothesColor
	
	return data
	
static func generate_backpack_item() -> Area2D:
	var backpack_instance: Area2D = backpack.instantiate() as Area2D
	var tree := Engine.get_main_loop() as SceneTree
	tree.current_scene.add_child(backpack_instance)
	
	var item: BackpackItem = backpack_instance.get_node("BackpackItem") as BackpackItem
	item.primary_color = randi_range(0, ClothesData.ClothesColor.size() - 1) as ClothesData.ClothesColor
	item._apply_data()
	
	return backpack_instance
#endregion
