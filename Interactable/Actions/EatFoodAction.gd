extends Action
class_name EatFoodAction

func _action_name() -> String: return "Eat"

func _execute(params: Array[Variant]) -> void:
	if params.size() < 2:
		push_warning("EatFoodAction: params.size() < 2!")
		super._execute(params)
		return
		
	var character: Char = params[0]
	var food: FoodItem = params[1]
	
	if character == Player.this.character:
		Chatbox.system_message("[color=info]You eat %s.[/color]" % [food.entity_name])
		var dependency: FoodDependency = Dependency.get_dependency("FoodDependency")
		dependency.satisfy(food.satiation)
		
	SoundManager.play_sound_2d(SoundLib.eat_sound, character.global_position, -15.0)
	
	if is_instance_valid(InventoryManager.open_inventory) && InventoryManager.open_inventory.items.has(food):
		InventoryManager.inventory.remove_item(food)
	
	super._execute(params)
	food.get_parent().queue_free()
