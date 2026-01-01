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
		First_Hunger:
			Chatbox.warning_message("[color=info]You feel hungry...[/color]")
			Player.this.character.add_status(HungryStatus.new())
		Second_Hunger:
			Chatbox.warning_message("[color=warning]You are getting weak![/color]")
			Player.this.character.stage_status(Player.this.character.get_status("HungryStatus"), 1)
		Third_Hunger:
			Chatbox.warning_message("[color=danger][b][i]You are starving![/i][/b][/color]")
			Player.this.character.stage_status(Player.this.character.get_status("HungryStatus"), 2)
		
func _on_threshold_left(threshold: float) -> void:
	super._on_threshold_left(threshold)
	match threshold:
		First_Hunger: 
			Chatbox.regular_message("[color=good]You are no longer hungry.[/color]")
			Player.this.character.remove_status(Player.this.character.get_status("HungryStatus"))
		Second_Hunger:
			Chatbox.regular_message("[color=good]You feel your strength returning![/color]")
			Player.this.character.stage_status(Player.this.character.get_status("HungryStatus"), 0)
		Third_Hunger:
			Chatbox.regular_message("[color=good]You are recovering from starvation![/color]")
			Player.this.character.stage_status(Player.this.character.get_status("HungryStatus"), 1)