extends Dependency
class_name FoodDependency

const First_Hunger: float = 5
const Second_Hunger: float = 10
const Third_Hunger: float = 15

func _init():
	super._init()
	description = "You need food to survive."
	thresholds = [First_Hunger, Second_Hunger, Third_Hunger]
	allow_negative_timer = true

func on_add_dependency() -> void:
	super.on_add_dependency()
	#Chatbox.important_message("[color=warning][b][i]You now need food to survive...[/i][/b][/color]", Chatbox.ColorLib["warning"])

func _on_threshold_reached(threshold: float) -> void:
	super._on_threshold_reached(threshold)
	match threshold:
		First_Hunger: print("You feel hungry...")
		Second_Hunger: print("You are getting weak!")
		Third_Hunger: print("You are starving!")
		
func _on_threshold_left(threshold: float) -> void:
	super._on_threshold_left(threshold)
	match threshold:
		First_Hunger: print("You are no longer hungry.")
		Second_Hunger: print("You feel your strength returning!")
		Third_Hunger: print("You are recovering from starvation!")
